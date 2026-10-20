/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_MGR_H
#define MOD_PLAYERBOTS_BIS_MGR_H

#include "Define.h"
#include <algorithm>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

class Player;
class PlayerbotAI;
struct ItemTemplate;

// Sentinel spec used for Druid Feral Tank, which shares talent tab 1 with Cat.
// Resolved at runtime from the bot's tank strategy.
#define BIS_SPEC_DRUID_BEAR 10

struct BisTier
{
    uint16 tierId = 0;
    uint8 expansion = 0;          // 0 = Vanilla, 1 = TBC, 2 = WotLK
    std::string name;
    uint8 requiredProgression = 0;  // mod-individual-progression state, 0 = ungated
};

struct BisItem
{
    uint32 itemId = 0;
    uint8 slot = 0;
    uint16 tierId = 0;
    uint8 rank = 1;  // 1 = best within its slot and tier
};

class BisPriorityMgr
{
public:
    static BisPriorityMgr* instance()
    {
        static BisPriorityMgr inst;
        return &inst;
    }

    void LoadConfig();
    void LoadTables();

    bool IsEnabled() const { return _enabled; }
    bool LeaveOtherSpecsBis() const { return _leaveOtherSpecsBis; }
    bool AnnounceOwnBis() const { return _announceOwnBis; }

    // Un bot ressuscite repart-il a plein ? Le coeur le releve a la fraction
    // que la source a choisie - la moitie pour ".group revive", le cinquieme
    // pour certains sorts - et mod-dungeon-clear retient alors le raid au repos
    // jusqu'a ce qu'il ait bu. Voir BisBotGate.cpp.
    bool FullAfterResurrect() const { return _fullAfterResurrect; }

    // Les bots recoivent-ils les sorts de classe que seul un livre enseigne ?
    // TBC a bien reverse ces rangs sur les maitres, mais a ReqLevel 61 : a 60
    // ils restent hors de portee, et InitAvailableSpells les saute. Voir
    // BisBookSpells.cpp.
    bool TeachBookSpells() const { return _teachBookSpells; }

    // Vrai quand le bot annonce des le JET, avant de savoir s'il emporte la
    // piece. A faux, il attend de la detenir - une seule ligne, par le gagnant,
    // juste avant l'equipement.
    bool AnnounceOnRoll() const { return _announceOnRoll; }

    // Niveau en dessous duquel un randombot se voit refuser la connexion.
    // 0 desactive le filtre : mod-playerbots n'a aucun reglage de ce genre, et
    // un module qui renvoie des bots sans qu'on le lui ait demande serait une
    // mauvaise surprise.
    uint32 MinBotLevel() const { return _minBotLevel; }

    // Double de Playerbots.DisableDeathKnightLogin, qui suffit dans le cas
    // normal. Celui-ci tient meme quand l'autre est perdu - un playerbots.conf
    // au mauvais prefixe, par exemple, laisse tous ses reglages sans effet.
    bool BlockDeathKnights() const { return _blockDeathKnights; }

    // La guilde dont les bots passent devant tout le monde a la connexion.
    // 0 desactive la priorite.
    uint32 VipGuildId() const { return _vipGuildId; }


    // Vrai UNE SEULE FOIS par couple (bot, objet) dans une courte fenetre.
    //
    // L'avis d'usage est une VALEUR : playerbots la recalcule a chaque fois
    // qu'une decision la touche, et il y en a plusieurs pour un seul objet -
    // au jet, a l'arrivee dans les sacs, puis a l'equipement. Chaque calcul
    // parlait, donc le gagnant annoncait deux ou trois fois la meme phrase.
    //
    // La fenetre ne s'etend pas a la session : un objet reperdu puis retrouve
    // des heures plus tard merite d'etre annonce de nouveau.
    bool AnnounceOnce(Player* bot, uint32 itemId);

    // True when this bot's gear decisions get the BiS layer on top of
    // playerbots' own logic. False when the feature is off or the bot is a type
    // the server excluded; there is no level gate, because the BiS layer only
    // ever adds to the original logic, never replaces it.
    bool AppliesTo(Player* bot);

    // Priority of itemId for this bot's class/spec, or 0 when the item is not on
    // the bot's list (wrong spec, unknown item, or tier above the current cap).
    // Higher wins. outSlot receives the slot the list assigns it to, outTierId
    // the tier the entry belongs to, outRank the rank it holds there.
    //
    // LE RANG EST RENDU, PAS DEDUIT. Il se lit dans la priorite - elle vaut
    // tier * 1000 + (255 - rang) - mais le jour ou cette formule change, tout
    // ce qui l'aurait defaite afficherait un chiffre faux sans rien casser.
    // Une sortie de plus coute un parametre et supprime la question.
    uint32 GetItemPriority(Player* bot, uint32 itemId, uint8* outSlot = nullptr,
                           uint16* outTierId = nullptr, uint8* outRank = nullptr);

