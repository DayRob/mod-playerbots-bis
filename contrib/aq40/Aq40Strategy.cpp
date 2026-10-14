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
    // Order matters. The tanks' posts come first - a post held is what keeps the
    // two emperors apart in the first place. Then, for everyone else: getting off
    // the wrong emperor, because standing there is what gets bots knocked around
    // and killed; pulling the two of them apart, because Heal Brother is what
    // loses the fight; and picking the right target last, which is also what the
    // others fall back on once the positioning is settled.

    // LES POSTES D'ABORD, ET ILS PRIMENT SUR TOUT LE RESTE.
    //
    // Les deux Empereurs apparaissent chacun sur son piedestal, a 158 yards
    // l'un de l'autre. Les y GARDER vaut mieux que les separer une fois qu'ils
    // se sont rejoints : un tank par socle, chacun tient le jumeau qu'on lui a
    // confie et le ramene chez lui, et Heal Brother - qui demande moins de
    // 60 yards - ne part jamais. Twin Teleport les echange toutes les 30 a 40
    // secondes en remettant les menaces a zero; le tank est deja sur place,
    // donc il recupere celui qui arrive au lieu de courir apres.
    //
    // Le troisieme tank prend les bestioles du milieu. Elles se reveillent une
    // par une, toutes les quelques secondes, et vont vers les soigneurs - c'est
    // le soin lui-meme qui leur donne la menace.
    triggers.push_back(
        new TriggerNode("aq40 tank off his pedestal",
            { NextAction("aq40 tank hold your pedestal", ACTION_RAID + 4.0f) }));

    triggers.push_back(
        new TriggerNode("aq40 bugs on the raid",
            { NextAction("aq40 tank the bugs", ACTION_RAID + 3.0f) }));

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
