/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisPriorityMgr.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include <vector>

// Rendre aux bots les sorts de classe que SEUL un livre enseigne.
//
// LE TROU
// -------
// mod-playerbots donne ses sorts aux bots dans PlayerbotFactory::InitAvailableSpells,
// qui parcourt les listes des MAITRES DE CLASSE et apprend ce que le bot peut
// apprendre. Tout sort absent de ces listes - ou verrouille au-dessus de son
// niveau - n'arrive donc jamais jusqu'a lui.
//
// Or une trentaine de sorts de rang maximum de l'ere vanilla ne s'apprenaient
// que dans un livre (Codex, Grimoire, Tome, Tablette, Manuel...). TBC les a
// bien reverses sur les maitres, mais a ReqLevel 61, pour que le livre garde
// sa valeur a 60. Dans acore_world :
//
//     SELECT TrainerId, ReqLevel, ReqAbility1 FROM trainer_spell WHERE SpellId = 25316;
//     -> 11 | 61 | 10961
//
// Priere de soins rang 5 est donc enseignee par les 36 maitres pretres, et
// refusee a tout personnage de niveau 60. GetTrainerSpellState renvoie rouge,
// InitAvailableSpells passe son chemin, et le bot soigne au rang 4 pour
// toujours. Meme histoire pour Soins superieurs V, Renovation X, Boule de feu
// XII, Trait de l'ombre X, Vague de soins X, Eviscration IX, Soins XI... soit
// un sort majeur manquant chez presque chaque soigneur et chaque DPS caster du
// raid, alors que le serveur est cale sur le contenu niveau 60.
//
// CE QU'ON FAIT
// -------------
// On lit la liste depuis item_template plutot que de la coder en dur : ce sont
// exactement les items de classe 9 (recette) / sous-classe 0 (livre de sort)
// dont le premier sort est 483 (Apprentissage) et le second le sort enseigne.
// Un serveur qui modifie ces items, ou qui en ajoute, est suivi sans toucher
// au module. Puis, pour chaque bot : meme classe, niveau atteint, rang
// precedent deja connu, sort pas deja su -> learnSpell.
//
// CE QU'ON NE FAIT PAS
// --------------------
// Aucun personnage de JOUEUR n'est touche, et les alts d'un joueur passes en
// bot non plus : seuls les bots du vivier (randombots et addclass) sont
// concernes, exactement comme le filtre de BisBotGate. Le livre reste donc une
// vraie trouvaille pour qui le loote, et un personnage qu'on peut reprendre au
// clavier ne se retrouve pas avec des sorts qu'il n'a pas gagnes.
//
// POURQUOI AUSSI UN BALAYAGE PERIODIQUE
// -------------------------------------
// La connexion et la montee de niveau couvrent le cas normal, mais
// mod-playerbots re-randomise ses bots en cours de vie, et une randomisation
// complete repasse sur leurs sorts. Le balayage - cinq minutes, le temps de
// parcourir quelques dizaines de HasSpell - rattrape ce cas sans qu'on ait a
// deviner quand il se produit.

namespace
{
    struct LivreDeSort
    {
        uint32 itemId;
        uint32 spellId;
        int32 classesAutorisees;  // AllowableClass, -1 = toutes
        uint8 niveauRequis;
    };

    std::vector<LivreDeSort> livres;
    bool livresCharges = false;

    void ChargerLesLivres()
    {
        livresCharges = true;
        livres.clear();

        QueryResult res = WorldDatabase.Query(
            "SELECT `entry`, `spellid_2`, `AllowableClass`, `RequiredLevel` FROM `item_template` "
            "WHERE `class` = 9 AND `subclass` = 0 AND `spellid_1` = 483 AND `spellid_2` > 0");
        if (!res)
        {
            LOG_INFO("server.loading",
                     "[mod-playerbots-bis] Aucun livre de sort dans item_template - rien a rattraper");
            return;
        }

        do
        {
            Field* fields = res->Fetch();

            LivreDeSort livre;
            livre.itemId = fields[0].Get<uint32>();
            livre.spellId = fields[1].Get<uint32>();
            livre.classesAutorisees = fields[2].Get<int32>();
            livre.niveauRequis = static_cast<uint8>(fields[3].Get<uint32>());

            // Un sort absent du DBC ne s'apprend pas : le learnSpell partirait
            // dans le vide et laisserait une ligne illisible dans le journal.
            if (!sSpellMgr->GetSpellInfo(livre.spellId))
                continue;

            livres.push_back(livre);
        } while (res->NextRow());

        LOG_INFO("server.loading", "[mod-playerbots-bis] {} sorts de classe enseignes par livre repertories",
                 static_cast<uint32>(livres.size()));
    }

