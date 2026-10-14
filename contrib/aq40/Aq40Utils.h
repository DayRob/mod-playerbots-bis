/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef PLAYERBOTS_AQ40UTILS_H
#define PLAYERBOTS_AQ40UTILS_H

#include "Creature.h"
#include "Unit.h"

class Player;
class PlayerbotAI;

// Temple of Ahn'Qiraj. Every number below is taken from the core script
// (src/server/scripts/Kalimdor/TempleOfAhnQiraj/boss_twinemperors.cpp) so the bot
// behaviour and the encounter stay in agreement.
constexpr uint32 TEMPLE_OF_AHNQIRAJ_MAP_ID = 531;

constexpr uint32 NPC_VEKLOR = 15276;     // caster twin, immune to physical damage
constexpr uint32 NPC_VEKNILASH = 15275;  // melee twin, immune to magic except holy
constexpr uint32 NPC_QIRAJI_SCARAB = 15316;
constexpr uint32 NPC_QIRAJI_SCORPION = 15317;

// The twins heal each other with Heal Brother (7393) every 3.6 seconds, but only
// while they are within 60 yards of one another. Keeping them apart is the whole
// fight, so the bots aim a little past that range and leave it there.
constexpr float HEAL_BROTHER_RANGE = 60.0f;
constexpr float SAFE_SEPARATION = 70.0f;

// Vek'lor never melees: he chases only until he is 45 yards from his victim and
// then stops. He does cast Arcane Burst (568) on anything in melee contact, which
// knocks it back, so a physical attacker standing on him gains nothing and loses
// its position.
constexpr float MELEE_STAY_AWAY_FROM_VEKLOR = 15.0f;

// Vek'nilash melees, uppercuts and strikes whoever is nearest. A caster does zero
// damage to him, so being close is pure downside - and after a teleport each twin
// grabs its nearest target with 2000 threat, which is how casters end up tanking.
constexpr float CASTER_STAY_AWAY_FROM_VEKNILASH = 25.0f;

// Where a spell dealer stands once it is on the right side of Vek'lor: close
// enough to cast, far enough that Vek'lor has no reason to walk back towards
// his brother (he only moves when his victim is over 45 yards away).
constexpr float CASTER_FAR_SIDE_OFFSET = 25.0f;

// The chamber is large; the twins have to be found from either end of it. Kept
// short enough that a bot busy elsewhere in the temple is never dragged in.
constexpr float TWIN_SCAN_RANGE = 150.0f;

// Mutate Bug (802) and Explode Bug (804) turn a scarab or scorpion hostile, and
// it goes for somebody. Only the bot it actually reached is left alone with it;
// everyone else stays on the emperors, because a woken bug is a rank-0 level-60
// nuisance and both emperors share one health pool on a 15-minute timer.

// The chamber's own bugs never strike first: npc_ahnqiraji_critter::Reset()
// returns early for any spawn that linked_respawn ties to a Vek'lor spawn, and
// in the emperors' hall every one of them is tied that way. So a bot fighting
// one there was sent. Nothing in this folder tries to stop that - a bot's own
// initiative is not what sends it, and overriding whatever does would reach
// outside this one fight. See the README.

class RaidAq40Utils
{
public:
    static Creature* GetVeklor(Player* bot);
    static Creature* GetVeknilash(Player* bot);

    // True once at least one twin is alive and fighting.
    static bool AreTwinsEngaged(Player* bot);

    // Spell damage only hurts Vek'lor, physical damage only hurts Vek'nilash.
    // Healers are deliberately left out of every assignment: they follow the raid
    // and heal, and forcing them around would only break that.
    static bool IsSpellDamageDealer(Player* bot);
    static bool IsPhysicalDamageDealer(Player* bot);

    // The twin this bot can actually damage, or nullptr for healers and for
    // anything we have no business steering.
    static Unit* GetAssignedTwin(Player* bot);

    // The twin this bot must stay away from, or nullptr.
    static Unit* GetForbiddenTwin(Player* bot);

    static float Separation(Unit* veklor, Unit* veknilash);

    // A woken scarab or scorpion is in melee on this bot specifically.
    static bool IsBugOnMe(Player* bot);

};

#endif
