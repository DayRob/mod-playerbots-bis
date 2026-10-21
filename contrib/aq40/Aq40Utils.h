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

// ═══ LES EMPEREURS JUMEAUX ═══════════════════════════════════════════════════
//
// Tout ce qui suit sort du script du coeur
// (src/server/scripts/Kalimdor/TempleOfAhnQiraj/boss_twinemperors.cpp) ou d'une
// mesure faite en jeu. Rien d'un guide, rien de memoire.
//
// CE QUI FAIT PERDRE LE COMBAT, et c'est la seule chose :
//
//     .Schedule(3600ms, [this](TaskContext context)
//     {
//         if (Creature* twin = GetTwin())
//             if (me->IsWithinDist(twin, 60.f))
//                 DoCast(twin, SPELL_HEAL_BROTHER, true);
//         context.Repeat();
//     });
//
// Chacun soigne son frere toutes les 3,6 secondes, mais SEULEMENT a moins de
// 60 yards. Et les degats sont partages entre les deux (Twin Empathy, 1177),
// donc deux Empereurs cote a cote annulent le raid entier. Toute la strategie
// tient a les garder ecartes.
//
// CE QUE CHACUN PERMET, et qui decide de qui fait quoi :
//
//   Vek'lor    immunise au PHYSIQUE, et a la PROVOCATION (constate en jeu).
//              Ne frappe jamais au contact. Suit sa cible jusqu'a 45 yards puis
//              s'arrete. Donc AUCUN TANK N'A DE PRISE SUR LUI - ni pour le
//              tenir, ni pour le deplacer. Ce sont les lanceurs de sorts qui le
//              tiennent, et un demoniste en premier.
//
//   Vek'nilash immunise au magique sauf au sacre. Frappe au contact, suit son
//              attaquant. C'est le SEUL des deux qu'un tank puisse tenir, et le
//              seul qu'on puisse emmener quelque part.
//
// D'OU LA REGLE CENTRALE : l'ecartement se fait en emmenant Vek'nilash loin de
// son frere, et tous les tanks sauf celui des bestioles s'en chargent.
//
// L'ECHANGE, toutes les 30 a 40 secondes :
//
//     DoResetThreatList();
//     ... 2 secondes plus tard ...
//     if (Unit* victim = me->SelectNearestTarget())
//     {
//         me->AddThreat(victim, 2000.f);
//         AttackStart(victim);
//     }
//
// Les positions sont echangees, les menaces remises a zero, et 2000 sont
// offerts au joueur le PLUS PROCHE - un soigneur, un voleur, n'importe qui.
// Vek'nilash se retrouve donc a l'autre bout de la salle sur quelqu'un qui ne
// peut pas l'encaisser, a cote de son frere. C'est la que tout se joue : il
// faut aller le reprendre et le ramener.
// ═════════════════════════════════════════════════════════════════════════════

constexpr uint32 TEMPLE_OF_AHNQIRAJ_MAP_ID = 531;

constexpr uint32 NPC_VEKLOR = 15276;     // immunise au physique et a la provocation
constexpr uint32 NPC_VEKNILASH = 15275;  // immunise au magique sauf au sacre
constexpr uint32 NPC_QIRAJI_SCARAB = 15316;
constexpr uint32 NPC_QIRAJI_SCORPION = 15317;

// Heal Brother (7393) ne part qu'en deca de cette distance.
constexpr float HEAL_BROTHER_RANGE = 60.0f;

// ─── LES DEUX MARQUES ────────────────────────────────────────────────────────
//
// Relevees en jeu au ".gps", sur les deux tetes de mort du schema de guilde.
// 133,3 yards les separent - plus du double des 60 de Heal Brother.
//
// Ce ne sont PAS les points d'apparition : les Empereurs poussent sur les
// plateformes du fond, et le raid les tire contre les murs gauche et droit.
struct Aq40Mark
{
    float x;
    float y;
    float z;
};

constexpr Aq40Mark MARQUE_A = { -8896.308f, 1283.0752f, -112.292564f };  // tete de mort gauche
constexpr Aq40Mark MARQUE_B = { -9027.637f, 1259.976f, -112.294556f };   // tete de mort droite

