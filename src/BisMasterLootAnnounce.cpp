/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisPriorityMgr.h"
#include "Group.h"
#include "Item.h"
#include "LootMgr.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "ScriptMgr.h"
#include <sstream>
#include <string>
#include <vector>

// Speaking up under master loot.
//
// Why this exists: with master loot, playerbots computes each bot's vote and
// then throws it away. LootRollAction does it explicitly —
//
//     case MASTER_LOOT:
//     case FREE_FOR_ALL:
//         group->CountRollVote(bot->GetGUID(), guid, PASS);
//
// — and MasterLootRollAction::isUseful() returns false whenever the master is a
// real player. So when YOU hold the loot, no bot ever expresses a preference:
// the "this is my best in slot" whisper from the item-usage layer never fires,
// because nothing ever asks a bot what it thinks of the corpse's contents.
//
// This script asks them. When the master looter opens a corpse, every bot in
// the group is polled against the same WantsAsUpgrade() test the item-usage
// layer uses, and the interested ones whisper the master. One whisper per bot,
// listing everything it wants, so a full raid does not produce forty lines.
class BisMasterLootAnnounceScript : public PlayerScript
{
public:
    BisMasterLootAnnounceScript()
        : PlayerScript("BisMasterLootAnnounceScript", {PLAYERHOOK_ON_BEFORE_SEND_LOOT})
    {
    }

    void OnPlayerBeforeSendLoot(Player* player, ObjectGuid /*lootGuid*/, Loot* loot) override
    {
        if (!sBisPriorityMgr->IsEnabled() || !sBisPriorityMgr->IsLoaded())
            return;

        if (!sBisPriorityMgr->AnnounceMasterLoot() || !player || !loot)
            return;

        // Bots open corpses constantly; only a human holding the loot is worth
        // reporting to.
        if (GET_PLAYERBOT_AI(player))
            return;

        Group* group = player->GetGroup();
        if (!group || group->GetLootMethod() != MASTER_LOOT)
            return;

        if (group->GetMasterLooterGuid() != player->GetGUID())
            return;

        // Collect what is still up for grabs. Quest items are deliberately left
        // out: they are not distributed by the master.
        std::vector<uint32> itemIds;
        for (LootItem const& item : loot->items)
        {
            if (item.is_looted || !item.itemid)
                continue;

            itemIds.push_back(item.itemid);
        }

        if (itemIds.empty())
            return;

        for (GroupReference* itr = group->GetFirstMember(); itr; itr = itr->next())
        {
            Player* bot = itr->GetSource();
            if (!bot || bot == player || !bot->IsInWorld())
                continue;

            PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot);
            if (!botAI)
                continue;  // a second real player speaks for themselves

            std::ostringstream wanted;
            uint32 count = 0;

            for (uint32 const itemId : itemIds)
            {
                uint16 tierId = 0;
                bool tooLowLevel = false;
                if (!sBisPriorityMgr->WantsAsUpgrade(bot, itemId, &tierId, &tooLowLevel))
                    continue;

                ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
                if (!proto)
                    continue;

                if (count)
                    wanted << ", ";

                wanted << "|cff1eff00" << proto->Name1 << "|r";

                std::string const tierName = sBisPriorityMgr->GetTierName(tierId);
                if (!tierName.empty())
                    wanted << " (" << tierName << ")";

                // Say so plainly rather than let the master hand over a piece the
                // bot cannot wear yet without knowing it.
                if (tooLowLevel)
                    wanted << " [niveau " << uint32(proto->RequiredLevel) << " requis]";

                ++count;
            }

            if (!count)
                continue;

            std::ostringstream msg;
            msg << (count > 1 ? "Je need ces objets : " : "Je need cet objet : ") << wanted.str();
            bot->Whisper(msg.str(), LANG_UNIVERSAL, player);
        }
    }
};

void AddSC_playerbots_bis_masterloot()
{
    new BisMasterLootAnnounceScript();
}
