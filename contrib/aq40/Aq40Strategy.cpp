/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Strategy.h"
#include "Strategy.h"

void RaidAq40Strategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    // Every trigger below answers false until a twin is in combat, so nothing
    // in this folder moves a bot, picks a target or blocks an action before the
    // pull. Outside the fight itself, the bots stay entirely under whatever
    // else drives them.
    //
    // Order matters. Getting off the wrong emperor comes first because standing
    // there is what gets bots knocked around and killed; pulling the two of them
    // apart comes next because Heal Brother is what loses the fight; picking the
    // right target is last, and it is also what the other two fall back on once
    // the positioning is settled.
    triggers.push_back(
        new TriggerNode("aq40 twins wrong side",
            { NextAction("aq40 twins keep distance", ACTION_RAID + 2.0f) }));

    triggers.push_back(
        new TriggerNode("aq40 twins too close together",
            { NextAction("aq40 twins drag apart", ACTION_RAID + 1.0f) }));

    // La moitie PREVENTIVE de la separation, et elle vaut tout le temps : un
    // raid qui se tient entre les deux Empereurs les fait converger sans que
    // personne fasse de faute. Apres chaque teleportation, les deux groupes se
    // retrouvent du mauvais cote d'un seul coup - c'est cette regle qui les
    // renvoie, au tick suivant, sans attendre que la separation soit perdue.
    triggers.push_back(
        new TriggerNode("aq40 twins between the emperors",
            { NextAction("aq40 twins cross over", ACTION_RAID + 0.5f) }));

    triggers.push_back(
        new TriggerNode("aq40 twins wrong target",
            { NextAction("aq40 twins attack my twin", ACTION_RAID) }));
}
