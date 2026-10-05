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

    // True when this bot's gear decisions get the BiS layer on top of
    // playerbots' own logic. False when the feature is off or the bot is a type
    // the server excluded; there is no level gate, because the BiS layer only
    // ever adds to the original logic, never replaces it.
    bool AppliesTo(Player* bot);

    // Priority of itemId for this bot's class/spec, or 0 when the item is not on
    // the bot's list (wrong spec, unknown item, or tier above the current cap).
    // Higher wins. outSlot receives the slot the list assigns it to, outTierId
    // the tier the entry belongs to.
    uint32 GetItemPriority(Player* bot, uint32 itemId, uint8* outSlot = nullptr,
                           uint16* outTierId = nullptr);

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
                        bool* outTooLowLevel = nullptr);

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
