/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef PLAYERBOTS_AQ40MULTIPLIERS_H
#define PLAYERBOTS_AQ40MULTIPLIERS_H

#include "Multiplier.h"

// Keeps a bot from waking the emperors' bugs on its own initiative.
class Aq40IdleQirajiBugMultiplier : public Multiplier
{
public:
    Aq40IdleQirajiBugMultiplier(PlayerbotAI* botAI) : Multiplier(botAI, "aq40 idle qiraji bug multiplier") {}
    float GetValue(Action* action) override;
};

#endif
