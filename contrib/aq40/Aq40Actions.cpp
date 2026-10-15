/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Actions.h"
#include "Aq40Utils.h"
#include "Timer.h"
#include <cmath>
#include <string>
#include <vector>

namespace
{
    // Les provocations de chaque classe de tank, dans l'ordre ou on les essaie.
    // CanCastSpell d'abord : un bot qui ne connait pas le sort, ou qui l'a en
    // recharge, doit passer au geste suivant au lieu de perdre son tick.
    //
    // JAMAIS SUR VEK'LOR : il y est immunise, constate en jeu. La tenter sur
    // lui ne ferait que gaspiller un temps d'incantation au moment precis ou il
    // ne faut pas.
    std::vector<std::string> const& Provocations()
    {
        static std::vector<std::string> const noms = { "taunt", "growl", "dark command", "mocking blow" };
        return noms;
    }

    bool Provoque(PlayerbotAI* botAI, Unit* cible)
    {
        if (!botAI || !cible)
            return false;

        for (std::string const& sort : Provocations())
            if (botAI->CanCastSpell(sort, cible) && botAI->CastSpell(sort, cible))
                return true;

        return false;
    }
}

bool Aq40TakeStationAction::Execute(Event /*event*/)
{
    Position station;
    if (!RaidAq40Utils::GetPrePullStation(bot, station))
        return false;

    if (bot->GetExactDist2d(station.GetPositionX(), station.GetPositionY()) >= MARK_TOLERANCE)
    {
        _retientDepuis = 0;
        return MoveTo(bot->GetMapId(), station.GetPositionX(), station.GetPositionY(), station.GetPositionZ(),
                      false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);
    }

    // ── EN PLACE ──────────────────────────────────────────────────────────
    //
    // Un corps-a-corps ou un lanceur de sorts rend la main tout de suite : son
    // retard ne coute que son propre temps de trajet, et le boss marchera vers
    // son tank de toute facon.
    if (RaidAq40Utils::TankIndex(bot) == TANK_INDEX_NONE)
        return false;

    // Un TANK, lui, retient le pull tant qu'un de ses collegues marche encore.
    // Un Empereur pulle alors qu'il n'y a personne a son poste part sur le
    // joueur le plus proche, et ce sera un soigneur.
    if (RaidAq40Utils::AllTanksPosted(bot))
        return false;

    uint32 const maintenant = getMSTime();
    if (!_retientDepuis)
        _retientDepuis = maintenant;

    // La limite. Un tank mort, bloque ou reste dehors ne doit pas pouvoir geler
    // le run : passe le delai, on rend la main et dungeon-clear pull comme il
    // l'aurait fait sans nous.
    if (getMSTimeDiff(_retientDepuis, maintenant) > PREPULL_HOLD_MAX_MS)
        return false;

    return true;
}

bool Aq40PullTogetherAction::Execute(Event /*event*/)
{
    // Celui qui tient Vek'lor engage Vek'lor; les tanks engagent Vek'nilash.
    Unit* mien = RaidAq40Utils::IsVeklorHolder(bot) ? static_cast<Unit*>(RaidAq40Utils::GetVeklor(bot))
                                                    : static_cast<Unit*>(RaidAq40Utils::GetVeknilash(bot));
    if (!mien || !mien->IsAlive())
        return false;

    // On marche dessus. Les partants font ce trajet en meme temps, chacun vers
    // le sien, puisque leur declencheur est devenu vrai au meme tick.
    if (bot->GetExactDist2d(mien) > TANK_GRAB_RANGE)
        return MoveTo(bot->GetMapId(), mien->GetPositionX(), mien->GetPositionY(), mien->GetPositionZ(),
                      false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);

    if (AI_VALUE(Unit*, "current target") != mien)
        return Attack(mien);

    return false;
}