    // True when this bot's class/spec has at least one row it can actually reach
    // (a tier at or below its cap). False means nothing is maintained for that
    // spec yet, and the bot must NOT defer to other specs: with no list of its
    // own it would refuse everything anybody else claims and end up naked.
    bool HasReachableList(Player* bot);

    // True when itemId is on SOMEONE's list but not on this bot's - the bot then
    // leaves it to whoever it belongs to instead of rolling on it as an upgrade.
    // Ignores the tier cap: an item is somebody's best in slot whatever phase
    // the server currently runs.
    bool IsBisForAnotherSpec(Player* bot, uint32 itemId);

    // Human-readable tier name for the whisper, e.g. "Vanilla Phase 1 - Molten
    // Core / Onyxia". Empty when the tier is unknown.
    std::string GetTierName(uint16 tierId) const;

    // Priority of whatever the bot currently wears in that slot. 0 when the slot
    // is empty or holds something absent from the list.
    uint32 GetWornPriority(Player* bot, uint8 slot);

    // Same, but aware that rings and trinkets come in interchangeable pairs: the
    // list names one slot, and an item is an upgrade as soon as it beats the
    // WEAKER of the two. outTargetSlot receives the slot it would replace.
    uint32 GetWornPriorityPaired(Player* bot, uint8 slot, uint8* outTargetSlot = nullptr);

    // True when slot is the off-hand AND the bot already holds a two-handed
    // weapon, which fills both hands. Titan's Grip is the exception, and the
    // core's own IsTwoHandUsed() already accounts for it.
    //
    // The lists cannot express this on their own. They rank slot 15 and slot 16
    // as two independent ladders, because that is how the guides present them:
    // a page whose weapon row is a staff simply stops using its off-hand row.
    // That "simply stops" is the information the per-slot import dropped, and
    // without it a bot claims, rolls for, and endlessly fails to equip an
    // off-hand it cannot physically wear.
    //
    // Answering from the WORN main hand rather than from the list keeps the
    // answer true and stable: the bot's hands decide, not a guess about which
    // weapon it will end up with, and the slot reopens by itself the day it
    // picks up a one-hander.
    bool OffHandClosed(Player* bot, uint8 slot);

    // Vrai quand le coeur refusera cette piece au creneau vise parce que le bot
    // en porte deja un exemplaire ailleurs et qu'elle est unique-equipee.
    bool UniqueAlreadyWorn(Player* bot, ItemTemplate const* proto, uint8 targetSlot);

    // Vrai quand cet objet de QUETE achete une piece que la liste du bot nomme,
    // et qu'il n'en a pas encore. Les jetons de Zul'Gurub sont poses aux
    // creneau, palier et rang de la piece qu'ils donnent (fichier 56), donc la
    // meme echelle les departage - mais ils ne sont ni arme ni armure, et tous
    // les chemins d'equipement les ecartent avant d'en arriver la.
    bool WantsQuestToken(Player* bot, uint32 itemId, uint16* outTierId = nullptr);

    // La piece que ce jeton de quete achete pour cette classe ET CETTE SPE, ou 0
    // quand la table n'en connait pas - un jeton qu'aucune liste ne reclame pour
    // elle, ou l'Idole primordiale hakkari, dont les quetes rendent des
    // enchantements et qui n'a donc aucune piece a donner.
    //
    // LA SPE FAIT PARTIE DE LA CLE, et Ahn'Qiraj est ce qui l'a montre. Les
    // jetons de Zul'Gurub donnaient une piece par CLASSE, donc la classe
    // suffisait. Les deux jetons d'arme qirajis, eux, ouvrent un CHOIX :
    //
    //   Imperial Qiraji Armaments, guerrier -> hache pour Fureur,
    //                                          BOUCLIER pour Protection
    //   Imperial Qiraji Regalia,   chaman   -> baton Acolyte pour Elementaire,
    //                                          baton Augur pour Restauration
    //
    // Avec une cle sans spe, un guerrier Protection echangeait son jeton contre
    // la hache et laissait le bouclier - le meilleur rang de la CLASSE gagnait,
    // pas celui du bot.
    //
    // La correspondance vient de playerbots_bis_quest_token (fichiers 56 et 75),
    // pas d'une deduction : chercher la piece par creneau, palier et rang
    // tomberait juste aujourd'hui et faux le jour ou deux pieces partagent un
    // rang.
    // TOUTES les pieces que ce jeton ouvre pour cette classe et cette spe, et
    // non plus la seule mieux classee.
    //
    // Les jetons epaules/bottes d'Ahn'Qiraj en ouvrent DEUX : Qiraji Bindings
    // of Command rend a un guerrier les Conqueror's Spaulders - rang 1 - et les
    // Conqueror's Greaves - rang 5. N'en garder qu'une laissait l'autre
    // inaccessible : le bot n'echangeait jamais son jeton contre elle, et
    // cessait meme de reclamer le jeton des qu'il portait la premiere.
    //
    // Rend une liste vide quand le jeton n'est pas connu, ce qui est aussi la
    // reponse pour tout objet qui n'est pas un jeton.
    std::vector<uint32> const& QuestTokenRewards(uint32 tokenId, uint8 cls, uint8 spec) const;

