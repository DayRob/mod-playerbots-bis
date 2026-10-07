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
    _announceMasterLoot = sConfigMgr->GetOption<bool>("PlayerbotsBis.AnnounceMasterLoot", true);
    _claimBelowRequiredLevel = sConfigMgr->GetOption<bool>("PlayerbotsBis.ClaimBelowRequiredLevel", true);
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

    _loaded = true;
    LOG_INFO("server.loading", "[mod-playerbots-bis] Loaded {} tiers and {} item rows",
             static_cast<uint32>(_tiers.size()), static_cast<uint32>(_itemCount));
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

uint32 BisPriorityMgr::GetItemPriority(Player* bot, uint32 itemId, uint8* outSlot, uint16* outTierId)
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
    // two - they are the same number - so the test below let a bot claim, roll
    // for and equip a second copy of what it had on, replacing it with itself.
    // That costs a drop another bot could have used, and the whisper announcing
    // it reads as nonsense.
    if (worn && worn->GetEntry() == itemId)
        return false;

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
// Et les bots SAVENT rendre une quete : TalkToQuestGiverAction::TurnInQuest
// s'en charge des que le bot parle au donneur avec la quete complete. Le jeton
// n'est donc pas perdu pour un bot qui le gagne - il faut l'amener au donneur,
// qui pour Zul'Gurub se tient sur l'ile de Yojamba, a cote de l'entree.
bool BisPriorityMgr::WantsQuestToken(Player* bot, uint32 itemId, uint16* outTierId)
{
    if (!AppliesTo(bot))
        return false;

    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
    if (!proto || proto->Class != ITEM_CLASS_QUEST)
        return false;

    uint8 slot = 0;
    uint16 tierId = 0;
    uint32 const priority = GetItemPriority(bot, itemId, &slot, &tierId);
    if (!priority)
        return false;

    // Un second exemplaire ne vaut rien : une quete, un jeton. Le prendre
    // retirerait le jet a un bot qui n'en a pas.
    if (bot->GetItemCount(itemId, true) > 0)
        return false;

    // Et rien a reclamer si le creneau porte deja aussi bien. La piece que le
    // jeton achete partage sa priorite, donc la comparaison est la meme que
    // pour une piece d'equipement.
    if (priority <= GetWornPriorityPaired(bot, slot))
        return false;

    if (outTierId)
        *outTierId = tierId;

    return true;
}

bool BisPriorityMgr::WantsAsUpgrade(Player* bot, uint32 itemId, uint16* outTierId, bool* outTooLowLevel)
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
    uint32 const priority = GetItemPriority(bot, itemId, &slot, &tierId);
    if (!priority)
        return false;

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
