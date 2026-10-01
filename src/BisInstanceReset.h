/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_INSTANCE_RESET_H
#define MOD_PLAYERBOTS_BIS_INSTANCE_RESET_H

#include "Define.h"

// Wipes every instance lock on the server, once, at startup.
//
// The point is a raid of forty bots. A bot bound to its own copy of Blackwing
// Lair is sent there on summon, however the group is formed, and no amount of
// re-inviting moves it: InstanceSaveMgr::PlayerGetDestinationInstanceId reads
// the bot's own permanent bind before it ever looks at the leader's. Clearing
// every lock before anyone logs in means the first entry of the evening always
// opens a fresh copy that the whole raid then shares.
//
// ".playerbotsbis libere" remains the tool for the same problem mid-session.
// This one removes the need to think about it at all.
namespace BisInstanceReset
{
    // 0 = off, 1 = raids only, 2 = raids and dungeons.
    enum Scope : uint8
    {
        SCOPE_OFF      = 0,
        SCOPE_RAIDS    = 1,
        SCOPE_ALL      = 2
    };

    // Call once, from the world thread, after InstanceSaveMgr::LoadInstances.
    void RunOnce();
}

#endif  // MOD_PLAYERBOTS_BIS_INSTANCE_RESET_H
