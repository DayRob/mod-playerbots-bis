/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_BOT_SCAN_H
#define MOD_PLAYERBOTS_BIS_BOT_SCAN_H

#include "BisPriorityMgr.h"
#include "Chat.h"
#include "Item.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "SharedDefines.h"
#include <algorithm>
#include <map>
#include <string>
#include <vector>

// Shared ground between the two windows the module feeds: the BiS roster
// (BisReport).
//
// Both ask the same three questions - which bots am I looking at, what does this
// bot's list pick for each slot, and does it own the piece - so the answers live
// here rather than in two copies that could drift apart. The plan counting a
// slot differently from the roster would be a bug nobody would notice until the
// two windows disagreed on screen.
namespace BisBotScan
{
    enum State : uint8
    {
        BIS_MISSING  = 0,
        BIS_CARRIED  = 1,
        BIS_EQUIPPED = 2,
    };

    // Broad role, derived from class and spec. Used by the dungeon plan to
    // avoid proposing a group of five damage dealers, which reads well on paper
    // and clears nothing.
    enum Role : uint8
    {
        ROLE_DPS    = 0,
        ROLE_TANK   = 1,
        ROLE_HEALER = 2,
    };

    inline char const* ClassName(uint8 cls)
    {
        static char const* const NAMES[MAX_CLASSES] = {
            "", "Guerrier", "Paladin", "Chasseur", "Voleur", "Pretre",
            "Chevalier de la mort", "Chaman", "Mage", "Demoniste", "", "Druide",
        };
        return (cls < MAX_CLASSES && NAMES[cls][0]) ? NAMES[cls] : "?";
    }

    // Spec 10 on the Druid is the module's Bear sentinel: Bear and Cat share
    // talent tab 1, so the list separates them by a value the tab cannot produce.
    inline char const* SpecName(uint8 cls, uint8 spec)
    {
        switch (cls)
        {
            case CLASS_WARRIOR:      return spec == 0 ? "Armes" : spec == 1 ? "Fureur" : "Protection";
            case CLASS_PALADIN:      return spec == 0 ? "Sacre" : spec == 1 ? "Protection" : "Vindicte";
            case CLASS_HUNTER:       return spec == 0 ? "Maitrise des betes" : spec == 1 ? "Precision" : "Survie";
            case CLASS_ROGUE:        return spec == 0 ? "Assassinat" : spec == 1 ? "Combat" : "Finesse";
            case CLASS_PRIEST:       return spec == 0 ? "Discipline" : spec == 1 ? "Sacre" : "Ombre";
            case CLASS_DEATH_KNIGHT: return spec == 0 ? "Sang" : spec == 1 ? "Givre" : "Impie";
            case CLASS_SHAMAN:       return spec == 0 ? "Elementaire" : spec == 1 ? "Amelioration" : "Restauration";
            case CLASS_MAGE:         return spec == 0 ? "Arcanes" : spec == 1 ? "Feu" : "Givre";
            case CLASS_WARLOCK:      return spec == 0 ? "Affliction" : spec == 1 ? "Demonologie" : "Destruction";
            case CLASS_DRUID:
                if (spec == BIS_SPEC_DRUID_BEAR)
                    return "Farouche (ours)";
                return spec == 0 ? "Equilibre" : spec == 1 ? "Farouche" : "Restauration";
            default: return "?";
        }
    }

    // The spec values are the ones the BiS lists are keyed by, which is also
    // what GetSpec() returns - so a Druid tank arrives as the Bear sentinel and
    // is recognised here, while a Cat is not.
    inline Role RoleOf(uint8 cls, uint8 spec)
    {
        switch (cls)
        {
            case CLASS_WARRIOR:      return spec == 2 ? ROLE_TANK : ROLE_DPS;
            case CLASS_PALADIN:      return spec == 1 ? ROLE_TANK : spec == 0 ? ROLE_HEALER : ROLE_DPS;
            case CLASS_PRIEST:       return spec == 2 ? ROLE_DPS : ROLE_HEALER;
            case CLASS_DEATH_KNIGHT: return spec == 0 ? ROLE_TANK : ROLE_DPS;
            case CLASS_SHAMAN:       return spec == 2 ? ROLE_HEALER : ROLE_DPS;
            case CLASS_DRUID:
                if (spec == BIS_SPEC_DRUID_BEAR) return ROLE_TANK;
                return spec == 2 ? ROLE_HEALER : ROLE_DPS;
            default: return ROLE_DPS;
        }
    }

    inline char const* RoleName(Role role)
    {
        return role == ROLE_TANK ? "tank" : role == ROLE_HEALER ? "soigneur" : "dps";
    }

