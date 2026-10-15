/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisPriorityMgr.h"
#include "Config.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectGuid.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include <unordered_set>
#include <vector>

// Refuser l'acces aux randombots qu'on ne veut pas voir dans le monde.
//
// POURQUOI CE FICHIER EXISTE
// --------------------------
// mod-playerbots ne filtre la connexion d'un randombot que sur sa CLASSE. Le
// test complet, dans RandomPlayerbotMgr::AddRandomBots :
//
//     if (GetEventValue(guid, "add") || GetEventValue(guid, "logout") ||
//         GetPlayerBot(guid) || currentBots.contains(guid) ||
//         (disableDeathKnightLogin && rClass == CLASS_DEATH_KNIGHT))
//         return false;
//
// La structure examinee ne transporte meme pas le niveau :
//
//     struct CharacterInfo { uint32 guid; uint8 rClass; uint8 rRace; uint32 accountId; };
//
// Il n'existe donc aucun reglage de niveau minimum, et un personnage niveau 1
// se connecte exactement comme un niveau 60. Playerbots.RandomBotMinLevel ne
// joue qu'a la randomisation, APRES la connexion, et la randomisation suivante
// d'un bot est programmee jusqu'a quatorze jours plus tard.
//
// POURQUOI EN DEUX TEMPS
// ----------------------
// La facon propre de retirer un bot serait de lui enlever sa marque "add" via
// SetEventValue. Elle est privee. Reste LogoutPlayerBot, publique et heritee
// de PlayerbotHolder, mais elle commence par :
//
//     if (Player* bot = GetPlayerBot(guid))
//
// et au moment ou le coeur declenche OnPlayerLogin, rien ne garantit que le
// bot soit deja inscrit dans playerBots. L'appel sortirait alors en silence :
// un filtre qui echoue sans le dire est pire que pas de filtre.
//
// D'ou la mise en attente : OnPlayerLogin juge, et le tick du monde execute
// quand le bot est joignable. Le verdict est pris une seule fois, a l'arrivee.
//
// CE QUE CE FILTRE NE PEUT PAS FAIRE
// ----------------------------------
// LogoutPlayerBot ne pose aucun delai de carence - c'est ProcessBot qui le
// fait, sur son propre chemin. Un bot renvoye ici peut donc etre re-tire au
// tirage suivant, et revenir. Le filtre tiendra - il le renverra a nouveau -
// mais la place aura ete gachee.
//
// La parade n'est pas dans ce fichier : elle consiste a sortir ces comptes du
// vivier (playerbots_account_type a 0, voir tools/pas_de_bots_niveau_1.ps1),
// pour qu'ils ne soient plus tires du tout. Ce filtre est alors la garantie
// de dernier recours, celle qui tient meme si un reglage se perd.

namespace
{
    // Les verdicts rendus a la connexion, en attente d'un tick ou le bot est
    // joignable. Un set et non une file : un meme bot peut etre juge plusieurs
    // fois si le gestionnaire s'acharne, et une seule expulsion suffit.
    std::unordered_set<ObjectGuid> enAttente;

    // Un bot est-il concerne par le filtre, et pourquoi.
    //
    // Seuls les RANDOMBOTS le sont. Les bots invoques a la main - addclass, ou
    // les alts d'un joueur - sont la parce qu'on les a demandes : les renvoyer
    // serait contredire l'ordre qu'on vient de donner.
    char const* RaisonDuRefus(Player* bot)
    {
        if (!bot)
            return nullptr;

        if (!sRandomPlayerbotMgr.IsRandomBot(bot))
            return nullptr;

        if (sRandomPlayerbotMgr.IsAddclassBot(bot))
            return nullptr;

        if (sBisPriorityMgr->BlockDeathKnights() && bot->getClass() == CLASS_DEATH_KNIGHT)
            return "chevalier de la mort";

        uint32 const plancher = sBisPriorityMgr->MinBotLevel();
        if (plancher && bot->GetLevel() < plancher)
            return "niveau sous le plancher";

        return nullptr;
    }
}

class BisBotGatePlayerScript : public PlayerScript
{
public:
    BisBotGatePlayerScript() : PlayerScript("BisBotGatePlayerScript", {PLAYERHOOK_ON_LOGIN}) {}

    void OnPlayerLogin(Player* player) override
    {
        if (!sBisPriorityMgr->MinBotLevel() && !sBisPriorityMgr->BlockDeathKnights())
            return;

        char const* raison = RaisonDuRefus(player);
        if (!raison)
            return;

        enAttente.insert(player->GetGUID());
    }
};