    // Seuls les bots du vivier. IsRandomBot repond des la connexion, sans
    // dependre du moment ou mod-playerbots attache son IA - ce qui n'est pas
    // garanti quand OnPlayerLogin passe.
    bool EstUnBotDuVivier(Player* player)
    {
        return player && sRandomPlayerbotMgr.IsRandomBot(player);
    }

    uint32 Rattraper(Player* bot)
    {
        if (!EstUnBotDuVivier(bot))
            return 0;

        uint32 const masque = 1u << (bot->getClass() - 1);
        uint8 const niveau = bot->GetLevel();
        uint32 appris = 0;

        for (LivreDeSort const& livre : livres)
        {
            if (livre.classesAutorisees != -1 && !(static_cast<uint32>(livre.classesAutorisees) & masque))
                continue;

            if (livre.niveauRequis > niveau)
                continue;

            if (bot->HasSpell(livre.spellId))
                continue;

            // Le garde-fou de race et de classe du coeur. Il attrape ce que le
            // masque de l'item laisse passer - AllowableClass porte encore des
            // bits de classes qui n'existent pas.
            if (!bot->IsSpellFitByClassAndRace(livre.spellId))
                continue;

            // Un rang ne se donne pas par-dessus un trou. Si le bot n'a pas le
            // rang precedent, c'est que quelque chose cloche ailleurs, et le
            // lui offrir masquerait le vrai probleme.
            if (uint32 const precedent = sSpellMgr->GetPrevSpellInChain(livre.spellId))
                if (!bot->HasSpell(precedent))
                    continue;

            bot->learnSpell(livre.spellId);
            ++appris;
        }

        return appris;
    }

    void Appliquer(Player* player)
    {
        if (!sBisPriorityMgr->TeachBookSpells())
            return;

        if (!livresCharges)
            ChargerLesLivres();

        if (livres.empty())
            return;

        if (uint32 const appris = Rattraper(player))
            LOG_INFO("server.loading", "[mod-playerbots-bis] {} apprend {} sort(s) de livre (niveau {})",
                     player->GetName(), appris, player->GetLevel());
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

    void OnPlayerLevelChanged(Player* player, uint8 /*ancienNiveau*/) override { Appliquer(player); }
};

// Le filet. Voir l'en-tete : une randomisation complete repasse sur les sorts
// du bot, et elle ne previent pas.
class BisBookSpellsWorldScript : public WorldScript
{
public:
    BisBookSpellsWorldScript() : WorldScript("BisBookSpellsWorldScript") {}

    void OnUpdate(uint32 diff) override
    {
        if (!sBisPriorityMgr->TeachBookSpells())
            return;

        _depuis += diff;
        if (_depuis < INTERVALLE_MS)
            return;
        _depuis = 0;

        if (!livresCharges)
            ChargerLesLivres();

        if (livres.empty())
            return;

        uint32 total = 0;
        uint32 bots = 0;

        for (auto const& paire : ObjectAccessor::GetPlayers())
        {
            uint32 const appris = Rattraper(paire.second);
            if (!appris)
                continue;

            total += appris;
            ++bots;
        }

        if (total)
            LOG_INFO("server.loading", "[mod-playerbots-bis] Rattrapage des sorts de livre : {} sort(s) pour {} bot(s)",
                     total, bots);
    }

private:
    static constexpr uint32 INTERVALLE_MS = 5 * 60 * 1000;

    uint32 _depuis = 0;
};

void AddSC_playerbots_bis_bookspells()
{
    new BisBookSpellsPlayerScript();
    new BisBookSpellsWorldScript();
}