    // Un objet que le bot doit RECLAMER sans qu'il soit sur sa liste
    // d'equipement, tant qu'il en possede moins que le compte voulu.
    //
    // Les montures d'Ahn'Qiraj sont le cas qui l'a fait naitre : un cristal
    // resonnant n'est ni arme ni armure, donc tous les chemins de ce module
    // l'ecartent, et il partait au premier venu alors que les bots s'en
    // servent. Ecrire ce cas-la dans le code aurait repondu a lui seul ; une
    // table repond a tous ceux de la meme forme et se corrige sans recompiler.
    //
    // La table est FACULTATIVE : une base ou le fichier 76 n'a jamais tourne
    // reste valide, les bots ne reclameront simplement rien de plus.
    bool WantsExtraItem(Player* bot, uint32 itemId) const;

    // What this item would push out if the bot put it on: the piece worn in the
    // slot the list assigns it, or nullptr when that slot is empty. Pairs are
    // resolved first, so on a ring or a trinket it names WHICH of the two goes -
    // the one thing a master cannot work out from the item alone.
    ItemTemplate const* WouldReplace(Player* bot, uint32 itemId);

    // The full "this is my best in slot and I want it" test: on the bot's list,
    // within its tier cap, wearable by its class and race, and better than what
    // it wears. Shared by the item-usage layer and the master-loot announcer so
    // the two can never disagree about what a bot considers its BiS.
    //
    // outTooLowLevel is set when the only thing standing in the way is the item's
    // required level. That is a TEMPORARY obstacle - a level 57 bot still wants
    // its level 60 best in slot and will grow into it - so it does not
    // disqualify the claim, unlike class, race, faction or proficiency, which
    // never change.
    bool WantsAsUpgrade(Player* bot, uint32 itemId, uint16* outTierId = nullptr,
                        bool* outTooLowLevel = nullptr, uint8* outRank = nullptr);

    // The other claim: an item NO list names, whose tooltip names this class
    // and no other, for a slot the lists have not settled and at an item level
    // at least equal to what is worn.
    //
    // It lives here rather than inside the usage value because two callers need
    // the same answer: the verdict that makes the bot want the piece, and the
    // vote it then casts for it. Split across two files, they drifted - the bot
    // announced the claim and passed on the roll.
    //
    // outSlot receives the slot the piece would go to.
    bool ClaimsClassRestricted(PlayerbotAI* botAI, Player* bot, uint32 itemId,
                               uint8* outSlot = nullptr);

    // Why AppliesTo() turned this character down, as a line fit to show the
    // player - or nullptr when there is nothing to explain, either because the
    // module does follow it or because it is a real player and never could be.
    //
    // A bot that vanishes from the report without a word is indistinguishable
    // from a bug. This is the sentence that tells the two apart.
    char const* WhyNotFollowed(Player* bot);

    bool AnnounceMasterLoot() const { return _announceMasterLoot; }
    bool ClaimBelowRequiredLevel() const { return _claimBelowRequiredLevel; }
    bool NeedOnlyForBis() const { return _needOnlyForBis; }

    // Cast the NEED for a genuine best in slot from this module, instead of
    // letting playerbots decide - it rewrites every NEED into a GREED or a PASS
    // according to AiPlayerbot.LootNeedRollLevel, which ships at "greed".
    bool ForceNeedForBis() const { return _forceNeedForBis; }

    // A piece no list names, but whose tooltip names this class and no other,
    // is claimed when the slot is not already settled by a listed piece.
    bool ClaimClassRestricted() const { return _claimClassRestricted; }

    // Highest tier this bot may pursue: the configured cap, optionally narrowed
    // by the bot's mod-individual-progression state.
    uint16 GetEffectiveTierCap(Player* bot);

    // The bot's spec as the lists index it, Bear sentinel included. Nothing
    // persists a spec - AiFactory recomputes it from the talents every time -
    // so anything outside the running server has to ask the module for it.
    uint8 GetSpec(Player* bot) { return ResolveSpec(bot); }

    // Every row this bot can actually reach, one entry per item at its best
    // reachable tier, sorted by slot then rank. Empty when nothing is
    // maintained for its class/spec/faction within the cap.
    std::vector<BisItem> GetReachableList(Player* bot);

