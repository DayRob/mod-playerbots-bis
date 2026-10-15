/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Triggers.h"
#include "Aq40Utils.h"

bool Aq40TwinsDragApartTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    // LES POSTES PASSENT AVANT. Un tank qui tient un piedestal, et le tank des
    // bestioles tant qu'une bestiole traine, ont une consigne qui connait la
    // salle; les quatre regles ci-dessous n'en savent rien et les renverraient
    // vers le milieu au tick suivant.
    if (RaidAq40Utils::IsOnAnchorDuty(bot) || RaidAq40Utils::IsOnBugDuty(bot))
        return false;

    if (!RaidAq40Utils::IsPhysicalDamageDealer(bot))
        return false;

    // A bot with a woken bug in its face deals with the bug first. Only that
    // bot: the rest of the raid stays on the emperors.
    if (RaidAq40Utils::IsBugOnMe(bot))
        return false;

    Unit* veklor = RaidAq40Utils::GetVeklor(bot);
    Unit* veknilash = RaidAq40Utils::GetVeknilash(bot);
    if (!veklor || !veknilash)
        return false;

    return RaidAq40Utils::Separation(veklor, veknilash) < SAFE_SEPARATION;
}

bool Aq40TwinsKeepDistanceTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    // LES POSTES PASSENT AVANT. Un tank qui tient un piedestal, et le tank des
    // bestioles tant qu'une bestiole traine, ont une consigne qui connait la
    // salle; les quatre regles ci-dessous n'en savent rien et les renverraient
    // vers le milieu au tick suivant.
    if (RaidAq40Utils::IsOnAnchorDuty(bot) || RaidAq40Utils::IsOnBugDuty(bot))
        return false;

    Unit* forbidden = RaidAq40Utils::GetForbiddenTwin(bot);
    if (!forbidden)
        return false;

    // QUAND LES DEUX EMPEREURS SONT TROP PRES, C'EST L'ECARTEMENT QUI COMMANDE.
    //
    // Sans cette sortie, les deux regles se battaient et celle-ci gagnait
    // toujours : au pull, les deux boss convergent sur le raid, donc Vek'lor est
    // a moins de 15 yards des melee, donc ce declencheur repond oui - et il
    // siege a ACTION_RAID + 2 contre + 1 pour l'ecartement. Resultat observe en
    // jeu : les jumeaux restaient colles, parce que la regle censee les separer
    // n'a jamais tourné une seule fois.
    //
    // Rien n'est perdu cote securite : le point vise par l'ecartement est, par
    // construction, de l'autre cote de Vek'nilash PAR RAPPORT A Vek'lor. S'en
    // approcher, c'est deja s'eloigner du jumeau interdit - en emmenant l'autre.
    //
    // Les lanceurs de sorts gardent ce declencheur en toutes circonstances :
    // aucune regle d'ecartement ne les concerne, donc rien ne prendrait le
    // relais.
    if (RaidAq40Utils::IsPhysicalDamageDealer(bot))
    {
        Unit* veklor = RaidAq40Utils::GetVeklor(bot);
        Unit* veknilash = RaidAq40Utils::GetVeknilash(bot);
        if (veklor && veknilash && RaidAq40Utils::Separation(veklor, veknilash) < SAFE_SEPARATION)
            return false;
    }

    float const keepAway = RaidAq40Utils::IsSpellDamageDealer(bot) ? CASTER_STAY_AWAY_FROM_VEKNILASH
                                                                   : MELEE_STAY_AWAY_FROM_VEKLOR;

    return bot->GetExactDist2d(forbidden) < keepAway;
}

bool Aq40TwinsWrongTargetTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    // LES POSTES PASSENT AVANT. Un tank qui tient un piedestal, et le tank des
    // bestioles tant qu'une bestiole traine, ont une consigne qui connait la
    // salle; les quatre regles ci-dessous n'en savent rien et les renverraient
    // vers le milieu au tick suivant.
    if (RaidAq40Utils::IsOnAnchorDuty(bot) || RaidAq40Utils::IsOnBugDuty(bot))
        return false;

    if (RaidAq40Utils::IsBugOnMe(bot))
        return false;

    Unit* assigned = RaidAq40Utils::GetAssignedTwin(bot);
    if (!assigned || !assigned->IsAlive())
        return false;

    return AI_VALUE(Unit*, "current target") != assigned;
}

