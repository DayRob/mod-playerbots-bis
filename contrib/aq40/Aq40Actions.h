/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef PLAYERBOTS_AQ40ACTIONS_H
#define PLAYERBOTS_AQ40ACTIONS_H

#include "AttackAction.h"
#include "MovementActions.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"

// Lache la bestiole endormie et cesse de la frapper.
//
// Rien d'autre : pas de nouvelle cible imposee. Ce que le bot doit faire a la
// place, ce sont les autres regles qui le disent - sa place avant le pull, son
// Empereur pendant le combat.
class Aq40LeaveNeutralAction : public AttackAction
{
public:
    Aq40LeaveNeutralAction(PlayerbotAI* botAI, std::string const name = "aq40 leave what is not hostile")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// AMENE LES DEUX EMPEREURS SUR LEURS MARQUES, hors combat, avant le pull.
//
// Pourquoi on les deplace au lieu d'aller les chercher : ils poussent en haut
// d'escaliers que le maillage de navigation ne relie pas de facon fiable au sol
// de la salle. playerbots accepte les chemins incomplets -
//
//     int typeOk = PATHFIND_NORMAL | PATHFIND_INCOMPLETE;
//
// - donc un bot envoye la-haut avance aussi loin qu'il peut et s'arrete,
// toujours au meme endroit. Trois essais en jeu, trois fois le meme pulleur en
// bas des marches et le meme boss en haut.
//
// On change aussi leur point d'ancrage : sans ca, le premier evade les
// ramenerait sur leur plateforme et tout serait a refaire.
class Aq40SetTheStageAction : public Action
{
public:
    Aq40SetTheStageAction(PlayerbotAI* botAI) : Action(botAI, "aq40 put the twins on their marks") {}
    bool Execute(Event event) override;
};

// Rejoint l'endroit d'ou ce bot doit partir, avant que le combat commence - et,
// pour un tank, RETIENT le pull tant que les autres marchent encore.
//
// Le maintien ne consiste pas a empecher quoi que ce soit : il suffit de rendre
// vrai. Cette regle siege bien au-dessus de la bande de pertinence de
// mod-dungeon-clear, donc tant qu'elle agit son action d'engagement n'est pas
// atteinte. Des que tout le monde est en place elle rend faux, et le pull part.
class Aq40TakeStationAction : public MovementAction
{
public:
    Aq40TakeStationAction(PlayerbotAI* botAI, std::string const name = "aq40 take your station")
        : MovementAction(botAI, name)
    {
    }

