/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_ACTIONCONTEXT_H
#define MOD_PLAYERBOTS_BIS_ACTIONCONTEXT_H

#include "BisEquipAction.h"
#include "BisLootRollAction.h"
#include "NamedObjectContext.h"

// Same mechanism as BisValueContext, applied to an action instead of a value:
// SharedNamedObjectContextList::Add() assigns into the creator map, so the last
// context registered for "loot roll" is the one bots build.
//
// "equip upgrades packet action" lives in the SAME WorldPacketActionContext as
// "loot roll", so the override that already works for the vote reaches the
// equip step too.
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
        creators["equip upgrades packet action"] = &BisActionContext::equip_upgrades;
    }

private:
    static Action* loot_roll(PlayerbotAI* botAI) { return new BisLootRollAction(botAI); }
    static Action* equip_upgrades(PlayerbotAI* botAI) { return new BisEquipUpgradesAction(botAI); }
};

#endif
