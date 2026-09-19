/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisItemUsageValue.h"
#include "BisPriorityMgr.h"
#include "Item.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include <sstream>
#include <string>

namespace
{
    // The BiS layer, applied on top of whatever playerbots already decided.
    //
    // Three branches, in order:
    //   1. the item is this bot's best in slot  -> announce it and take it
    //   2. it is somebody else's best in slot   -> leave it to them
    //   3. it belongs to no list                -> playerbots' own verdict stands
    //
    // Branch 3 is the common case and is exactly the original behaviour: the
    // stat-weight comparison against the equipped item, with its 1.1x threshold.
    // This layer only ever overrides that verdict for items the lists know, at
    // any level - a level 30 bot recognises its level 60 best in slot just as
    // well as a capped one.
    ItemUsage ApplyBisPolicy(PlayerbotAI* botAI, Player* bot, uint32 itemId, ItemUsage base)
    {
        if (!sBisPriorityMgr->AppliesTo(bot))
            return base;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
        if (!proto)
            return base;

        // Only gear is arbitrated. Quest items, ammo, reagents, consumables and
        // every vendor / auction / disenchant verdict pass through untouched.
        if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR)
            return base;

        uint8 slot = 0;
        uint16 tierId = 0;
        uint32 const priority = sBisPriorityMgr->GetItemPriority(bot, itemId, &slot, &tierId);

        // ── Branch 2 ──────────────────────────────────────────────────────────
        if (!priority)
        {
            // Deferring is only fair when the bot has a list of its own to fall
            // back on. A spec nobody has written a list for yet would otherwise
            // refuse every item any other spec claims while never claiming
            // anything, and end up the worst geared character on the server.
            // Such a bot keeps playerbots' original behaviour untouched.
            if (sBisPriorityMgr->LeaveOtherSpecsBis() && sBisPriorityMgr->HasReachableList(bot) &&
                sBisPriorityMgr->IsBisForAnotherSpec(bot, itemId))
                return ITEM_USAGE_NONE;

            return base;  // ── Branch 3: nobody's list, original logic wins
        }

        // ── Branch 1 ──────────────────────────────────────────────────────────
        // Wanting an item the bot can NEVER wear would make it roll on something
        // it can never equip, so the class / race / faction / proficiency gate is
        // re-checked here: the forced verdict below bypasses the one playerbots
        // applies upstream.
        //
        // A missing LEVEL is deliberately not treated the same way. It is a
        // temporary obstacle that disappears as the bot grows, and lumping it in
        // with the permanent ones made a level 57 bot stay silent in front of its
        // own level 60 best in slot and let the piece go.
        bool tooLowLevel = false;
        {
            InventoryResult const canUse = bot->BotCanUseItem(proto);
            if (canUse != EQUIP_ERR_OK)
            {
                if (canUse != EQUIP_ERR_CANT_EQUIP_LEVEL_I || !sBisPriorityMgr->ClaimBelowRequiredLevel())
                    return base;

                tooLowLevel = true;
            }
        }

        uint8 targetSlot = slot;
        uint32 const wornPriority = sBisPriorityMgr->GetWornPriorityPaired(bot, slot, &targetSlot);

        // Already wearing this piece, or something higher up the ladder.
        if (priority <= wornPriority)
            return ITEM_USAGE_NONE;

        if (sBisPriorityMgr->AnnounceOwnBis() && botAI)
        {
            std::string const tierName = sBisPriorityMgr->GetTierName(tierId);
            std::ostringstream out;
            out << "|cff1eff00" << proto->Name1 << "|r - c'est mon BiS";
            if (!tierName.empty())
                out << " (" << tierName << ")";
            if (tooLowLevel)
                out << " - je le garde, il me faut le niveau " << uint32(proto->RequiredLevel);
            botAI->TellMaster(out.str());
        }

        return bot->GetItemByPos(INVENTORY_SLOT_BAG_0, targetSlot) ? ITEM_USAGE_REPLACE : ITEM_USAGE_EQUIP;
    }
}

ItemUsage BisItemUsageValue::Calculate()
{
    ItemUsage const base = ItemUsageValue::Calculate();
    return ApplyBisPolicy(botAI, bot, GetItemIdFromQualifier().itemId, base);
}

ItemUsage BisItemUpgradeValue::Calculate()
{
    ItemUsage const base = ItemUpgradeValue::Calculate();
    return ApplyBisPolicy(botAI, bot, GetItemIdFromQualifier().itemId, base);
}