// ─── LES DEUX POINTS DE PULL ─────────────────────────────────────────────────
//
// Releves en jeu au ".gps", debout au sol, a cote de chaque Empereur. Ce ne
// sont PAS des marques de combat : on y va pour accrocher, puis on ramene.
//
//     POSTE_PULL_VEKLOR      a 16 yards de Vek'lor, sur sa plateforme
//     POSTE_PULL_VEKNILASH   a 22 yards de Vek'nilash, sur la sienne
//
// POURQUOI UN POINT PLUTOT QUE "MARCHE SUR LE BOSS". Les Empereurs sont en haut
// d'escaliers, et un bot lache sur leurs coordonnees depuis le sol de la salle
// s'arretait en bas des marches. Ces deux points sont a leur niveau, sur un sol
// que le client confirme (FloorZ -105.6 et -107.4), donc le chemin y mene
// vraiment. Le second tombe a 0.8 yard de l'endroit ou le tank du run se tenait
// quand il a engage : c'est le bon endroit, verifie deux fois.
//
// Les 141 yards qui les separent sont aussi une securite : les deux pulleurs ne
// se croisent jamais et n'amenent jamais leur Empereur vers celui de l'autre.
constexpr Aq40Mark POSTE_PULL_VEKLOR = { -8878.521f, 1218.7222f, -105.6064f };
constexpr Aq40Mark POSTE_PULL_VEKNILASH = { -9018.47f, 1197.4792f, -107.35514f };

// ─── LES DISTANCES ───────────────────────────────────────────────────────────

// Chaque marque est a 166 et 168 yards de la plateforme d'en face. A 150, un
// bot poste ne trouvait jamais les deux Empereurs et toutes les regles qui en
// ont besoin echouaient en silence. Mesure, pas supposee.
constexpr float TWIN_SCAN_RANGE = 250.0f;

// Assez pres pour qu'une marque soit tenue.
constexpr float MARK_TOLERANCE = 3.0f;

// Au-dela, un tank va CHERCHER Vek'nilash au lieu de l'attendre. C'est aussi la
// portee de la provocation.
constexpr float TANK_GRAB_RANGE = 25.0f;

// A QUELLE DISTANCE ON ENGAGE VRAIMENT, et ce n'est pas la meme pour les deux
// pulleurs. Le tank doit etre au CONTACT; le lanceur de sorts, lui, s'arrete
// des qu'il peut lancer - Vek'lor viendra a lui, puisqu'il suit sa cible
// jusqu'a 45 yards puis s'arrete, et c'est precisement ce qu'on veut.
//
// Le pull partait a 25 yards pour tout le monde : trop loin pour qu'un tank
// frappe, donc rien ne s'engageait, donc la regle de mise en place - juste en
// dessous dans la file - le renvoyait a sa marque. Aller-retour sans fin, et
// aucun pull. Vu en jeu.
constexpr float PULL_SPELL_RANGE = 28.0f;

// Un attaquant physique colle a Vek'lor ne gagne rien - il est immunise - et
// declenche Arcane Burst (568), qui repousse des qu'un joueur est a portee de
// contact. Un lanceur de sorts colle a Vek'nilash prend ses Uppercuts, qui
// visent au hasard parmi ce qui est a sa portee.
constexpr float MELEE_STAY_AWAY_FROM_VEKLOR = 15.0f;
constexpr float CASTER_STAY_AWAY_FROM_VEKNILASH = 25.0f;

// Ou se tient celui qui tient Vek'lor : assez pres pour lancer, assez loin pour
// qu'Arcane Burst ne le trouve pas, et surtout a poste FIXE - c'est sa position
// a lui qui decide ou Vek'lor se plante, puisque Vek'lor s'arrete a 45 yards de
// sa cible et ne bouge plus.
constexpr float VEKLOR_HOLDER_OFFSET = 25.0f;

// De combien chacun se decale de sa marque vers le milieu avant le pull, pour
// ne pas se tenir sur son tank.
constexpr float MELEE_PREPULL_OFFSET = 10.0f;

// ET LES LANCEURS DE SORTS SE TIENNENT LOIN, EUX AUSSI.
//
// Ils ne reculaient pas du tout - zero yard - donc ils se posaient SUR leur
// marque, c'est-a-dire sur Vek'lor, que la laisse y maintient. Or le script ne
// demande rien d'autre pour lancer Jaillissement des arcanes :
//
//     if (Player* player = me->SelectNearestPlayer(NOMINAL_MELEE_RANGE))
//
// Un seul joueur au contact, et toute la salle est repoussee.
//
// Vingt yards : au-dela du contact, et bien en deca des trente d'un sort. La
// meme bande que celle ou le demoniste tient Vek'lor, pour la meme raison.
constexpr float CASTER_PREPULL_OFFSET = 20.0f;

