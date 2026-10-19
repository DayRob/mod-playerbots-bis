/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisPriorityMgr.h"
#include <algorithm>
#include "AiFactory.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Item.h"
#include "Log.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "PlayerbotAIConfig.h"
#include "Playerbots.h"
#include "QueryResult.h"

namespace
{
    // mod-individual-progression stores a character's state as a rewarded hidden
    // quest, id 66000 + state. Reading it that way keeps this module free of any
    // compile-time dependency on that module: when it is not installed, no such
    // quest exists and the query simply returns nothing.
    constexpr uint32 IP_QUEST_BASE = 66000;
    constexpr uint32 IP_QUEST_MAX_STATE = 18;  // PROGRESSION_WOTLK_TIER_5

    // A tier always outranks every tier below it; rank orders items inside one
    // tier and slot, 1 being the best. 1000 leaves room for 255 ranks and keeps
    // the arithmetic obvious in logs.
    constexpr uint32 TIER_WEIGHT = 1000;

    // Rings and trinkets have two interchangeable slots. The list names one of
    // them; an item is an upgrade as soon as it beats the weaker of the pair.
    uint8 PairedSlot(uint8 slot)
    {
        switch (slot)
        {
            case EQUIPMENT_SLOT_FINGER1:  return EQUIPMENT_SLOT_FINGER2;
            case EQUIPMENT_SLOT_FINGER2:  return EQUIPMENT_SLOT_FINGER1;
            case EQUIPMENT_SLOT_TRINKET1: return EQUIPMENT_SLOT_TRINKET2;
            case EQUIPMENT_SLOT_TRINKET2: return EQUIPMENT_SLOT_TRINKET1;
            default:                      return 0xFF;
        }
    }
}

void BisPriorityMgr::LoadConfig()
{
    _enabled = sConfigMgr->GetOption<bool>("PlayerbotsBis.Enable", false);
    _applyToRandomBots = sConfigMgr->GetOption<bool>("PlayerbotsBis.ApplyToRandomBots", true);
    _applyToAddClassBots = sConfigMgr->GetOption<bool>("PlayerbotsBis.ApplyToAddClassBots", false);
    _applyToAltBots = sConfigMgr->GetOption<bool>("PlayerbotsBis.ApplyToAltBots", false);
    _leaveOtherSpecsBis = sConfigMgr->GetOption<bool>("PlayerbotsBis.LeaveOtherSpecsBis", true);
    _announceOwnBis = sConfigMgr->GetOption<bool>("PlayerbotsBis.AnnounceOwnBis", true);
    _announceOnRoll = sConfigMgr->GetOption<bool>("PlayerbotsBis.AnnounceOnRoll", true);
    _minBotLevel = sConfigMgr->GetOption<uint32>("PlayerbotsBis.MinBotLevel", 0);
    _blockDeathKnights = sConfigMgr->GetOption<bool>("PlayerbotsBis.BlockDeathKnights", false);
    _vipGuildId = sConfigMgr->GetOption<uint32>("PlayerbotsBis.VipGuildId", 0);
    _announceMasterLoot = sConfigMgr->GetOption<bool>("PlayerbotsBis.AnnounceMasterLoot", true);
    _claimBelowRequiredLevel = sConfigMgr->GetOption<bool>("PlayerbotsBis.ClaimBelowRequiredLevel", true);
    _fullAfterResurrect = sConfigMgr->GetOption<bool>("PlayerbotsBis.FullAfterResurrect", true);
    _needOnlyForBis = sConfigMgr->GetOption<bool>("PlayerbotsBis.NeedOnlyForBis", false);
    _forceNeedForBis = sConfigMgr->GetOption<bool>("PlayerbotsBis.ForceNeedForBis", true);
    _claimClassRestricted = sConfigMgr->GetOption<bool>("PlayerbotsBis.ClaimClassRestricted", true);
    _maxTier = static_cast<uint16>(sConfigMgr->GetOption<uint32>("PlayerbotsBis.MaxTier", 0));
    _useIndividualProgression = sConfigMgr->GetOption<bool>("PlayerbotsBis.UseIndividualProgression", false);
    _progressionCacheSeconds = sConfigMgr->GetOption<uint32>("PlayerbotsBis.ProgressionCacheSeconds", 300);
}

