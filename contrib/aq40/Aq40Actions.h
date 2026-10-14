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

// Walks Vek'nilash away from his brother. Vek'nilash follows whoever he is
// fighting, so the physical attackers back off a few yards at a time and he comes
// with them until the two of them are out of Heal Brother range.
class Aq40TwinsDragApartAction : public AttackAction
{
public:
    Aq40TwinsDragApartAction(PlayerbotAI* botAI, std::string const name = "aq40 twins drag apart")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// Steps out of the reach of the twin this bot cannot hurt.
class Aq40TwinsKeepDistanceAction : public MovementAction
{
public:
    Aq40TwinsKeepDistanceAction(PlayerbotAI* botAI, std::string const name = "aq40 twins keep distance")
        : MovementAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// Crosses to the far side of its own twin, so that twin faces away from its
// brother. This is the preventive half of the separation: a raid that stands
// between the emperors drags them together without anyone doing anything wrong.
class Aq40TwinsFarSideAction : public MovementAction
{
public:
    Aq40TwinsFarSideAction(PlayerbotAI* botAI, std::string const name = "aq40 twins cross over")
        : MovementAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// Switches onto the twin this bot can actually damage. Both emperors share their
// damage, so the half of the raid that picks the wrong one contributes nothing.
class Aq40TwinsAttackMyTwinAction : public AttackAction
{
public:
    Aq40TwinsAttackMyTwinAction(PlayerbotAI* botAI, std::string const name = "aq40 twins attack my twin")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// Rejoint l'endroit d'ou ce bot doit partir, avant que le combat commence - et,
// pour un tank, RETIENT le pull tant que les trois postes ne sont pas tenus.
//
// Le maintien ne consiste pas a empecher quoi que ce soit : il suffit de rendre
// vrai. Cette regle siege bien au-dessus de la bande de dungeon-clear, donc tant
// qu'elle agit, l'action d'engagement du module de donjon n'est pas atteinte, et
// le pull attend. Des que tout le monde est en place, elle rend faux et le pull
// part - sans commande, sans pause a reprendre.
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
    // aussi longtemps que le bot - le contexte le garde une fois cree - donc
    // cette date traverse les ticks.
    uint32 _retientDepuis = 0;
};

// Tient son piedestal, et le jumeau qui va avec.
//
// Trois gestes, dans cet ordre : provoquer quand le jumeau confie regarde
// ailleurs, aller le chercher quand il est trop loin pour ca, et sinon rentrer
// sur son socle - le jumeau suit, et c'est comme ca que les deux Empereurs
// reviennent chacun sur le sien.
class Aq40TankAnchorAction : public AttackAction
{
public:
    Aq40TankAnchorAction(PlayerbotAI* botAI, std::string const name = "aq40 tank hold your pedestal")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

// Arrache au soigneur la bestiole que Mutate Bug ou Explode Bug vient de
// reveiller. La provocation d'abord : le soin fabrique de la menace a chaque
// sort, donc attendre d'en produire par les degats laisse le soigneur se faire
// mordre plusieurs secondes de plus.
class Aq40TankTheBugsAction : public AttackAction
{
public:
    Aq40TankTheBugsAction(PlayerbotAI* botAI, std::string const name = "aq40 tank the bugs")
        : AttackAction(botAI, name)
    {
    }

    bool Execute(Event event) override;
};

#endif
