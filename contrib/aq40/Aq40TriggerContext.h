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
        creators["aq40 target not hostile"] = &RaidAq40TriggerContext::target_not_hostile;
        creators["aq40 twins not on their marks"] = &RaidAq40TriggerContext::twins_not_on_marks;
        creators["aq40 not in place yet"] = &RaidAq40TriggerContext::not_in_place_yet;
        creators["aq40 ready to pull"] = &RaidAq40TriggerContext::ready_to_pull;
        creators["aq40 tank off his mark"] = &RaidAq40TriggerContext::tank_off_his_mark;
        creators["aq40 veklor adrift"] = &RaidAq40TriggerContext::veklor_adrift;
        creators["aq40 bugs on the raid"] = &RaidAq40TriggerContext::bugs_on_the_raid;
        creators["aq40 twin not placed yet"] = &RaidAq40TriggerContext::twin_not_placed;
        creators["aq40 a twin is on me"] = &RaidAq40TriggerContext::twin_on_me;
        creators["aq40 hunter pet is out"] = &RaidAq40TriggerContext::hunter_pet_out;
        creators["aq40 too close to the wrong twin"] = &RaidAq40TriggerContext::too_close;
        creators["aq40 twins wrong target"] = &RaidAq40TriggerContext::wrong_target;
    }

private:
    static Trigger* target_not_hostile(PlayerbotAI* botAI) { return new Aq40NeutralTargetTrigger(botAI); }
    static Trigger* twins_not_on_marks(PlayerbotAI* botAI) { return new Aq40SetTheStageTrigger(botAI); }
    static Trigger* not_in_place_yet(PlayerbotAI* botAI) { return new Aq40TakeStationTrigger(botAI); }
    static Trigger* ready_to_pull(PlayerbotAI* botAI) { return new Aq40PullTogetherTrigger(botAI); }
    static Trigger* tank_off_his_mark(PlayerbotAI* botAI) { return new Aq40TankTrigger(botAI); }
    static Trigger* veklor_adrift(PlayerbotAI* botAI) { return new Aq40VeklorHolderTrigger(botAI); }
    static Trigger* bugs_on_the_raid(PlayerbotAI* botAI) { return new Aq40BugTankTrigger(botAI); }
    static Trigger* twin_not_placed(PlayerbotAI* botAI) { return new Aq40HoldFireTrigger(botAI); }
    static Trigger* twin_on_me(PlayerbotAI* botAI) { return new Aq40DraggingTwinTrigger(botAI); }
    static Trigger* hunter_pet_out(PlayerbotAI* botAI) { return new Aq40HunterPetTrigger(botAI); }
    static Trigger* too_close(PlayerbotAI* botAI) { return new Aq40KeepAwayTrigger(botAI); }
    static Trigger* wrong_target(PlayerbotAI* botAI) { return new Aq40WrongTargetTrigger(botAI); }
};

#endif
