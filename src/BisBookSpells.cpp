/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisBookSpells.h"
#include "Bag.h"
#include "BisPriorityMgr.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include <unordered_map>
#include <vector>

// QU'EST-CE QU'ON CORRIGE, ET QU'EST-CE QU'ON NE CORRIGE PAS
// ----------------------------------------------------------
// A niveau 60 le maitre de classe ne va pas plus loin, et le dernier rang
// s'achete en livre : Codex de Priere de soins V, Tome de Boule de feu XII,
// Grimoire de Trait de l'ombre X... TBC a reverse ces sorts sur les maitres,
// mais a ReqLevel 61, precisement pour que le livre garde sa valeur a 60 :
//
//     SELECT TrainerId, ReqLevel FROM trainer_spell WHERE SpellId = 25316;
//     -> 11 | 61
//
// C'est la regle du jeu, pas un trou de donnees, et le module ne la contourne
// pas : le dernier rang reste une trouvaille.
//
// CE QUI MANQUAIT VRAIMENT. mod-playerbots n'apprend les sorts que par les
// maitres (PlayerbotFactory::InitAvailableSpells). Un livre qui tombe dans le
// sac d'un bot n'est donc jamais ouvert : il y dort, ou part chez le marchand.
// Et comme un livre n'est ni arme ni armure, aucun bot ne vote dessus au jet
// de butin - il echoit au premier venu, souvent a qui ne peut pas le lire.
//
// Le module ferme donc la boucle, des deux cotes :
//   - au JET, un bot qui saurait lire le livre le reclame (BisLootRollAction) ;
//   - en SAC, il l'ouvre : le sort est appris, le livre consomme.
//
// Rien n'est donne. Il faut que le livre soit tombe.
//
// LA PORTE DE SERVICE. PlayerbotsBis.TeachBookSpells, a 0 par defaut, donne les
// sorts sans livre. C'est une triche assumee - voir le fichier conf - pour un
// serveur qui veut ses soigneurs au plein rang sans attendre les drops.

namespace
{
    struct LivreDeSort
    {
        uint32 spellId;
        int32 classesAutorisees;  // AllowableClass, -1 = toutes
        uint8 niveauRequis;
    };

    std::unordered_map<uint32, LivreDeSort> livres;  // itemId -> livre
    bool livresCharges = false;

    void ChargerLesLivres()
    {
        livresCharges = true;
        livres.clear();

        // La liste n'est pas codee en dur : ce sont exactement les items de
        // classe 9 (recette) / sous-classe 0 (livre de sort) dont le premier
        // sort est 483, "Apprentissage", et le second le sort enseigne. Un
        // serveur qui modifie ces items, ou qui en ajoute, est suivi sans
        // toucher au module.
        QueryResult res = WorldDatabase.Query(
            "SELECT `entry`, `spellid_2`, `AllowableClass`, `RequiredLevel` FROM `item_template` "
            "WHERE `class` = 9 AND `subclass` = 0 AND `spellid_1` = 483 AND `spellid_2` > 0");
        if (!res)
        {
            LOG_INFO("server.loading", "[mod-playerbots-bis] Aucun livre de sort dans item_template");
            return;
        }

        do
        {
            Field* fields = res->Fetch();

            uint32 const itemId = fields[0].Get<uint32>();

            LivreDeSort livre;
            livre.spellId = fields[1].Get<uint32>();
            livre.classesAutorisees = fields[2].Get<int32>();
            livre.niveauRequis = static_cast<uint8>(fields[3].Get<uint32>());

            // Un sort absent du DBC ne s'apprend pas : le learnSpell partirait
            // dans le vide et le livre serait detruit pour rien.
            if (!sSpellMgr->GetSpellInfo(livre.spellId))
                continue;

            livres[itemId] = livre;
        } while (res->NextRow());

        LOG_INFO("server.loading", "[mod-playerbots-bis] {} livres de sort repertories",
                 static_cast<uint32>(livres.size()));
    }

    // Seuls les bots du vivier. IsRandomBot repond des la connexion, sans
    // dependre du moment ou mod-playerbots attache son IA - ce qui n'est pas
    // garanti quand OnPlayerLogin passe. Un personnage de JOUEUR n'est jamais
    // touche : ses livres sont a lui, et c'est a lui de les ouvrir.
    bool EstUnBotDuVivier(Player* player)
    {
        return player && sRandomPlayerbotMgr.IsRandomBot(player);
    }

    // Ce bot peut-il apprendre ce sort maintenant ? Le test est le meme que
    // celui du jeu : classe, niveau, rang precedent, et pas deja su.
    bool PeutApprendreLeSort(Player* bot, LivreDeSort const& livre)
    {
        uint32 const masque = 1u << (bot->getClass() - 1);

        if (livre.classesAutorisees != -1 && !(static_cast<uint32>(livre.classesAutorisees) & masque))
            return false;

        if (livre.niveauRequis > bot->GetLevel())
            return false;

        if (bot->HasSpell(livre.spellId))
            return false;

        // Le garde-fou de race et de classe du coeur. Il attrape ce que le
        // masque de l'item laisse passer - AllowableClass porte encore des bits
        // de classes qui n'existent pas.
        if (!bot->IsSpellFitByClassAndRace(livre.spellId))
            return false;

        // Un rang ne se pose pas par-dessus un trou : sans le rang precedent,
        // c'est que le bot n'a pas le sort du tout, et le livre ne doit pas
        // servir de raccourci.
        if (uint32 const precedent = sSpellMgr->GetPrevSpellInChain(livre.spellId))
            if (!bot->HasSpell(precedent))
                return false;

        return true;
    }