// L'ecartement lateral entre deux bots du meme groupe, gradue sur leur GUID :
// sans lui, trente bots visent le meme point et s'empilent.
constexpr float PREPULL_SPREAD_STEP = 4.0f;

// ─── LE VERROU D'ARRIVEE ─────────────────────────────────────────────────────
//
// La mise en place ne COMMENCE que lorsque le bot est DANS la salle : avant, le
// raid est en chemin, et le chemin appartient a mod-dungeon-clear. Sans ce
// verrou elle demarrait en plein trajet et sortait le tank de la route qu'il
// suivait - "off-line rejoin made no progress", vu dans le journal.
//
// La distance se mesure au MILIEU des deux marques, et pas a un Empereur. Le
// seuil precedent - un Empereur a moins de 60 yards - etait faux : depuis le
// milieu de la salle, les deux plateformes sont a 114 yards (releve :
// Vek'lor en -8868.3, 1206.0; Vek'nilash en -9023.7, 1176.2). Un raid rassemble
// au milieu, ce que fait dungeon-clear avant son pull, n'aurait donc JAMAIS
// declenche la mise en place, et rien ne l'aurait dit.
//
// Deux seuils, pour que le verrou ne claque pas d'un tick a l'autre : on entre
// a 120 et on ne se considere sorti qu'a 150.
constexpr float TWINS_ROOM_RANGE = 120.0f;
constexpr float PREPULL_GATHER_RANGE = 150.0f;

// Combien de temps les tanks deja en place retiennent le pull en attendant les
// autres. Avec une limite, parce qu'un tank mort ou bloque ne doit pas pouvoir
// geler le run pour toujours.
constexpr uint32 PREPULL_HOLD_MAX_MS = 20000;

// Portee de recherche des bestioles reveillees.
constexpr float BUG_SCAN_RANGE = 60.0f;

// A QUELLE DISTANCE DE SA MARQUE UN EMPEREUR EST "PLACE".
//
// Large, et pour une raison : les deux ne s'arretent pas au meme endroit.
// Vek'nilash finit SUR la marque, son tank l'y amene au contact. Vek'lor, lui,
// s'arrete a 45 yards de sa cible et ne bouge plus - avec celui qui le tient
// poste a 25 yards de la marque vers le milieu, il se plante une vingtaine de
// yards EN DECA. Trente couvre les deux sans jamais se tromper de camp : les
// marques sont a 133 yards l'une de l'autre.
constexpr float TWIN_PLACED_RANGE = 30.0f;

// COMBIEN DE TEMPS LE RAID RETIENT SES COUPS, au maximum.
//
// Un tank qui traine Vek'nilash sur soixante yards met une dizaine de
// secondes. Vingt laissent la marge, et la limite existe pour un seul cas :
// celui ou un Empereur n'arrive JAMAIS a sa marque - son tank est mort, son
// demoniste aussi, il s'est coince quelque part. Sans elle, quarante bots
// regarderaient le combat sans frapper jusqu'au wipe.
constexpr uint32 HOLD_FIRE_MAX_MS = 20000;

// Les soigneurs ne sont pas places, mais ils ne doivent PAS etre le joueur le
// plus proche d'un Empereur : la teleportation offre 2000 de menace au plus
// proche, et ce doit etre un tank. Vingt-cinq yards les en ecartent tout en les
// laissant largement a portee de soin - un sort porte a 40.
constexpr float HEALER_STAY_AWAY = 25.0f;

// DE COMBIEN IL FAUT ETRE "DU MAUVAIS COTE" POUR QUE LA TRAVERSEE SE DECLENCHE,
// et de combien il faut avoir passe le milieu pour qu'elle s'arrete.
//
// Les deux marques sont a 133 yards l'une de l'autre, donc cette marge ne
// decide jamais rien de serre : elle existe pour qu'un bot pile au milieu ne
// fasse pas clignoter la regle d'un tick a l'autre.
constexpr float WRONG_SIDE_MARGIN = 10.0f;

