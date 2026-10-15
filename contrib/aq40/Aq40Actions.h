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

// S'ecarte du jumeau qu'il ne peut pas blesser.
// NE PAS FRAPPER tant que l'Empereur n'est pas pose, et lacher la cible qu'on
// avait deja prise.
//
// Lacher ne suffirait pas : l'IA de classe en reprendrait une au tick suivant.
// L'action rend donc VRAI, ce qui arrete la file au-dessus des regles
// d'attaque - c'est ce "vrai" qui retient le raid, pas le lacher lui-meme.
class Aq40HoldFireAction : public AttackAction
{
public:
    Aq40HoldFireAction(PlayerbotAI* botAI) : AttackAction(botAI, "aq40 hold your fire") {}
    bool Execute(Event event) override;
};

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
