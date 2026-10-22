/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisAtiesh.h"
#include "BisPriorityMgr.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "ScriptMgr.h"
#include <algorithm>
#include <cctype>
#include <string>
#include <unordered_map>

// CE QUE LE MODULE FAIT, ET CE QU'IL NE FAIT PAS.
//
// Il fait l'echange que fait la chaine de quetes : quarante eclats plus la
// base donnent le baton de la classe du collecteur. Il ne fait PAS le trajet
// jusqu'a Anachronos, ni les etapes intermediaires - Cadre d'Atiesh, Atiesh
// souille - parce qu'un bot ne sait pas rendre une quete a un PNJ de Tanaris.
//
// Le resultat est donc celui du jeu ; c'est le chemin qui est raccourci. Dit
// autrement : rien n'est donne, il faut que les quarante eclats soient tombes.
//
// LA VERSION DU BATON SE DEDUIT, elle ne se configure pas. Quatre objets
// portent le nom "Atiesh, Greatstaff of the Guardian" - mage, demoniste,
// pretre, druide - et AllowableClass les departage. Le collecteur recoit celui
// que sa classe peut porter, et changer de collecteur change de version sans
// toucher a la configuration.

namespace
{
    // Druide, la derniere des classes de 3.3.5. En dur plutot que MAX_CLASSES
    // pour ne dependre d'aucun en-tete du coeur : la boucle qui s'en sert ne
    // fait que lire des bits d'AllowableClass.
    uint8 const DERNIERE_CLASSE = 11;

    char const* const NOM_ECLAT = "Splinter of Atiesh";
    char const* const NOM_BASE  = "Base of Atiesh";
    char const* const NOM_BATON = "Atiesh, Greatstaff of the Guardian";

    uint32 eclatId = 0;
    uint32 baseId  = 0;
    std::unordered_map<uint8, uint32> batons;  // classe -> entry
    bool charge = false;

    void Charger()
    {
        charge = true;
        eclatId = 0;
        baseId  = 0;
        batons.clear();

        // Resolution par NOM et non par identifiant code en dur : un serveur
        // qui renumerote ses objets, ou qui ajoute une version du baton, est
        // suivi sans toucher au module. Si un nom ne sort pas, le journal le
        // dit et la fonctionnalite reste inerte - elle ne devine pas.
        QueryResult res = WorldDatabase.Query(
            "SELECT `entry`, `name`, `AllowableClass` FROM `item_template` "
            "WHERE `name` IN ('{}', '{}', '{}')",
            NOM_ECLAT, NOM_BASE, NOM_BATON);
        if (!res)
        {
            LOG_INFO("server.loading", "[mod-playerbots-bis] Atiesh : aucun composant trouve dans item_template");
            return;
        }

        do
        {
            Field* fields = res->Fetch();

            uint32 const entry = fields[0].Get<uint32>();
            std::string const nom = fields[1].Get<std::string>();
            int32 const classes = fields[2].Get<int32>();

            if (nom == NOM_ECLAT)
            {
                eclatId = entry;
                continue;
            }

            if (nom == NOM_BASE)
            {
                baseId = entry;
                continue;
            }

            // Le baton. AllowableClass vaut -1 quand l'objet n'est reserve a
            // personne, sinon un masque ou la classe N occupe le bit N-1. On
            // range l'objet sous chaque classe qui peut le porter : une seule
            // pour les quatre versions d'Atiesh.
            for (uint8 classe = 1; classe <= DERNIERE_CLASSE; ++classe)
            {
                uint32 const bit = 1u << (classe - 1);
                if (classes != -1 && !(static_cast<uint32>(classes) & bit))
                    continue;

                // Premier arrive, premier servi : si deux objets du meme nom
                // visaient la meme classe, prendre le plus petit identifiant
                // est arbitraire mais stable d'un demarrage a l'autre.
                if (!batons.count(classe))
                    batons[classe] = entry;
            }
        } while (res->NextRow());

        LOG_INFO("server.loading",
                 "[mod-playerbots-bis] Atiesh : eclat {}, base {}, {} version(s) du baton",
                 eclatId, baseId, static_cast<uint32>(batons.size()));
    }

    void ChargerSiBesoin()
    {
        if (!charge)
            Charger();
    }

