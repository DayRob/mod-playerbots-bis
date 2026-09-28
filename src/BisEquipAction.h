/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_EQUIPACTION_H
#define MOD_PLAYERBOTS_BIS_EQUIPACTION_H

#include "EquipAction.h"

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

private:
    // Puts on every bagged piece the lists rank above what the bot wears in
    // that slot. Returns true when at least one was equipped.
    bool EquipBisFromBags();
};

#endif
