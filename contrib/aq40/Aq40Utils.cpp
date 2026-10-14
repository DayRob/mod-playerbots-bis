/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Utils.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include <initializer_list>

Creature* RaidAq40Utils::GetVeklor(Player* bot)
{
    return bot ? bot->FindNearestCreature(NPC_VEKLOR, TWIN_SCAN_RANGE) : nullptr;
}

Creature* RaidAq40Utils::GetVeknilash(Player* bot)
{
    return bot ? bot->FindNearestCreature(NPC_VEKNILASH, TWIN_SCAN_RANGE) : nullptr;
}

bool RaidAq40Utils::AreTwinsEngaged(Player* bot)
{
    Creature* veklor = GetVeklor(bot);
    Creature* veknilash = GetVeknilash(bot);
    if (!veklor || !veknilash)
        return false;

    return veklor->IsInCombat() || veknilash->IsInCombat();
}

bool RaidAq40Utils::IsSpellDamageDealer(Player* bot)
{
    if (!bot)
        return false;

    // bySpec on purpose: the answer has to match the character's talents, not
    // whichever strategies happen to be loaded on it right now.
    return PlayerbotAI::IsCaster(bot, true) && !PlayerbotAI::IsHeal(bot, true);
}

bool RaidAq40Utils::IsPhysicalDamageDealer(Player* bot)
{
    if (!bot)
        return false;

    // Hunters count here: their shots are physical, so Vek'lor is immune to them
    // even though they fight at range. Tanks count too - Vek'nilash is the twin a
    // warrior can hold.
    return !PlayerbotAI::IsCaster(bot, true) && !PlayerbotAI::IsHeal(bot, true);
}

Unit* RaidAq40Utils::GetAssignedTwin(Player* bot)
{
    if (IsSpellDamageDealer(bot))
        return GetVeklor(bot);

    if (IsPhysicalDamageDealer(bot))
        return GetVeknilash(bot);

    return nullptr;
}

Unit* RaidAq40Utils::GetForbiddenTwin(Player* bot)
{
    if (IsSpellDamageDealer(bot))
        return GetVeknilash(bot);

    if (IsPhysicalDamageDealer(bot))
        return GetVeklor(bot);

    return nullptr;
}

float RaidAq40Utils::Separation(Unit* veklor, Unit* veknilash)
{
    if (!veklor || !veknilash)
        return 0.0f;

    return veklor->GetExactDist2d(veknilash);
}

bool RaidAq40Utils::IsBugOnMe(Player* bot)
{
    if (!bot)
        return false;

    // Unit::getAttackers() is exactly the question: who has this bot in melee
    // right now. Asking it beats looking for the nearest bug and hoping it is
    // the one doing the biting - a second bug behind the first used to make the
    // whole raid stand down from the boss.
    for (Unit* attaquant : bot->getAttackers())
    {
        if (!attaquant)
            continue;

        uint32 const entry = attaquant->GetEntry();
        if (entry == NPC_QIRAJI_SCARAB || entry == NPC_QIRAJI_SCORPION)
            return true;
    }

    return false;
}
