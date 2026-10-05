/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include <algorithm>
#include "BisEquipAction.h"
#include "BisBotScan.h"
#include "BisPriorityMgr.h"
#include "Chat.h"
#include "ChatHelper.h"
#include "Event.h"
#include "Item.h"
#include "ItemPackets.h"
#include "ItemVisitors.h"
#include "ObjectAccessor.h"
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

bool BisEquipUpgradesAction::EquipBisFromBags(ChatHandler* report)
{
    CollectItemsVisitor visitor;
    IterateItems(&visitor, ITERATE_ITEMS_IN_BAGS);

    // Off-hands go last. The sweep takes the bags in their own order, so a bot
    // trading a two-hander for a one-hander in this very pass would only reach
    // its off-hand if the bags happened to hold it further along - and stay a
    // weapon short until the next item arrived otherwise. Handling the main hand
    // first makes the off-hand's own test read a hand that is already settled.
    std::stable_sort(visitor.items.begin(), visitor.items.end(),
                     [](Item const* a, Item const* b)
                     {
                         auto offHand = [](Item const* item)
                         {
                             ItemTemplate const* const proto = item ? item->GetTemplate() : nullptr;
                             if (!proto)
                                 return 0;

                             switch (proto->InventoryType)
                             {
                                 case INVTYPE_SHIELD:
                                 case INVTYPE_WEAPONOFFHAND:
                                 case INVTYPE_HOLDABLE:
                                     return 1;
                                 default:
                                     return 0;
                             }
                         };

                         return offHand(a) < offHand(b);
                     });

    bool equipped = false;

    for (Item* item : visitor.items)
    {
        if (!item)
            continue;

        ItemTemplate const* proto = item->GetTemplate();
        if (!proto)
            continue;

        // Only gear. Everything else keeps playerbots' own handling. Not
        // reported either: a report naming every reagent and potion in the
        // bags would bury the lines that matter.
        if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR)
            continue;

        uint8 slot = 0;
        uint16 tierId = 0;
        uint32 const priority = sBisPriorityMgr->GetItemPriority(bot, proto->ItemId, &slot, &tierId);
        if (!priority)
        {
            // No list names it AT THIS BOT'S CAP - which is not the same as
            // "no list names it at all". A piece listed only for Blackwing Lair
            // lands here for a bot whose ceiling stops at Molten Core, and that
            // distinction is the whole reason this report exists.
            if (report)
                report->PSendSysMessage("  {} : aucune ligne a son palier", ChatHelper::FormatItem(proto));
            continue;
        }

        // Unlike the claim made at loot time, a missing level is disqualifying
        // here: the core refuses the equip outright, so forcing it would only
        // spend a packet per tick until the bot grows into the piece.
        if (InventoryResult const canUse = bot->BotCanUseItem(proto); canUse != EQUIP_ERR_OK)
        {
            if (report)
                report->PSendSysMessage("  {} : ne peut pas l'equiper (code {})",
                                        ChatHelper::FormatItem(proto), uint32(canUse));
            continue;
        }

        uint8 targetSlot = slot;
        uint32 const worn = sBisPriorityMgr->GetWornPriorityPaired(bot, slot, &targetSlot);

        // A two-hander fills both hands, so the core refuses this one every
        // single time. Sending the packet anyway spent a refusal per item
        // received and answered the master in the core's own words, which read
        // like a module failure rather than what it is: a slot the bot's own
        // weapon closed.
        if (sBisPriorityMgr->OffHandClosed(bot, targetSlot))
        {
            if (report)
                report->PSendSysMessage("  {} : main gauche fermee par l'arme a deux mains portee",
                                        ChatHelper::FormatItem(proto));
            continue;
        }

        if (priority <= worn)
        {
            if (report)
                report->PSendSysMessage("  {} : deja mieux au creneau {} (porte {}, sac {})",
                                        ChatHelper::FormatItem(proto), uint32(slot), worn, priority);
            continue;  // already wearing this piece, or something higher up the ladder
        }

        // What goes away, read BEFORE the swap - afterwards the slot holds the
        // new piece and the old one is somewhere in the bags, indistinguishable
        // from everything else the bot carries. Only the template is kept: the
        // Item object may move or be destroyed by the equip, while an
        // ItemTemplate lives in the object manager's store for the run.
        Item const* const previous = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, targetSlot);
        ItemTemplate const* const replaced = previous ? previous->GetTemplate() : nullptr;

        // The off-hand a two-hander pushes out is a second loss, and the one a
        // master notices least: nothing names it, it simply stops being worn.
        bool const twoHander = proto->InventoryType == INVTYPE_2HWEAPON;
        ItemTemplate const* displacedOffHand = nullptr;
        if (twoHander && targetSlot == EQUIPMENT_SLOT_MAINHAND)
        {
            Item const* const offHand = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
            displacedOffHand = offHand ? offHand->GetTemplate() : nullptr;
        }

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

        // The handler answers by changing the inventory, not by returning
        // anything, and it declines in silence - a full bag with no room for
        // the piece coming off, an off-hand that cannot be put away. Counting
        // the packet as a success would report work that never happened, so
        // the result is read back from the slot itself.
        Item* const now = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, targetSlot);
        if (!now || now->GetEntry() != proto->ItemId)
        {
            if (report)
                report->PSendSysMessage("  {} : le coeur a refuse l'equipement au creneau {} "
                                        "(sacs pleins ?)", ChatHelper::FormatItem(proto), uint32(targetSlot));
            continue;
        }

        // Said out loud for the same reason the claim is: the bot is putting on
        // something playerbots' own score had just declined, and without a word
        // that reads as the item jumping slots by itself.
        // The off-hand is only reported as displaced if it actually left: with
        // the bags full the core refuses the whole swap, and that case already
        // returned above - but a stale claim here would be worse than silence.
        if (displacedOffHand && bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND))
            displacedOffHand = nullptr;

        // Said out loud for the same reason the claim is: the bot is putting on
        // something playerbots' own score had just declined, and without a word
        // that reads as the item jumping slots by itself. Naming what leaves
        // matters as much as naming what arrives - on a paired slot it is the
        // only way to know WHICH ring went.
        if (sBisPriorityMgr->AnnounceOwnBis() && botAI)
        {
            std::string const tierName = sBisPriorityMgr->GetTierName(tierId);
            std::ostringstream out;
            out << "J'equipe " << ChatHelper::FormatItem(proto);
            if (replaced)
                out << " a la place de " << ChatHelper::FormatItem(replaced);
            else
                out << " sur un creneau vide";
            if (displacedOffHand)
                out << ", et je range " << ChatHelper::FormatItem(displacedOffHand);
            if (!tierName.empty())
                out << " (" << tierName << ")";
            botAI->TellMaster(out.str());
        }

        if (report)
        {
            std::ostringstream line;
            line << "  " << ChatHelper::FormatItem(proto) << " : EQUIPE au creneau "
                 << uint32(targetSlot);
            if (replaced)
                line << " a la place de " << ChatHelper::FormatItem(replaced);
            else
                line << " (creneau vide)";
            if (displacedOffHand)
                line << ", main gauche rangee : " << ChatHelper::FormatItem(displacedOffHand);
            line << " (" << sBisPriorityMgr->GetTierName(tierId) << ")";
            report->PSendSysMessage("{}", line.str());
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


namespace
{
    bool ReportOne(ChatHandler* handler, std::string const& name)
    {
        Player* bot = ObjectAccessor::FindPlayerByName(name, false);
        if (!bot)
        {
            handler->PSendSysMessage("{} n'est pas connecte.", name);
            return true;
        }

        PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot);
        if (!botAI)
        {
            handler->PSendSysMessage("{} n'est pas un bot.", bot->GetName());
            return true;
        }

        if (char const* why = sBisPriorityMgr->WhyNotFollowed(bot))
        {
            handler->PSendSysMessage("{} n'est pas suivi : {}", bot->GetName(), why);
            return true;
        }

        // The three values that decide everything downstream, printed before
        // any verdict. A wrong spec or a ceiling below the phase explains a
        // whole bot at once, where the per-item lines would only repeat it.
        uint8 const spec = sBisPriorityMgr->GetSpec(bot);
        uint16 const cap = sBisPriorityMgr->GetEffectiveTierCap(bot);
        std::string const capName = sBisPriorityMgr->GetTierName(cap);

        handler->PSendSysMessage("{} - {} {} - palier plafond {} ({})", bot->GetName(),
                                 BisBotScan::ClassName(bot->getClass()),
                                 BisBotScan::SpecName(bot->getClass(), spec),
                                 uint32(cap), capName.empty() ? "sans nom" : capName);

        BisEquipUpgradesAction action(botAI);
        if (!action.EquipBisFromBags(handler))
            handler->PSendSysMessage("Rien equipe.");

        return true;
    }
}

bool BisEquipCommand::HandleEquipNow(ChatHandler* handler, char const* args)
{
    if (!sBisPriorityMgr->IsEnabled() || !sBisPriorityMgr->IsLoaded())
    {
        handler->PSendSysMessage("mod-playerbots-bis : module desactive ou tables non chargees.");
        return true;
    }

    std::string arg = args ? args : "";
    while (!arg.empty() && arg.back() == ' ')
        arg.pop_back();

    bool const all = arg == "all";

    // A name instead of a scope switches to the detailed mode. One bot, one
    // line per piece of gear it carries, with the reason it stayed in the bag.
    // "0 ont equipe" over 359 bots says nothing about which of the four tests
    // refused, and that is exactly what has to be known.
    if (!arg.empty() && !all)
        return ReportOne(handler, arg);

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