// ─── LA LAISSE ───────────────────────────────────────────────────────────────
//
// De combien un Empereur peut s'ecarter de sa tete de mort avant qu'on l'y
// ramene, et a quelle frequence au maximum.
//
// Huit yards, pas trois : un boss au contact de son tank oscille de quelques
// yards en permanence, et le ramener pour ca ferait une teleportation par
// seconde. Et trois secondes entre deux recalages, parce qu'une laisse qui tire
// a chaque tick se verrait.
//
// ELLE SUIT L'ECHANGE, ELLE NE LE CONTRARIE PAS : on ramene chaque Empereur sur
// la tete de mort dont il est LE PLUS PRES, donc apres une teleportation c'est
// l'autre, et les bots doivent bien changer de cote.
constexpr float LEASH_DRIFT_RANGE = 8.0f;
constexpr uint32 LEASH_COOLDOWN_MS = 3000;

// ─── LE PLAFOND DE LA LAISSE, EN COMBAT ──────────────────────────────────────
//
// UNE LAISSE CORRIGE UNE DERIVE, ELLE NE DEMENAGE PAS UN BOSS.
//
// En fonctionnement normal, la correction en combat vaut quelques yards : les
// Empereurs sont poses sur leurs marques AVANT le pull, et apres leur propre
// teleportation chacun atterrit sur la marque d'en face - celle dont il est le
// plus pres - donc l'ecart reste petit.
//
// Un ecart enorme en plein combat ne peut venir que d'une situation anormale :
// la strategie armee alors que le combat a deja commence, un boss parti au bout
// de la salle derriere un bot. Le ramener de quatre-vingts yards d'un coup fait
// basculer la creature en EVASION - elle rentre chez elle, se soigne et devient
// immunisee, et le combat est perdu. Constate en jeu.
//
// Au-dela de ce plafond, la laisse ne fait donc rien : le combat se deroule mal
// mais il se deroule, ce qui vaut mieux qu'un boss qui se soigne a fond.
constexpr float LEASH_MAX_MOVE = 30.0f;

// ─── LA MINUTERIE DE LA TELEPORTATION ────────────────────────────────────────
//
// Elle n'est pas devinee, elle est lue dans le script du coeur :
//
//     .Schedule(30s, [this](TaskContext context)
//     {
//         DoCastSelf(SPELL_TWIN_TELEPORT_0);
//         context.Repeat(30s, 40s);
//     })
//
// La PREMIERE tombe a exactement trente secondes; les suivantes entre trente et
// quarante, au hasard. Trente est donc le PLANCHER, et c'est la seule date sur
// laquelle on puisse s'appuyer sans se tromper : partir cinq secondes avant
// elle, c'est partir cinq secondes avant la plus precoce des echeances
// possibles, jamais apres.
//
// DE COMBIEN ON PART EN AVANCE : le temps de la traversee, mesure en jeu -
// SEIZE secondes pour les 133 yards qui separent les deux marques.
//
// Et c'est bien le temps de trajet qu'il faut mettre ici, pas une marge de
// confort. Une avance de cinq secondes sur un trajet de seize ferait arriver
// le raid onze secondes APRES l'echange : il aurait paye cinq secondes de
// degats pour rien. Partir seize secondes avant le plancher, c'est arriver
// pile a la premiere echeance possible.
//
// Le prix est reel et il faut le savoir : les attaquants frappent de la
// teleportation a T+14, puis traversent. Quatorze secondes de degats par
// cycle, et jusqu'a dix de plus a attendre sur place quand l'echange tombe
// tard. C'est le marche, et il se change ici, sur une ligne.
// A QUELLE DISTANCE DE LA MARQUE LES ATTAQUANTS S'ARRETENT EN ATTENDANT.
//
// Ils traversent avant l'echange, mais ils ne vont PAS jusqu'au bout. Le
// script donne ses 2000 de menace au joueur LE PLUS PROCHE :
//
//     if (Unit* victim = me->SelectNearestTarget())
//     {
//         me->AddThreat(victim, 2000.f);
//         AttackStart(victim);
//     }
//
// Des attaquants postes sur la marque ou l'Empereur va atterrir les
// prendraient a la place du tank, qui attend la precisement pour ca. Toute la
// traversee serait faite pour saboter le poste qu'elle vient rejoindre.
//
// Trente-cinq yards, et la marge n'est pas decorative : le tank se tient a
// trois yards de sa marque, et la laisse laisse l'Empereur deriver de huit
// avant de le ramener - donc le tank peut etre a onze yards du point
// d'atterrissage dans le pire des cas. Les attaquants, eux, sont a vingt-sept
// au minimum. Le tank gagne toujours.
//
// Ce qui reste a parcourir apres l'echange - trente-cinq yards, cinq secondes -
// est le prix a payer pour que la menace aille au bon endroit.
constexpr float PRESWAP_STANDOFF = 35.0f;

