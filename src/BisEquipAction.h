/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_EQUIPACTION_H
#define MOD_PLAYERBOTS_BIS_EQUIPACTION_H

#include "EquipAction.h"

class ChatHandler;

// Replacement for playerbots' "equip upgrades packet action", the action that
// runs when a bot receives an item.
//
// WHY THIS EXISTS. Replacing the "item usage" and "item upgrade" values is
// enough to decide what a bot ROLLS on, but not what it PUTS ON. For weapons,
// EquipAction takes the decision itself:
//
//     bool canDualWieldOrTG = (canDualWield || isTwoHander);
//     if (isWeapon && canDualWieldOrTG)
//     {
//         StatsWeightCalculator calculator(bot);
//         ...
//         else { /* No improvement, do nothing */ return; }
//     }
//
// Being two-handed is enough to enter that branch, and from there only
// playerbots' stat score has a say - it weighs a two-hander against the sum of
// both hands and the ladder is never consulted. A shaman would announce a
// two-handed axe as its best in slot, roll on it, win it, and leave it in its
// bags for ever.
//
// So this runs the original first, unchanged, and then makes one pass of its
// own over the bags for pieces the ladder claims and the original left behind.
class BisEquipUpgradesAction : public EquipUpgradesPacketAction
{
public:
    explicit BisEquipUpgradesAction(PlayerbotAI* botAI)
        : EquipUpgradesPacketAction(botAI, "equip upgrades packet action") {}

    bool Execute(Event event) override;

    // Puts on every bagged piece the lists rank above what the bot wears in
    // that slot. Returns true when at least one was equipped.
    //
    // Public because of WHEN this action runs: it is a packet action, fired as
    // an item arrives. A piece already sitting in the bags is never looked at
    // again until the next item lands - so a quest reward handed to forty bots
    // at once, or anything received while the module was off, stays there.
    // ".playerbotsbis equipe" calls this directly to sweep that up.
    bool EquipBisFromBags();
};

namespace BisEquipCommand
{
    // args: empty for the caller's guild, "all" for every bot the module
    // applies to. Runs the bag sweep on each and prints what was put on.
    bool HandleEquipNow(ChatHandler* handler, char const* args);
}

#endif
