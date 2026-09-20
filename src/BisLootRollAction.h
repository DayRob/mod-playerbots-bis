/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_LOOTROLLACTION_H
#define MOD_PLAYERBOTS_BIS_LOOTROLLACTION_H

#include "LootRollAction.h"

// Reserves NEED for the bot's own best in slot.
//
// Playerbots votes NEED on any piece its scoring calls an upgrade. With
// PlayerbotsBis.NeedOnlyForBis on, that stays a GREED and only a real best in
// slot is worth a NEED, so a raid of bots stops outbidding each other - and you
// - on gear none of them is actually chasing.
//
// The implementation votes GREED itself on the rolls it wants downgraded and
// then defers to playerbots for everything else: the base Execute() skips any
// roll already voted on, so its decision tree is reused rather than copied.
class BisLootRollAction : public LootRollAction
{
public:
    BisLootRollAction(PlayerbotAI* botAI) : LootRollAction(botAI, "loot roll") {}

    bool Execute(Event event) override;
};

#endif