    bool Execute(Event event) override;

private:
    // Depuis quand ce bot retient. Zero tant qu'il marche encore. L'objet vit
    // aussi longtemps que le bot, donc cette date traverse les ticks.
    uint32 _retientDepuis = 0;
};

// Part chercher son Empereur, en meme temps que les autres partants.
class Aq40PullTogetherAction : public AttackAction
{
public:
    Aq40PullTogetherAction(PlayerbotAI* botAI, std::string const name = "aq40 pull together")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// LE TANK, ET SES DEUX ETATS.
//
// Vek'nilash de mon cote : je le tiens. Cible, provocation des qu'il regarde
// ailleurs, et je le ramene sur ma marque - dos au mur, pour que l'Uppercut ne
// me sorte pas de position.
//
// Vek'lor de mon cote : je ne le touche pas. Immunise au physique ET a la
// provocation, aucun tank n'a de prise sur lui. J'attends sur ma marque, parce
// que dans trente secondes c'est Vek'nilash qui arrivera ici - et le script
// donne ses 2000 de menace au joueur LE PLUS PROCHE.
class Aq40TankAction : public AttackAction
{
public:
    Aq40TankAction(PlayerbotAI* botAI, std::string const name = "aq40 tank your side")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// Celui qui tient Vek'lor : il le garde par les degats, et il RECULE quand
// Vek'lor s'approche trop - sinon Jaillissement des arcanes le repousse et tout
// le placement part avec.
class Aq40HoldVeklorAction : public AttackAction
{
public:
    Aq40HoldVeklorAction(PlayerbotAI* botAI, std::string const name = "aq40 hold veklor")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// Arrache au soigneur la bestiole que Mutate Bug ou Explode Bug vient de
// reveiller, et tient le milieu entre deux.
class Aq40BugTankAction : public AttackAction
{
public:
    Aq40BugTankAction(PlayerbotAI* botAI, std::string const name = "aq40 tank the bugs")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// NE PAS FRAPPER tant que l'Empereur n'est pas pose - ET EN PROFITER POUR
// CHANGER DE COTE.
//
// Lacher la cible ne suffirait pas : l'IA de classe en reprendrait une au tick
// suivant. L'action rend donc VRAI, ce qui arrete la file au-dessus des regles
// d'attaque - c'est ce "vrai" qui retient le raid, pas le lacher lui-meme.
//
// Mais retenir ses coups ne veut pas dire rester plante. La teleportation
// echange les deux Empereurs : les corps-a-corps se retrouvent du cote de
// Vek'lor, qu'ils ne peuvent pas blesser, et les lanceurs de sorts du cote de
// Vek'nilash, dont ils prennent les Uppercuts. Le temps que les tanks
// replacent les boss est exactement celui qu'il faut au raid pour traverser,
// et c'est ce que fait un vrai raid : on ne tape pas, on se deplace.
class Aq40HoldFireAction : public MovementAction
{
public:
    Aq40HoldFireAction(PlayerbotAI* botAI) : MovementAction(botAI, "aq40 hold your fire") {}
    bool Execute(Event event) override;
};

// EMMENE SUR SA MARQUE L'EMPEREUR QU'ON A SUR LE DOS.
//
// La meme consigne qu'un tank, pour quelqu'un qui n'en est pas un : il l'est
// devenu, le temps que l'echange lui a donne. On vise la marque du cote ou se
// trouve l'Empereur, jamais l'autre - traverser la salle avec lui, ce serait
// l'amener a son frere.
class Aq40DragToMarkAction : public MovementAction
{
public:
    Aq40DragToMarkAction(PlayerbotAI* botAI) : MovementAction(botAI, "aq40 take him to the mark") {}
    bool Execute(Event event) override;
};

// RENVOIE LE FAMILIER DU CHASSEUR, le temps de la salle.
class Aq40DismissPetAction : public Action
{
public:
    Aq40DismissPetAction(PlayerbotAI* botAI) : Action(botAI, "aq40 dismiss your pet") {}
    bool Execute(Event event) override;
};

// PART A L'AVANCE VERS LA PLACE QU'ON OCCUPERA APRES LA TELEPORTATION.
//
// Rien a deviner sur la destination : l'echange permute les deux Empereurs,
// donc celui qu'on peut blesser sera exactement la ou se tient l'autre. On va
// l'y attendre.
class Aq40PreSwapAction : public MovementAction
{
public:
    Aq40PreSwapAction(PlayerbotAI* botAI) : MovementAction(botAI, "aq40 go where he will be") {}
    bool Execute(Event event) override;
};

// TRAVERSE LA SALLE, et ne fait que ca jusqu'a ce que ce soit fini.
//
// Pas de cible a reprendre, pas de coup a porter, pas d'ecart a corriger : un
// bot du mauvais cote n'a qu'une chose utile a faire, et c'est marcher. Tout
// le reste - frapper, s'ecarter, changer de cible - redeviendra vrai tout seul
// une fois qu'il sera arrive, et sera alors juste du premier coup.
class Aq40CrossOverAction : public MovementAction
{
public:
    Aq40CrossOverAction(PlayerbotAI* botAI) : MovementAction(botAI, "aq40 cross the room") {}
    bool Execute(Event event) override;
};

// S'ecarte du jumeau qu'il ne peut pas blesser.
class Aq40KeepAwayAction : public MovementAction
{
public:
    Aq40KeepAwayAction(PlayerbotAI* botAI, std::string const name = "aq40 keep away")
        : MovementAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// Bascule sur le jumeau qu'il peut vraiment blesser.
class Aq40AttackMyTwinAction : public AttackAction
{
public:
    Aq40AttackMyTwinAction(PlayerbotAI* botAI, std::string const name = "aq40 attack my twin")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

#endif
