/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisPriorityMgr.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotsDatabase.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include <string>
#include <vector>

// Trier les candidats AVANT que le gestionnaire ne tire au sort.
//
// POURQUOI UNE FILE PLUTOT QU'UNE EXPULSION
// -----------------------------------------
// BisBotGate.cpp renvoie un bot indesirable une fois arrive. Ca marche, mais
// ca gaspille : le personnage a ete charge, place dans le monde, puis jete, et
// la place qu'il occupait dans le compte de la population a ete perdue le
// temps de l'aller-retour.
//
// Il existe un cran plus tot. tryLoginBot ecarte tout bot portant un evenement
// "logout" actif, AVANT de le retenir comme candidat :
//
//     if (GetEventValue(guid, "add") || GetEventValue(guid, "logout") || ...)
//         return false;
//
// et GetEventValue lit un cache rempli PARESSEUSEMENT, bot par bot, depuis la
// base :
//
//     BotEventCache& cache = eventCache[bot];
//     if (!cache.loaded) { ... SELECT ... FROM playerbots_random_bots ... }
//
// Une ligne ecrite avant la premiere consultation d'un bot est donc lue et
// respectee. Ecrire au demarrage - avant qu'aucun bot ne se connecte - revient
// a poser un refus que le gestionnaire appliquera lui-meme, sans jamais tenter
// la connexion.
//
// LA MEME MECANIQUE SERT LES VIP
// ------------------------------
// GetBots(), appele une seule fois au demarrage, remplit la liste des bots a
// connecter avec ceux qui portent deja un "add" valide, et s'arrete au
// plafond. Les bots de la guilde recoivent donc ce "add" ici : ils sont dans
// la liste avant que le tirage au sort ne distribue les places restantes.
//
// Un refus et une priorite, ecrits au meme endroit, par le meme mecanisme.
//
// LA FENETRE EST ETROITE ET C'EST TOUT LE SUJET
// ---------------------------------------------
// OnStartup se declenche apres l'initialisation du monde - donc apres que
// mod-playerbots a cree ses comptes et ses personnages - et avant la premiere
// connexion de bot. C'est le seul instant ou la base fait foi : des que le
// gestionnaire a consulte un bot, son cache prend le dessus et ce qu'on ecrit
// ici ne sera relu qu'au prochain demarrage.

namespace
{
    // Un an, la valeur que le coeur lui-meme emploie pour PermanentlyInWorldTime.
    // On ne choisit pas un chiffre : on reprend le sien, pour que le refus dure
    // aussi longtemps que durerait une autorisation.
    constexpr uint32 DUREE = 31104000;

    // Les guids des personnages que le gestionnaire ne doit pas retenir.
    //
    // Le tri des comptes est delegue a mod-playerbots plutot que refait ici :
    //
    //     bool PlayerbotAIConfig::IsInRandomAccountList(uint32 id);
    //
    // C'est la meme fonction dont IsRandomBot se sert. Reconstruire le critere
    // - par un LIKE sur le prefixe des comptes, par exemple - obligerait a
    // joindre la base d'authentification depuis celle des personnages, donc a
    // ecrire son nom en dur, et a diverger le jour ou le prefixe change.
    std::vector<uint32> CollecterIndesirables(uint32 plancher, bool sansDK)
    {
        std::vector<uint32> guids;

        QueryResult result = CharacterDatabase.Query("SELECT guid, account, level, class FROM characters");
        if (!result)
            return guids;

        do
        {
            Field* fields = result->Fetch();
            uint32 const guid = fields[0].Get<uint32>();
            uint32 const compte = fields[1].Get<uint32>();
            uint8 const niveau = fields[2].Get<uint8>();
            uint8 const classe = fields[3].Get<uint8>();

            if (!sPlayerbotAIConfig.IsInRandomAccountList(compte))
                continue;

            bool const tropBas = plancher && niveau < plancher;
            bool const interdit = sansDK && classe == CLASS_DEATH_KNIGHT;
            if (tropBas || interdit)
                guids.push_back(guid);
        } while (result->NextRow());

        return guids;
    }

    // Les bots d'une guilde, pour la priorite. Les personnages de JOUEUR en sont
    // exclus par le meme test : leur donner un "add" ferait tenter au serveur de
    // les connecter comme bots, ce qui est le seul vrai danger de ce fichier.
    std::vector<uint32> CollecterVip(uint32 guildId)
    {
        std::vector<uint32> guids;

        QueryResult result = CharacterDatabase.Query(
            "SELECT c.guid, c.account FROM characters c "
            "JOIN guild_member gm ON gm.guid = c.guid WHERE gm.guildid = {}", guildId);
        if (!result)
            return guids;

        do
        {
            Field* fields = result->Fetch();
            uint32 const guid = fields[0].Get<uint32>();
            uint32 const compte = fields[1].Get<uint32>();

            if (sPlayerbotAIConfig.IsInRandomAccountList(compte))
                guids.push_back(guid);
        } while (result->NextRow());

        return guids;
    }

    // Poser un evenement pour une liste de bots, en remplacant le precedent du
    // meme nom. Une transaction unique : des centaines d'ecritures separees sur
    // un pool a quatre connexions asynchrones, c'est precisement ce qui produit
    // les "Deadlock found when trying to get lock" du demarrage.
    void PoserEvenement(std::vector<uint32> const& guids, char const* evenement)
    {
        if (guids.empty())
            return;

        PlayerbotsDatabaseTransaction trans = PlayerbotsDatabase.BeginTransaction();

        for (uint32 guid : guids)
        {
            trans->Append("DELETE FROM playerbots_random_bots WHERE owner = 0 AND bot = {} AND event = '{}'",
                          guid, evenement);
            trans->Append("INSERT INTO playerbots_random_bots (owner, bot, `time`, validIn, event, `value`, `data`) "
                          "VALUES (0, {}, UNIX_TIMESTAMP(), {}, '{}', 1, NULL)",
                          guid, DUREE, evenement);
        }

        PlayerbotsDatabase.CommitTransaction(trans);
    }
}

class BisBotQueueWorldScript : public WorldScript
{
public:
    BisBotQueueWorldScript() : WorldScript("BisBotQueueWorldScript", {WORLDHOOK_ON_STARTUP}) {}

    void OnStartup() override
    {
        uint32 const plancher = sBisPriorityMgr->MinBotLevel();
        bool const sansDK = sBisPriorityMgr->BlockDeathKnights();
        uint32 const vipGuild = sBisPriorityMgr->VipGuildId();

        if (!plancher && !sansDK && !vipGuild)
            return;

        if (plancher || sansDK)
        {
            std::vector<uint32> const refuses = CollecterIndesirables(plancher, sansDK);
            PoserEvenement(refuses, "logout");
            LOG_INFO("server.loading",
                     "[mod-playerbots-bis] File d'attente : {} bots ecartes avant toute connexion "
                     "(plancher {}, chevaliers de la mort {})",
                     refuses.size(), plancher, sansDK ? "exclus" : "admis");
        }

        if (vipGuild)
        {
            std::vector<uint32> const vip = CollecterVip(vipGuild);
            PoserEvenement(vip, "add");
            LOG_INFO("server.loading",
                     "[mod-playerbots-bis] File d'attente : {} bots de la guilde {} places en tete",
                     vip.size(), vipGuild);
        }
    }
};

void AddSC_playerbots_bis_botqueue()
{
    new BisBotQueueWorldScript();
}
