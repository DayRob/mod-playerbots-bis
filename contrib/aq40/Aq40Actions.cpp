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

namespace
{
    // Pose un Empereur sur sa marque, et l'y ancre.
    bool PoserSurSaMarque(Creature* jumeau)
    {
        Position marque;
        if (!RaidAq40Utils::GetTwinMark(jumeau, marque))
            return false;

        if (!RaidAq40Utils::NeedsMoving(jumeau))
            return false;

        float const o = jumeau->GetOrientation();

        jumeau->NearTeleportTo(marque.GetPositionX(), marque.GetPositionY(), marque.GetPositionZ(), o);

        // ET ON DEPLACE SON ANCRAGE AVEC LUI. Sinon le premier evade - un wipe,
        // un reset, un bot qui sort de la salle - le ramene sur sa plateforme,
        // et il faudrait tout recommencer.
        jumeau->SetHomePosition(marque.GetPositionX(), marque.GetPositionY(), marque.GetPositionZ(), o);
        return true;
    }
}

bool Aq40SetTheStageAction::Execute(Event /*event*/)
{
    bool fait = false;

    if (Creature* veklor = RaidAq40Utils::GetVeklor(bot))
        fait |= PoserSurSaMarque(veklor);

    if (Creature* veknilash = RaidAq40Utils::GetVeknilash(bot))
        fait |= PoserSurSaMarque(veknilash);

    // Chacun sur SA marque, c'est-a-dire celle de son cote, donc 133 yards les
    // separent - plus du double des 60 de Heal Brother. Le pull qui suit part
    // de deux bots deja au contact de leur Empereur : plus d'escaliers, plus de
    // trainage sur soixante yards, plus rien a rater.
    return fait;
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
    bool const demoniste = RaidAq40Utils::IsVeklorHolder(bot);

    Unit* mien = demoniste ? static_cast<Unit*>(RaidAq40Utils::GetVeklor(bot))
                           : static_cast<Unit*>(RaidAq40Utils::GetVeknilash(bot));
    if (!mien || !mien->IsAlive())
        return false;

    // LA PORTEE A LAQUELLE CE BOT PEUT REELLEMENT ENGAGER, et elle n'est pas la
    // meme pour les deux. Le tank doit etre au CONTACT - GetMeleeRange tient
    // compte de l'allonge du boss, qui est un gros modele. Le lanceur de sorts,
    // lui, s'arrete des qu'il peut lancer : Vek'lor viendra a lui, puisqu'il
    // suit sa cible jusqu'a 45 yards puis s'arrete.
    float const portee = demoniste ? PULL_SPELL_RANGE : bot->GetMeleeRange(mien);
    bool const aPortee = bot->GetExactDist2d(mien) <= portee;

    // ── PAR LE POINT DE PULL D'ABORD ──────────────────────────────────────
    //
    // Les Empereurs sont en haut d'escaliers. Un bot lache sur leurs
    // coordonnees depuis le sol de la salle s'arretait en bas des marches, et
    // n'engageait rien - vu en jeu, le pulleur en bas, le boss en haut. Le
    // point de pull est a leur niveau, sur un sol que le client confirme, donc
    // le chemin y mene vraiment.
    //
    // Ce n'est qu'un passage : une fois dessus, on finit a la main les derniers
    // yards. Et des qu'on est a portee d'engager, il ne sert plus a rien - un
    // demoniste arrive a 16 yards de Vek'lor peut deja lancer.
    Position depart;
    if (!aPortee && !RaidAq40Utils::IsTwinPlaced(mien) && RaidAq40Utils::GetPullStation(bot, depart) &&
        bot->GetExactDist2d(depart.GetPositionX(), depart.GetPositionY()) > MARK_TOLERANCE)
    {
        MoveTo(bot->GetMapId(), depart.GetPositionX(), depart.GetPositionY(), depart.GetPositionZ(),
               false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);
        return true;
    }

    // ── PUIS LES DERNIERS YARDS JUSQU'A LUI ───────────────────────────────
    //
    // Les partants font ce trajet en meme temps, chacun vers le sien, puisque
    // leur declencheur est devenu vrai au MEME tick.
    if (!aPortee)
    {
        MoveTo(bot->GetMapId(), mien->GetPositionX(), mien->GetPositionY(), mien->GetPositionZ(),
               false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);

        // ON NE REND JAMAIS LA MAIN EN CHEMIN. Rendre faux ici laissait la file
        // descendre d'un cran jusqu'a la mise en place, qui renvoyait le
        // pulleur a sa marque : il repartait, se faisait rappeler, et le boss
        // n'etait jamais touche.
        return true;
    }

    if (AI_VALUE(Unit*, "current target") != mien)
        Attack(mien);

    // Vrai jusqu'a ce que le combat commence - le declencheur s'eteint alors de
    // lui-meme, puisqu'il exige que les Empereurs ne soient pas engages.
    return true;
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
    if (bot->GetExactDist2d(marque.GetPositionX(), marque.GetPositionY()) >= MARK_TOLERANCE)
        return MoveTo(bot->GetMapId(), marque.GetPositionX(), marque.GetPositionY(), marque.GetPositionZ(),
                      false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);

    // ── SUR LA MARQUE : ON NE LA QUITTE PLUS, ON LE LAISSE VENIR ──────────
    //
    // Rendre faux des qu'on touche la marque rendait la main a l'IA de classe,
    // qui voit un boss a dix yards et va le chercher. Le tank repartait donc
    // aussitot, sortait de la marque, la regle le renvoyait dessus, et les deux
    // oscillaient en derivant - le boss n'arrivait jamais vraiment a l'endroit
    // voulu. C'est exactement ce qui a ete vu en jeu.
    //
    // Tant qu'il n'est pas au contact, on tient la position : Vek'nilash suit
    // son attaquant, il viendra. Le pas qu'on ne fait pas vers lui, c'est lui
    // qui le fait vers nous, et la marque reste tenue.
    if (bot->GetExactDist2d(veknilash) > bot->GetMeleeRange(veknilash))
        return true;

    // Au contact sur la marque : plus rien a conduire, l'IA de classe frappe -
    // et elle ne bougera pas, puisqu'elle est deja a portee.
    return false;
}

