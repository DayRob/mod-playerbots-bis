/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Strategy.h"
#include "Strategy.h"

void RaidAq40Strategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    // ═══ L'ORDRE, ET POURQUOI CELUI-LA ══════════════════════════════════════
    //
    // D'abord ce qui agit AVANT le pull - laisser les bestioles tranquilles,
    // se placer, puller - puis le combat. Les trois premieres regles sont les
    // seules qui bougent un bot avant que quoi que ce soit ait commence, donc
    // les seules qui puissent se disputer avec mod-dungeon-clear, qui a aussi
    // un avis sur ou le raid se tient et par ou il passe : elles ne repondent
    // vrai que quand le raid est ARRIVE (un Empereur a portee) et DANS la
    // salle. En chemin, elles se taisent.
    //
    // Les regles de combat, elles, repondent toutes faux tant qu'un Empereur
    // n'est pas en combat : elles ne deplacent personne, ne choisissent aucune
    // cible et ne bloquent aucune action en dehors du combat lui-meme.
    //
    // Pendant le combat, les trois postes passent avant les regles generales :
    // ils savent ou ils vont, les autres non. Et chacun d'eux se tait pour qui
    // n'est pas concerne, donc il n'y a jamais deux regles sur un meme bot.
    // ════════════════════════════════════════════════════════════════════════

    // 0. ON NE TOUCHE PAS AUX BESTIOLES QUI DORMENT, et c'est la premiere
    //    regle de la salle - avant le placement, avant le pull, avant tout.
    //
    //    Les scarabees et scorpions du temple ne mordent personne tant qu'un
    //    Empereur ne les a pas retournes : ils gardent leur faction de creature
    //    inoffensive, et c'est a ca qu'on les reconnait. Les attaquer met le
    //    bot en combat, donc l'ecarte de sa place, donc casse la mise en place -
    //    et reveille pour de bon ce que la salle avait laisse tranquille.
    //
    //    Elle ne vaut que DANS la salle : ailleurs dans le temple, ces memes
    //    bestioles sont du trash ordinaire que mod-dungeon-clear a raison de
    //    nettoyer, et lui interdire partout serait defaire un module qui fait
    //    son travail.
    triggers.push_back(
        new TriggerNode("aq40 chasing a critter",
            { NextAction("aq40 leave the critters", ACTION_RAID + 7.0f) }));

    // 1. SE PLACER, PUIS PULLER ENSEMBLE.
    //
    //    Le pull ne part que lorsque les tanks sont sur leurs marques, et les
    //    partants voient la condition devenir vraie au MEME tick, donc ils
    //    s'elancent ensemble. Ce n'est pas du confort : engager un Empereur
    //    envoie l'autre sur celui qui l'a engage -
    //
    //        if (Creature* twin = GetTwin())
    //            if (!twin->IsInCombat())
    //                twin->AI()->AttackStart(who);
    //
    //    - donc sans un lanceur de sorts sur Vek'lor au meme instant, les deux
    //    se rejoignent avant le premier coup et Heal Brother part des la
    //    premiere seconde. Vu dans le journal du run : Vek'lor engage le tank
    //    de Vek'nilash a 150 yards, puis marche 69 yards vers le raid.
    //
    //    Au-dessus des regles de combat, et pour une raison : tant qu'un bot
    //    marche vers sa place, rien d'autre ne doit l'en detourner.
    triggers.push_back(
        new TriggerNode("aq40 ready to pull",
            { NextAction("aq40 pull together", ACTION_RAID + 6.0f) }));

    triggers.push_back(
        new TriggerNode("aq40 not in place yet",
            { NextAction("aq40 take your station", ACTION_RAID + 5.0f) }));

    // 2. LES TANKS, un par bout de salle, et ils n'en changent jamais. Celui
    //    qui a Vek'nilash de son cote le tient et le ramene sur sa marque, dos
    //    au mur. L'autre attend sur la sienne, parce que l'echange lui amenera
    //    Vek'nilash dans trente secondes et que les 2000 de menace offerts vont
    //    au joueur le PLUS PROCHE.
    triggers.push_back(
        new TriggerNode("aq40 tank off his mark",
            { NextAction("aq40 tank your side", ACTION_RAID + 4.0f) }));

    // 3. CELUI QUI TIENT VEK'LOR, et ce n'est pas un tank : Vek'lor est
    //    immunise au physique comme a la provocation. Un demoniste le garde par
    //    les degats, et recule des que Vek'lor s'approche - sinon Jaillissement
    //    des arcanes le repousse et tout le placement part avec.
    triggers.push_back(
        new TriggerNode("aq40 veklor adrift",
            { NextAction("aq40 hold veklor", ACTION_RAID + 3.5f) }));

    // 4. LE TANK DES BESTIOLES tient le milieu, la ou elles se reveillent et ou
    //    se tiennent les soigneurs, et provoque celle qui en mange un.
    triggers.push_back(
        new TriggerNode("aq40 bugs on the raid",
            { NextAction("aq40 tank the bugs", ACTION_RAID + 3.0f) }));

    // 5. ET POUR TOUT LE RESTE DU RAID, deux regles seulement : ne pas rester
    //    colle au jumeau qu'on ne peut pas blesser, et frapper celui qu'on
    //    peut. Le reste du placement suit la cible toute seule.
    triggers.push_back(
        new TriggerNode("aq40 too close to the wrong twin",
            { NextAction("aq40 keep away", ACTION_RAID + 2.0f) }));

    triggers.push_back(
        new TriggerNode("aq40 twins wrong target",
            { NextAction("aq40 attack my twin", ACTION_RAID) }));
}
