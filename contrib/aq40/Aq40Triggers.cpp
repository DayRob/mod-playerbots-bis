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

    if (RaidAq40Utils::IsBugOnMe(bot))
        return false;

    Unit* assigned = RaidAq40Utils::GetAssignedTwin(bot);
    if (!assigned || !assigned->IsAlive())
        return false;

    return AI_VALUE(Unit*, "current target") != assigned;
}
