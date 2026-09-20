/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_ACTIONCONTEXT_H
#define MOD_PLAYERBOTS_BIS_ACTIONCONTEXT_H

#include "BisLootRollAction.h"
#include "NamedObjectContext.h"

// Same mechanism as BisValueContext, applied to an action instead of a value:
// SharedNamedObjectContextList::Add() assigns into the creator map, so the last
// context registered for "loot roll" is the one bots build.
//
// "master loot roll" is deliberately left alone. Playerbots forces a PASS there
// and the master hands the piece out himself, so there is no vote to reserve -
// that case is covered by the whisper in BisMasterLootAnnounce instead.
class BisActionContext : public NamedObjectContext<Action>
{
public:
    BisActionContext()
    {
        creators["loot roll"] = &BisActionContext::loot_roll;
    }

private:
    static Action* loot_roll(PlayerbotAI* botAI) { return new BisLootRollAction(botAI); }
};

#endif
