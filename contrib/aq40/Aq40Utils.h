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

// LES DEUX POSTES DE TANK.
//
// Ce NE SONT PAS les points d'apparition. Les deux Empereurs poussent sur les
// plateformes du fond, aux deux coins hauts de la salle; le raid les tire
// contre les murs gauche et droit, a mi-hauteur - c'est la qu'on les tient, et
// c'est ce que montre le schema de guilde. Hors des bestioles du milieu, hors
// du chemin des deux groupes qui se croisent a chaque echange.
//
// A zero, les postes se rabattent sur GetHomePosition(), donc sur les
// plateformes d'apparition. La strategie marche toujours - 158,2 yards
// separent les deux, soit bien plus que les 60 de Heal Brother - mais ce n'est
// pas le placement de la guilde. Pour les remplir : se placer sur chaque tete
// de mort du schema, faire ".gps" en jeu, et coller les deux relevés ici.
// L'ORDRE N'A PAS D'IMPORTANCE : le code attribue a chaque rang le poste le
// plus proche de la plateforme qui lui revient.
struct Aq40TankPost
{
    float x;
    float y;
    float z;
};

// Relevés en jeu sur la carte 531, sur les deux tetes de mort du schema de
// guilde. 133,3 yards les separent, et chacun est a une bonne quatre-vingtaine
// de yards de la plateforme d'apparition qui lui fait face.
constexpr Aq40TankPost TANK_POST_A = { -8896.308f, 1283.0752f, -112.292564f };  // tete de mort gauche
constexpr Aq40TankPost TANK_POST_B = { -9027.637f, 1259.976f, -112.294556f };   // tete de mort droite

// Assez pres pour que le poste soit tenu. Trois yards laissent au bot de quoi
// se replacer sans repartir a chaque tick.
constexpr float TANK_ANCHOR_TOLERANCE = 3.0f;

// Pas de poste : ce bot n'est pas un tank, ou n'est pas en groupe.
constexpr uint8 TANK_INDEX_NONE = 255;

constexpr float VEKLOR_TANK_DISTANCE = 10.0f;

// Au-dela, le tank va CHERCHER son jumeau au lieu de l'attendre sur son socle :
// c'est le cas de la capture ou les deux Empereurs ont fini sur le meme
// piedestal. En deca, il rentre et le jumeau suit.
constexpr float TANK_GRAB_RANGE = 25.0f;

// ── LA MISE EN PLACE AVANT LE PULL ────────────────────────────────────────
//
// Elle n'existe que dans UNE fenetre : les Jumeaux pas encore engages, le bot
// hors combat, et le raid deja dans la salle. C'est exactement l'etat ou
// mod-dungeon-clear met le run quand DungeonClear.WaitAtBoss = 1 : il met en
// pause juste avant le pull, et sa propre documentation dit que "the driving
// ladder is inert when paused and followers stop trailing the leader". Rien ne
// tire donc les bots pendant qu'ils se placent, et rien n'est bloque non plus :
// des qu'un bot est a son poste, le declencheur rend faux et le pull - le tien
// ou celui de dungeon-clear - part sans rien avoir a attendre.
//
// Au-dela de cette distance du milieu de la salle, on ne touche a rien : un bot
// encore dans le couloir appartient a dungeon-clear.
constexpr float PREPULL_GATHER_RANGE = 100.0f;

// De combien chacun se decale de son poste vers le milieu, pour ne pas se tenir
// sur son tank. Un corps-a-corps n'a que quelques pas a faire au pull; un
// lanceur de sorts est deja a portee.
constexpr float MELEE_PREPULL_OFFSET = 10.0f;
constexpr float CASTER_PREPULL_OFFSET = 20.0f;

// COMBIEN DE TEMPS LES TANKS RETIENNENT LE PULL.
//
// Un tank deja a son poste rend faux des qu'il n'a plus rien a faire, et c'est
// ce qui laisse dungeon-clear pull. Tant que ses collegues marchent encore, il
// retient au contraire - sa regle siege bien au-dessus de la bande de
// dungeon-clear, donc le pull attend que les trois postes soient tenus. Sans
// toi, sans commande.
//
// Avec une limite, parce qu'un tank mort, bloque ou hors de la salle ne doit
// pas pouvoir geler le run pour toujours. Passe ce delai, chacun rend la main
// et dungeon-clear pull comme il l'aurait fait.
constexpr uint32 PREPULL_HOLD_MAX_MS = 20000;

// L'ecartement lateral entre deux bots du meme groupe, gradue sur leur GUID :
// sans lui, trente-six bots visent le meme point et s'empilent.
constexpr float PREPULL_SPREAD_STEP = 4.0f;

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

    // Les deux postes, ranges : poste0 pour le rang 0, poste1 pour le rang 1.
    // Faux tant que les deux Empereurs ne sont pas trouves.
    static bool GetPosts(Player* bot, Position& poste0, Position& poste1);

    // Le poste que ce tank doit tenir. Faux s'il n'a pas de poste.
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

    // Le milieu des deux postes : la ou les bestioles se reveillent et ou se
    // tiennent les soigneurs. Le poste du tank des bestioles quand la salle est
    // calme.
    static bool GetBugStation(Player* bot, Position& out);

    // Ou ce bot doit se tenir AVANT le pull. Les trois tanks sur leurs postes,
    // les corps-a-corps du cote ou Vek'nilash sera tenu, les lanceurs de sorts
    // du cote de Vek'lor, chacun decale de ses voisins. Faux pour les
    // soigneurs : ils suivent, et c'est tres bien comme ca.
    static bool GetPrePullStation(Player* bot, Position& out);

    // Vrai quand chaque bot tank qui a un poste s'y trouve. C'est la condition
    // du pull : tant qu'elle est fausse, les tanks deja arrives retiennent.
    static bool AllTanksPosted(Player* bot);
};

#endif
