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

    // A bot with a woken bug in its face deals with the bug first. Only that
    // bot: the rest of the raid stays on the emperors.
    if (RaidAq40Utils::IsBugOnMe(bot))
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

    if (RaidAq40Utils::IsBugOnMe(bot))
        return false;

    Unit* assigned = RaidAq40Utils::GetAssignedTwin(bot);
    if (!assigned || !assigned->IsAlive())
        return false;

    return AI_VALUE(Unit*, "current target") != assigned;
}
