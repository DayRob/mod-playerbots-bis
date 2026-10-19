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

    // 0. ON NE FRAPPE JAMAIS LE PREMIER sur ce qui ne nous attaque pas - barre
    //    de vie jaune, pas rouge. C'est la premiere regle de la carte, avant le
    //    placement, avant le pull, avant tout.
    //
    //    Le script du coeur des bestioles du temple (npc_ahnqiraji_critter) :
    //
    //        if (Player* player = me->SelectNearestPlayer(10.f))
    //            if (player->IsInCombat())
    //                AttackStart(player);
    //        context.Repeat(3500ms, 4s);
    //
    //    Toutes les quatre secondes, chacune cherche un joueur EN COMBAT a
    //    moins de dix yards et lui saute dessus. Un seul bot qui engage une
    //    bestiole tranquille, et tout ce qui traine a dix yards d'un combattant
    //    rejoint - puis a dix yards de ceux-la. C'est comme ca qu'on passe de
    //    six bots en combat a dix-huit empiles sur des scarabes immobiles.
    //
    //    La regle ne nomme aucune entree : elle vaut pour tout ce qui est
    //    neutre dans le temple, et elle rend la main des que la cible mange
    //    quelqu'un du groupe - ce qui nous attaque se tue, qu'il soit jaune ou
    //    rouge.
    triggers.push_back(
        new TriggerNode("aq40 target not hostile",
            { NextAction("aq40 leave what is not hostile", ACTION_RAID + 7.0f) }));

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
    //    ET QUAND TOUT LE MONDE EST EN PLACE, ON AMENE LES EMPEREURS. Ils
    //    poussent en haut d'escaliers que le maillage de navigation ne relie
    //    pas de facon fiable au sol de la salle, et playerbots accepte les
    //    chemins incomplets : un bot envoye la-haut avance aussi loin qu'il
    //    peut et s'arrete. Trois essais en jeu, trois fois le meme resultat.
    //    Donc on ne va plus les chercher, on les pose - chacun sur la marque de
    //    son cote, 133 yards entre eux.
    triggers.push_back(
        new TriggerNode("aq40 twins not on their marks",
            { NextAction("aq40 put the twins on their marks", ACTION_RAID + 8.0f) }));

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
    // 6. UN EMPEREUR SUR LE DOS DE QUELQU'UN QUI N'EST PAS TANK. L'echange
    //    offre 2000 de menace au joueur le PLUS PROCHE - un soigneur, un
    //    voleur, n'importe qui. Celui-la tient un Empereur qu'il n'a pas
    //    demande; sans consigne il le promene au hasard, et le hasard le ramene
    //    vers son frere. Il a donc la meme que les tanks : la marque du cote ou
    //    l'Empereur se trouve, et on l'y garde jusqu'a ce qu'un tank reprenne.
    triggers.push_back(
        new TriggerNode("aq40 a twin is on me",
            { NextAction("aq40 take him to the mark", ACTION_RAID + 2.5f) }));

    // 7. ET PAS DE FAMILIER DE CHASSEUR DANS CETTE SALLE. Grondement est une
    //    provocation, et le familier la lance tout seul : il arrache un
    //    Empereur a son tank sans prevenir et le promene le temps qu'on le
    //    reprenne. Au-dessus de tout, parce que c'est une seule action, une
    //    fois, et que tout le reste en depend.
    triggers.push_back(
        new TriggerNode("aq40 hunter pet is out",
            { NextAction("aq40 dismiss your pet", ACTION_RAID + 9.0f) }));

    // 8. LA TELEPORTATION APPROCHE : LES ATTAQUANTS PARTENT AVANT. Elle tombe
    //    au plus tot trente secondes apres la precedente - c'est le plancher du
    //    script, pas une estimation - et traverser la salle prend seize
    //    secondes, mesurees en jeu. Partir seize secondes avant le plancher,
    //    c'est arriver pile a la plus precoce des echeances possibles.
    //
    //    Au-dessus de la traversee de rattrapage : quand les deux sont vraies,
    //    c'est que le bot est en retard d'un echange ET qu'il faut deja repartir
    //    pour le suivant. La destination d'arrivee est la meme.
    triggers.push_back(
        new TriggerNode("aq40 teleport is coming",
            { NextAction("aq40 go where he will be", ACTION_RAID + 2.45f) }));

    // 9. DU MAUVAIS COTE : ON TRAVERSE, ET ON NE FAIT QUE CA. La teleportation
    //    echange les Empereurs, donc elle echange les cotes. Cette regle est
    //    volontairement au-dessus de l'ecartement et de la retenue des degats :
    //    portee par elles, la traversee se faisait couper en chemin - la
    //    retenue expire au bout de vingt secondes, et traverser 133 yards en
    //    prend dix-neuf. Le bot retombait alors sous l'ecartement, qui le
    //    repoussait d'un petit saut, encore et encore, sur place.
    //
    //    Elle n'a ni minuterie ni condition de combat : vraie tant que le
    //    jumeau interdit est plus pres que le sien, eteinte une fois le milieu
    //    passe.
    triggers.push_back(
        new TriggerNode("aq40 on the wrong side",
            { NextAction("aq40 cross the room", ACTION_RAID + 2.4f) }));

    triggers.push_back(
        new TriggerNode("aq40 too close to the wrong twin",
            { NextAction("aq40 keep away", ACTION_RAID + 2.0f) }));

    // 6. ET PERSONNE NE FRAPPE TANT QUE SON EMPEREUR N'EST PAS POSE. Un tank
    //    qui traine Vek'nilash sur soixante yards ne tient que par sa
    //    provocation : trente-cinq attaquants qui ouvrent pendant le trajet lui
    //    prennent la menace, l'Empereur se retourne, et l'ecart entre les deux
    //    freres - donc le combat - est perdu. Les soigneurs n'en sont pas.
    triggers.push_back(
        new TriggerNode("aq40 twin not placed yet",
            { NextAction("aq40 hold your fire", ACTION_RAID + 2.2f) }));

    // 10. LES SOIGNEURS ONT AUSSI TROIS POSTES : gauche, droite, milieu. Celui
    //     de gauche soigne qui tient la tete de mort de gauche, quel que soit
    //     l'Empereur qui s'y trouve - la teleportation echange les boss, pas
    //     les marques, donc il ne traverse jamais.
    //
    //     SOUS LES SOINS, ET C'EST VOLONTAIRE. ACTION_NORMAL + 2 passe au-dessus
    //     des soins d'appoint et du remplissage, mais reste SOUS les soins
    //     moyens (20) et critiques (30) : un soigneur ne lachera jamais un tank
    //     a terre pour aller corriger sa position. Se replacer, c'est ne pas
    //     soigner.
    triggers.push_back(
        new TriggerNode("aq40 healer off his post",
            { NextAction("aq40 take your heal post", ACTION_NORMAL + 2.0f) }));

    triggers.push_back(
        new TriggerNode("aq40 twins wrong target",
            { NextAction("aq40 attack my twin", ACTION_RAID) }));
}
