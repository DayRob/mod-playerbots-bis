/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Triggers.h"
#include "Aq40Utils.h"

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

    // ARRIVER D'ABORD. Tant qu'aucun Empereur n'est a portee, le raid est
    // encore en chemin, et ce chemin appartient a dungeon-clear. Une fois le
    // verrou pose il ne se releve qu'au combat : les marques sont a plus de
    // 80 yards des plateformes, donc un bot en route vers la sienne sortirait
    // sinon du seuil en chemin et s'arreterait a mi-parcours.
    if (!_arrive)
    {
        Creature* const veklor = RaidAq40Utils::GetVeklor(bot);
        Creature* const veknilash = RaidAq40Utils::GetVeknilash(bot);
        if (!veklor && !veknilash)
            return false;

        bool proche = false;
        if (veklor && bot->GetExactDist2d(veklor) <= PREPULL_ARRIVED_RANGE)
            proche = true;
        if (veknilash && bot->GetExactDist2d(veknilash) <= PREPULL_ARRIVED_RANGE)
            proche = true;

        if (!proche)
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
    return RaidAq40Utils::AllTanksPosted(bot);
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

    // Les trois postes ont leur propre consigne, qui sait ou elle va.
    if (RaidAq40Utils::IsVeknilashTank(bot) || RaidAq40Utils::IsBugTank(bot) ||
        RaidAq40Utils::IsVeklorHolder(bot))
        return false;

    if (RaidAq40Utils::IsBugOnMe(bot))
        return false;

    Unit* interdit = RaidAq40Utils::GetForbiddenTwin(bot);
    if (!interdit)
        return false;

    float const ecart = RaidAq40Utils::IsSpellDamageDealer(bot) ? CASTER_STAY_AWAY_FROM_VEKNILASH
                                                                : MELEE_STAY_AWAY_FROM_VEKLOR;

    return bot->GetExactDist2d(interdit) < ecart;
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

bool Aq40ChasingCritterTrigger::IsActive()
{
    if (!bot->IsAlive())
        return false;

    // DANS LA SALLE SEULEMENT. La strategie est posee sur toute la carte 531,
    // mais ailleurs dans le temple ces bestioles sont du trash ordinaire que
    // mod-dungeon-clear a raison de nettoyer. Une distance au milieu, donc rien
    // de cher a payer pour la poser a chaque tick.
    if (!RaidAq40Utils::IsInTwinsRoom(bot))
        return false;

    Unit* cible = AI_VALUE(Unit*, "current target");
    if (!cible)
        return false;

    uint32 const entry = cible->GetEntry();
    if (entry != NPC_QIRAJI_SCARAB && entry != NPC_QIRAJI_SCORPION)
        return false;

    // REVEILLEE OU ENDORMIE : C'EST LE COMBAT QUI TRANCHE, PAS LA FACTION.
    //
    // Le script de Mutate Bug et d'Explode Bug fait SetInCombatWithZone() sur
    // celle qu'il retourne, en plus de lui mettre FACTION_HOSTILE. Une
    // bestiole reveillee est donc EN COMBAT, et c'est un vrai combat dont le
    // tank des bestioles s'occupe; une endormie n'a rien demande a personne.
    //
    // J'avais d'abord teste la faction, et c'etait fragile : il suffisait que
    // ces bestioles naissent deja hostiles dans la base pour que le test
    // reponde "reveillee" sur toutes, et la regle n'aurait jamais rien fait -
    // en silence. Le combat, lui, ne se discute pas, et il couvre le cas de
    // celle qui mord sans que sa faction l'ait dit : si elle me mange, elle est
    // en combat.
    return !cible->IsInCombat();
}