    // Equipped beats carried: an item found on the bot's body is reported as
    // worn even though GetItemCount would also count it.
    inline uint8 ResolveState(Player* bot, uint32 itemId)
    {
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
            if (Item* worn = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                if (worn->GetEntry() == itemId)
                    return BIS_EQUIPPED;

        return bot->GetItemCount(itemId, true) > 0 ? BIS_CARRIED : BIS_MISSING;
    }

    // One target per slot: the best reachable pick, highest phase first and rank
    // 1 within it.
    //
    // Counting every rank-1 row instead counts the same slot once per phase - a
    // head slot listed in pre-raid and again in Molten Core contributes two - so
    // the denominator grows with the number of phases opened and 100% stops
    // being reachable by construction. A warrior showed 35 "pieces" for
    // seventeen slots.
    // A slot's target has to be something the bot can WEAR. The lists also
    // carry pieces that merely LEAD to gear - the Zul'Gurub tokens sit at the
    // slot, tier and rank of the set piece they buy, so a bot's wrist slot can
    // hold both Zandalar Vindicator's Armguards and Primal Hakkari Armsplint at
    // rank 1 of the same tier. Equal on every field the comparison below reads,
    // std::sort leaves their order unspecified, and the slot's target became
    // whichever landed first: half the time a quest item, which no bot can ever
    // equip, so the slot read as missing for ever and the ratio lost a point it
    // could not earn back.
    inline bool CanBeWorn(uint32 itemId)
    {
        ItemTemplate const* const proto = sObjectMgr->GetItemTemplate(itemId);
        return proto && (proto->Class == ITEM_CLASS_WEAPON || proto->Class == ITEM_CLASS_ARMOR);
    }

    // One target per slot: the best reachable pick, highest phase first and rank
    // 1 within it - among the pieces that can actually be worn.
    inline std::map<uint8, BisItem> TargetsPerSlot(std::vector<BisItem> const& list)
    {
        std::map<uint8, BisItem> targets;
        for (BisItem const& row : list)
        {
            if (!CanBeWorn(row.itemId))
                continue;

            auto it = targets.find(row.slot);
            if (it == targets.end())
                targets.emplace(row.slot, row);
            else if (row.tierId > it->second.tierId ||
                     (row.tierId == it->second.tierId && row.rank < it->second.rank))
                it->second = row;
        }
        return targets;
    }

    // Bots the module applies to, optionally narrowed to one guild. Only bots in
    // the world can be inspected: the answer comes from their live inventory.
    // skipped, when given, receives one line per character that IS a bot, IS in
    // scope, and was nonetheless left out - with the reason. Without it a bot
    // simply disappears from the report, which looks exactly like a bug.
    inline std::vector<Player*> CollectBots(uint32 guildId, bool all,
                                            std::vector<std::string>* skipped = nullptr)
    {
        std::vector<Player*> bots;
        for (auto const& pair : ObjectAccessor::GetPlayers())
        {
            Player* bot = pair.second;
            if (!bot || !bot->IsInWorld())
                continue;

            bool const inScope = all || bot->GetGuildId() == guildId;

            if (!sBisPriorityMgr->AppliesTo(bot))
            {
                // Scope is checked AFTER the verdict here, so that a guild bot
                // the module refuses is still named: the player asked about his
                // guild, and that is where he expects the answer.
                if (skipped && inScope)
                    if (char const* why = sBisPriorityMgr->WhyNotFollowed(bot))
                        skipped->push_back(bot->GetName() + " - " + why);
                continue;
            }

            if (!inScope)
                continue;

            bots.push_back(bot);
        }

        if (skipped)
            std::sort(skipped->begin(), skipped->end());

        std::sort(bots.begin(), bots.end(), [](Player* a, Player* b)
        {
            if (a->getClass() != b->getClass())
                return a->getClass() < b->getClass();
            return a->GetName() < b->GetName();
        });

        return bots;
    }

    // Fields are separated by ';', never '|'. The client runs chat text through
    // its escape parser before an addon ever sees it, and '|' opens an escape
    // sequence: "B|Cruvmarl" reads as the start of a colour code |c......, and a
    // malformed one kills the client outright (ERROR #134). ChatHandler doubles
    // '|' into '||' in system messages for exactly this reason.
    constexpr char FIELD_SEP = ';';

    // Addon messages cap at 255 bytes including the marker, so payloads stay
    // well under that and a long item list travels in several pieces.
    constexpr size_t PAYLOAD_MAX = 200;

    // The stream travels as ordinary system messages carrying a marker, not as
    // CHAT_MSG_ADDON. Addon messages built server side killed the 3.3.5 client
    // outright (ERROR #134), while the summary lines printed by these very
    // commands arrive fine - so the stream rides the path already proven to work
    // here. The addon hides these lines with a CHAT_MSG_SYSTEM filter; without
    // the addon they are merely visible, never fatal.
    inline void SendMarked(ChatHandler* handler, char const* marker, std::string const& payload)
    {
        if (!handler)
            return;

        // No formatting: the payload must reach the client byte for byte, and a
        // stray brace in a guild name would otherwise be read as a placeholder.
        handler->SendSysMessage(std::string(marker) + payload);
    }
}

#endif