// Le bras executif. Il vit dans le tick du monde, ou GetPlayerBot repond.
class BisBotGateWorldScript : public WorldScript
{
public:
    BisBotGateWorldScript() : WorldScript("BisBotGateWorldScript") {}

    void OnUpdate(uint32 diff) override
    {
        if (enAttente.empty())
            return;

        // Une seconde entre deux passages : assez court pour que le bot ne
        // traine pas dans le monde, assez long pour ne pas repasser sur la
        // liste a chaque tick du serveur.
        _depuis += diff;
        if (_depuis < 1000)
            return;
        _depuis = 0;

        // La copie est deliberee : LogoutPlayerBot finit par passer par des
        // chemins qui peuvent toucher a l'etat des bots, et iterer sur le set
        // qu'on modifie serait une invitation au plantage.
        std::vector<ObjectGuid> const aTraiter(enAttente.begin(), enAttente.end());
        enAttente.clear();

        for (ObjectGuid const& guid : aTraiter)
        {
            Player* bot = ObjectAccessor::FindPlayer(guid);

            // Deja parti de lui-meme, ou jamais arrive : le verdict n'a plus
            // d'objet. On ne le garde pas en attente indefiniment.
            if (!bot)
                continue;

            // Le verdict est rejuge ici. Entre la connexion et ce tick, le bot
            // a pu etre randomise et passer au-dessus du plancher - le renvoyer
            // alors serait renvoyer un bot parfaitement acceptable.
            char const* raison = RaisonDuRefus(bot);
            if (!raison)
                continue;

            // "server.loading" et non un logger a nous : AzerothCore n'ecrit que
            // dans les loggers declares par worldserver.conf, et un nom inconnu
            // disparait en silence. Le reste du module ecrit deja la, donc on
            // sait que ca sort. Un refus qu'on ne voit pas est un refus qu'on ne
            // peut pas diagnostiquer.
            LOG_INFO("server.loading", "[mod-playerbots-bis] {} deconnecte : {} (niveau {})",
                     bot->GetName(), raison, bot->GetLevel());

            sRandomPlayerbotMgr.LogoutPlayerBot(guid);
        }
    }

private:
    uint32 _depuis = 0;
};

// ---------------------------------------------------------------------------
// UN BOT RESSUSCITE REPART A PLEIN.
//
// POURQUOI ICI, ET PAS DANS UNE COMMANDE. Le coeur releve a la fraction que la
// SOURCE a choisie : la moitie pour ".group revive", un cinquieme pour certains
// sorts, la moitie au cimetiere. Et mod-dungeon-clear retient ensuite tout le
// raid au repos - sa propre documentation le dit :
//
//     the freshly-raised member's low health/mana then holds the tank at the
//     normal between-pulls rest floors until they recover
//
// Soit trois minutes d'attente apres chaque mort, pour quarante bots dont
// aucun ne tient de clavier. En se branchant sur la resurrection elle-meme
// plutot que sur une commande, TOUTES les sources sont couvertes du meme coup :
// la commande du maitre de jeu, la resurrection automatique de dungeon-clear,
// le rez d'un druide en plein combat, le cimetiere.
//
// Ce hook ne change RIEN a qui peut ressusciter qui, ni quand : seulement
// l'etat dans lequel on se releve. Et jamais pour un joueur.
class BisFullAfterResurrectScript : public PlayerScript
{
public:
    BisFullAfterResurrectScript()
        : PlayerScript("BisFullAfterResurrectScript", {PLAYERHOOK_ON_PLAYER_RESURRECT})
    {
    }

    void OnPlayerResurrect(Player* player, float /*restore_percent*/, bool& /*applySickness*/) override
    {
        if (!player || !sBisPriorityMgr->FullAfterResurrect())
            return;

        // JAMAIS UN JOUEUR. Lui rendre sa vie d'office, c'est decider a sa
        // place - et son repos a lui ne retient pas le tank de la meme maniere.
        if (!GET_PLAYERBOT_AI(player))
            return;

        player->SetFullHealth();

        if (player->getPowerType() == POWER_MANA)
            player->SetPower(POWER_MANA, player->GetMaxPower(POWER_MANA));
    }
};

void AddSC_playerbots_bis_botgate()
{
    new BisBotGatePlayerScript();
    new BisBotGateWorldScript();
    new BisFullAfterResurrectScript();
}
