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
        creators["aq40 twins too close together"] = &RaidAq40TriggerContext::twins_too_close_together;
        creators["aq40 twins wrong side"] = &RaidAq40TriggerContext::twins_wrong_side;
        creators["aq40 twins between the emperors"] = &RaidAq40TriggerContext::twins_wrong_side_of_room;
        creators["aq40 twins wrong target"] = &RaidAq40TriggerContext::twins_wrong_target;
        creators["aq40 not in place yet"] = &RaidAq40TriggerContext::not_in_place_yet;
        creators["aq40 ready to pull"] = &RaidAq40TriggerContext::ready_to_pull;
        creators["aq40 tank off his pedestal"] = &RaidAq40TriggerContext::tank_off_his_pedestal;
        creators["aq40 bugs on the raid"] = &RaidAq40TriggerContext::bugs_on_the_raid;
    }

private:
    static Trigger* twins_too_close_together(PlayerbotAI* botAI) { return new Aq40TwinsDragApartTrigger(botAI); }
    static Trigger* twins_wrong_side(PlayerbotAI* botAI) { return new Aq40TwinsKeepDistanceTrigger(botAI); }
    static Trigger* twins_wrong_side_of_room(PlayerbotAI* botAI) { return new Aq40TwinsWrongSideTrigger(botAI); }
    static Trigger* twins_wrong_target(PlayerbotAI* botAI) { return new Aq40TwinsWrongTargetTrigger(botAI); }
    static Trigger* not_in_place_yet(PlayerbotAI* botAI) { return new Aq40PrePullTrigger(botAI); }
    static Trigger* ready_to_pull(PlayerbotAI* botAI) { return new Aq40PullTogetherTrigger(botAI); }
    static Trigger* tank_off_his_pedestal(PlayerbotAI* botAI) { return new Aq40TankAnchorTrigger(botAI); }
    static Trigger* bugs_on_the_raid(PlayerbotAI* botAI) { return new Aq40TankTheBugsTrigger(botAI); }
};

#endif
