/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Actions.h"
#include "Aq40Utils.h"
#include <cmath>
#include <string>
#include <vector>

namespace
{
    // Les provocations de chaque classe de tank, dans l'ordre ou on les essaie.
    // CanCastSpell d'abord : un bot qui ne connait pas le sort, ou qui l'a en
    // recharge, doit passer au geste suivant au lieu de perdre son tick.
    //
    // Pas de paladin dans la liste par hasard : Main du chatiment existe, mais
    // ce serveur n'a pas de bot paladin. La laisser ne couterait rien et
    // prendrait la place d'une question reglee.
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

    // How far past Vek'nilash the attackers plant themselves. Small enough that he
    // closes the gap in a step or two, large enough that he actually has to walk.
    constexpr float DRAG_STEP = 8.0f;
}

bool Aq40TwinsDragApartAction::Execute(Event /*event*/)
{
    Unit* veklor = RaidAq40Utils::GetVeklor(bot);
    Unit* veknilash = RaidAq40Utils::GetVeknilash(bot);
    if (!veklor || !veknilash)
        return false;

    // Dragging him anywhere is pointless until he is the one being hit.
    if (AI_VALUE(Unit*, "current target") != veknilash)
        return Attack(veknilash);

    float dX = veknilash->GetPositionX() - veklor->GetPositionX();
    float dY = veknilash->GetPositionY() - veklor->GetPositionY();
    float separation = std::sqrt(dX * dX + dY * dY);

    // On the pull the two of them are side by side, so "away from Vek'lor" has no
    // meaningful direction yet. Pull towards the bot instead, which at least takes
    // Vek'nilash off the pile.
    if (separation < 1.0f)
    {
        dX = bot->GetPositionX() - veklor->GetPositionX();
        dY = bot->GetPositionY() - veklor->GetPositionY();
        separation = std::sqrt(dX * dX + dY * dY);

        if (separation < 1.0f)
            return false;
    }

    float const targetX = veknilash->GetPositionX() + DRAG_STEP * (dX / separation);
    float const targetY = veknilash->GetPositionY() + DRAG_STEP * (dY / separation);

    if (bot->GetExactDist2d(targetX, targetY) < 2.0f)
        return false;

    return MoveTo(bot->GetMapId(), targetX, targetY, veknilash->GetPositionZ(), false, false, false, false,
                  MovementPriority::MOVEMENT_COMBAT, true, false);
}

bool Aq40TwinsKeepDistanceAction::Execute(Event /*event*/)
{
    Unit* forbidden = RaidAq40Utils::GetForbiddenTwin(bot);
    if (!forbidden)
        return false;

    float const keepAway = RaidAq40Utils::IsSpellDamageDealer(bot) ? CASTER_STAY_AWAY_FROM_VEKNILASH
                                                                   : MELEE_STAY_AWAY_FROM_VEKLOR;

    return FleePosition(forbidden->GetPosition(), keepAway, 1000);
}

bool Aq40TwinsAttackMyTwinAction::Execute(Event /*event*/)
{
    Unit* assigned = RaidAq40Utils::GetAssignedTwin(bot);
    if (!assigned || !assigned->IsAlive())
        return false;

    if (AI_VALUE(Unit*, "current target") == assigned)
        return false;

    return Attack(assigned);
}

bool Aq40TwinsFarSideAction::Execute(Event /*event*/)
{
    Unit* mine = RaidAq40Utils::GetAssignedTwin(bot);
    Unit* other = RaidAq40Utils::GetForbiddenTwin(bot);
    if (!mine || !other)
        return false;

    float const dX = mine->GetPositionX() - other->GetPositionX();
    float const dY = mine->GetPositionY() - other->GetPositionY();
    float const ecart = std::sqrt(dX * dX + dY * dY);
    if (ecart < 1.0f)
        return false;

    // Un attaquant physique se place AU CONTACT, pas en retrait : sa place est
    // derriere son jumeau, pas a huit yards de lui. L'ecartement actif, lui,
    // vise plus loin exprès pour faire marcher le boss - mais il ne tourne que
    // quand la separation est deja perdue, et il coute le DPS de la melee.
    // Celle-ci ne coute rien et sert tout le temps.
    float const recul = RaidAq40Utils::IsSpellDamageDealer(bot) ? CASTER_FAR_SIDE_OFFSET
                                                                : bot->GetMeleeRange(mine);

    float const targetX = mine->GetPositionX() + recul * (dX / ecart);
    float const targetY = mine->GetPositionY() + recul * (dY / ecart);

    if (bot->GetExactDist2d(targetX, targetY) < 2.0f)
        return false;

    return MoveTo(bot->GetMapId(), targetX, targetY, mine->GetPositionZ(), false, false, false, false,
                  MovementPriority::MOVEMENT_COMBAT, true, false);
}

