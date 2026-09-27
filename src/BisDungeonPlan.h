/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_DUNGEON_PLAN_H
#define MOD_PLAYERBOTS_BIS_DUNGEON_PLAN_H

class ChatHandler;

// Which instance to run, and with which bots.
//
// The roster says what each bot is missing; this says where to go and get it.
// Both halves already exist - the bots' missing pieces come from the module's
// own lists, and the world database knows which creature drops what and where
// that creature spawns - so nothing new is stored: the crossing is computed on
// demand and only the item-to-instance index is cached.
namespace BisDungeonPlan
{
    // args: empty for the caller's guild, "all" for every bot the module
    // applies to. Prints a ranked plan and streams it to the companion window.
    bool HandlePlan(ChatHandler* handler, char const* args);

    // Drops the cached item-to-instance index, so ".playerbotsbis reload" picks
    // up loot table edits without a restart.
    void Invalidate();
}

#endif