constexpr uint32 TELEPORT_MIN_MS = 30000;
constexpr uint32 TELEPORT_LEAD_MS = 16000;

// ET MOINS D'AVANCE POUR LES ECHANGES SUIVANTS.
//
// Le premier echange tombe a EXACTEMENT trente secondes : la date est connue,
// et seize secondes d'avance y menent pile. Les suivants tombent entre trente
// et quarante, donc partir aussi tot ne sert qu'a attendre plus longtemps sur
// place - et attendre, c'est ne pas frapper.
//
// Onze secondes, et le chiffre vient du trajet reel : avec le point d'attente a
// trente-cinq yards de la marque, les attaquants ne parcourent plus 133 yards
// mais 98. A la vitesse mesuree en jeu - 8,3 yards par seconde, soit les 133
// yards en seize secondes - cela fait un peu moins de douze secondes. Partir
// onze secondes avant le plancher les y amene donc juste a temps, et leur rend
// cinq secondes de degats a chaque cycle.
constexpr uint32 TELEPORT_LEAD_NEXT_MS = 11000;

// ─── LES TROIS POSTES DE SOIN ────────────────────────────────────────────────
//
// Un soigneur par bout de salle, et un pour le milieu. Celui de gauche soigne
// qui tient la tete de mort de gauche, quel que soit l'Empereur qui s'y trouve
// a cet instant - et il n'a donc JAMAIS a traverser. C'est tout l'interet d'un
// poste fixe : la teleportation echange les boss, pas les marques.
//
// A trente yards de sa marque, vers le milieu. Deux contraintes le fixent : il
// faut rester au-dela des vingt-cinq yards qui l'ecartent des Empereurs - sinon
// l'echange lui offrirait ses 2000 de menace - et en deca des quarante yards
// d'un sort de soin, pour atteindre le tank qui, lui, est SUR la marque.
constexpr float HEALER_POST_OFFSET = 30.0f;

// Au-dela de cet ecart, un soigneur rejoint son poste. Large a dessein : se
// replacer, c'est ne pas soigner, et un soigneur qui corrige trois yards en
// permanence ne sert plus a rien.
constexpr float HEALER_POST_TOLERANCE = 8.0f;

// Pas de poste : ni tank, ni en groupe.
constexpr uint8 TANK_INDEX_NONE = 255;

class RaidAq40Utils
{
public:
    static Creature* GetVeklor(Player* bot);
    static Creature* GetVeknilash(Player* bot);

    // Vrai des qu'un des deux est en combat. UN SEUL SUFFIT : exiger les deux
    // coutait une seconde recherche en grille et rendait faux pour un bot trop
    // loin de l'autre bout de la salle, alors que le combat avait commence.
    static bool AreTwinsEngaged(Player* bot);

    // ─── LES ROLES ───────────────────────────────────────────────────────────

    // Les degats magiques ne touchent que Vek'lor, les physiques que
    // Vek'nilash. Les soigneurs sont exclus de toute assignation : ils suivent
    // le raid et soignent, et les pousser quelque part ne ferait que les couper
    // de ce qu'ils doivent voir.
    static bool IsSpellDamageDealer(Player* bot);
    static bool IsPhysicalDamageDealer(Player* bot);

    // Le jumeau que ce bot peut blesser, et celui dont il doit s'ecarter.
    //
    // Pour un SOIGNEUR, "interdit" vaut les DEUX : il n'attaque personne, mais
    // il ne doit etre le plus proche d'aucun des deux quand l'echange distribue
    // ses 2000 de menace. GetForbiddenTwin lui rend donc le plus proche.
    static Unit* GetAssignedTwin(Player* bot);
    static Unit* GetForbiddenTwin(Player* bot);

    // L'ECART QUE CE BOT DOIT GARDER avec le jumeau qui lui est interdit. Ce
    // n'est pas la meme chose pour un corps-a-corps, un lanceur de sorts et un
    // soigneur, et c'est la seule question que pose la regle d'ecartement.
    static float GetStayAwayRange(Player* bot);

