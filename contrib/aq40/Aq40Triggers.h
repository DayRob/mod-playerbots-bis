/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef PLAYERBOTS_AQ40TRIGGERS_H
#define PLAYERBOTS_AQ40TRIGGERS_H

#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "Trigger.h"

// Ce bot a pris pour cible un PNJ QUI NE NOUS ATTAQUE PAS - barre de vie jaune
// dans le client, pas rouge.
//
// Les scarabees et scorpions du temple en sont, et ils sont la raison d'etre de
// cette regle, mais elle ne les nomme pas : elle vaut pour tout ce qui est
// neutre dans le Temple d'Ahn'Qiraj. Nommer des entrees, c'etait se tromper a
// la premiere creature oubliee.
//
// POURQUOI C'EST LA PREMIERE REGLE DE LA CARTE. Le script du coeur de ces
// bestioles (npc_ahnqiraji_critter) dit :
//
//     if (Player* player = me->SelectNearestPlayer(10.f))
//         if (player->IsInCombat())
//             AttackStart(player);
//     context.Repeat(3500ms, 4s);
//
// Toutes les quatre secondes, chacune cherche un joueur EN COMBAT a moins de
// dix yards et lui saute dessus. Un seul bot qui engage quoi que ce soit dans
// la salle, et tout ce qui traine a dix yards d'un combattant rejoint - puis
// a dix yards de ceux-la, et ainsi de suite. Releve en jeu : six bots en
// combat, puis dix-huit empiles sur des scarabes qui n'avaient pas bouge.
//
// Donc on ne frappe jamais le premier. Ce qui nous attaque, en revanche, se
// tue : la regle rend la main des que la cible mange quelqu'un du groupe.
class Aq40NeutralTargetTrigger : public Trigger
{
public:
    Aq40NeutralTargetTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 target not hostile") {}
    bool IsActive() override;
};

// TOUT LE MONDE EST EN PLACE ET LES EMPEREURS NE LE SONT PAS.
//
// On ne va plus les chercher : on les AMENE. Les deux poussent en haut
// d'escaliers, et le maillage de navigation n'y mene pas de facon fiable - un
// chemin incomplet est accepte par playerbots (PATHFIND_INCOMPLETE), donc le
// bot avance aussi loin qu'il peut et s'arrete, toujours au meme endroit, quel
// que soit le code qui lui a donne la destination. Vu trois fois en jeu, le
// pulleur en bas des marches et le boss en haut.
//
// Un seul bot s'en charge - le tank de rang 0 - sinon quarante bots
// repositionneraient les Empereurs a chaque tick. Et jamais en combat : hors
// combat, un Empereur deplace reste ou on le met.
class Aq40SetTheStageTrigger : public Trigger
{
public:
    Aq40SetTheStageTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 twins not on their marks") {}
    bool IsActive() override;
};

// Le raid est dans la salle, les Empereurs dorment encore, et ce bot n'est pas
// a l'endroit d'ou il doit partir.
class Aq40TakeStationTrigger : public Trigger
{
public:
    Aq40TakeStationTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 not in place yet") {}
    bool IsActive() override;

private:
    // Le raid est-il ARRIVE ? Pose une fois qu'un Empereur est a portee, remis
    // a faux au combat. Sans ce verrou la mise en place demarrait en plein
    // trajet et sortait le tank du chemin que mod-dungeon-clear suivait.
    bool _arrive = false;
};

// Tout le monde est en place et les Empereurs dorment : c'est le moment du
// pull, et il appartient aux tanks et a celui qui tient Vek'lor.
class Aq40PullTogetherTrigger : public Trigger
{
public:
    Aq40PullTogetherTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 ready to pull") {}
    bool IsActive() override;

private:
    // CE BOT EST PARTI, ET IL FINIT SON TRAJET.
    //
    // Sans ce verrou, le premier coup porte par n'importe quel pulleur eteint
    // la regle pour tous les autres : le script envoie le second Empereur sur
    // celui qui a engage le premier, donc les deux passent "engages" au MEME
    // instant, alors que le tank d'en face a encore soixante yards a parcourir.
    // Il s'arretait la ou il en etait. Vu en jeu : le demoniste pulle, le
    // guerrier qui faisait le chemin en parallele se fige.
    //
    // Il ne se releve qu'au combat - celui de CE bot - ou si son Empereur
    // disparait.
    bool _parti = false;

