/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Triggers.h"
#include "Aq40Utils.h"
#include "Timer.h"

bool Aq40TakeStationTrigger::IsActive()
{
    if (!bot->IsAlive() || bot->IsInCombat())
        return false;

    // Il mange ou il boit : on le laisse finir. MoveTo releve un bot assis,
    // donc le placer maintenant lui couperait sa boisson - et dungeon-clear,
    // qui libere son repos juste avant le pull, aurait a la recommencer.
    if (bot->IsSitState())
        return false;

    if (RaidAq40Utils::AreTwinsEngaged(bot))
    {
        _arrive = false;
        return false;
    }

    Position station;
    if (!RaidAq40Utils::GetPrePullStation(bot, station))
        return false;

    // ARRIVER D'ABORD. Tant que le bot n'est pas DANS la salle, le raid est
    // encore en chemin, et ce chemin appartient a dungeon-clear. Une fois le
    // verrou pose il ne se releve qu'au combat : les marques sont aux deux
    // bouts de la piece, donc un bot en route vers la sienne sortirait sinon du
    // seuil en chemin et s'arreterait a mi-parcours.
    //
    // Mesure au MILIEU, pas a un Empereur : depuis le centre de la salle les
    // deux plateformes sont a 114 yards, donc l'ancien seuil - un Empereur a
    // moins de 60 - ne se serait jamais pose sur un raid rassemble au milieu.
    if (!_arrive)
    {
        if (!RaidAq40Utils::IsInTwinsRoom(bot))
            return false;

        _arrive = true;
    }

    // Jamais hors de la salle.
    Position milieu;
    RaidAq40Utils::GetMiddle(milieu);
    if (bot->GetExactDist2d(milieu.GetPositionX(), milieu.GetPositionY()) > PREPULL_GATHER_RANGE)
        return false;

    // PAS DE TEST DE POSITION ICI, et c'est voulu : un tank deja arrive a
    // encore quelque chose a faire - retenir le pull pendant que ses collegues
    // marchent - et c'est l'action qui le sait.
    return true;
}

bool Aq40PullTogetherTrigger::IsActive()
{
    if (!bot->IsAlive() || bot->IsInCombat())
        return false;

    // Deja parti : le pull appartient au passe.
    if (RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    // QUI PULLE : les tanks, et celui qui tient Vek'lor.
    //
    // Ce dernier n'est pas un tank et c'est tout l'interet. Le script du coeur
    // envoie le second Empereur sur celui qui a engage le premier :
    //
    //     if (Creature* twin = GetTwin())
    //         if (!twin->IsInCombat())
    //             twin->AI()->AttackStart(who);
    //
    // Sans un lanceur de sorts sur Vek'lor au meme instant, il part donc sur le
    // tank de Vek'nilash et les deux Empereurs se rejoignent avant le premier
    // coup. Et aucun tank ne peut l'en empecher : il est immunise au physique
    // comme a la provocation.
    if (!RaidAq40Utils::IsVeknilashTank(bot) && !RaidAq40Utils::IsVeklorHolder(bot))
        return false;

    // ET SEULEMENT QUAND TOUT LE MONDE EST EN PLACE. Les partants voient cette
    // condition devenir vraie au MEME tick, donc ils s'elancent ensemble.
    if (RaidAq40Utils::AllTanksPosted(bot))
        return true;

    // MAIS L'ATTENTE A UNE FIN. Ce pulleur est a son poste et attend les
    // autres; si au bout de vingt secondes la condition n'est toujours pas
    // vraie, elle ne le sera probablement jamais - et un raid qui ne pulle
    // jamais est pire qu'un pull imparfait. Le compteur ne demarre que lorsque
    // CE bot est arrive, donc il ne court pas pendant que lui-meme marche.
    Position poste;
    if (!RaidAq40Utils::GetPrePullStation(bot, poste) ||
        bot->GetExactDist2d(poste.GetPositionX(), poste.GetPositionY()) > MARK_TOLERANCE * 2.0f)
    {
        _pretDepuis = 0;
        return false;
    }

    uint32 const maintenant = getMSTime();
    if (!_pretDepuis)
        _pretDepuis = maintenant;

    return getMSTimeDiff(_pretDepuis, maintenant) > PREPULL_HOLD_MAX_MS;
}

bool Aq40TankTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    if (!RaidAq40Utils::IsVeknilashTank(bot))
        return false;

    // Une bestiole lui mord les mollets : qu'il la tue d'abord, il ne tiendra
    // rien avec ca dans le dos.
    return !RaidAq40Utils::IsBugOnMe(bot);
}

bool Aq40VeklorHolderTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    return RaidAq40Utils::IsVeklorHolder(bot);
}

bool Aq40BugTankTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    return RaidAq40Utils::IsBugTank(bot);
}

