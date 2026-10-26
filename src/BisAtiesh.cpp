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
#include <sstream>
#include <string>
#include <vector>
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
    char const* const NOM_TETE  = "Staff Head of Atiesh";
    char const* const NOM_BASE  = "Base of Atiesh";
    char const* const NOM_BATON = "Atiesh, Greatstaff of the Guardian";

    uint32 eclatId = 0;
    uint32 teteId  = 0;
    uint32 baseId  = 0;
    std::unordered_map<uint8, uint32> batons;  // classe -> entry
    bool charge = false;

    void Charger()
    {
        charge = true;
        eclatId = 0;
        teteId  = 0;
        baseId  = 0;
        batons.clear();

        // Resolution par NOM et non par identifiant code en dur : un serveur
        // qui renumerote ses objets, ou qui ajoute une version du baton, est
        // suivi sans toucher au module. Si un nom ne sort pas, le journal le
        // dit et la fonctionnalite reste inerte - elle ne devine pas.
        QueryResult res = WorldDatabase.Query(
            "SELECT `entry`, `name`, `AllowableClass` FROM `item_template` "
            "WHERE `name` IN ('{}', '{}', '{}', '{}')",
            NOM_ECLAT, NOM_TETE, NOM_BASE, NOM_BATON);
        if (!res)
        {
            LOG_INFO("server.loading", "[mod-playerbots-bis] Atiesh : aucun composant trouve dans item_template");
            return;
        }

        struct Candidat
        {
            uint32 entry;
            int32 classes;
        };
        std::vector<Candidat> candidats;

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

            if (nom == NOM_TETE)
            {
                teteId = entry;
                continue;
            }

            if (nom == NOM_BASE)
            {
                baseId = entry;
                continue;
            }

            // Le baton. Mis de cote pour un rangement en DEUX PASSES, plus
            // bas : l'ordre des lignes ne doit pas decider du resultat.
            candidats.push_back({entry, classes});
        } while (res->NextRow());

        // DEUX PASSES, et c'est tout l'interet. CINQ objets portent le nom
        // "Atiesh, Greatstaff of the Guardian" : les quatre versions de classe
        // - mage, demoniste, pretre, druide - et le baton NON IMPREGNE, etape
        // intermediaire de la chaine, que rien ne reserve a une classe.
        //
        // Une passe unique rangeait le premier venu : si la base renvoyait le
        // baton non impregne en tete, il raflait la place de TOUTES les classes
        // et le collecteur recevait l'etape intermediaire au lieu de son arme.
        // La requete n'ayant pas d'ORDER BY, le resultat dependait de l'humeur
        // du moteur.
        //
        // Donc : d'abord ce qui est reserve a une classe, et seulement ensuite
        // ce qui ne l'est pas, pour combler les classes restees vides.
        for (auto const& c : candidats)
        {
            if (c.classes == -1)
                continue;

            for (uint8 classe = 1; classe <= DERNIERE_CLASSE; ++classe)
                if (static_cast<uint32>(c.classes) & (1u << (classe - 1)))
                    if (!batons.count(classe))
                        batons[classe] = c.entry;
        }

        for (auto const& c : candidats)
        {
            if (c.classes != -1)
                continue;

            for (uint8 classe = 1; classe <= DERNIERE_CLASSE; ++classe)
                if (!batons.count(classe))
                    batons[classe] = c.entry;
        }

        LOG_INFO("server.loading",
                 "[mod-playerbots-bis] Atiesh : eclat {}, tete {}, base {}, {} version(s) du baton",
                 eclatId, teteId, baseId, static_cast<uint32>(batons.size()));
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

    // CE QUE LE COLLECTEUR TIENT, a la derniere observation. Sert a ne parler
    // que lorsque le compte BOUGE : repeter "7/40" toutes les quinze secondes
    // noierait le canal et rendrait l'annonce inutile.
    struct Avancement
    {
        uint32 eclats = 0;
        bool tete = false;
        bool base = false;
        bool connu = false;
    };

    std::unordered_map<ObjectGuid, Avancement> suivi;

    // L'annonce de progression. Un eclat qui tombe ne dit rien de lui-meme -
    // le message de butin se perd dans le flot d'un raid de quarante - et sans
    // compteur on ne sait jamais ou on en est sans fouiller les sacs du bot.
    void AnnoncerLaCollecte(Player* player)
    {
        if (!eclatId)
            return;

        uint32 const requis = sBisPriorityMgr->AtieshSplinters();

        Avancement maintenant;
        maintenant.eclats = player->GetItemCount(eclatId, true);
        maintenant.tete = teteId && player->GetItemCount(teteId, true) > 0;
        maintenant.base = baseId && player->GetItemCount(baseId, true) > 0;
        maintenant.connu = true;

        Avancement const avant = suivi[player->GetGUID()];
        suivi[player->GetGUID()] = maintenant;

        // Rien en main : rien a dire. Evite aussi d'annoncer "0/40" au premier
        // demarrage, quand la collecte n'a pas commence.
        if (!maintenant.eclats && !maintenant.tete && !maintenant.base)
            return;

        // Au tout premier passage l'etat n'est pas "connu" : on annonce, ce qui
        // rappelle ou en est la collecte apres chaque redemarrage. Ensuite, on
        // ne parle que si quelque chose a ete GAGNE - un compte qui descend est
        // un assemblage ou une suppression, pas une progression.
        bool const progresse = !avant.connu
                               || maintenant.eclats > avant.eclats
                               || (maintenant.tete && !avant.tete)
                               || (maintenant.base && !avant.base);
        if (!progresse)
            return;

        PlayerbotAI* botAI = GET_PLAYERBOT_AI(player);
        if (!botAI)
            return;

        std::ostringstream out;
        out << "Eclat d'Atiesh : " << maintenant.eclats << "/" << requis;

        // Ce qui manque n'est dit qu'une fois les eclats reunis. Avant ca,
        // c'est du bruit : la Tete et la Base tombent en fin de raid, il est
        // normal de ne pas les avoir.
        if (maintenant.eclats >= requis)
        {
            if (!maintenant.tete && !maintenant.base)
                out << " - il manque la Tete et la Base";
            else if (!maintenant.tete)
                out << " - il manque la Tete";
            else if (!maintenant.base)
                out << " - il manque la Base";
        }
        else
        {
            if (maintenant.tete)
                out << " - Tete en main";
            if (maintenant.base)
                out << " - Base en main";
        }

        botAI->TellMaster(out.str());
    }

    // L'assemblage. Quarante eclats plus la base deviennent le baton.
    bool Assembler(Player* player)
    {
        if (!EstLeCollecteur(player) || !eclatId || !teteId || !baseId)
            return false;

        uint32 const batonId = BatonDe(player);
        if (!batonId || DejaServi(player))
            return false;

        uint32 const requis = sBisPriorityMgr->AtieshSplinters();
        if (player->GetItemCount(eclatId, true) < requis)
            return false;

        // La Tete et la Base tombent sur des boss differents de la fin du
        // raid : les quarante eclats peuvent etre reunis bien avant elles.
        if (!player->GetItemCount(teteId, true) || !player->GetItemCount(baseId, true))
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
        player->DestroyItemCount(teteId, 1, true);
        player->DestroyItemCount(baseId, 1, true);

        Item* const baton = player->StoreNewItem(place, batonId, true);
        if (!baton)
        {
            LOG_ERROR("server.loading",
                      "[mod-playerbots-bis] Atiesh : StoreNewItem a echoue pour {} apres destruction",
                      player->GetName());
            return false;
        }

        LOG_INFO("server.loading",
                 "[mod-playerbots-bis] Atiesh : {} assemble le baton {} ({} eclats + la tete + la base)",
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
        return itemId && (itemId == eclatId || itemId == teteId || itemId == baseId);
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

        // La Tete et la Base sont uniques - maxcount 1 dans item_template.
        // Un second exemplaire ne sert a rien et prive le raid ; le coeur
        // refuserait d'ailleurs de le ranger.
        if ((itemId == teteId || itemId == baseId) && bot->GetItemCount(itemId, true) > 0)
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

        if (!EstLeCollecteur(player))
            return;

        AnnoncerLaCollecte(player);
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

        // L'eclat suffit a tenir le compteur. La Tete, la Base et les versions
        // du baton ne servent qu'a l'assemblage, qui verifie lui-meme ce qui
        // lui manque : sans ca, une base absente de item_template ferait taire
        // aussi le suivi de collecte.
        if (!eclatId)
            return;

        for (auto const& paire : ObjectAccessor::GetPlayers())
        {
            Player* player = paire.second;
            if (!player || !EstLeCollecteur(player))
                continue;

            AnnoncerLaCollecte(player);
            Assembler(player);
        }
    }

private:
    // Quinze secondes. Plus court que les livres de sort, parce que le compteur
    // "x/40" doit arriver pendant que tu regardes encore le butin, pas une
    // minute plus tard. Le cout reste nul : tout sauf le collecteur est ecarte
    // par une comparaison de nom, et lui seul fait lire des sacs.
    static constexpr uint32 INTERVALLE_MS = 15 * 1000;

    uint32 _depuis = 0;
};

void AddSC_playerbots_bis_atiesh()
{
    new BisAtieshPlayerScript();
    new BisAtieshWorldScript();
}
