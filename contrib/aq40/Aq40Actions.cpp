/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Actions.h"
#include "Aq40Utils.h"
#include <cmath>

namespace
{
    // How far past Vek'nilash the attackers plant themselves. Small enough that he
    // closes the gap in a step or two, large enough that he actually has to walk.
    constexpr float DRAG_STEP = 8.0f;
}

bool Aq40TwinsDragApartAction::Execute(Event /*event*/)
{
    Unit* veklor = RaidAq40Utils::GetVeklor(bot);
    Unit* veknilash = RaidAq40Utils::GetVeknilash(bot);
    if (!veklor || !veknilash)
        return false;

    // Dragging him anywhere is pointless until he is the one being hit.
    if (AI_VALUE(Unit*, "current target") != veknilash)
        return Attack(veknilash);

    float dX = veknilash->GetPositionX() - veklor->GetPositionX();
    float dY = veknilash->GetPositionY() - veklor->GetPositionY();
    float separation = std::sqrt(dX * dX + dY * dY);

    // On the pull the two of them are side by side, so "away from Vek'lor" has no
    // meaningful direction yet. Pull towards the bot instead, which at least takes
    // Vek'nilash off the pile.
    if (separation < 1.0f)
    {
        dX = bot->GetPositionX() - veklor->GetPositionX();
        dY = bot->GetPositionY() - veklor->GetPositionY();
        separation = std::sqrt(dX * dX + dY * dY);

        if (separation < 1.0f)
            return false;
    }

    float const targetX = veknilash->GetPositionX() + DRAG_STEP * (dX / separation);
    float const targetY = veknilash->GetPositionY() + DRAG_STEP * (dY / separation);

    if (bot->GetExactDist2d(targetX, targetY) < 2.0f)
        return false;

    return MoveTo(bot->GetMapId(), targetX, targetY, veknilash->GetPositionZ(), false, false, false, false,
                  MovementPriority::MOVEMENT_COMBAT, true, false);
}

bool Aq40TwinsKeepDistanceAction::Execute(Event /*event*/)
{
    Unit* forbidden = RaidAq40Utils::GetForbiddenTwin(bot);
    if (!forbidden)
        return false;

    float const keepAway = RaidAq40Utils::IsSpellDamageDealer(bot) ? CASTER_STAY_AWAY_FROM_VEKNILASH
                                                                   : MELEE_STAY_AWAY_FROM_VEKLOR;

    return FleePosition(forbidden->GetPosition(), keepAway, 1000);
}

bool Aq40TwinsAttackMyTwinAction::Execute(Event /*event*/)
{
    Unit* assigned = RaidAq40Utils::GetAssignedTwin(bot);
    if (!assigned || !assigned->IsAlive())
        return false;

    if (AI_VALUE(Unit*, "current target") == assigned)
        return false;

    return Attack(assigned);
}
