/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef PLAYERBOTS_AQ40UTILS_H
#define PLAYERBOTS_AQ40UTILS_H

#include "Creature.h"
#include "Position.h"
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

// LES DEUX PIEDESTAUX. Chaque Empereur apparait sur le sien, aux deux bouts de
// la salle - mesure sur une base reelle : 158,2 yards entre les deux. Le script
// du coeur ne touche jamais a la position d'origine d'une creature (aucun
// SetHomePosition dans boss_twinemperors.cpp), donc GetHomePosition() rend
// toujours le piedestal de depart, meme apres trois teleportations.
//
// C'est la seule reference fixe de ce combat, et c'est ce qui fait tenir toute
// la strategie : un tank par piedestal, chacun ramene le jumeau qu'on lui a
// confie sur SON socle, et les deux restent a 158 yards - loin des 60 de Heal
// Brother, sans que personne ait rien a trainer.
constexpr float TANK_ANCHOR_TOLERANCE = 3.0f;

// Pas de poste : ce bot n'est pas un tank, ou n'est pas en groupe.
constexpr uint8 TANK_INDEX_NONE = 255;

// Vek'lor lance Arcane Burst (568) des qu'un joueur est a portee de contact
// (SelectNearestPlayer(NOMINAL_MELEE_RANGE), soit 5 yards), toutes les 7 a 12
// secondes, et ca repousse. Le tank qui le tient se place donc juste au-dela -
// assez pres pour rester le joueur le plus proche, ce qui est tout ce que la
// teleportation regarde.
constexpr float VEKLOR_TANK_DISTANCE = 10.0f;

// Au-dela, le tank va CHERCHER son jumeau au lieu de l'attendre sur son socle :
// c'est le cas de la capture ou les deux Empereurs ont fini sur le meme
// piedestal. En deca, il rentre et le jumeau suit.
constexpr float TANK_GRAB_RANGE = 25.0f;

// How far the bug tank looks for a woken bug. Wide enough to cover the raid he
// is protecting - the healers stand behind their own group, not on him - and
// short enough that he never leaves the fight to chase something at the far end
// of the chamber.
constexpr float BUG_SCAN_RANGE = 60.0f;

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

    // ── LES TANKS, PAR PIEDESTAL ──────────────────────────────────────────
    //
    // Les bots tanks du groupe sont ranges par GUID - un ordre qui ne change
    // jamais, et c'est tout ce qu'on lui demande : un choix "malin" qui changerait
    // d'avis d'un tick a l'autre ferait osciller deux tanks entre les deux bouts
    // de la salle. Le rang donne le poste :
    //
    //   rang 0 -> le piedestal de Vek'nilash
    //   rang 1 -> le piedestal de Vek'lor
    //   rang 2 -> les bestioles du milieu
    //   au-dela -> rien de particulier, ils se battent comme les autres
    //
    // Un humain n'est jamais range : rien ici ne le ferait bouger. Si c'est toi
    // qui tiens un cote, le bot de rang 0 doublera ton poste - inoffensif, et
    // visible d'un coup d'oeil.
    static uint8 TankIndex(Player* bot);

    // Le socle que ce tank doit tenir. Faux s'il n'a pas de poste.
    static bool GetAnchor(Player* bot, Position& out);

    // Le jumeau confie a ce tank. CE N'EST PAS une distance : les deux socles
    // se partagent les deux Empereurs, celui qui est le plus pres du socle du
    // rang 0 lui revient et l'autre va au rang 1. Les deux tanks font le meme
    // calcul, donc ils ne peuvent pas se retrouver sur le meme jumeau - y
    // compris quand les deux ont fini colles sur le meme piedestal.
    static Unit* GetTwinForTank(Player* bot);

    // Vrai pour les rangs 0 et 1 pendant le combat : leur consigne de poste
    // remplace alors les quatre regles de placement, qui ne savent rien des
    // socles et les feraient repartir vers le milieu.
    static bool IsOnAnchorDuty(Player* bot);

    // ── LE TANK DES BESTIOLES ─────────────────────────────────────────────
    //
    // Vek'lor lance Explode Bug (804) toutes les 4,5 a 10 secondes et
    // Vek'nilash Mutate Bug (802) toutes les 10 a 20 : chaque incantation
    // retourne UNE bestiole de la salle (le script du sort fait
    // RandomResize(targets, 1)), qui passe hostile et entre en combat avec la
    // zone entiere. Sans menace sur personne, elle part vers qui lui en donne -
    // et c'est le soigneur, parce que chaque sort de soin en fabrique sur tout
    // ce qui est en combat avec lui.
    static bool IsBugTank(Player* bot);

    // La bestiole reveillee dont ce bot doit s'occuper, la plus urgente
    // d'abord : celle qui mange un soigneur, puis celle qui mange quelqu'un
    // d'autre, puis la sienne ou celle qui n'a encore personne. nullptr quand
    // la salle est calme.
    static Unit* GetBugToTank(Player* bot);

    // Vrai pendant tout le combat pour le tank des bestioles - c'est un poste,
    // pas une reaction. Les quatre regles des Empereurs se taisent alors pour
    // lui : sans ca, "mauvaise cible" le rappellerait sur Vek'nilash des que la
    // salle se calme, et la bestiole suivante tomberait a quatre-vingts yards
    // de la ou il est reparti.
    static bool IsOnBugDuty(Player* bot);

    // Le milieu des deux socles : la ou les bestioles se reveillent et ou se
    // tiennent les soigneurs. Le poste du tank des bestioles quand la salle est
    // calme.
    static bool GetBugStation(Player* bot, Position& out);
};

#endif