void BisPriorityMgr::LoadTables()
{
    _tiers.clear();
    _items.clear();
    _minTierByCombo.clear();
    _bisOwners.clear();
    _questTokens.clear();
    _wantedItems.clear();
    _itemCount = 0;
    _loaded = false;

    QueryResult tierResult = WorldDatabase.Query(
        "SELECT `tier_id`, `expansion`, `name`, `required_progression` "
        "FROM `playerbots_bis_tier` ORDER BY `tier_id`");
    if (!tierResult)
    {
        LOG_ERROR("server.loading", "[mod-playerbots-bis] playerbots_bis_tier is missing or empty - module inactive");
        return;
    }

    do
    {
        Field* fields = tierResult->Fetch();
        BisTier tier;
        tier.tierId = fields[0].Get<uint16>();
        tier.expansion = fields[1].Get<uint8>();
        tier.name = fields[2].Get<std::string>();
        tier.requiredProgression = fields[3].Get<uint8>();
        _tiers[tier.tierId] = tier;
    } while (tierResult->NextRow());

    QueryResult itemResult = WorldDatabase.Query(
        // Every identifier is back-quoted: `rank` is a reserved word from MySQL 8
        // onward (the RANK() window function), and an unquoted one aborts the
        // whole statement with error 1064.
        "SELECT `class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank` "
        "FROM `playerbots_bis_item`");
    if (!itemResult)
    {
        LOG_WARN("server.loading", "[mod-playerbots-bis] playerbots_bis_item is empty - no bot will be governed");
        _loaded = true;
        return;
    }

    uint32 skipped = 0;
    do
    {
        Field* fields = itemResult->Fetch();
        uint8 cls = fields[0].Get<uint8>();
        uint8 spec = fields[1].Get<uint8>();
        uint8 slot = fields[2].Get<uint8>();
        uint8 faction = fields[3].Get<uint8>();
        uint16 tierId = fields[4].Get<uint16>();
        uint32 itemId = fields[5].Get<uint32>();
        uint8 rank = fields[6].Get<uint8>();

        if (_tiers.find(tierId) == _tiers.end())
        {
            ++skipped;  // row points at a tier the ladder does not define
            continue;
        }

        BisItem entry;
        entry.itemId = itemId;
        entry.slot = slot;
        entry.tierId = tierId;
        entry.rank = rank ? rank : 1;

        // Faction rows are stored alongside the neutral ones; the lookup below
        // reads the neutral map first and lets the faction map override it.
        uint32 const comboKey = MakeKey(cls, spec, faction);
        auto& bucket = _items[comboKey];

        auto minIt = _minTierByCombo.find(comboKey);
        if (minIt == _minTierByCombo.end() || tierId < minIt->second)
            _minTierByCombo[comboKey] = tierId;

        // Reverse index for the courtesy rule. Faction is deliberately left out:
        // an item belongs to a spec whichever side lists it.
        uint16 const ownerKey = (uint16(cls) << 8) | spec;
        auto& owners = _bisOwners[itemId];
        if (std::find(owners.begin(), owners.end(), ownerKey) == owners.end())
            owners.push_back(ownerKey);

        // Every tier is kept. Only a duplicate of the SAME tier collapses, and
        // then the better rank wins - two rows for one tier and one slot would
        // otherwise make the priority depend on row order.
        auto& rows = bucket[itemId];
        auto sameTier = std::find_if(rows.begin(), rows.end(),
                                     [tierId](BisItem const& r) { return r.tierId == tierId; });
        if (sameTier == rows.end())
            rows.push_back(entry);
        else if (sameTier->rank > entry.rank)
            *sameTier = entry;

        ++_itemCount;
    } while (itemResult->NextRow());

    if (skipped)
        LOG_WARN("server.loading", "[mod-playerbots-bis] {} item rows reference an undefined tier and were ignored",
                 skipped);

    LoadQuestTokens();
    LoadWantedItems();

    _loaded = true;
    LOG_INFO("server.loading", "[mod-playerbots-bis] Loaded {} tiers, {} item rows and {} quest-token conversions",
             static_cast<uint32>(_tiers.size()), static_cast<uint32>(_itemCount),
             static_cast<uint32>(_questTokens.size()));
}

namespace
{
    // (jeton << 16) | (classe << 8) | spe. Ecrite une fois et appelee des deux
    // cotes : une cle composee a la main a deux endroits finit par differer, et
    // le symptome serait un jeton qui ne se convertit plus - sans erreur.
    uint64 QuestTokenKey(uint32 tokenId, uint8 cls, uint8 spec)
    {
        return (static_cast<uint64>(tokenId) << 16)
             | (static_cast<uint64>(cls) << 8)
             | static_cast<uint64>(spec);
    }
}

