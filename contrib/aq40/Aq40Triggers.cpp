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
