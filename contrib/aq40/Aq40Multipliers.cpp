/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Multipliers.h"
#include "Aq40Utils.h"
#include "ChooseTargetActions.h"
#include "MovementActions.h"
#include "Playerbots.h"

float Aq40IdleQirajiBugMultiplier::GetValue(Action* action)
{
    if (!action)
        return 1.0f;

    // These two are the only actions in playerbots that pick a target the raid
    // is not already fighting: everything else chooses from the group's threat
    // lists, where a sleeping bug never appears. Stopping them here stops the
    // walk before it starts, which is what actually pulls the emperors.
    if (dynamic_cast<AttackAnythingAction*>(action))
        return RaidAq40Utils::IsIdleQirajiBug(botAI, AI_VALUE(Unit*, "grind target")) ? 0.0f : 1.0f;

    if (dynamic_cast<AggressiveTargetAction*>(action))
        return RaidAq40Utils::IsIdleQirajiBug(botAI, AI_VALUE(Unit*, "aggressive target")) ? 0.0f : 1.0f;

    // And if something got there anyway, no swing and no step towards it until
    // the target is gone. "drop target" is a plain Action, not a MovementAction,
    // so it is the one thing still allowed to run - and it is what clears this.
    if (dynamic_cast<MovementAction*>(action))
        return RaidAq40Utils::IsIdleQirajiBug(botAI, AI_VALUE(Unit*, "current target")) ? 0.0f : 1.0f;

    return 1.0f;
}