// La table est FACULTATIVE. Une base ou le fichier 56 n'a jamais tourne reste
// une base valide : les bots ne reclameront simplement aucun jeton, et aucun
// n'aura a etre converti. Un ERROR ici ferait croire a une installation cassee.
void BisPriorityMgr::LoadQuestTokens()
{
    QueryResult result = WorldDatabase.Query(
        "SELECT `token_id`, `class`, `spec`, `piece_id` FROM `playerbots_bis_quest_token`");
    if (!result)
        return;

    do
    {
        Field* fields = result->Fetch();
        uint32 const tokenId = fields[0].Get<uint32>();
        uint8 const cls = fields[1].Get<uint8>();
        uint8 const spec = fields[2].Get<uint8>();
        uint32 const pieceId = fields[3].Get<uint32>();

        if (!tokenId || !pieceId)
            continue;

        // TOUTES les pieces, pas la derniere lue. Un jeton qui en ouvre deux a
        // deux lignes, et les deux comptent.
        std::vector<uint32>& pieces = _questTokens[QuestTokenKey(tokenId, cls, spec)];
        if (std::find(pieces.begin(), pieces.end(), pieceId) == pieces.end())
            pieces.push_back(pieceId);
    } while (result->NextRow());
}

// Duree pendant laquelle une meme phrase ne sera pas repetee. Assez longue
// pour couvrir jet, reception et equipement - les trois moments ou la valeur
// est recalculee pour un meme objet - et assez courte pour qu'un objet reperdu
// puis retrouve plus tard soit annonce de nouveau.
namespace { constexpr time_t ANNONCE_FENETRE = 120; }

bool BisPriorityMgr::AnnounceOnce(Player* bot, uint32 itemId)
{
    if (!bot)
        return false;

    uint64 const cle = (uint64(bot->GetGUID().GetCounter()) << 32) | itemId;
    time_t const maintenant = time(nullptr);

    std::lock_guard<std::mutex> verrou(_annonceMutex);

    auto const it = _dejaAnnonce.find(cle);
    if (it != _dejaAnnonce.end() && maintenant - it->second < ANNONCE_FENETRE)
        return false;

    _dejaAnnonce[cle] = maintenant;

    // Purge opportuniste : sans elle la table grossirait pour toute la duree de
    // vie du serveur, un couple par objet convoite et par bot.
    if (_dejaAnnonce.size() > 4096)
    {
        for (auto i = _dejaAnnonce.begin(); i != _dejaAnnonce.end(); )
        {
            if (maintenant - i->second >= ANNONCE_FENETRE)
                i = _dejaAnnonce.erase(i);
            else
                ++i;
        }
    }

    return true;
}

// Facultative, comme playerbots_bis_quest_token et pour la meme raison : une
// base ou le fichier 76 n'a pas tourne n'est pas une base cassee.
void BisPriorityMgr::LoadWantedItems()
{
    QueryResult result = WorldDatabase.Query(
        "SELECT `item_id`, `max_count` FROM `playerbots_bis_wanted_item`");
    if (!result)
        return;

    do
    {
        Field* fields = result->Fetch();
        uint32 const itemId = fields[0].Get<uint32>();
        uint32 const maxCount = fields[1].Get<uint32>();

        // Un compte a zero voudrait dire "n'en veut jamais", ce qui s'ecrit en
        // retirant la ligne. Le lire comme 1 evitera une table ou une ligne
        // presente ne fait rien.
        if (itemId)
            _wantedItems[itemId] = maxCount ? maxCount : 1;
    } while (result->NextRow());
}

bool BisPriorityMgr::WantsExtraItem(Player* bot, uint32 itemId) const
{
    if (!bot || !_loaded)
        return false;

    auto const it = _wantedItems.find(itemId);
    if (it == _wantedItems.end())
        return false;

    // GetItemCount part de EQUIPMENT_SLOT_START : ce qui est porte compte
    // autant que ce qui dort dans un sac. Un bot qui en tient deja un n'a rien
    // a gagner a un second, et le prendre le retirerait a un bot qui n'en a
    // aucun - la meme regle que pour les pieces.
    return bot->GetItemCount(itemId, true) < it->second;
}

std::vector<uint32> const& BisPriorityMgr::QuestTokenRewards(uint32 tokenId, uint8 cls, uint8 spec) const
{
    static std::vector<uint32> const aucune;

    auto const it = _questTokens.find(QuestTokenKey(tokenId, cls, spec));
    return it == _questTokens.end() ? aucune : it->second;
}

uint8 BisPriorityMgr::ResolveSpec(Player* bot)
{
    uint8 spec = static_cast<uint8>(AiFactory::GetPlayerSpecTab(bot));

    // Feral Druids share tab 1. The list separates Bear from Cat, so a tank
    // Druid is looked up under the sentinel spec instead.
    if (bot->getClass() == CLASS_DRUID && spec == DRUID_TAB_FERAL && PlayerbotAI::IsTank(bot))
        return BIS_SPEC_DRUID_BEAR;

    return spec;
}