    std::string EnMinuscules(std::string texte)
    {
        std::transform(texte.begin(), texte.end(), texte.begin(),
                       [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
        return texte;
    }

    // Le collecteur designe. Nomme dans la configuration, compare sans tenir
    // compte de la casse - personne ne tape le nom de son bot a la majuscule
    // pres. Vide = fonctionnalite eteinte, ce qui est le defaut.
    //
    // Aucun test "est-ce un bot" : nommer son propre personnage est un usage
    // legitime, et c'est meme le seul moyen de porter Atiesh soi-meme, les
    // composants etant lies quand ramasses.
    bool EstLeCollecteur(Player* player)
    {
        if (!player)
            return false;

        std::string const& voulu = sBisPriorityMgr->AtieshCollector();
        if (voulu.empty())
            return false;

        return EnMinuscules(player->GetName()) == EnMinuscules(voulu);
    }

    // Le baton que CE joueur peut porter, 0 si sa classe n'a pas de version.
    uint32 BatonDe(Player* player)
    {
        auto itr = batons.find(player->getClass());
        return itr == batons.end() ? 0 : itr->second;
    }

    // Le travail est-il fini ? Le collecteur tient deja son baton : il cesse
    // de reclamer les eclats, qui ne lui servent plus a rien et qui priveraient
    // un futur collecteur.
    bool DejaServi(Player* player)
    {
        uint32 const batonId = BatonDe(player);
        return batonId && player->GetItemCount(batonId, true) > 0;
    }

    // L'assemblage. Quarante eclats plus la base deviennent le baton.
    bool Assembler(Player* player)
    {
        if (!EstLeCollecteur(player) || !eclatId || !baseId)
            return false;

        uint32 const batonId = BatonDe(player);
        if (!batonId || DejaServi(player))
            return false;

        uint32 const requis = sBisPriorityMgr->AtieshSplinters();
        if (player->GetItemCount(eclatId, true) < requis)
            return false;

        if (!player->GetItemCount(baseId, true))
            return false;

        // LA PLACE D'ABORD. Detruire quarante eclats pour decouvrir ensuite que
        // les sacs sont pleins perdrait un raid entier de collecte. Le test
        // passe avant la moindre destruction, et un echec se retente au
        // balayage suivant.
        ItemPosCountVec place;
        if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, place, batonId, 1) != EQUIP_ERR_OK)
        {
            LOG_INFO("server.loading",
                     "[mod-playerbots-bis] Atiesh : {} a les composants mais les sacs pleins",
                     player->GetName());
            return false;
        }

        player->DestroyItemCount(eclatId, requis, true);
        player->DestroyItemCount(baseId, 1, true);

        Item* const baton = player->StoreNewItem(place, batonId, true);
        if (!baton)
        {
            LOG_ERROR("server.loading",
                      "[mod-playerbots-bis] Atiesh : StoreNewItem a echoue pour {} apres destruction",
                      player->GetName());
            return false;
        }

        LOG_INFO("server.loading", "[mod-playerbots-bis] Atiesh : {} assemble le baton {} ({} eclats + la base)",
                 player->GetName(), batonId, requis);

        // Dit a voix haute, parce que c'est l'evenement d'un serveur entier et
        // qu'il n'apparait nulle part ailleurs : aucun jet, aucun message de
        // butin ne signale un objet cree hors du jeu.
        if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(player))
            botAI->TellMaster("Atiesh est assemble.");

        return true;
    }
}

namespace BisAtiesh
{
    bool EstUnComposant(uint32 itemId)
    {
        ChargerSiBesoin();
        return itemId && (itemId == eclatId || itemId == baseId);
    }

    bool Reclame(Player* bot, uint32 itemId)
    {
        if (!EstUnComposant(itemId))
            return false;

        if (!EstLeCollecteur(bot))
            return false;

        // Sa classe n'a pas de version du baton : le laisser collecter
        // quarante eclats qu'il ne pourra jamais echanger n'a pas de sens.
        if (!BatonDe(bot))
            return false;

        if (DejaServi(bot))
            return false;

        // La base est unique : une seconde ne sert a rien et prive le raid.
        if (itemId == baseId && bot->GetItemCount(baseId, true) > 0)
            return false;

        // Et les eclats s'arretent au compte voulu, pour la meme raison.
        if (itemId == eclatId && bot->GetItemCount(eclatId, true) >= sBisPriorityMgr->AtieshSplinters())
            return false;

        return true;
    }
}

class BisAtieshPlayerScript : public PlayerScript
{
public:
    BisAtieshPlayerScript() : PlayerScript("BisAtieshPlayerScript", {PLAYERHOOK_ON_LOGIN}) {}

    void OnPlayerLogin(Player* player) override
    {
        ChargerSiBesoin();
        Assembler(player);
    }
};

// Le balayage. Le quarantieme eclat arrive en cours de raid, et le collecteur
// ne se reconnecte pas pour autant : sans lui, le baton attendrait la prochaine
// connexion du bot.
class BisAtieshWorldScript : public WorldScript
{
public:
    BisAtieshWorldScript() : WorldScript("BisAtieshWorldScript") {}

    void OnUpdate(uint32 diff) override
    {
        // La fonctionnalite eteinte ne coute qu'une lecture de chaine.
        if (sBisPriorityMgr->AtieshCollector().empty())
            return;

        _depuis += diff;
        if (_depuis < INTERVALLE_MS)
            return;
        _depuis = 0;

        ChargerSiBesoin();
        if (!eclatId || !baseId || batons.empty())
            return;

        for (auto const& paire : ObjectAccessor::GetPlayers())
            Assembler(paire.second);
    }

private:
    // Une minute, comme les livres de sort : assez court pour que le baton
    // arrive avant le boss suivant, assez long pour que le balayage ne pese
    // rien - il ne lit les sacs que du seul collecteur.
    static constexpr uint32 INTERVALLE_MS = 60 * 1000;

    uint32 _depuis = 0;
};

void AddSC_playerbots_bis_atiesh()
{
    new BisAtieshPlayerScript();
    new BisAtieshWorldScript();
}