bool Aq40TankAction::Execute(Event /*event*/)
{
    Position marque;
    if (!RaidAq40Utils::GetMyMark(bot, marque))
        return false;

    Creature* const veknilash = RaidAq40Utils::GetVeknilash(bot);
    if (!veknilash || !veknilash->IsAlive())
        return false;

    // ── VEK'LOR DE MON COTE : J'ATTENDS ───────────────────────────────────
    //
    // Rien a tenir. Immunise au physique ET a la provocation, Vek'lor ne
    // connaitra jamais ce tank; c'est le demoniste qui le garde, par les
    // degats. Le travail du tank ici, c'est d'etre LE PLUS PROCHE quand
    // l'echange lui amenera Vek'nilash - le script donne ses 2000 de menace au
    // joueur le plus proche, et le guide en fait la condition :
    //
    //     "Pour reprendre l'aggro de Vek'nilash apres une teleportation, le
    //      Guerrier doit etre le personnage le plus proche a proximite de
    //      l'empereur."
    if (!RaidAq40Utils::IsVeknilashOnMySide(bot))
    {
        if (bot->GetExactDist2d(marque.GetPositionX(), marque.GetPositionY()) >= MARK_TOLERANCE)
            return MoveTo(bot->GetMapId(), marque.GetPositionX(), marque.GetPositionY(),
                          marque.GetPositionZ(), false, false, false, false,
                          MovementPriority::MOVEMENT_COMBAT, true, false);

        // Rendre faux ici rendrait la main a l'IA de classe, qui l'enverrait
        // chercher une cible a frapper a l'autre bout de la salle - c'est-a-dire
        // exactement ce que ce poste existe pour empecher. Un tank qui attend
        // trente secondes sans rien faire, c'est le prix de l'echange, et c'est
        // ce que fait un vrai raid : "le Demoniste qui tanke patiente sagement
        // jusqu'a la prochaine teleportation", et le guerrier de meme.
        return true;
    }

    // ── VEK'NILASH DE MON COTE : JE LE TIENS ──────────────────────────────

    if (AI_VALUE(Unit*, "current target") != veknilash)
        return Attack(veknilash);

    float const distance = bot->GetExactDist2d(veknilash);

    // La provocation, des qu'il regarde ailleurs. C'est tout le travail de
    // l'echange : les menaces sont remises a zero et les 2000 offerts peuvent
    // tomber sur un soigneur. Vek'nilash, lui, n'est pas immunise.
    if (veknilash->GetVictim() != bot && distance <= TANK_GRAB_RANGE && Provoque(botAI, veknilash))
        return true;

    // Aller le chercher. Apres une teleportation il arrive a l'autre bout, et
    // tant que personne n'est alle le reprendre il reste a cote de son frere.
    if (distance > TANK_GRAB_RANGE)
        return MoveTo(bot->GetMapId(), veknilash->GetPositionX(), veknilash->GetPositionY(),
                      veknilash->GetPositionZ(), false, false, false, false,
                      MovementPriority::MOVEMENT_COMBAT, true, false);

    // Et on l'emmene sur la marque, lui derriere : il suit son attaquant au
    // contact. Dos au mur, pour que l'Uppercut ne sorte pas le tank de la
    // position - et donc de la zone de soins.
    if (bot->GetExactDist2d(marque.GetPositionX(), marque.GetPositionY()) < MARK_TOLERANCE)
        return false;  // arrive : l'IA de classe reprend la main pour frapper

    return MoveTo(bot->GetMapId(), marque.GetPositionX(), marque.GetPositionY(), marque.GetPositionZ(),
                  false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);
}

