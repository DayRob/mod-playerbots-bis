/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Strategy.h"
#include "Aq40Multipliers.h"
#include "Strategy.h"

void RaidAq40Strategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    // Order matters. Getting off the wrong emperor comes first because standing
    // there is what gets bots knocked around and killed; pulling the two of them
    // apart comes next because Heal Brother is what loses the fight; picking the
    // right target is last, and it is also what the other two fall back on once
    // the positioning is settled.
    // Above all of them: nobody wakes a bug the raid is not already fighting.
    // This is the only rule here that applies before the pull, because waking
    // a bug is how the pull happens by accident.
    triggers.push_back(
        new TriggerNode("aq40 idle qiraji bug target",
            { NextAction("drop target", ACTION_RAID + 10.0f) }));

    triggers.push_back(
        new TriggerNode("aq40 twins wrong side",
            { NextAction("aq40 twins keep distance", ACTION_RAID + 2.0f) }));

    triggers.push_back(
        new TriggerNode("aq40 twins too close together",
            { NextAction("aq40 twins drag apart", ACTION_RAID + 1.0f) }));

    triggers.push_back(
        new TriggerNode("aq40 twins wrong target",
            { NextAction("aq40 twins attack my twin", ACTION_RAID) }));
}

void RaidAq40Strategy::InitMultipliers(std::vector<Multiplier*>& multipliers)
{
    multipliers.push_back(new Aq40IdleQirajiBugMultiplier(botAI));
}
