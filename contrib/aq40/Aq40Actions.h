/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef PLAYERBOTS_AQ40ACTIONS_H
#define PLAYERBOTS_AQ40ACTIONS_H

#include "AttackAction.h"
#include "MovementActions.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"

// Walks Vek'nilash away from his brother. Vek'nilash follows whoever he is
// fighting, so the physical attackers back off a few yards at a time and he comes
// with them until the two of them are out of Heal Brother range.
class Aq40TwinsDragApartAction : public AttackAction
{
public:
    Aq40TwinsDragApartAction(PlayerbotAI* botAI, std::string const name = "aq40 twins drag apart")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// Steps out of the reach of the twin this bot cannot hurt.
class Aq40TwinsKeepDistanceAction : public MovementAction
{
public:
    Aq40TwinsKeepDistanceAction(PlayerbotAI* botAI, std::string const name = "aq40 twins keep distance")
        : MovementAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// Switches onto the twin this bot can actually damage. Both emperors share their
// damage, so the half of the raid that picks the wrong one contributes nothing.
class Aq40TwinsAttackMyTwinAction : public AttackAction
{
public:
    Aq40TwinsAttackMyTwinAction(PlayerbotAI* botAI, std::string const name = "aq40 twins attack my twin")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

#endif
