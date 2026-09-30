/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_UNBIND_H
#define MOD_PLAYERBOTS_BIS_UNBIND_H

class ChatHandler;

// Free the bots' instance locks, so they follow their leader into HIS copy.
//
// The core decides a teleport's destination copy like this
// (InstanceSaveMgr::PlayerGetDestinationInstanceId):
//
//     if (ipb && ipb->perm) return ipb->save->GetInstanceId();  // 1. own PERMANENT lock
//     if (Group* g = player->GetGroup())
//     {
//         if (leader bind) return that;                         // 2. the LEADER's lock
//         return 0;                                             // 3. a brand new copy
//     }
//
// A bot that killed a boss somewhere holds a permanent lock, and step 1 sends it
// back there whatever its group does. That is the whole bug: the raid is on the
// same map, at the same coordinates, in two parallel copies.
//
// ".instance unbind" cannot fix it in bulk - it works on one selected target -
// and deleting the rows in character_instance does nothing until a restart,
// because the manager keeps its binds in memory. This goes through that manager,
// so it takes effect at once.
namespace BisUnbind
{
    // args: optional "guilde" to widen from the caller's group to his guild, and
    // an optional map id to narrow to one instance. The caller is never touched:
    // his own lock is his raid's progress.
    bool HandleUnbind(ChatHandler* handler, char const* args);
}

#endif
