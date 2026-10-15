/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef PLAYERBOTS_AQ40TRIGGERCONTEXT_H
#define PLAYERBOTS_AQ40TRIGGERCONTEXT_H

#include "Aq40Triggers.h"
#include "NamedObjectContext.h"

class RaidAq40TriggerContext : public NamedObjectContext<Trigger>
{
public:
    RaidAq40TriggerContext()
    {
        creators["aq40 chasing a critter"] = &RaidAq40TriggerContext::chasing_a_critter;
        creators["aq40 not in place yet"] = &RaidAq40TriggerContext::not_in_place_yet;
        creators["aq40 ready to pull"] = &RaidAq40TriggerContext::ready_to_pull;
        creators["aq40 tank off his mark"] = &RaidAq40TriggerContext::tank_off_his_mark;
        creators["aq40 veklor adrift"] = &RaidAq40TriggerContext::veklor_adrift;
        creators["aq40 bugs on the raid"] = &RaidAq40TriggerContext::bugs_on_the_raid;
        creators["aq40 too close to the wrong twin"] = &RaidAq40TriggerContext::too_close;
        creators["aq40 twins wrong target"] = &RaidAq40TriggerContext::wrong_target;
    }

private:
    static Trigger* chasing_a_critter(PlayerbotAI* botAI) { return new Aq40ChasingCritterTrigger(botAI); }
    static Trigger* not_in_place_yet(PlayerbotAI* botAI) { return new Aq40TakeStationTrigger(botAI); }
    static Trigger* ready_to_pull(PlayerbotAI* botAI) { return new Aq40PullTogetherTrigger(botAI); }
    static Trigger* tank_off_his_mark(PlayerbotAI* botAI) { return new Aq40TankTrigger(botAI); }
    static Trigger* veklor_adrift(PlayerbotAI* botAI) { return new Aq40VeklorHolderTrigger(botAI); }
    static Trigger* bugs_on_the_raid(PlayerbotAI* botAI) { return new Aq40BugTankTrigger(botAI); }
    static Trigger* too_close(PlayerbotAI* botAI) { return new Aq40KeepAwayTrigger(botAI); }
    static Trigger* wrong_target(PlayerbotAI* botAI) { return new Aq40WrongTargetTrigger(botAI); }
};

#endif