bool Aq40HoldVeklorAction::Execute(Event /*event*/)
{
    Creature* const veklor = RaidAq40Utils::GetVeklor(bot);
    if (!veklor || !veklor->IsAlive())
        return false;

    // RECULER PASSE AVANT TOUT. Le guide est net :
    //
    //     "Il est essentiel que le Demoniste soit vigilant et recule
    //      legerement. S'il ne reagit pas assez rapidement, Vek'lor lancera son
    //      Jaillissement des arcanes sur le Demo Tank, perturbant gravement le
    //      positionnement."
    //
    // Et le script ne le declenche que s'il trouve un joueur a portee de
    // contact : SelectNearestPlayer(NOMINAL_MELEE_RANGE).
    if (bot->GetExactDist2d(veklor) < MELEE_STAY_AWAY_FROM_VEKLOR)
        return FleePosition(veklor->GetPosition(), MELEE_STAY_AWAY_FROM_VEKLOR, 1000);

    // Sa cible, toujours : c'est par les degats qu'il le tient, et c'est sa
    // position a lui qui decide ou Vek'lor se plante - Vek'lor s'arrete des
    // qu'il est a 45 yards de sa cible et ne bouge plus.
    if (AI_VALUE(Unit*, "current target") != veklor)
        return Attack(veklor);

    // Et il tient sa station, pour que Vek'lor reste ou il est.
    Position station;
    if (!RaidAq40Utils::GetVeklorStation(bot, station))
        return false;

    if (bot->GetExactDist2d(station.GetPositionX(), station.GetPositionY()) < MARK_TOLERANCE)
        return false;  // en place : l'IA de classe reprend la main pour lancer

    return MoveTo(bot->GetMapId(), station.GetPositionX(), station.GetPositionY(), station.GetPositionZ(),
                  false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);
}

bool Aq40BugTankAction::Execute(Event /*event*/)
{
    Unit* bestiole = RaidAq40Utils::GetBugToTank(bot);

    // RIEN A FAIRE : ON TIENT LE MILIEU. C'est le poste du guide - "un groupe
    // qui s'occupera exclusivement des insectes" - et les bestioles tombent la,
    // au milieu, ou se tiennent aussi les soigneurs.
    if (!bestiole)
    {
        Position milieu;
        RaidAq40Utils::GetMiddle(milieu);

        if (bot->GetExactDist2d(milieu.GetPositionX(), milieu.GetPositionY()) >= MARK_TOLERANCE)
            return MoveTo(bot->GetMapId(), milieu.GetPositionX(), milieu.GetPositionY(),
                          milieu.GetPositionZ(), false, false, false, false,
                          MovementPriority::MOVEMENT_COMBAT, true, false);

        return true;
    }

    // Elle est deja sur moi : rien a arracher, l'IA de classe la tue.
    if (bestiole->GetVictim() == bot)
    {
        if (AI_VALUE(Unit*, "current target") != bestiole)
            return Attack(bestiole);

        return false;
    }

    // La provocation d'abord : le soin fabrique de la menace a chaque sort,
    // donc attendre d'en produire par les degats laisse le soigneur se faire
    // mordre plusieurs secondes de plus.
    if (Provoque(botAI, bestiole))
        return true;

    if (AI_VALUE(Unit*, "current target") != bestiole)
        return Attack(bestiole);

    return MoveTo(bot->GetMapId(), bestiole->GetPositionX(), bestiole->GetPositionY(),
                  bestiole->GetPositionZ(), false, false, false, false,
                  MovementPriority::MOVEMENT_COMBAT, true, false);
}

bool Aq40KeepAwayAction::Execute(Event /*event*/)
{
    Unit* interdit = RaidAq40Utils::GetForbiddenTwin(bot);
    if (!interdit)
        return false;

    float const ecart = RaidAq40Utils::IsSpellDamageDealer(bot) ? CASTER_STAY_AWAY_FROM_VEKNILASH
                                                                : MELEE_STAY_AWAY_FROM_VEKLOR;

    return FleePosition(interdit->GetPosition(), ecart, 1000);
}

bool Aq40AttackMyTwinAction::Execute(Event /*event*/)
{
    Unit* assigne = RaidAq40Utils::GetAssignedTwin(bot);
    if (!assigne || !assigne->IsAlive())
        return false;

    if (AI_VALUE(Unit*, "current target") == assigne)
        return false;

    return Attack(assigne);
}

bool Aq40LeaveNeutralAction::Execute(Event /*event*/)
{
    Unit* cible = AI_VALUE(Unit*, "current target");
    if (!cible)
        return false;

    // On lache tout ce qui pointe vers elle : la valeur que l'IA relit au tick
    // suivant, la cible affichee, et l'attaque en cours. Omettre l'une des
    // trois laisse le bot y revenir tout seul.
    context->GetValue<Unit*>("current target")->Set(nullptr);
    bot->SetTarget();
    bot->AttackStop();
    return true;
}
