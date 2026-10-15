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

// Ce bot a pris pour cible une bestiole de la salle QUI DORT.
//
// Les scarabees et scorpions de la salle ne mordent personne tant qu'un
// Empereur ne les a pas retournes, et ils ne sont PAS EN COMBAT : c'est a ca
// qu'on les reconnait. Les attaquer met le bot en combat, donc l'ecarte de sa
// place, donc casse la mise en place - et en fait reveille pour de bon ce que
// la salle avait laisse tranquille.
class Aq40ChasingCritterTrigger : public Trigger
{
public:
    Aq40ChasingCritterTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 chasing a critter") {}
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

// Ce bot est colle au jumeau qu'il ne peut pas blesser. Pour un physique c'est
// Jaillissement des arcanes qui le repousse; pour un lanceur de sorts c'est
// l'Uppercut de Vek'nilash, qui frappe au hasard parmi ce qui est a sa portee.
class Aq40KeepAwayTrigger : public Trigger
{
public:
    Aq40KeepAwayTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 too close to the wrong twin") {}
    bool IsActive() override;
};

// Ce bot frappe le jumeau qui est immunise a ce qu'il fait.
class Aq40WrongTargetTrigger : public Trigger
{
public:
    Aq40WrongTargetTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 twins wrong target") {}
    bool IsActive() override;
};

#endif