namespace
{
    bool IsOnRandomBotAccount(Player* bot)
    {
        WorldSession const* const session = bot->GetSession();
        if (!session)
            return false;

        return sPlayerbotAIConfig.IsInRandomAccountList(session->GetAccountId());
    }
}

bool BisPriorityMgr::AppliesTo(Player* bot)
{
    if (!_enabled || !_loaded || !bot)
        return false;

    if (!GET_PLAYERBOT_AI(bot))
        return false;

    // No level gate and no "has a list" gate any more. The BiS layer sits on top
    // of playerbots' own scoring instead of replacing it, so a bot it knows
    // nothing about simply keeps the original behaviour and is never frozen.

    if (sRandomPlayerbotMgr.IsRandomBot(bot))
        return _applyToRandomBots;

    if (sRandomPlayerbotMgr.IsAddclassBot(bot))
        return _applyToAddClassBots;

    // A bot sitting on a random-bot ACCOUNT that the rotation is not currently
    // holding. IsRandomBot is not "was created as a random bot":
    //
    //     if (!IsInRandomAccountList(...)) return false;
    //     return currentBots.contains(bot);
    //
    // currentBots is the manager's rotation. A bot brought online by hand with
    // ".playerbots bot add" joins the world outside it, so that test says no
    // although nothing about the character is an alt - and it would silently
    // fall into the alt category, which is off by default.
    //
    // Checked AFTER the addclass test on purpose: addclass accounts belong to
    // the same pool, so putting this first would swallow that category whole.
    if (IsOnRandomBotAccount(bot))
        return _applyToRandomBots;

    return _applyToAltBots;
}

uint8 BisPriorityMgr::GetProgressionLevel(Player* bot)
{
    uint32 const accountId = bot->GetSession() ? bot->GetSession()->GetAccountId() : 0;
    if (!accountId)
        return 0;

    time_t const now = time(nullptr);
    {
        std::lock_guard<std::mutex> guard(_progressionMutex);
        auto it = _progressionCache.find(accountId);
        if (it != _progressionCache.end() && it->second.expiry > now)
            return it->second.level;
    }

    uint8 level = 0;
    QueryResult result = CharacterDatabase.Query(
        "SELECT MAX(cc.quest) FROM character_queststatus_rewarded cc "
        "JOIN characters c ON cc.guid = c.guid "
        "WHERE c.account = {} AND cc.quest BETWEEN {} AND {}",
        accountId, IP_QUEST_BASE + 1, IP_QUEST_BASE + IP_QUEST_MAX_STATE);

    if (result)
    {
        Field* fields = result->Fetch();
        if (!fields[0].IsNull())
        {
            uint32 const questId = fields[0].Get<uint32>();
            if (questId > IP_QUEST_BASE)
                level = static_cast<uint8>(questId - IP_QUEST_BASE);
        }
    }

    {
        std::lock_guard<std::mutex> guard(_progressionMutex);
        ProgressionCacheEntry& entry = _progressionCache[accountId];
        entry.level = level;
        entry.expiry = now + _progressionCacheSeconds;
    }

    return level;
}

uint16 BisPriorityMgr::GetEffectiveTierCap(Player* bot)
{
    uint16 cap = _maxTier;
    if (!cap)
    {
        // No configured cap: the ladder's own top is the ceiling.
        for (auto const& kv : _tiers)
            cap = std::max(cap, kv.first);
    }

    if (!_useIndividualProgression)
        return cap;

    uint8 const progression = GetProgressionLevel(bot);

    // Walk the ladder down until a tier this character has actually unlocked.
    // A tier with required_progression = 0 is never gated.
    uint16 allowed = 0;
    for (auto const& kv : _tiers)
    {
        BisTier const& tier = kv.second;
        if (tier.tierId > cap)
            continue;
        if (tier.requiredProgression && tier.requiredProgression > progression)
            continue;
        allowed = std::max(allowed, tier.tierId);
    }

    return allowed;
}