    // CET EMPEREUR EST-IL ARRIVE OU IL DOIT ETRE ? C'est ce qui libere les
    // degats du raid : tant qu'il est en chemin, le frapper le ferait se
    // retourner sur celui qui frappe, et le placement serait perdu.
    static bool IsTwinPlaced(Unit* jumeau);

    // CET EMPEREUR DOIT-IL ETRE AMENE SUR SA MARQUE ? Plus exigeant que
    // IsTwinPlaced, qui tolere trente yards parce qu'il juge un boss en train
    // d'etre traine. Ici on pose, donc on pose juste.
    static bool NeedsMoving(Creature* jumeau, float tolerance = MARK_TOLERANCE);

    // La marque ou cet Empereur doit se tenir : celle de son cote.
    static bool GetTwinMark(Creature* jumeau, Position& out);

    // Le rang de ce bot parmi les bots TANKS du groupe, par ordre de GUID - un
    // ordre qui ne change jamais, et c'est tout ce qu'on lui demande. Le rang 2
    // prend les bestioles; tous les autres vont sur Vek'nilash.
    //
    // Le role TENU, pas la specialisation : celui qui tiendra un Empereur est
    // celui qui tourne avec la strategie de tank. C'est aussi la reponse qui ne
    // coute rien, et elle est demandee pour chaque membre du groupe.
    static uint8 TankIndex(Player* bot);

    // Le rang de ce bot parmi les SOIGNEURS bots du groupe, meme principe que
    // TankIndex : par ordre de GUID, un ordre qui ne change jamais.
    //
    // Rang 0 a gauche, rang 1 a droite, rang 2 au milieu avec le tank des
    // bestioles. Au-dela, pas de poste : ils suivent le raid et soignent ou ils
    // peuvent, ce qui est deja ce qu'un raid fait de ses soigneurs en surnombre.
    static uint8 HealerIndex(Player* bot);

    // Tous les tanks sauf le rang 2.
    static bool IsVeknilashTank(Player* bot);

    // Le rang 2, et seulement s'il existe (il faut donc au moins trois tanks).
    static bool IsBugTank(Player* bot);

    // Celui qui tient Vek'lor, et ce n'est pas un tank : demoniste d'abord,
    // sinon le premier lanceur de sorts par GUID.
    static bool IsVeklorHolder(Player* bot);

    // ─── LES PLACES ──────────────────────────────────────────────────────────

    // Les deux marques, dans l'ordre. QUI EST DE QUEL COTE, releve dans le
    // journal du run - les Empereurs poussent en
    //
    //     Vek'lor     (-8868.3, 1206.0, -104.2)
    //     Vek'nilash  (-9023.7, 1176.2, -104.2)
    //
    // ce qui met MARQUE_A a 82 yards de la plateforme de VEK'LOR (168 de
    // l'autre) et MARQUE_B a 84 de celle de VEK'NILASH (166 de l'autre).
    //
    // C'etait ecrit a l'envers ici, et ca se voyait en jeu : les corps-a-corps
    // partaient se poster dans le dos de Vek'lor, qui est immunise a ce qu'ils
    // font, et les lanceurs de sorts sous les Uppercuts de Vek'nilash.
    static void GetMarks(Position& marqueA, Position& marqueB);

    // La marque la plus proche d'un Empereur donne. PERSONNE NE SE PLACE SUR
    // UNE LETTRE : on se place du cote de celui qu'on vient voir, et c'est sa
    // position a lui qui repond. Une lettre, ca peut etre faux; une distance,
    // non.
    static bool GetMarkNear(Unit* jumeau, Position& out);

    // LA MARQUE DE CE TANK, et elle ne change JAMAIS.
    //
    // Rang 0 a gauche, rang 1 a droite, et chacun garde son bout de salle pour
    // tout le combat. C'est le guide qui le dit, et c'est la clef de l'echange :
    //
    //     "le tank guerrier pourra se deplacer le long du mur derriere lui.
    //      Ce sera proche de l'endroit ou le guerrier tankera APRES la
    //      teleportation."
    //
    // Celui qui a Vek'nilash de son cote le tient; l'autre attend sur sa marque
    // que l'echange le lui amene. Les faire traverser la salle a chaque fois
    // couterait 133 yards de course et l'aggro avec.
    //
    // Les tanks en SURNOMBRE (rang 3 et au-dela) n'ont pas de marque a eux :
    // ils vont preter main-forte sur Vek'nilash, ou qu'il soit.
    static bool GetMyMark(Player* bot, Position& out);