bool Aq40KeepAwayTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    // Les trois postes ont leur propre consigne, qui sait ou elle va. LES
    // SOIGNEURS, EUX, PASSENT ICI : ils n'attaquent personne, mais la
    // teleportation offre 2000 de menace au joueur le PLUS PROCHE, et ce doit
    // etre un tank. Un soigneur colle a un Empereur se retrouve a le tanker.
    if (RaidAq40Utils::IsVeknilashTank(bot) || RaidAq40Utils::IsBugTank(bot) ||
        RaidAq40Utils::IsVeklorHolder(bot))
        return false;

    if (RaidAq40Utils::IsBugOnMe(bot))
        return false;

    Unit* interdit = RaidAq40Utils::GetForbiddenTwin(bot);
    if (!interdit)
        return false;

    return bot->GetExactDist2d(interdit) < RaidAq40Utils::GetStayAwayRange(bot);
}

bool Aq40HoldFireTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    // Les trois postes travaillent pendant le trajet : c'est leur trajet.
    if (RaidAq40Utils::IsVeknilashTank(bot) || RaidAq40Utils::IsBugTank(bot) ||
        RaidAq40Utils::IsVeklorHolder(bot))
        return false;

    // Une bestiole le mord : qu'il la tue, elle ne fera pas perdre le placement.
    if (RaidAq40Utils::IsBugOnMe(bot))
        return false;

    // Les soigneurs n'ont rien a retenir - GetAssignedTwin leur rend nullptr.
    Unit* assigne = RaidAq40Utils::GetAssignedTwin(bot);
    if (!assigne || !assigne->IsAlive())
        return false;

    // LES DEUX EMPEREURS, PAS SEULEMENT LE SIEN.
    //
    // Je ne retenais d'abord que ceux dont le propre jumeau etait en chemin.
    // C'est trop faible, et pour une raison qui ne se voit pas : les degats
    // sont PARTAGES entre les deux freres (Twin Empathy, 1177). Frapper Vek'lor
    // pendant qu'un tank traine Vek'nilash fait donc monter la barre d'un
    // Empereur qu'on croyait laisser tranquille, et rien ne garantit que la
    // menace qui en decoule reste sur le bon. Tant qu'un seul des deux n'est
    // pas pose, tout le monde attend - sauf les trois postes, qui travaillent.
    Creature* const veklor = RaidAq40Utils::GetVeklor(bot);
    Creature* const veknilash = RaidAq40Utils::GetVeknilash(bot);

    bool const poses = (!veklor || !veklor->IsAlive() || RaidAq40Utils::IsTwinPlaced(veklor)) &&
                       (!veknilash || !veknilash->IsAlive() || RaidAq40Utils::IsTwinPlaced(veknilash));

    if (poses)
    {
        _retientDepuis = 0;
        return false;
    }

    // ET LA RETENUE A UNE FIN. Elle repart a zero a chaque fois que les deux
    // sont poses, donc elle redemarre neuve a chaque teleportation; mais si un
    // Empereur n'arrive jamais - son tank est mort, il s'est coince - le raid
    // ne doit pas le regarder sans frapper jusqu'au wipe.
    uint32 const maintenant = getMSTime();
    if (!_retientDepuis)
        _retientDepuis = maintenant;

    return getMSTimeDiff(_retientDepuis, maintenant) <= HOLD_FIRE_MAX_MS;
}

bool Aq40WrongTargetTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    if (RaidAq40Utils::IsVeknilashTank(bot) || RaidAq40Utils::IsBugTank(bot) ||
        RaidAq40Utils::IsVeklorHolder(bot))
        return false;

    if (RaidAq40Utils::IsBugOnMe(bot))
        return false;

    Unit* assigne = RaidAq40Utils::GetAssignedTwin(bot);
    if (!assigne || !assigne->IsAlive())
        return false;

    return AI_VALUE(Unit*, "current target") != assigne;
}

bool Aq40NeutralTargetTrigger::IsActive()
{
    if (!bot->IsAlive())
        return false;

    Unit* cible = AI_VALUE(Unit*, "current target");
    if (!cible || !cible->IsAlive())
        return false;

    // ROUGE : il nous est hostile, c'est du vrai trash, on le tue. C'est aussi
    // le cas d'une bestiole retournee par un Empereur : le script du sort lui
    // met FACTION_HOSTILE, donc elle passe rouge et cette regle la lache.
    if (bot->IsHostileTo(cible))
        return false;

    // JAUNE, MAIS IL MANGE UN DES NOTRES. Les bestioles de la salle attaquent
    // sans changer de faction - npc_ahnqiraji_critter fait AttackStart() et
    // rien d'autre - donc elles restent jaunes tout en etant un vrai danger.
    // Celle-la se tue, et le test ne coute rien : on lit sa victime, et on
    // regarde si c'est un joueur de notre groupe.
    if (Unit* victime = cible->GetVictim())
        if (Player* joueur = victime->ToPlayer())
            if (joueur->GetGroup() && joueur->GetGroup() == bot->GetGroup())
                return false;

    // Jaune, et il n'attaque personne chez nous : on le laisse tranquille.
    return true;
}