bool Aq40TankAnchorAction::Execute(Event /*event*/)
{
    Unit* mien = RaidAq40Utils::GetTwinForTank(bot);
    if (!mien || !mien->IsAlive())
        return false;

    Position socle;
    if (!RaidAq40Utils::GetAnchor(bot, socle))
        return false;

    // ── LE POSTE DE VEK'LOR : ATTENDRE L'ECHANGE ──────────────────────────
    //
    // Rien a tenir ici. Vek'lor est immunise a tout ce qu'un tank frappe, et le
    // provoquer ne ferait que le promener - il suit sa cible jusqu'a 45 yards,
    // donc l'aggro d'un tank qui recule le ferait avancer. Ce sont les lanceurs
    // de sorts qui le gardent, et ils le font en lui faisant des degats.
    //
    // Le travail du tank, ici, c'est d'etre LA quand ca bascule. Twin Teleport
    // echange les deux toutes les 30 a 40 secondes, vide les menaces et offre
    // 2000 au joueur le PLUS PROCHE. A dix yards il est plus proche que les
    // lanceurs de sorts, qui se tiennent a 25 - donc Vek'nilash, en arrivant,
    // l'agresse lui. Et dix yards, c'est aussi deux de plus que la portee de
    // contact qu'Arcane Burst (568) cherche avant de repousser.
    if (mien->GetEntry() == NPC_VEKLOR)
    {
        // Sauf s'il se fait mordre. Un tank qui attend l'echange n'a rien
        // d'autre a faire que de tuer la bestiole qui lui est tombee dessus, et
        // rendre faux ici rend la main a son IA de classe pour exactement ca.
        if (RaidAq40Utils::IsBugOnMe(bot))
            return false;

        Unit* autre = RaidAq40Utils::GetVeknilash(bot);
        if (!autre)
            return false;

        float dX = mien->GetPositionX() - autre->GetPositionX();
        float dY = mien->GetPositionY() - autre->GetPositionY();
        float const ecart = std::sqrt(dX * dX + dY * dY);

        // Le poste est a dix yards de Vek'lor, du cote oppose a son frere : y
        // aller ne rapproche donc jamais le tank de l'autre Empereur. Les deux
        // colles l'un sur l'autre, la direction ne veut plus rien dire et le
        // socle reste la meilleure reponse.
        float posteX = socle.GetPositionX();
        float posteY = socle.GetPositionY();
        float posteZ = socle.GetPositionZ();

        if (ecart >= 1.0f)
        {
            posteX = mien->GetPositionX() + VEKLOR_TANK_DISTANCE * (dX / ecart);
            posteY = mien->GetPositionY() + VEKLOR_TANK_DISTANCE * (dY / ecart);
            posteZ = mien->GetPositionZ();
        }

        if (bot->GetExactDist2d(posteX, posteY) >= TANK_ANCHOR_TOLERANCE)
            return MoveTo(bot->GetMapId(), posteX, posteY, posteZ, false, false, false, false,
                          MovementPriority::MOVEMENT_COMBAT, true, false);

        // EN POSTE, ET ON Y RESTE. Rendre faux ici rendrait la main a l'IA de
        // classe, qui enverrait le tank chercher une cible a frapper a l'autre
        // bout de la salle - c'est-a-dire exactement ce que ce poste existe
        // pour empecher. Un tank qui attend trente secondes sans rien faire,
        // c'est le prix de l'echange, et c'est ce que fait un vrai raid.
        return true;
    }

    // ── LE POSTE DE VEK'NILASH : LE TENIR, ET LE RAMENER CHEZ LUI ─────────
    if (AI_VALUE(Unit*, "current target") != mien)
        return Attack(mien);

    float const distance = bot->GetExactDist2d(mien);

    // La provocation, des qu'il regarde ailleurs. C'est tout le "pret a prendre
    // l'aggro au switch" : les 2000 de menace offerts apres la teleportation
    // vont au plus proche, et une bestiole ou un voleur mal place peut passer
    // devant. La provocation corrige en un geste ce que la distance a rate.
    if (mien->GetVictim() != bot && distance <= TANK_GRAB_RANGE && Provoque(botAI, mien))
        return true;

    // Trop loin meme pour le provoquer : on va le chercher. C'est le cas de la
    // salle ou les deux Empereurs ont fini sur le meme piedestal.
    if (mien->GetVictim() != bot && distance > TANK_GRAB_RANGE)
        return MoveTo(bot->GetMapId(), mien->GetPositionX(), mien->GetPositionY(), mien->GetPositionZ(),
                      false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);

    // Et on rentre sur le socle, lui derriere : il suit son attaquant au
    // contact. C'est comme ca que les deux Empereurs reviennent chacun sur son
    // piedestal au lieu de rester colles.
    if (bot->GetExactDist2d(socle.GetPositionX(), socle.GetPositionY()) < TANK_ANCHOR_TOLERANCE)
        return false;  // en poste : l'IA de classe reprend la main pour frapper

    return MoveTo(bot->GetMapId(), socle.GetPositionX(), socle.GetPositionY(), socle.GetPositionZ(),
                  false, false, false, false, MovementPriority::MOVEMENT_COMBAT, true, false);
}

bool Aq40TankTheBugsAction::Execute(Event /*event*/)
{
    Unit* bestiole = RaidAq40Utils::GetBugToTank(bot);

    // RIEN A FAIRE : ON TIENT LE MILIEU. C'est le poste du schema - les
    // bestioles se reveillent la, les soigneurs s'y tiennent. Rendre faux ici
    // rendrait la main a l'IA de classe, qui renverrait le tank sur Vek'nilash
    // a quatre-vingts yards de la prochaine bestiole.
    if (!bestiole)
    {
        Position milieu;
        if (!RaidAq40Utils::GetBugStation(bot, milieu))
            return false;

        if (bot->GetExactDist2d(milieu.GetPositionX(), milieu.GetPositionY()) >= TANK_ANCHOR_TOLERANCE)
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

    if (Provoque(botAI, bestiole))
        return true;

    if (AI_VALUE(Unit*, "current target") != bestiole)
        return Attack(bestiole);

    // Hors de portee de provocation et deja pris pour cible : il reste a courir
    // dessus. Sans ca, le tank reste plante pendant que le soigneur se fait
    // manger a vingt yards de lui.
    return MoveTo(bot->GetMapId(), bestiole->GetPositionX(), bestiole->GetPositionY(),
                  bestiole->GetPositionZ(), false, false, false, false,
                  MovementPriority::MOVEMENT_COMBAT, true, false);
}
