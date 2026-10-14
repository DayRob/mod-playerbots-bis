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
        creators["aq40 twins drag apart"] = &RaidAq40ActionContext::twins_drag_apart;
        creators["aq40 twins keep distance"] = &RaidAq40ActionContext::twins_keep_distance;
        creators["aq40 twins cross over"] = &RaidAq40ActionContext::twins_cross_over;
        creators["aq40 twins attack my twin"] = &RaidAq40ActionContext::twins_attack_my_twin;
        creators["aq40 tank hold your pedestal"] = &RaidAq40ActionContext::tank_hold_your_pedestal;
        creators["aq40 tank the bugs"] = &RaidAq40ActionContext::tank_the_bugs;
    }

private:
    static Action* twins_drag_apart(PlayerbotAI* botAI) { return new Aq40TwinsDragApartAction(botAI); }
    static Action* twins_keep_distance(PlayerbotAI* botAI) { return new Aq40TwinsKeepDistanceAction(botAI); }
    static Action* twins_cross_over(PlayerbotAI* botAI) { return new Aq40TwinsFarSideAction(botAI); }
    static Action* twins_attack_my_twin(PlayerbotAI* botAI) { return new Aq40TwinsAttackMyTwinAction(botAI); }
    static Action* tank_hold_your_pedestal(PlayerbotAI* botAI) { return new Aq40TankAnchorAction(botAI); }
    static Action* tank_the_bugs(PlayerbotAI* botAI) { return new Aq40TankTheBugsAction(botAI); }
};

#endif
