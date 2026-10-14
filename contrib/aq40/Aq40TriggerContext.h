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
        creators["aq40 idle qiraji bug target"] = &RaidAq40TriggerContext::idle_qiraji_bug_target;
        creators["aq40 twins too close together"] = &RaidAq40TriggerContext::twins_too_close_together;
        creators["aq40 twins wrong side"] = &RaidAq40TriggerContext::twins_wrong_side;
        creators["aq40 twins wrong target"] = &RaidAq40TriggerContext::twins_wrong_target;
    }

private:
    static Trigger* idle_qiraji_bug_target(PlayerbotAI* botAI) { return new Aq40IdleQirajiBugTargetTrigger(botAI); }
    static Trigger* twins_too_close_together(PlayerbotAI* botAI) { return new Aq40TwinsDragApartTrigger(botAI); }
    static Trigger* twins_wrong_side(PlayerbotAI* botAI) { return new Aq40TwinsKeepDistanceTrigger(botAI); }
    static Trigger* twins_wrong_target(PlayerbotAI* botAI) { return new Aq40TwinsWrongTargetTrigger(botAI); }
};

#endif
