/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisEquipAction.h"
#include "BisBotScan.h"
#include "BisPriorityMgr.h"
#include "Chat.h"
#include "ChatHelper.h"
#include "Event.h"
#include "Item.h"
#include "ItemPackets.h"
#include "ItemVisitors.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include <sstream>
#include <string>
#include <vector>

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

// ---------------------------------------------------------------------------
// ".playerbotsbis equipe" - the same sweep, on demand.
//
// The action above is a packet action: it answers an arriving item. That is the
// right moment in normal play, and the wrong one for everything that lands
// outside it - a quest reward turned in by forty bots at once, a piece looted
// while the module was switched off, a list that changed under a bot that has
// received nothing since. In all of those the gear sits in the bags, correct and
// unworn, with nothing scheduled to look at it again.
// ---------------------------------------------------------------------------


bool BisEquipCommand::HandleEquipNow(ChatHandler* handler, char const* args)
{
    if (!sBisPriorityMgr->IsEnabled() || !sBisPriorityMgr->IsLoaded())
    {
        handler->PSendSysMessage("mod-playerbots-bis : module desactive ou tables non chargees.");
        return true;
    }

    std::string const arg = args ? args : "";
    bool const all = arg.find("all") != std::string::npos;

    Player* const viewer = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;

    uint32 guildId = 0;
    if (!all)
    {
        if (!viewer || !viewer->GetGuildId())
        {
            handler->PSendSysMessage("Tu n'es dans aucune guilde. Utilise |cffffd100.playerbotsbis equipe all|r "
                                     "pour couvrir tous les bots.");
            return true;
        }
        guildId = viewer->GetGuildId();
    }

    std::vector<std::string> skipped;
    std::vector<Player*> const bots = BisBotScan::CollectBots(guildId, all, &skipped);
    if (bots.empty())
    {
        handler->PSendSysMessage("Aucun bot concerne. Les bots doivent etre connectes.");
        for (std::string const& line : skipped)
            handler->PSendSysMessage("  ignore : {}", line);
        return true;
    }

    uint32 changed = 0;

    for (Player* bot : bots)
    {
        PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot);
        if (!botAI)
            continue;

        // Built on the stack for this one call. The action carries no state of
        // its own between invocations - it reads the bags, the worn gear and
        // the ladder, all of which live on the bot - so a temporary is exactly
        // as correct as the one the engine keeps.
        BisEquipUpgradesAction action(botAI);
        if (action.EquipBisFromBags())
            ++changed;
    }

    handler->PSendSysMessage("{} bot(s) examines, {} ont equipe au moins une piece.",
                             uint32(bots.size()), changed);

    if (!changed)
        handler->PSendSysMessage("Rien a equiper : soit les pieces sont deja portees, soit aucune "
                                 "liste ne les nomme a leur palier (|cffffd100.playerbotsbis missing "
                                 "<nom>|r pour le detail d'un bot).");

    for (std::string const& line : skipped)
        handler->PSendSysMessage("  ignore : {}", line);

    return true;
}