bool Aq40HoldVeklorAction::Execute(Event /*event*/)
{
    Creature* const veklor = RaidAq40Utils::GetVeklor(bot);
    if (!veklor || !veklor->IsAlive())
        return false;

    float const ecart = bot->GetExactDist2d(veklor);

    // ─── TROP PRES : RECULER, ET CA PASSE AVANT TOUT ──────────────────────
    //
    //     "Il est essentiel que le Demoniste soit vigilant et recule
    //      legerement. S'il ne reagit pas assez rapidement, Vek'lor lancera son
    //      Jaillissement des arcanes sur le Demo Tank, perturbant gravement le
    //      positionnement."
    //
    // Le script ne declenche Arcane Burst que s'il trouve un joueur a portee de
    // contact : SelectNearestPlayer(NOMINAL_MELEE_RANGE).
    if (ecart < MELEE_STAY_AWAY_FROM_VEKLOR)
        return FleePosition(veklor->GetPosition(), MELEE_STAY_AWAY_FROM_VEKLOR, 1000);

    // Sa cible, toujours : c'est par les degats qu'il le tient. Immunise a la
    // provocation, Vek'lor ne connait que ca.
    if (AI_VALUE(Unit*, "current target") != veklor)
        return Attack(veklor);

    // ─── TROP LOIN POUR LANCER : SE RAPPROCHER ────────────────────────────
    //
    // C'EST ICI QUE JE ME SUIS TROMPE, et la geometrie est implacable :
    //
    //     MoveChase(who, 45.0f, 0)
    //
    // Vek'lor s'arrete a QUARANTE-CINQ yards de sa cible et ne bouge plus. Or
    // un sort de demoniste porte a trente. Un demoniste qui attend sagement sur
    // une station fixe se retrouve donc a quarante-cinq yards d'un Empereur
    // qu'il ne peut PAS toucher : pas de degats, pas de menace, pas d'aggro.
    // Exactement ce qui a ete vu en jeu.
    //
    // Et c'est lui qui doit combler, pas Vek'lor : Vek'lor ne recule jamais, il
    // ne fait que se rapprocher jusqu'a 45. C'est donc le demoniste qui decide
    // de la distance, et il doit la ramener dans sa portee.
    if (ecart > PULL_SPELL_RANGE)
        return MoveTo(bot->GetMapId(), veklor->GetPositionX(), veklor->GetPositionY(),
                      veklor->GetPositionZ(), false, false, false, false,
                      MovementPriority::MOVEMENT_COMBAT, true, false);

    // ─── DANS LA BANDE : ON NE BOUGE PLUS ─────────────────────────────────
    //
    // Entre 15 et 28 yards, il peut lancer sans reveiller Jaillissement des
    // arcanes. On rend la main a l'IA de classe, qui fait ce qu'elle sait faire
    // - et comme le demoniste ne bouge plus, Vek'lor ne bouge plus non plus.
    // C'est sa position a lui qui ancre l'Empereur, pas une station ecrite
    // d'avance.
    return false;
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

bool Aq40HoldFireAction::Execute(Event /*event*/)
{
    // ON ARRETE DE FRAPPER, ON NE LACHE PAS LA CIBLE.
    //
    // Je remettais "current target" a nullptr et j'appelais SetTarget() a
    // CHAQUE tick. L'IA de classe reprenait une cible au tick suivant, je la
    // relachais, elle la reprenait : le bot passait son temps a se retourner
    // sans avancer ni frapper - "bloque sur place a tourner la camera", vu en
    // jeu. Garder la cible ne coute rien : la menace vient des degats, et le
    // "vrai" rendu plus bas suffit a les empecher.
    bot->AttackStop();

    // ── ET ON CHANGE DE COTE PENDANT CE TEMPS ─────────────────────────────
    //
    // Retenir ses coups ne veut pas dire rester plante. La teleportation
    // echange les deux Empereurs : apres elle, les corps-a-corps se retrouvent
    // du cote de Vek'lor - immunise au physique, et son Jaillissement des
    // arcanes les repousse - et les lanceurs de sorts du cote de Vek'nilash,
    // dont ils prennent les Uppercuts. Les deux groupes doivent traverser.
    //
    // Le temps que les tanks replacent les boss est exactement celui qu'il faut
    // pour le faire, et c'est ce que fait un vrai raid : on ne tape pas, on se
    // deplace. La destination se lit sur la position de l'Empereur qu'on peut
    // blesser, donc elle bascule d'elle-meme a chaque echange - il n'y a rien a
    // memoriser et rien a remettre a zero.
    Position place;
    if (RaidAq40Utils::GetPrePullStation(bot, place) &&
        bot->GetExactDist2d(place.GetPositionX(), place.GetPositionY()) >= MARK_TOLERANCE)
    {
        MoveTo(bot->GetMapId(), place.GetPositionX(), place.GetPositionY(), place.GetPositionZ(),
               false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);
    }

    // ET ON REND VRAI, MEME SI ON N'A PAS BOUGE. C'est ce "vrai" qui retient le
    // raid : il arrete la file au-dessus des regles d'attaque, donc aucun sort
    // ni aucun coup ne part. Rendre faux rouvrirait le feu des qu'il n'y a plus
    // rien d'autre a faire.
    return true;
}

bool Aq40DragToMarkAction::Execute(Event /*event*/)
{
    Unit* mien = RaidAq40Utils::GetTwinOnMe(bot);
    if (!mien)
        return false;

    // LA MARQUE DE SON COTE A LUI, pas du mien. Si l'echange m'a colle
    // Vek'nilash alors que je me tenais au milieu, je l'emmene vers le bout de
    // salle dont il est le plus pres - l'emmener vers l'autre, ce serait
    // l'amener a son frere, et Heal Brother repartirait.
    Position marque;
    if (!RaidAq40Utils::GetMarkNear(mien, marque))
        return false;

    // Arrive : on reste. Rendre faux ici rendrait la main a l'IA de classe, qui
    // enverrait un corps-a-corps chercher une cible ailleurs - avec l'Empereur
    // derriere lui. On le garde la jusqu'a ce qu'un vrai tank le reprenne, et
    // c'est exactement ce que fait un joueur a qui le boss est tombe dessus.
    if (bot->GetExactDist2d(marque.GetPositionX(), marque.GetPositionY()) < MARK_TOLERANCE)
        return true;

    MoveTo(bot->GetMapId(), marque.GetPositionX(), marque.GetPositionY(), marque.GetPositionZ(),
           false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);
    return true;
}

bool Aq40DismissPetAction::Execute(Event /*event*/)
{
    if (!bot->GetPet())
        return false;

    // PET_SAVE_AS_CURRENT : il reste dans son emplacement actif, donc le
    // chasseur le rappellera de lui-meme une fois sorti de la salle. On ne lui
    // supprime rien, on le range.
    bot->RemovePet(nullptr, PET_SAVE_AS_CURRENT);
    return true;
}

bool Aq40PreSwapAction::Execute(Event /*event*/)
{
    Position place;
    if (!RaidAq40Utils::GetSwapStation(bot, place))
        return false;

    // Tant qu'on marche, on ne frappe pas : la cible est a l'autre bout, et lui
    // donner de la menace maintenant la donnerait sur un Empereur qu'un tank
    // s'apprete a reprendre.
    if (bot->GetExactDist2d(place.GetPositionX(), place.GetPositionY()) >= MARK_TOLERANCE)
    {
        bot->AttackStop();
        MoveTo(bot->GetMapId(), place.GetPositionX(), place.GetPositionY(), place.GetPositionZ(),
               false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);
        return true;
    }

    // ARRIVE, ET ON ATTEND. On rend vrai pour que rien ne renvoie le bot d'ou
    // il vient pendant les quelques secondes qui restent - c'est tout l'objet
    // d'etre parti en avance. Son Empereur va lui tomber dessus tout seul.
    return true;
}

bool Aq40CrossOverAction::Execute(Event /*event*/)
{
    // On ne frappe pas en traversant : ce serait donner de la menace sur un
    // Empereur qu'un tank est en train de replacer, a l'autre bout.
    bot->AttackStop();

    Position place;
    if (!RaidAq40Utils::GetPrePullStation(bot, place))
        return false;

    if (bot->GetExactDist2d(place.GetPositionX(), place.GetPositionY()) >= MARK_TOLERANCE)
        MoveTo(bot->GetMapId(), place.GetPositionX(), place.GetPositionY(), place.GetPositionZ(),
               false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);

    // VRAI DANS TOUS LES CAS, et c'est tout l'interet de cette regle. Tant
    // qu'elle est allumee, rien d'autre ne tourne sur ce bot : ni l'ecartement
    // qui le repoussait d'un petit saut, ni l'IA de classe qui le renvoyait sur
    // une cible du mauvais cote. Elle s'eteint quand il a passe le milieu, pas
    // avant, et pas sur une minuterie.
    return true;
}

bool Aq40KeepAwayAction::Execute(Event /*event*/)
{
    Unit* interdit = RaidAq40Utils::GetForbiddenTwin(bot);
    if (!interdit)
        return false;

    return FleePosition(interdit->GetPosition(), RaidAq40Utils::GetStayAwayRange(bot), 1000);
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
