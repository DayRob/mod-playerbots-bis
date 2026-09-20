/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisLootRollAction.h"
#include "BisPriorityMgr.h"
#include "Event.h"
#include "Group.h"
#include "ItemUsageValue.h"
#include "LootMgr.h"
#include "ObjectMgr.h"
#include "PlayerbotAIConfig.h"
#include "Playerbots.h"
#include <vector>

bool BisLootRollAction::Execute(Event event)
{
    // Every early exit hands the roll straight back to playerbots, so the
    // feature being off - or the bot not being ours to govern - costs one
    // comparison and changes nothing.
    if (!sBisPriorityMgr->NeedOnlyForBis() || !sBisPriorityMgr->AppliesTo(bot))
        return LootRollAction::Execute(event);

    // A spec with no reachable list would never recognise a best in slot, so
    // downgrading its NEEDs would leave it unable to gear itself at all. Same
    // guard as the "leave it to the other spec" branch, for the same reason.
    if (!sBisPriorityMgr->HasReachableList(bot))
        return LootRollAction::Execute(event);

    Group* group = bot->GetGroup();
    if (!group)
        return LootRollAction::Execute(event);

    // Under master loot and free for all, playerbots passes on everything and
    // the master decides. Nothing to downgrade.
    LootMethod const method = group->GetLootMethod();
    if (method == MASTER_LOOT || method == FREE_FOR_ALL)
        return LootRollAction::Execute(event);

    // Scan first and vote afterwards: casting a vote can complete a roll and
    // destroy it, which would leave the copied pointers dangling mid-loop.
    // CountRollVote takes a guid, so a vote cast for a roll that has just gone
    // is simply not found.
    std::vector<ObjectGuid> downgrade;

    for (Roll* roll : group->GetRolls())
    {
        if (!roll)
            continue;

        auto voteItr = roll->playerVote.find(bot->GetGUID());
        if (voteItr == roll->playerVote.end() || voteItr->second != NOT_EMITED_YET)
            continue;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(roll->itemid);
        if (!proto)
            continue;

        // Only gear is arbitrated. Recipes, armor tokens, trade goods and the
        // rest keep playerbots' own vote.
        if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR)
            continue;

        // Mirror the parameter playerbots builds, so a random-suffix piece is
        // looked up exactly as its own vote would look it up.
        int32 randomProperty = 0;
        if (roll->itemRandomPropId)
            randomProperty = roll->itemRandomPropId;
        else if (roll->itemRandomSuffix)
            randomProperty = -static_cast<int32>(roll->itemRandomSuffix);

        std::string param = std::to_string(roll->itemid);
        if (randomProperty != 0)
            param += "," + std::to_string(randomProperty);

        ItemUsage const usage = AI_VALUE2(ItemUsage, "item usage", param);

        // These three are the usages playerbots turns into NEED. Anything else
        // already votes GREED or PASS, so there is nothing to downgrade.
        if (usage != ITEM_USAGE_EQUIP && usage != ITEM_USAGE_REPLACE && usage != ITEM_USAGE_BAD_EQUIP)
            continue;

        // A genuine best in slot keeps its NEED.
        if (sBisPriorityMgr->WantsAsUpgrade(bot, roll->itemid))
            continue;

        downgrade.push_back(roll->itemGUID);
    }

    // AiPlayerbot.LootGreedRollLevel still has the last word: at 0 the bot is
    // not allowed to greed at all and passes instead.
    RollVote const vote = sPlayerbotAIConfig.lootGreedRollLevel ? GREED : PASS;
    for (ObjectGuid const& guid : downgrade)
        group->CountRollVote(bot->GetGUID(), guid, vote);

    // Everything we did not touch is still unvoted, and the base pass skips the
    // rolls we just answered.
    bool const voted = LootRollAction::Execute(event);
    return voted || !downgrade.empty();
}
