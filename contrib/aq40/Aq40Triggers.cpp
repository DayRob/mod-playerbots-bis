/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Triggers.h"
#include "Aq40Utils.h"

bool Aq40TwinsDragApartTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    if (!RaidAq40Utils::IsPhysicalDamageDealer(bot))
        return false;

    // A bot being chewed on by an awakened bug deals with the bug first.
    if (RaidAq40Utils::IsAngryBugNear(bot))
        return false;

    Unit* veklor = RaidAq40Utils::GetVeklor(bot);
    Unit* veknilash = RaidAq40Utils::GetVeknilash(bot);
    if (!veklor || !veknilash)
        return false;

    return RaidAq40Utils::Separation(veklor, veknilash) < SAFE_SEPARATION;
}

bool Aq40TwinsKeepDistanceTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    Unit* forbidden = RaidAq40Utils::GetForbiddenTwin(bot);
    if (!forbidden)
        return false;

    float const keepAway = RaidAq40Utils::IsSpellDamageDealer(bot) ? CASTER_STAY_AWAY_FROM_VEKNILASH
                                                                   : MELEE_STAY_AWAY_FROM_VEKLOR;

    return bot->GetExactDist2d(forbidden) < keepAway;
}

bool Aq40TwinsWrongTargetTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    if (RaidAq40Utils::IsAngryBugNear(bot))
        return false;

    Unit* assigned = RaidAq40Utils::GetAssignedTwin(bot);
    if (!assigned || !assigned->IsAlive())
        return false;

    return AI_VALUE(Unit*, "current target") != assigned;
}

bool Aq40IdleQirajiBugTargetTrigger::IsActive()
{
    if (!bot->IsAlive())
        return false;

    return RaidAq40Utils::IsIdleQirajiBug(botAI, AI_VALUE(Unit*, "current target"));
}
