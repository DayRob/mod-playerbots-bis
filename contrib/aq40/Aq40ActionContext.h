/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef PLAYERBOTS_AQ40ACTIONCONTEXT_H
#define PLAYERBOTS_AQ40ACTIONCONTEXT_H

#include "Action.h"
#include "Aq40Actions.h"
#include "NamedObjectContext.h"

class RaidAq40ActionContext : public NamedObjectContext<Action>
{
public:
    RaidAq40ActionContext()
    {
        creators["aq40 leave what is not hostile"] = &RaidAq40ActionContext::leave_what_is_not_hostile;
        creators["aq40 put the twins on their marks"] = &RaidAq40ActionContext::put_the_twins;
        creators["aq40 take your station"] = &RaidAq40ActionContext::take_your_station;
        creators["aq40 pull together"] = &RaidAq40ActionContext::pull_together;
        creators["aq40 tank your side"] = &RaidAq40ActionContext::tank_your_side;
        creators["aq40 hold veklor"] = &RaidAq40ActionContext::hold_veklor;
        creators["aq40 tank the bugs"] = &RaidAq40ActionContext::tank_the_bugs;
        creators["aq40 hold your fire"] = &RaidAq40ActionContext::hold_your_fire;
        creators["aq40 take him to the mark"] = &RaidAq40ActionContext::take_him_to_the_mark;
        creators["aq40 dismiss your pet"] = &RaidAq40ActionContext::dismiss_your_pet;
        creators["aq40 keep away"] = &RaidAq40ActionContext::keep_away;
        creators["aq40 attack my twin"] = &RaidAq40ActionContext::attack_my_twin;
    }

private:
    static Action* leave_what_is_not_hostile(PlayerbotAI* botAI) { return new Aq40LeaveNeutralAction(botAI); }
    static Action* put_the_twins(PlayerbotAI* botAI) { return new Aq40SetTheStageAction(botAI); }
    static Action* take_your_station(PlayerbotAI* botAI) { return new Aq40TakeStationAction(botAI); }
    static Action* pull_together(PlayerbotAI* botAI) { return new Aq40PullTogetherAction(botAI); }
    static Action* tank_your_side(PlayerbotAI* botAI) { return new Aq40TankAction(botAI); }
    static Action* hold_veklor(PlayerbotAI* botAI) { return new Aq40HoldVeklorAction(botAI); }
    static Action* tank_the_bugs(PlayerbotAI* botAI) { return new Aq40BugTankAction(botAI); }
    static Action* hold_your_fire(PlayerbotAI* botAI) { return new Aq40HoldFireAction(botAI); }
    static Action* take_him_to_the_mark(PlayerbotAI* botAI) { return new Aq40DragToMarkAction(botAI); }
    static Action* dismiss_your_pet(PlayerbotAI* botAI) { return new Aq40DismissPetAction(botAI); }
    static Action* keep_away(PlayerbotAI* botAI) { return new Aq40KeepAwayAction(botAI); }
    static Action* attack_my_twin(PlayerbotAI* botAI) { return new Aq40AttackMyTwinAction(botAI); }
};

#endif