bool Aq40TwinsWrongSideTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    // LES POSTES PASSENT AVANT. Un tank qui tient un piedestal, et le tank des
    // bestioles tant qu'une bestiole traine, ont une consigne qui connait la
    // salle; les quatre regles ci-dessous n'en savent rien et les renverraient
    // vers le milieu au tick suivant.
    if (RaidAq40Utils::IsOnAnchorDuty(bot) || RaidAq40Utils::IsOnBugDuty(bot))
        return false;

    if (RaidAq40Utils::IsBugOnMe(bot))
        return false;

    Unit* mine = RaidAq40Utils::GetAssignedTwin(bot);
    Unit* other = RaidAq40Utils::GetForbiddenTwin(bot);
    if (!mine || !other)
        return false;

    // Le mauvais cote, c'est etre plus pres du jumeau interdit que son propre
    // jumeau ne l'est : le bot est alors entre les deux, et le boss qu'il tient
    // se dirige vers son frere pour l'atteindre.
    //
    // Pose comme une comparaison et non comme une distance fixe, parce que la
    // bonne distance change tout le temps : c'est la geometrie des deux boss
    // qui decide. Le declencheur ne repond donc oui que quand le placement est
    // vraiment faux, et laisse l'IA de classe tranquille le reste du temps.
    return bot->GetExactDist2d(other) < mine->GetExactDist2d(other);
}

bool Aq40TankAnchorTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    // Pas de test de position ici. Savoir si le poste est tenu demande de
    // connaitre le socle, le jumeau confie et la distance qui va avec - c'est
    // exactement ce que l'action calcule, et le lui faire calculer deux fois
    // ouvrait la porte a ce que les deux reponses divergent. L'action rend faux
    // quand il n'y a rien a faire, et l'IA de classe reprend la main.
    return RaidAq40Utils::IsOnAnchorDuty(bot);
}

bool Aq40TankTheBugsTrigger::IsActive()
{
    if (!bot->IsAlive() || !RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    return RaidAq40Utils::IsOnBugDuty(bot);
}

bool Aq40PrePullTrigger::IsActive()
{
    if (!bot->IsAlive() || bot->IsInCombat())
        return false;

    // Il mange ou il boit : on le laisse finir. MoveTo releve un bot assis, donc
    // le placer maintenant lui couperait sa boisson - et dungeon-clear, qui
    // libere son Smart Rest juste avant le pull, aurait a la recommencer.
    if (bot->IsSitState())
        return false;

    if (RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    Position station;
    if (!RaidAq40Utils::GetPrePullStation(bot, station))
        return false;

    // DANS LA SALLE, PAS DANS LE COULOIR. Un bot encore en chemin appartient a
    // dungeon-clear, qui connait la route; le tirer vers un poste a travers les
    // murs ne ferait que le perdre.
    Position milieu;
    if (!RaidAq40Utils::GetBugStation(bot, milieu))
        return false;

    if (bot->GetExactDist2d(milieu.GetPositionX(), milieu.GetPositionY()) > PREPULL_GATHER_RANGE)
        return false;

    // PAS DE TEST DE POSITION ICI, et c'est voulu. Un tank arrive a son poste a
    // encore quelque chose a faire - retenir le pull pendant que ses collegues
    // marchent - et c'est l'action qui le sait. Elle rend faux des qu'il n'y a
    // plus rien a tenir, et le pull part alors tout seul.
    return true;
}

bool Aq40PullTogetherTrigger::IsActive()
{
    if (!bot->IsAlive() || bot->IsInCombat())
        return false;

    // Deja parti : le pull appartient au passe, les regles de combat prennent
    // le relais.
    if (RaidAq40Utils::AreTwinsEngaged(bot))
        return false;

    // Seuls les deux tanks de postes pullent. Le tank des bestioles et tout le
    // reste du raid attendent que ca commence.
    if (RaidAq40Utils::TankIndex(bot) > 1)
        return false;

    // ET SEULEMENT QUAND TOUT LE MONDE EST EN PLACE. C'est toute la raison
    // d'etre de ce declencheur : les deux tanks le voient devenir vrai au MEME
    // tick, donc ils partent ensemble, chacun sur son Empereur.
    return RaidAq40Utils::AllTanksPosted(bot);
}