uint32 BisPriorityMgr::GetItemPriority(Player* bot, uint32 itemId, uint8* outSlot,
                                       uint16* outTierId, uint8* outRank)
{
    if (!_loaded || !itemId)
        return 0;

    uint8 const cls = bot->getClass();
    uint8 const spec = ResolveSpec(bot);
    uint8 const faction = bot->GetTeamId() == TEAM_ALLIANCE ? 1 : 2;

    uint16 const cap = GetEffectiveTierCap(bot);

    // Of the tiers that list this piece, take the highest one the bot can
    // actually reach - the most recent phase's opinion is the current one - and
    // break a tie on the better rank. Rows above the cap are content the bot has
    // not unlocked; ignoring them here is what lets a piece that is rank 1
    // pre-raid and rank 3 at MC still be claimed by a pre-raid bot.
    auto best = [cap](std::vector<BisItem> const& rows) -> BisItem const*
    {
        BisItem const* pick = nullptr;
        for (BisItem const& row : rows)
        {
            if (row.tierId > cap)
                continue;
            if (!pick || row.tierId > pick->tierId || (row.tierId == pick->tierId && row.rank < pick->rank))
                pick = &row;
        }
        return pick;
    };

    BisItem const* found = nullptr;

    // Neutral rows first, faction rows override them.
    auto neutral = _items.find(MakeKey(cls, spec, 0));
    if (neutral != _items.end())
    {
        auto it = neutral->second.find(itemId);
        if (it != neutral->second.end())
            found = best(it->second);
    }

    auto factional = _items.find(MakeKey(cls, spec, faction));
    if (factional != _items.end())
    {
        auto it = factional->second.find(itemId);
        if (it != factional->second.end())
            if (BisItem const* pick = best(it->second))
                found = pick;
    }

    if (!found)
        return 0;

    if (outSlot)
        *outSlot = found->slot;
    if (outTierId)
        *outTierId = found->tierId;
    if (outRank)
        *outRank = found->rank;

    return uint32(found->tierId) * TIER_WEIGHT + (255u - std::min<uint32>(found->rank, 255u));
}

std::vector<BisItem> BisPriorityMgr::GetReachableList(Player* bot)
{
    std::vector<BisItem> out;
    if (!bot || !_loaded)
        return out;

    uint8 const cls = bot->getClass();
    uint8 const spec = ResolveSpec(bot);
    uint8 const faction = bot->GetTeamId() == TEAM_ALLIANCE ? 1 : 2;
    uint16 const cap = GetEffectiveTierCap(bot);

    // Same choice GetItemPriority makes for a single item, applied to the whole
    // list: of the tiers that name this piece, the highest one within the cap,
    // ties broken on the better rank.
    auto best = [cap](std::vector<BisItem> const& rows) -> BisItem const*
    {
        BisItem const* pick = nullptr;
        for (BisItem const& row : rows)
        {
            if (row.tierId > cap)
                continue;
            if (!pick || row.tierId > pick->tierId || (row.tierId == pick->tierId && row.rank < pick->rank))
                pick = &row;
        }
        return pick;
    };

    // A list lives in TWO buckets: the neutral rows under faction 0, which carry
    // most of the table, and the faction rows that override them. Reading only
    // the faction bucket - as this did at first - finds almost nothing and
    // reports a fully geared bot as having no list at all.
    std::unordered_map<uint32, BisItem> chosen;

    auto absorb = [&](uint8 f, bool overrides)
    {
        auto bucket = _items.find(MakeKey(cls, spec, f));
        if (bucket == _items.end())
            return;

        for (auto const& entry : bucket->second)
        {
            BisItem const* pick = best(entry.second);
            if (!pick)
                continue;

            auto it = chosen.find(entry.first);
            if (it == chosen.end())
                chosen.emplace(entry.first, *pick);
            else if (overrides)
                it->second = *pick;
        }
    };

    absorb(0, false);
    absorb(faction, true);

    out.reserve(chosen.size());
    for (auto const& entry : chosen)
        out.push_back(entry.second);

    std::sort(out.begin(), out.end(), [](BisItem const& a, BisItem const& b)
    {
        if (a.slot != b.slot)
            return a.slot < b.slot;
        if (a.rank != b.rank)
            return a.rank < b.rank;
        return a.tierId > b.tierId;
    });

    return out;
}

bool BisPriorityMgr::HasReachableList(Player* bot)
{
    if (!_loaded)
        return false;

    uint8 const cls = bot->getClass();
    uint8 const spec = ResolveSpec(bot);
    uint8 const faction = bot->GetTeamId() == TEAM_ALLIANCE ? 1 : 2;
    uint16 const cap = GetEffectiveTierCap(bot);

    // _minTierByCombo holds the lowest tier present for each combo, so this
    // stays O(1) on a decision path that runs for every lootable item.
    for (uint8 f : {uint8(0), faction})
    {
        auto it = _minTierByCombo.find(MakeKey(cls, spec, f));
        if (it != _minTierByCombo.end() && it->second <= cap)
            return true;
    }

    return false;
}

uint32 BisPriorityMgr::GetWornPriorityPaired(Player* bot, uint8 slot, uint8* outTargetSlot)
{
    uint32 worn = GetWornPriority(bot, slot);
    uint8 target = slot;

    if (uint8 const paired = PairedSlot(slot); paired != 0xFF)
    {
        uint32 const pairedPriority = GetWornPriority(bot, paired);
        if (pairedPriority < worn)
        {
            worn = pairedPriority;
            target = paired;
        }
    }

    if (outTargetSlot)
        *outTargetSlot = target;

    return worn;
}

