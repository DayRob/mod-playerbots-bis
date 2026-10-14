/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef PLAYERBOTS_AQ40TRIGGERS_H
#define PLAYERBOTS_AQ40TRIGGERS_H

#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "Trigger.h"

// The twins are close enough to heal each other and this bot can do something
// about it - only a physical attacker can, because Vek'nilash is the twin that
// follows whoever it is hitting.
class Aq40TwinsDragApartTrigger : public Trigger
{
public:
    Aq40TwinsDragApartTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 twins too close together") {}
    bool IsActive() override;
};

// This bot is standing next to the twin it cannot hurt.
class Aq40TwinsKeepDistanceTrigger : public Trigger
{
public:
    Aq40TwinsKeepDistanceTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 twins wrong side") {}
    bool IsActive() override;
};

// This bot is hitting the twin that is immune to what it does.
class Aq40TwinsWrongTargetTrigger : public Trigger
{
public:
    Aq40TwinsWrongTargetTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 twins wrong target") {}
    bool IsActive() override;
};

#endif