    // Ouvrir les livres que le bot porte. Le sort est appris, le livre
    // consomme - exactement ce que ferait un joueur en faisant clic droit.
    uint32 OuvrirLesLivres(Player* bot)
    {
        if (!EstUnBotDuVivier(bot))
            return 0;

        // Reperer d'abord, agir ensuite : DestroyItem remanie le sac, et
        // detruire en pleine iteration reviendrait a scier la branche.
        struct ALire
        {
            uint8 sac;
            uint8 emplacement;
            uint32 spellId;
        };
        std::vector<ALire> aLire;

        auto examiner = [&](uint8 sac, uint8 emplacement)
        {
            Item* item = bot->GetItemByPos(sac, emplacement);
            if (!item)
                return;

            auto itr = livres.find(item->GetEntry());
            if (itr == livres.end())
                return;

            // Un livre que le bot ne peut pas lire reste en sac. Il le vendra
            // peut-etre, et c'est tres bien : il ne lui sert a rien.
            if (!PeutApprendreLeSort(bot, itr->second))
                return;

            aLire.push_back({sac, emplacement, itr->second.spellId});
        };

        for (uint8 i = INVENTORY_SLOT_ITEM_START; i < INVENTORY_SLOT_ITEM_END; ++i)
            examiner(INVENTORY_SLOT_BAG_0, i);

        for (uint8 sac = INVENTORY_SLOT_BAG_START; sac < INVENTORY_SLOT_BAG_END; ++sac)
            if (Bag* contenant = bot->GetBagByPos(sac))
                for (uint32 j = 0; j < contenant->GetBagSize(); ++j)
                    examiner(sac, static_cast<uint8>(j));

        for (ALire const& lecture : aLire)
        {
            bot->learnSpell(lecture.spellId);
            bot->DestroyItem(lecture.sac, lecture.emplacement, true);
        }

        return static_cast<uint32>(aLire.size());
    }

    // La porte de service : les sorts sans le livre. A 0 par defaut.
    uint32 DonnerSansLivre(Player* bot)
    {
        if (!sBisPriorityMgr->TeachBookSpells() || !EstUnBotDuVivier(bot))
            return 0;

        uint32 appris = 0;
        for (auto const& paire : livres)
        {
            if (!PeutApprendreLeSort(bot, paire.second))
                continue;

            bot->learnSpell(paire.second.spellId);
            ++appris;
        }

        return appris;
    }

    void Appliquer(Player* player)
    {
        if (!livresCharges)
            ChargerLesLivres();

        if (livres.empty())
            return;

        if (uint32 const lus = OuvrirLesLivres(player))
            LOG_INFO("server.loading", "[mod-playerbots-bis] {} ouvre {} livre(s) de sort", player->GetName(), lus);

        if (uint32 const donnes = DonnerSansLivre(player))
            LOG_INFO("server.loading", "[mod-playerbots-bis] {} recoit {} sort(s) de livre sans le livre (niveau {})",
                     player->GetName(), donnes, player->GetLevel());
    }
}

namespace BisBookSpells
{
    bool PeutApprendre(Player* bot, uint32 itemId)
    {
        if (!EstUnBotDuVivier(bot))
            return false;

        if (!livresCharges)
            ChargerLesLivres();

        auto itr = livres.find(itemId);
        if (itr == livres.end())
            return false;

        return PeutApprendreLeSort(bot, itr->second);
    }
}

class BisBookSpellsPlayerScript : public PlayerScript
{
public:
    BisBookSpellsPlayerScript()
        : PlayerScript("BisBookSpellsPlayerScript", {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEVEL_CHANGED})
    {
    }

    void OnPlayerLogin(Player* player) override { Appliquer(player); }

    // La montee de niveau compte autant que la connexion : un livre niveau 60
    // ramasse a 58 dort en sac jusqu'ici, et c'est le bon moment pour l'ouvrir.
    void OnPlayerLevelChanged(Player* player, uint8 /*ancienNiveau*/) override { Appliquer(player); }
};

// Le balayage. C'est lui qui fait l'essentiel du travail : un livre arrive en
// cours de partie, par le butin, et le bot ne se reconnecte pas pour autant.
class BisBookSpellsWorldScript : public WorldScript
{
public:
    BisBookSpellsWorldScript() : WorldScript("BisBookSpellsWorldScript") {}

    void OnUpdate(uint32 diff) override
    {
        _depuis += diff;
        if (_depuis < INTERVALLE_MS)
            return;
        _depuis = 0;

        if (!livresCharges)
            ChargerLesLivres();

        if (livres.empty())
            return;

        uint32 lus = 0;
        uint32 donnes = 0;

        for (auto const& paire : ObjectAccessor::GetPlayers())
        {
            lus += OuvrirLesLivres(paire.second);
            donnes += DonnerSansLivre(paire.second);
        }

        if (lus)
            LOG_INFO("server.loading", "[mod-playerbots-bis] {} livre(s) de sort ouverts par les bots", lus);

        if (donnes)
            LOG_INFO("server.loading", "[mod-playerbots-bis] {} sort(s) de livre donnes sans livre", donnes);
    }

private:
    // Une minute. Un livre gagne au jet doit etre lu avant le combat suivant,
    // pas au prochain quart d'heure - et le balayage ne coute qu'une poignee
    // de lectures de sac par bot.
    static constexpr uint32 INTERVALLE_MS = 60 * 1000;

    uint32 _depuis = 0;
};

void AddSC_playerbots_bis_bookspells()
{
    new BisBookSpellsPlayerScript();
    new BisBookSpellsWorldScript();
}