    // The configured ceiling, straight from the conf file (0 = no cap), and the
    // ceiling that actually applies once "no cap" is resolved to the ladder's
    // own top. Printed by ".playerbotsbis reload" so the value the server ended
    // up with can be read in game - which also settles WHICH conf file won,
    // a question no amount of staring at the folder answers.
    uint16 GetConfiguredMaxTier() const { return _maxTier; }
    uint16 GetLadderTop() const
    {
        uint16 top = 0;
        for (auto const& kv : _tiers)
            top = std::max(top, kv.first);
        return top;
    }

    bool IsLoaded() const { return _loaded; }
    size_t TierCount() const { return _tiers.size(); }
    size_t ItemCount() const { return _itemCount; }

private:
    BisPriorityMgr() = default;

    static uint32 MakeKey(uint8 cls, uint8 spec, uint8 faction)
    {
        return (uint32(cls) << 16) | (uint32(spec) << 8) | faction;
    }

    // Remplit _questTokens depuis playerbots_bis_quest_token, si la table existe.
    void LoadQuestTokens();

    // Remplit _wantedItems depuis playerbots_bis_wanted_item, si elle existe.
    void LoadWantedItems();

    // Resolves the bot's spec, including the Druid Bear sentinel.
    static uint8 ResolveSpec(Player* bot);

    // Account-wide progression level derived from mod-individual-progression's
    // hidden reward quests (66000 + state). 0 when the module is absent.
    uint8 GetProgressionLevel(Player* bot);

    // Read-only after LoadTables(); safe to share across map threads.
    std::unordered_map<uint16, BisTier> _tiers;
    // (cls<<16|spec<<8|faction) -> itemId -> every tier that lists it.
    //
    // A piece often appears in several phases at once: Dal'Rend's Sacred Charge
    // is rank 1 pre-raid, rank 3 at MC and rank 2 at BWL for a Fury warrior.
    // Collapsing those to one row lost whichever the bot could actually reach,
    // so the rows are kept side by side and GetItemPriority picks the highest
    // tier within the bot's cap.
    std::unordered_map<uint32, std::unordered_map<uint32, std::vector<BisItem>>> _items;
    // (cls<<16|spec<<8|faction) -> lowest tier present, so an empty or
    // out-of-reach list is detected without scanning the bucket.
    std::unordered_map<uint32, uint16> _minTierByCombo;
    // itemId -> every (cls<<8|spec) that lists it. Backs IsBisForAnotherSpec
    // without scanning the whole table on each decision.
    std::unordered_map<uint32, std::vector<uint16>> _bisOwners;
    // (tokenId<<8|cls) -> les pieces achetees. Plat plutot qu'imbrique : la table
    // compte quelques dizaines de lignes, et une classe tient sur huit bits.
    // Cle sur 64 bits : (jeton << 16) | (classe << 8) | spe. Le jeton seul tient
    // deja sur plus de 16 bits, et la spe d'ours vaut 10 - les deux decalages de
    // huit laissent la place aux trois sans se chevaucher.
    std::unordered_map<uint64, std::vector<uint32>> _questTokens;

    // objet -> nombre au-dela duquel le bot cesse d'en vouloir.
    std::unordered_map<uint32, uint32> _wantedItems;
    size_t _itemCount = 0;
    bool _loaded = false;

    // Progression cache: accountId -> (level, expiry). Written from map threads.
    struct ProgressionCacheEntry
    {
        uint8 level = 0;
        time_t expiry = 0;
    };
    std::unordered_map<uint32, ProgressionCacheEntry> _progressionCache;
    std::mutex _progressionMutex;

    bool _enabled = false;
    bool _applyToRandomBots = true;
    bool _applyToAddClassBots = false;
    bool _applyToAltBots = false;
    bool _leaveOtherSpecsBis = true;
    bool _announceOwnBis = true;
    bool _fullAfterResurrect = true;
    bool _teachBookSpells = true;
    bool _announceOnRoll = true;
    uint32 _minBotLevel = 0;
    bool _blockDeathKnights = false;
    uint32 _vipGuildId = 0;

    // (guid bas << 32 | itemId) -> instant de la derniere annonce.
    std::unordered_map<uint64, time_t> _dejaAnnonce;
    std::mutex _annonceMutex;
    bool _announceMasterLoot = true;
    bool _claimBelowRequiredLevel = true;
    bool _forceNeedForBis = true;
    bool _needOnlyForBis = false;
    bool _claimClassRestricted = true;
    uint16 _maxTier = 0;
    bool _useIndividualProgression = false;
    uint32 _progressionCacheSeconds = 300;
};

#define sBisPriorityMgr BisPriorityMgr::instance()

#endif