    // DEPUIS QUAND CE PULLEUR EST-IL PRET. Sans cette sortie, un seul tank qui
    // n'arrive pas a son poste - bloque, assis, mort, ou simplement en
    // surnombre sur un point deja occupe - gele le raid pour toujours : la
    // retenue de la mise en place expire au bout de vingt secondes et rend la
    // main, mais le pull, lui, attendait une condition qui ne devenait jamais
    // vraie. Personne ne retenait plus rien et personne ne partait.
    uint32 _pretDepuis = 0;
};

// Un tank, pendant le combat. L'action decide s'il tient Vek'nilash ou s'il
// attend l'echange sur sa marque - c'est la geometrie qui tranche, et elle
// bascule d'elle-meme toutes les trente a quarante secondes.
class Aq40TankTrigger : public Trigger
{
public:
    Aq40TankTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 tank off his mark") {}
    bool IsActive() override;
};

// Celui qui tient Vek'lor, pendant le combat.
class Aq40VeklorHolderTrigger : public Trigger
{
public:
    Aq40VeklorHolderTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 veklor adrift") {}
    bool IsActive() override;
};

// Le tank des bestioles, pendant le combat. Un poste, pas une reaction : entre
// deux bestioles il tient le milieu, la ou elles tombent et ou se tiennent les
// soigneurs.
class Aq40BugTankTrigger : public Trigger
{
public:
    Aq40BugTankTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 bugs on the raid") {}
    bool IsActive() override;
};

// UN CHASSEUR A ENCORE SON FAMILIER DANS LA SALLE DES JUMEAUX.
//
// Un familier de chasseur connait Grondement, qui est une PROVOCATION, et il la
// lance tout seul. Il arrache donc un Empereur a son tank sans prevenir, le
// tourne vers lui, et le promene le temps que le tank reprenne - c'est-a-dire
// le temps qu'il faut pour que les deux freres se retrouvent a portee de soin.
// Il entre aussi dans la table de menace, ce qui fausse tout ce que le raid
// croit savoir de qui tient quoi.
//
// On le renvoie, et seulement ici : ailleurs dans le temple un familier est un
// atout, et le chasseur le rappellera de lui-meme une fois sorti.
class Aq40HunterPetTrigger : public Trigger
{
public:
    Aq40HunterPetTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 hunter pet is out") {}
    bool IsActive() override;
};

// UN EMPEREUR A CE BOT POUR VICTIME, et ce bot n'est pas un des trois postes.
//
// Ca arrive a n'importe qui, et c'est prevu par le script : l'echange remet les
// menaces a zero, puis
//
//     if (Unit* victim = me->SelectNearestTarget())
//     {
//         me->AddThreat(victim, 2000.f);
//         AttackStart(victim);
//     }
//
// Les 2000 vont au joueur LE PLUS PROCHE - un soigneur, un voleur, n'importe
// qui. Celui-la tient un Empereur qu'il n'a pas demande. Sans consigne il le
// promene au hasard, et le hasard le ramene vers son frere.
//
// Il a donc la meme consigne qu'un tank, parce que c'est ce qu'il est devenu
// pour les trente secondes qui viennent : emmener ce qu'il tient sur la marque
// du cote ou il se trouve, et l'y garder jusqu'a ce qu'un vrai tank le reprenne.
class Aq40DraggingTwinTrigger : public Trigger
{
public:
    Aq40DraggingTwinTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 a twin is on me") {}
    bool IsActive() override;
};

// LA PROCHAINE TELEPORTATION APPROCHE : ON PART AVANT.
//
// Ce n'est pas une devinette. Le script du coeur dit :
//
//     .Schedule(30s, [this](TaskContext context)
//     {
//         DoCastSelf(SPELL_TWIN_TELEPORT_0);
//         context.Repeat(30s, 40s);
//     })
//
// La premiere tombe a exactement trente secondes, les suivantes entre trente et
// quarante. Trente est donc le PLANCHER, et c'est la seule date sur laquelle on
// puisse s'appuyer sans jamais se tromper dans le mauvais sens : partir seize
// secondes avant elle - le temps de la traversee, mesure en jeu - c'est arriver
// pile a la plus precoce des echeances possibles.
//
// LE DECLENCHEUR SE SOUVIENT, et c'est tout ce qu'il memorise : la date du
// dernier echange, reperee a la bascule de Vek'nilash d'une marque a l'autre.
// Pas besoin de guetter un sort : l'echange, c'est deux Empereurs qui
// permutent, et ca se lit sur leurs positions.
class Aq40AnticipateTrigger : public Trigger
{
public:
    Aq40AnticipateTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 teleport is coming") {}
    bool IsActive() override;

private:
    bool _arme = false;        // la minuterie a-t-elle demarre
    bool _coteA = false;       // Vek'nilash etait-il du cote de la marque A
    bool _echangeVu = false;   // en a-t-on deja vu un passer
    uint32 _dernierEchange = 0;
};