    // QUEL EMPEREUR A CE BOT POUR VICTIME, s'il y en a un.
    //
    // La question se pose pour TOUT LE MONDE, pas seulement les tanks :
    // l'echange remet les menaces a zero et offre 2000 au joueur le PLUS
    // PROCHE, qui peut tres bien etre un soigneur ou un voleur. Celui-la tient
    // un Empereur qu'il n'a pas demande, et il doit savoir ou l'emmener - sinon
    // il le promene au hasard, et le hasard, c'est vers le frere.
    static Unit* GetTwinOnMe(Player* bot);

    // Vek'nilash est-il du cote de ce tank ? C'est ce qui decide, a chaque
    // instant, s'il tient ou s'il attend. Pas d'etat a conserver : la geometrie
    // repond, et elle bascule d'elle-meme a l'echange.
    static bool IsVeknilashOnMySide(Player* bot);

    // OU SE TIENT CELUI QUI TIENT VEK'LOR : la marque du cote de Vek'lor,
    // decalee vers le milieu. Sa position decide celle de Vek'lor, qui s'arrete
    // a 45 yards de sa cible.
    //
    //     "Il est essentiel que le Demoniste soit vigilant et RECULE
    //      legerement. S'il ne reagit pas assez rapidement, Vek'lor lancera son
    //      Jaillissement des arcanes sur le Demo Tank."
    static bool GetVeklorStation(Player* bot, Position& out);

    // Le milieu des deux marques : la ou tombent les bestioles et ou se
    // tiennent les soigneurs.
    static void GetMiddle(Position& out);

    // CE BOT EST-IL DANS LA SALLE DES EMPEREURS ? Une distance au milieu, donc
    // aucune recherche en grille. C'est le verrou d'arrivee de la mise en
    // place : voir TWINS_ROOM_RANGE.
    static bool IsInTwinsRoom(Player* bot);


    // Ou ce bot doit se tenir AVANT le pull, selon son role. Faux pour les
    // soigneurs, qui ne sont pas places.
    static bool GetPrePullStation(Player* bot, Position& out);

    // OU IL SE TIENDRA APRES LA PROCHAINE TELEPORTATION. Rien a deviner :
    // l'echange permute les deux Empereurs, donc celui qu'on peut blesser sera
    // exactement la ou se tient l'autre. Faux pour tous ceux qui ne sont pas un
    // attaquant - les trois postes gardent leur bout de salle, les soigneurs
    // suivent le raid.
    static bool GetSwapStation(Player* bot, Position& out);

    // L'autre des deux marques, et la place calculee sur une marque donnee.
    static bool GetOtherMark(Position const& marque, Position& out);
    static bool GetStationAt(Player* bot, Position const& marque, Position& out);

    // D'OU CE BOT VA ACCROCHER SON EMPEREUR. Faux pour tous ceux qui ne pullent
    // pas - c'est-a-dire tout le monde sauf les tanks de Vek'nilash et celui
    // qui tient Vek'lor.
    static bool GetPullStation(Player* bot, Position& out);

    // Vrai quand chaque tank qui a une place s'y trouve. C'est la condition du
    // pull : tant qu'elle est fausse, les tanks deja arrives retiennent.
    static bool AllTanksPosted(Player* bot);

    // ─── LES BESTIOLES ───────────────────────────────────────────────────────
    //
    // Vek'lor lance Explode Bug (804) toutes les 4,5 a 10 secondes et
    // Vek'nilash Mutate Bug (802) toutes les 10 a 20 : chaque incantation
    // retourne UNE bestiole de la salle - le script du sort fait
    // RandomResize(targets, 1) - qui passe hostile et entre en combat avec la
    // zone. Sans menace sur personne, elle part vers qui lui en donne, et c'est
    // le soigneur : chaque sort de soin en fabrique sur tout ce qui est en
    // combat avec lui.

    // Une bestiole reveillee est en melee sur ce bot precisement. Reveillee se
    // lit sur le COMBAT, jamais sur la faction : le script du sort fait
    // SetInCombatWithZone() sur celle qu'il retourne.
    static bool IsBugOnMe(Player* bot);

    // La plus urgente : celle qui mange un soigneur, puis celle qui mange
    // quelqu'un d'autre, puis la sienne ou celle qui n'a encore personne.
    static Unit* GetBugToTank(Player* bot);

    static float Separation(Unit* veklor, Unit* veknilash);
};

#endif
