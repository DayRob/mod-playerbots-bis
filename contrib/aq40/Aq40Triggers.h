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

// The twins are close enough to heal each other and this bot can do something
// about it - only a physical attacker can, because Vek'nilash is the twin that
// follows whoever it is hitting.
class Aq40TwinsDragApartTrigger : public Trigger
{
public:
    Aq40TwinsDragApartTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 twins too close together") {}
    bool IsActive() override;
};

// This bot is standing next to the twin it cannot hurt.
class Aq40TwinsKeepDistanceTrigger : public Trigger
{
public:
    Aq40TwinsKeepDistanceTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 twins wrong side") {}
    bool IsActive() override;
};

// This bot is standing between the two emperors, so its own twin is being
// pulled towards its brother instead of away from him.
class Aq40TwinsWrongSideTrigger : public Trigger
{
public:
    Aq40TwinsWrongSideTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 twins between the emperors") {}
    bool IsActive() override;
};

// This bot is hitting the twin that is immune to what it does.
class Aq40TwinsWrongTargetTrigger : public Trigger
{
public:
    Aq40TwinsWrongTargetTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 twins wrong target") {}
    bool IsActive() override;
};

// Les Jumeaux ne sont pas encore engages, le raid est dans la salle, et ce bot
// n'est pas a l'endroit d'ou il doit partir.
class Aq40PrePullTrigger : public Trigger
{
public:
    Aq40PrePullTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 not in place yet") {}
    bool IsActive() override;
};

// Tout le monde est a son poste et les Empereurs dorment encore : c'est le
// moment du pull, et il appartient aux deux tanks de postes.
class Aq40PullTogetherTrigger : public Trigger
{
public:
    Aq40PullTogetherTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 ready to pull") {}
    bool IsActive() override;
};

// Ce bot a un piedestal a tenir et le combat a commence. Toujours vrai pour les
// rangs 0 et 1 pendant le combat : c'est l'action qui juge s'il y a quelque
// chose a faire, et elle rend faux des que le poste est tenu - l'IA de classe
// reprend alors la main pour frapper et encaisser.
class Aq40TankAnchorTrigger : public Trigger
{
public:
    Aq40TankAnchorTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 tank off his pedestal") {}
    bool IsActive() override;
};

// Une bestiole reveillee traine, et ce bot est celui dont c'est le travail.
class Aq40TankTheBugsTrigger : public Trigger
{
public:
    Aq40TankTheBugsTrigger(PlayerbotAI* botAI) : Trigger(botAI, "aq40 bugs on the raid") {}
    bool IsActive() override;
};

#endif
