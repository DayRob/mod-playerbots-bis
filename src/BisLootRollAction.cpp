/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisLootRollAction.h"
#include "BisPriorityMgr.h"
#include "ChatHelper.h"
#include "Event.h"
#include "Group.h"
#include "ItemUsageValue.h"
#include "LootMgr.h"
#include "ObjectMgr.h"
#include "PlayerbotAIConfig.h"
#include "Playerbots.h"
#include <sstream>
#include <string>
#include <vector>

bool BisLootRollAction::Execute(Event event)
{
    // Two independent jobs, either of which can be off:
    //   - NeedOnlyForBis  : take the NEED away from what is not best in slot
    //   - ForceNeedForBis : make sure what IS best in slot actually gets one
    //
    // The second exists because playerbots rewrites its own verdict afterwards:
    //
    //     if (vote == NEED)
    //         if (lootNeedRollLevel == 0 ...) vote = PASS;
    //         else if (lootNeedRollLevel == 1) vote = GREED;
    //
    // and that setting ships at 1. Out of the box a bot therefore never needs
    // anything, whatever the ladder says, and a best in slot competes with the
    // whole raid's greed rolls on a coin toss.
    bool const needOnly  = sBisPriorityMgr->NeedOnlyForBis();
    bool const forceNeed = sBisPriorityMgr->ForceNeedForBis();

    // Every early exit hands the roll straight back to playerbots, so the
    // feature being off - or the bot not being ours to govern - costs one
    // comparison and changes nothing.
    if ((!needOnly && !forceNeed) || !sBisPriorityMgr->AppliesTo(bot))
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
    //
    // Two outcomes, because two different things are being said. "downgrade" is
    // a refusal - the bot wanted it only by stat score, and the config decides
    // whether a refusal greeds or passes. "claim" is the module asking for the
    // piece: it always greeds, whatever LootGreedRollLevel says, because a
    // claim that ends in a PASS is a claim the bot announced and then abandoned.
    std::vector<ObjectGuid> downgrade;
    std::vector<ObjectGuid> claim;
    std::vector<ObjectGuid> need;

    // Roll const* et non Roll* : selon la revision du coeur, GetRolls() rend
    // soit std::vector<Roll*>, soit std::vector<Roll const*>. Le pointeur
    // constant accepte les deux, et la boucle ne fait que des lectures.
    for (Roll const* roll : group->GetRolls())
    {
        if (!roll)
            continue;

        auto voteItr = roll->playerVote.find(bot->GetGUID());
        if (voteItr == roll->playerVote.end() || voteItr->second != NOT_EMITED_YET)
            continue;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(roll->itemid);
        if (!proto)
            continue;

        // Les JETONS DE QUETE, d'abord, parce qu'ils ne survivraient pas au
        // filtre suivant. Un jeton hakkari n'est ni arme ni armure, donc tous
        // les chemins d'equipement l'ecartent - a juste titre, il ne s'equipe
        // pas. Mais il achete une piece que la liste nomme, et sans ce branchement
        // TOUS les bots passaient : l'objet ne revenait a personne.
        //
        // NEED et non GREED : le jeton vaut exactement la piece qu'il donne,
        // et celle-ci est souvent rang 1. Un GREED le laisserait a n'importe
        // quel bot qui cupidite au hasard.
        if (proto->Class == ITEM_CLASS_QUEST)
        {
            if (forceNeed && sBisPriorityMgr->WantsQuestToken(bot, roll->itemid))
            {
                need.push_back(roll->itemGUID);

                // Rien n'est dit ici, et c'est voulu. Un jet de butin fait
                // evaluer l'objet par tous les bots presents : chaque phrase
                // prononcee a ce moment se repete autant de fois qu'il y a de
                // pretendants, pour une piece qu'un seul emportera. Le client
                // annonce deja "X a choisi Besoin pour [objet]", ce qui dit
                // l'essentiel.
                //
                // Les pieces d'equipement, elles, parlent au moment de
                // l'equipement - le seul ou "a la place de" est vrai. Un jeton
                // ne s'equipe jamais, donc il reste silencieux.
            }
            continue;
        }

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

        // A genuine best in slot. Cast the NEED here rather than leaving it to
        // playerbots, which would turn it into a GREED or a PASS depending on
        // LootNeedRollLevel.
        if (sBisPriorityMgr->WantsAsUpgrade(bot, roll->itemid))
        {
            // Unless the bot already holds one. A second copy of the piece it
            // is about to equip is worth nothing to it, and needing on it would
            // take the roll from a bot that has none - which is the opposite of
            // what the ladder is for.
            if (forceNeed && !bot->GetItemCount(proto->ItemId, true))
                need.push_back(roll->itemGUID);

            continue;
        }

        // Everything below is the refusal half, which NeedOnlyForBis owns.
        if (!needOnly)
            continue;

        // Reserved to this class, for a slot no list has settled: the bot rolls
        // for it, but with GREED. NEED would put it level with a bot whose list
        // actually names the piece, and the whole point of the ladder is that
        // the list wins. Since the item is class-restricted, nobody outside the
        // class can NEED it either, so greeding still reaches it whenever no
        // list claims it.
        if (sBisPriorityMgr->ClaimsClassRestricted(botAI, bot, roll->itemid))
        {
            claim.push_back(roll->itemGUID);
            continue;
        }

        downgrade.push_back(roll->itemGUID);
    }

    // AiPlayerbot.LootGreedRollLevel still has the last word on a refusal: at 0
    // the bot is not allowed to greed at all and passes instead.
    RollVote const vote = sPlayerbotAIConfig.lootGreedRollLevel ? GREED : PASS;
    for (ObjectGuid const& guid : downgrade)
        group->CountRollVote(bot->GetGUID(), guid, vote);

    for (ObjectGuid const& guid : claim)
        group->CountRollVote(bot->GetGUID(), guid, GREED);

    for (ObjectGuid const& guid : need)
        group->CountRollVote(bot->GetGUID(), guid, NEED);

    // Everything we did not touch is still unvoted, and the base pass skips the
    // rolls we just answered.
    bool const voted = LootRollAction::Execute(event);
    return voted || !downgrade.empty() || !claim.empty() || !need.empty();
}