namespace
{
    // True when the tooltip names this class AND NO OTHER - "Classes : Mage",
    // not "Classes : Pretre, Chaman, Mage, Demoniste, Druide".
    //
    // The narrow reading is deliberate. Accepting any item that merely allows
    // the class would cover nearly every cloth drop, and forty bots would then
    // claim everything - the exact stampede NeedOnlyForBis exists to stop. An
    // item reserved to one class is unambiguous: it was itemised for this bot,
    // and nobody else in the raid can wear it.
    bool IsReservedForClass(ItemTemplate const* proto, uint8 cls)
    {
        int32 const allowed = proto->AllowableClass;
        if (allowed <= 0)
            return false;  // no restriction at all

        return uint32(allowed) == (1u << (cls - 1));
    }
}

char const* BisPriorityMgr::WhyNotFollowed(Player* bot)
{
    if (!bot)
        return nullptr;

    if (!_enabled)
        return "module desactive";

    if (!_loaded)
        return "tables non chargees";

    // A real player is not a bot that went missing, so there is nothing to
    // report about it.
    if (!GET_PLAYERBOT_AI(bot))
        return nullptr;

    // IsRandomBot is not "was created as a random bot": it also requires the
    // random manager to still hold the bot in currentBots. One that left that
    // set falls through to the alt-bot category, which is off by default - and
    // that is the case this message exists to name.
    if (sRandomPlayerbotMgr.IsRandomBot(bot))
        return _applyToRandomBots ? nullptr : "randombot, PlayerbotsBis.ApplyToRandomBots = 0";

    if (sRandomPlayerbotMgr.IsAddclassBot(bot))
        return _applyToAddClassBots ? nullptr : "bot addclass, PlayerbotsBis.ApplyToAddClassBots = 0";

    if (IsOnRandomBotAccount(bot))
        return _applyToRandomBots ? nullptr
                                  : "randombot hors rotation, PlayerbotsBis.ApplyToRandomBots = 0";

    return _applyToAltBots ? nullptr
                           : "ni randombot ni addclass (alt), PlayerbotsBis.ApplyToAltBots = 0";
}

bool BisPriorityMgr::ClaimsClassRestricted(PlayerbotAI* botAI, Player* bot, uint32 itemId, uint8* outSlot)
{
    if (!botAI || !bot || !_claimClassRestricted || !AppliesTo(bot))
        return false;

    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
    if (!proto)
        return false;

    if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR)
        return false;

    // A piece the lists DO name is branch 1's business, never this one.
    if (GetItemPriority(bot, itemId))
        return false;

    if (!IsReservedForClass(proto, bot->getClass()))
        return false;

    // Unlike a listed best in slot, a missing level disqualifies here. The
    // claim exists to fill an empty slot now; holding a piece for a level the
    // bot has not reached, on nobody's authority but item level, would just
    // park loot in a bag.
    if (bot->CanUseItem(proto) != EQUIP_ERR_OK)
        return false;

    uint8 const dstSlot = botAI->FindEquipSlot(proto, NULL_SLOT, true);
    if (dstSlot == NULL_SLOT)
        return false;

    // A slot already settled by a listed piece is never disturbed by something
    // no list names.
    if (GetWornPriorityPaired(bot, dstSlot))
        return false;

    Item* const worn = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, dstSlot);

    // The piece the bot is ALREADY wearing. Item level cannot separate those
    // two - they are the same number - so without this test a bot claims, rolls
    // for and equips a second copy of what it had on, replacing it with itself.
    // That costs a drop another bot could have used, and the whisper announcing
    // it reads as nonsense.
    //
    // LES DEUX EMPLACEMENTS DE LA PAIRE, et c'est ce qui manquait. Sur un
    // anneau ou un bijou, FindEquipSlot rend volontiers celui des deux qui est
    // LIBRE : regarder ce seul emplacement ne voit pas l'exemplaire porte a
    // l'autre, et le bot reclame une seconde fois ce qu'il a deja sur lui.
    // C'est le defaut observe sur Aegis of Preservation, un bijou.
    //
    // UniqueAlreadyWorn ne couvre pas ce cas : elle passe par
    // CanEquipUniqueItem, qui ne connait que les objets marques
    // unique-equipe. La plupart des bijoux ne le sont pas.
    for (uint8 s : {dstSlot, PairedSlot(dstSlot)})
    {
        if (s == 0xFF)
            continue;

        Item const* const porte = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, s);
        if (porte && porte->GetEntry() == itemId)
            return false;
    }

    // Item level is the blunt measure the stat score is not: it cannot rate a
    // downgrade as an upgrade, and it cannot be fooled by weights tuned for
    // another spec. Equal counts as good enough, deliberately: the claim exists
    // to settle a slot no list covers, where a sidegrade is still an answer.
    if (worn && proto->ItemLevel < worn->GetTemplate()->ItemLevel)
        return false;

    if (outSlot)
        *outSlot = dstSlot;

    return true;
}

