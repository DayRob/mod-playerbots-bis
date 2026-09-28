/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisEquipAction.h"
#include "BisPriorityMgr.h"
#include "ChatHelper.h"
#include "Event.h"
#include "Item.h"
#include "ItemPackets.h"
#include "ItemVisitors.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include <sstream>

bool BisEquipUpgradesAction::Execute(Event event)
{
    // The original keeps every case it already handles well - armour, rings,
    // trinkets, and the weapon arbitration when its own score agrees with us.
    // This only picks up what it leaves behind.
    bool const acted = EquipUpgradesPacketAction::Execute(event);

    if (!sBisPriorityMgr->IsEnabled() || !sBisPriorityMgr->IsLoaded() ||
        !sBisPriorityMgr->AppliesTo(bot))
        return acted;

    return EquipBisFromBags() || acted;
}

bool BisEquipUpgradesAction::EquipBisFromBags()
{
    CollectItemsVisitor visitor;
    IterateItems(&visitor, ITERATE_ITEMS_IN_BAGS);

    bool equipped = false;

    for (Item* item : visitor.items)
    {
        if (!item)
            continue;

        ItemTemplate const* proto = item->GetTemplate();
        if (!proto)
            continue;

        // Only gear. Everything else keeps playerbots' own handling.
        if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR)
            continue;

        uint8 slot = 0;
        uint16 tierId = 0;
        uint32 const priority = sBisPriorityMgr->GetItemPriority(bot, proto->ItemId, &slot, &tierId);
        if (!priority)
            continue;  // no list names it; the original's verdict stands

        // Unlike the claim made at loot time, a missing level is disqualifying
        // here: the core refuses the equip outright, so forcing it would only
        // spend a packet per tick until the bot grows into the piece.
        if (bot->BotCanUseItem(proto) != EQUIP_ERR_OK)
            continue;

        uint8 targetSlot = slot;
        if (priority <= sBisPriorityMgr->GetWornPriorityPaired(bot, slot, &targetSlot))
            continue;  // already wearing this piece, or something higher up the ladder

        // A two-hander goes to the main hand with an off-hand still on: the
        // core moves that off-hand to the bags when there is room, and refuses
        // the whole thing when there is none. Either way it answers for itself,
        // and a refusal simply means the next item received tries again.
        WorldPacket packet(CMSG_AUTOEQUIP_ITEM_SLOT, 2);
        ObjectGuid const guid = item->GetGUID();
        packet << guid << targetSlot;

        WorldPackets::Item::AutoEquipItemSlot equipPacket(std::move(packet));
        equipPacket.Read();
        bot->GetSession()->HandleAutoEquipItemSlotOpcode(equipPacket);

        // Said out loud for the same reason the claim is: the bot is putting on
        // something playerbots' own score had just declined, and without a word
        // that reads as the item jumping slots by itself.
        if (sBisPriorityMgr->AnnounceOwnBis() && botAI)
        {
            std::string const tierName = sBisPriorityMgr->GetTierName(tierId);
            std::ostringstream out;
            out << "J'equipe " << ChatHelper::FormatItem(proto);
            if (!tierName.empty())
                out << " (" << tierName << ")";
            botAI->TellMaster(out.str());
        }

        equipped = true;
    }

    return equipped;
}