// CE BOT EST DU MAUVAIS COTE DE LA SALLE, et il traverse.
//
// Apres chaque teleportation, les corps-a-corps se retrouvent du cote de
// Vek'lor - immunise au physique - et les lanceurs de sorts du cote de
// Vek'nilash, dont ils prennent les Uppercuts. Les deux groupes doivent
// echanger de bout de salle.
//
// POURQUOI C'EST UNE REGLE A ELLE SEULE, ET PAS UN EFFET DE BORD D'UNE AUTRE.
// La traversee etait portee par la retenue des degats, qui s'arrete au bout de
// vingt secondes - or traverser 133 yards en prend dix-neuf. Au moindre retard
// la retenue expirait en cours de route et le bot retombait sous les regles du
// dessous : l'ecartement le repoussait d'un petit saut, il retombait a portee,
// se faisait repousser encore. Sur place, a tourner, sans jamais partir.
//
// Elle n'a donc ni minuterie ni condition de combat : elle est vraie tant que
// le jumeau INTERDIT est plus pres que le sien, et elle s'eteint quand le bot
// a passe le milieu. Rien d'autre ne peut l'interrompre, sauf un Empereur qui
// lui tombe dessus - et celui-la a sa propre consigne.
class Aq40WrongSideTrigger : public Trigger
{
public:
    Aq40WrongSideTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 on the wrong side") {}
    bool IsActive() override;
};

// UN SOIGNEUR LOIN DE SON POSTE, pendant le combat.
//
// Il en a un, maintenant : gauche, droite ou milieu. Et il n'en bouge pas de
// tout le combat - la teleportation echange les Empereurs, pas les marques,
// donc celui de gauche soigne qui tient la gauche, quel que soit le boss qui
// s'y trouve a cet instant.
//
// HUIT YARDS DE JEU, ET UNE PERTINENCE BASSE. Se replacer, c'est ne pas
// soigner : cette regle siege VOLONTAIREMENT sous les soins moyens et
// critiques, pour qu'un soigneur ne lache jamais un tank a terre pour aller
// corriger sa position.
class Aq40HealerPostTrigger : public Trigger
{
public:
    Aq40HealerPostTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 healer off his post") {}
    bool IsActive() override;
};

// Ce bot est colle au jumeau qu'il ne peut pas blesser. Pour un physique c'est
// Jaillissement des arcanes qui le repousse; pour un lanceur de sorts c'est
// l'Uppercut de Vek'nilash, qui frappe au hasard parmi ce qui est a sa portee.
class Aq40KeepAwayTrigger : public Trigger
{
public:
    Aq40KeepAwayTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 too close to the wrong twin") {}
    bool IsActive() override;
};

// L'Empereur de ce bot n'est pas encore arrive ou il doit etre, et le bot n'est
// ni tank ni celui qui le tient : il ne frappe pas.
//
// C'EST LA REGLE DU VRAI RAID. Un tank qui traine Vek'nilash sur soixante
// yards ne tient que par sa provocation; trente-cinq attaquants qui ouvrent
// pendant le trajet lui prennent la menace, l'Empereur se retourne sur eux, et
// le placement - donc l'ecart entre les deux freres, donc le combat - est
// perdu. On attend qu'il soit pose, puis tout le monde ouvre en meme temps.
//
// Les soigneurs n'en sont pas : ils soignent pendant le trajet, c'est meme la
// qu'on a le plus besoin d'eux.
class Aq40HoldFireTrigger : public Trigger
{
public:
    Aq40HoldFireTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 twin not placed yet") {}
    bool IsActive() override;

private:
    // Depuis quand ce bot retient ses coups. Remis a zero des que les deux
    // Empereurs sont poses, donc il repart a chaque teleportation.
    uint32 _retientDepuis = 0;
};

// Ce bot frappe le jumeau qui est immunise a ce qu'il fait.
class Aq40WrongTargetTrigger : public Trigger
{
public:
    Aq40WrongTargetTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 twins wrong target") {}
    bool IsActive() override;
};

#endif