bool BisPriorityMgr::OffHandClosed(Player* bot, uint8 slot)
{
    return slot == EQUIPMENT_SLOT_OFFHAND && bot && bot->IsTwoHandUsed();
}

ItemTemplate const* BisPriorityMgr::WouldReplace(Player* bot, uint32 itemId)
{
    if (!bot)
        return nullptr;

    uint8 slot = 0;
    if (!GetItemPriority(bot, itemId, &slot))
        return nullptr;

    uint8 targetSlot = slot;
    GetWornPriorityPaired(bot, slot, &targetSlot);

    Item const* const worn = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, targetSlot);
    return worn ? worn->GetTemplate() : nullptr;
}

// Un creneau APPARIE - doigts, bijoux - rend le plus FAIBLE de ses deux cotes,
// pour que la nouvelle piece remplace la moins bonne. Il ne regarde donc pas ce
// que porte le cote le plus fort, et c'est exactement la que ca casse : un bot
// portant deja Band of Dark Dominion au doigt 1 et un anneau pre-raid au doigt 2
// voyait une amelioration au doigt 2, l'annoncait, et le coeur refusait
// l'equipement - l'anneau est UNIQUE-EQUIPE. A chaque tick, indefiniment.
//
// CanEquipUniqueItem est le test juste, et non l'egalite des identifiants : deux
// anneaux IDENTIQUES mais NON uniques sont parfaitement legitimes en 3.3.5 - un
// pretre portait volontiers deux Ring of Spell Power. Le creneau vise est exclu
// du compte, pour que la piece qu'on s'apprete a retirer n'y figure pas.
//
// Une seule fonction pour les DEUX chemins : l'avis qui annonce et la
// reclamation qui jette. Divergents, ils produisaient precisement ce bogue - une
// annonce repetee sans jamais d'equipement.
bool BisPriorityMgr::UniqueAlreadyWorn(Player* bot, ItemTemplate const* proto, uint8 targetSlot)
{
    if (!bot || !proto)
        return false;

    return bot->CanEquipUniqueItem(proto, targetSlot) != EQUIP_ERR_OK;
}

// Un jeton de quete que la liste du bot reclame.
//
// Pourquoi ce chemin separe : WantsAsUpgrade, l'avis d'usage et la passe
// d'equipement ecartent tous ce qui n'est ni ITEM_CLASS_WEAPON ni
// ITEM_CLASS_ARMOR - a juste titre, un objet de quete ne s'equipe pas. Mais le
// jet, lui, doit avoir lieu : un jeton hakkari vaut une piece de rang 1, et
// avec tous les bots qui passent il ne revenait a personne.
//
// Et le jeton gagne ne dort pas dans le sac : BisEquipUpgradesAction::
// ConvertQuestTokens l'echange contre la piece des que le bot le tient. Le
// chemin du jeu - l'ile de Yojamba et la reputation Zandalar, jusqu'a 21000
// Revere pour certaines pieces - est hors de portee de bots qui ne montent
// aucune reputation, donc l'echange est direct.
bool BisPriorityMgr::WantsQuestToken(Player* bot, uint32 itemId, uint16* outTierId)
{
    if (!AppliesTo(bot))
        return false;

    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
    if (!proto)
        return false;

    // UN JETON, C'EST CE QUE LA TABLE DE CONVERSION NOMME - PAS UNE CLASSE
    // D'OBJET. Cette ligne testait ITEM_CLASS_QUEST, et c'etait faux : les
    // jetons de Zul'Gurub et les idoles d'Ahn'Qiraj sont bien des objets de
    // quete (12), mais les SEPT jetons du tier 2.5 - Imperial Qiraji Armaments
    // et Regalia, Carapace et Husk of the Old God, Vek'lor's Diadem, les deux
    // Qiraji Bindings - sont des objets DIVERS (15). Le filtre les rendait
    // invisibles : 105 lignes de listes sur lesquelles aucun bot ne votait, et
    // les meilleures pieces du raid partaient au plus haut jet de cupidite.
    //
    // Interroger la table est aussi plus juste que l'ancien test : un bot ne
    // reclame plus un jeton qu'il ne saurait pas convertir, alors qu'avant il
    // suffisait que le jeton figure dans sa liste.
    std::vector<uint32> const& pieces = QuestTokenRewards(itemId, bot->getClass(), GetSpec(bot));
    if (pieces.empty())
        return false;

    // Un second exemplaire ne vaut rien : une quete, un jeton. Le prendre
    // retirerait le jet a un bot qui n'en a pas.
    if (bot->GetItemCount(itemId, true) > 0)
        return false;

    // ── UNE SEULE PIECE QUI MANQUE SUFFIT ─────────────────────────────────
    //
    // On interroge CHAQUE piece que le jeton ouvre, et chacune dans SON
    // creneau. Je posais la question au jeton lui-meme, dont les lignes copient
    // celles des pieces : GetItemPriority n'en retenait que la mieux classee,
    // donc la comparaison portait toujours sur le meme creneau. Un guerrier qui
    // portait les epaules rang 1 cessait de reclamer le jeton, et n'allait
    // jamais chercher les bottes rang 5 qu'il ouvrait pourtant aussi.
    //
    // Le palier rendu est celui de la premiere piece qui manque, et l'ordre
    // vient de la table - les pieces y sont rangees par rang, la meilleure
    // d'abord.
    for (uint32 const pieceId : pieces)
    {
        uint8 slot = 0;
        uint16 tierId = 0;
        uint32 const priority = GetItemPriority(bot, pieceId, &slot, &tierId);
        if (!priority)
            continue;

        // Deja porte, en sac ou en banque : celle-la ne motive plus rien.
        if (bot->GetItemCount(pieceId, true) > 0)
            continue;

        // Et rien a reclamer si le creneau porte deja aussi bien.
        if (priority <= GetWornPriorityPaired(bot, slot))
            continue;

        if (outTierId)
            *outTierId = tierId;

        return true;
    }

    return false;
}

