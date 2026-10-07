/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisItemUsageValue.h"
#include "BisPriorityMgr.h"
#include "ChatHelper.h"
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

            // ── Branch 3: nobody's list, original logic wins ──────────────
            //
            // With one guard. Playerbots' rule is "1.1 times better by stat
            // score", and it knows nothing about the ladder, so it happily
            // swaps a best in slot out for a dungeon blue. Branch 1 then swaps
            // it straight back on the next tick, and the bot flip-flops for
            // ever, announcing "c'est mon BiS" on every cycle.
            //
            // So an item on nobody's list may never displace one that IS on
            // this bot's list. GetWornPriorityPaired returns the weakest of a
            // paired slot, so a second ring or trinket still goes to the free
            // or unlisted side - only a slot already holding a listed piece is
            // protected.
            if (botAI && (base == ITEM_USAGE_EQUIP || base == ITEM_USAGE_REPLACE || base == ITEM_USAGE_BAD_EQUIP))
            {
                uint8 const dstSlot = botAI->FindEquipSlot(proto, NULL_SLOT, true);
                if (dstSlot != NULL_SLOT && sBisPriorityMgr->GetWornPriorityPaired(bot, dstSlot))
                    return ITEM_USAGE_NONE;
            }

            // ── Branch 3b: the piece is reserved to this class ─────────────
            //
            // Playerbots only claims what its stat score rates 1.1 times better
            // than the worn item, and that score is crude. So a bot would pass
            // on a drop whose tooltip reads "Classes : Mage" while wearing a
            // quest green in the same slot - and with nobody else in the raid
            // able to wear it, the piece rots.
            //
            // The conditions live in ClaimsClassRestricted, because the loot
            // vote has to reach the same verdict: this claim is answered with
            // GREED, not NEED, so a bot for whom the piece IS best in slot
            // still outranks it.
            uint8 claimSlot = 0;
            if (sBisPriorityMgr->ClaimsClassRestricted(botAI, bot, itemId, &claimSlot))
            {
                Item const* const worn = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, claimSlot);

                // Dit a voix haute, parce que cette reclamation n'a aucune
                // liste derriere elle : sans un mot, un bot qui porte une piece
                // qu'aucune table ne nomme ressemble a un bogue plutot qu'a la
                // regle que c'est.
                //
                // AnnounceOnRoll decide QUAND. A 1, des le jet : tous les
                // pretendants parlent, donc plusieurs lignes pour une piece
                // qu'un seul emportera - mais on voit qui la convoite, et c'est
                // le moment utile si on arbitre soi-meme. A 0, le bot attend de
                // DETENIR la piece : une seule ligne, par le gagnant, juste
                // avant l'equipement.
                if (sBisPriorityMgr->AnnounceOwnBis() &&
                    (sBisPriorityMgr->AnnounceOnRoll() || bot->GetItemCount(itemId, true) > 0))
                {
                    std::ostringstream out;
                    out << ChatHelper::FormatItem(proto) << " - je le prends";
                    if (worn && worn->GetTemplate())
                        out << " a la place de " << ChatHelper::FormatItem(worn->GetTemplate());
                    out << " : reserve a ma classe, et je n'ai pas encore"
                           " mon BiS a cet emplacement";
                    botAI->TellMaster(out.str());
                }

                return worn ? ITEM_USAGE_REPLACE : ITEM_USAGE_EQUIP;
            }

            return base;
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
            InventoryResult const canUse = bot->CanUseItem(proto);
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

        // Et le refus que la comparaison de priorites ne peut pas voir sur un
        // creneau appaire : un exemplaire deja porte a l'autre doigt, d'une
        // piece unique-equipee. Sans ce test, le bot annonce une amelioration
        // que le coeur refusera, a chaque tick.
        if (sBisPriorityMgr->UniqueAlreadyWorn(bot, proto, targetSlot))
            return ITEM_USAGE_NONE;

        // What it costs, named here rather than at the equip. The equip that
        // follows a roll is playerbots' own EquipAction, which answers with its
        // "Equipping ..." and knows nothing of this module - only a sweep over
        // the bags goes through BisEquipAction. The claim is therefore the one
        // moment where this module can say what leaves.
        Item const* const worn = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, targetSlot);

        // Meme reglage. A 0, le bot attend de TENIR la piece, ce qui est aussi
        // le seul moment ou "a la place de" est certain - l'equipement suit.
        if (sBisPriorityMgr->AnnounceOwnBis() && botAI &&
            (sBisPriorityMgr->AnnounceOnRoll() || bot->GetItemCount(itemId, true) > 0))
        {
            std::string const tierName = sBisPriorityMgr->GetTierName(tierId);
            std::ostringstream out;
            out << ChatHelper::FormatItem(proto) << " - c'est mon BiS";
            if (!tierName.empty())
                out << " (" << tierName << ")";
            if (worn && worn->GetTemplate())
                out << ", a la place de " << ChatHelper::FormatItem(worn->GetTemplate());
            else
                out << ", creneau vide";
            if (tooLowLevel)
                out << " - je le garde, il me faut le niveau " << uint32(proto->RequiredLevel);
            botAI->TellMaster(out.str());
        }

        return worn ? ITEM_USAGE_REPLACE : ITEM_USAGE_EQUIP;
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
