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