bool BisPriorityMgr::WantsAsUpgrade(Player* bot, uint32 itemId, uint16* outTierId,
                                    bool* outTooLowLevel, uint8* outRank)
{
    if (outTooLowLevel)
        *outTooLowLevel = false;

    if (!AppliesTo(bot))
        return false;

    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
    if (!proto)
        return false;

    if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR)
        return false;

    uint8 slot = 0;
    uint16 tierId = 0;
    uint8 rank = 0;
    uint32 const priority = GetItemPriority(bot, itemId, &slot, &tierId, &rank);
    if (!priority)
        return false;

    if (outRank)
        *outRank = rank;

    // Same reason the equip sweep refuses it: a two-hander leaves no off-hand to
    // fill. Claiming it here would have the bot roll NEED on a piece the core
    // will not let it put on.
    if (OffHandClosed(bot, slot))
        return false;

    // Claiming something the bot can NEVER wear would have it ask for an item it
    // can never equip, so the class / race / faction / proficiency gate applies.
    //
    // A missing level is a different matter: Player::CanUseItem returns
    // EQUIP_ERR_CANT_EQUIP_LEVEL_I for it, and that obstacle disappears on its
    // own as the bot levels. Treating it like the others made a level 57 bot
    // stay silent in front of its own level 60 best in slot and let it go.
    InventoryResult const canUse = bot->CanUseItem(proto);
    if (canUse != EQUIP_ERR_OK)
    {
        if (canUse != EQUIP_ERR_CANT_EQUIP_LEVEL_I || !_claimBelowRequiredLevel)
            return false;

        if (outTooLowLevel)
            *outTooLowLevel = true;
    }

    uint8 targetSlot = slot;
    if (priority <= GetWornPriorityPaired(bot, slot, &targetSlot))
        return false;  // already wearing this piece, or something better

    if (UniqueAlreadyWorn(bot, proto, targetSlot))
        return false;

    if (outTierId)
        *outTierId = tierId;

    return true;
}

bool BisPriorityMgr::IsBisForAnotherSpec(Player* bot, uint32 itemId)
{
    auto it = _bisOwners.find(itemId);
    if (it == _bisOwners.end())
        return false;  // nobody's best in slot

    uint16 const mine = (uint16(bot->getClass()) << 8) | ResolveSpec(bot);

    for (uint16 owner : it->second)
        if (owner != mine)
            return true;

    return false;
}

std::string BisPriorityMgr::GetTierName(uint16 tierId) const
{
    auto it = _tiers.find(tierId);
    return it == _tiers.end() ? std::string() : it->second.name;
}

uint32 BisPriorityMgr::GetWornPriority(Player* bot, uint8 slot)
{
    Item* worn = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!worn)
        return 0;

    return GetItemPriority(bot, worn->GetEntry(), nullptr);
}
