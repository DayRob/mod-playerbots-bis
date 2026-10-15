/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Utils.h"
#include <cmath>
#include "Group.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include <list>

Creature* RaidAq40Utils::GetVeklor(Player* bot)
{
    return bot ? bot->FindNearestCreature(NPC_VEKLOR, TWIN_SCAN_RANGE) : nullptr;
}

Creature* RaidAq40Utils::GetVeknilash(Player* bot)
{
    return bot ? bot->FindNearestCreature(NPC_VEKNILASH, TWIN_SCAN_RANGE) : nullptr;
}

bool RaidAq40Utils::AreTwinsEngaged(Player* bot)
{
    if (Creature* veknilash = GetVeknilash(bot))
        if (veknilash->IsInCombat())
            return true;

    if (Creature* veklor = GetVeklor(bot))
        if (veklor->IsInCombat())
            return true;

    return false;
}

bool RaidAq40Utils::IsSpellDamageDealer(Player* bot)
{
    if (!bot)
        return false;

    // bySpec a dessein : la reponse doit coller aux talents du personnage, pas
    // aux strategies qui se trouvent chargees sur lui a cet instant.
    return PlayerbotAI::IsCaster(bot, true) && !PlayerbotAI::IsHeal(bot, true);
}

bool RaidAq40Utils::IsPhysicalDamageDealer(Player* bot)
{
    if (!bot)
        return false;

    // Les chasseurs comptent ici : leurs tirs sont physiques, donc Vek'lor y
    // est immunise meme s'ils combattent a distance. Les tanks aussi.
    return !PlayerbotAI::IsCaster(bot, true) && !PlayerbotAI::IsHeal(bot, true);
}

Unit* RaidAq40Utils::GetAssignedTwin(Player* bot)
{
    if (IsSpellDamageDealer(bot))
        return GetVeklor(bot);

    if (IsPhysicalDamageDealer(bot))
        return GetVeknilash(bot);

    return nullptr;
}

Unit* RaidAq40Utils::GetForbiddenTwin(Player* bot)
{
    if (IsSpellDamageDealer(bot))
        return GetVeknilash(bot);

    if (IsPhysicalDamageDealer(bot))
        return GetVeklor(bot);

    return nullptr;
}

uint8 RaidAq40Utils::TankIndex(Player* bot)
{
    if (!bot || !bot->IsAlive() || !GET_PLAYERBOT_AI(bot) || !PlayerbotAI::IsTank(bot, false))
        return TANK_INDEX_NONE;

    Group* groupe = bot->GetGroup();
    if (!groupe)
        return TANK_INDEX_NONE;

    uint8 rang = 0;

    for (GroupReference* ref = groupe->GetFirstMember(); ref; ref = ref->next())
    {
        Player* membre = ref->GetSource();
        if (!membre || membre == bot || !membre->IsAlive())
            continue;

        // Un humain n'est jamais range : rien ici ne le ferait bouger, et lui
        // donner un poste reviendrait a ne le donner a personne.
        if (!GET_PLAYERBOT_AI(membre) || !PlayerbotAI::IsTank(membre, false))
            continue;

        if (membre->GetGUID().GetCounter() < bot->GetGUID().GetCounter())
            ++rang;
    }

    return rang;
}

bool RaidAq40Utils::IsVeknilashTank(Player* bot)
{
    uint8 const rang = TankIndex(bot);
    return rang != TANK_INDEX_NONE && rang != 2;
}

bool RaidAq40Utils::IsBugTank(Player* bot)
{
    return TankIndex(bot) == 2;
}

bool RaidAq40Utils::IsVeklorHolder(Player* bot)
{
    // Le test le moins cher d'abord : tout le raid sauf les lanceurs de sorts
    // s'arrete ici, et la liste du groupe n'est jamais parcourue pour eux.
    if (!bot || !bot->IsAlive() || !GET_PLAYERBOT_AI(bot) || !IsSpellDamageDealer(bot))
        return false;

    Group* groupe = bot->GetGroup();
    if (!groupe)
        return false;

    bool const jeSuisDemoniste = bot->getClass() == CLASS_WARLOCK;

    for (GroupReference* ref = groupe->GetFirstMember(); ref; ref = ref->next())
    {
        Player* membre = ref->GetSource();
        if (!membre || membre == bot || !membre->IsAlive())
            continue;

        if (!GET_PLAYERBOT_AI(membre) || !IsSpellDamageDealer(membre))
            continue;

        // UN DEMONISTE PASSE AVANT TOUT LE MONDE : c'est le tank de Vek'lor de
        // la strategie d'origine. Drain de vie, Lien spirituel et une armure
        // demoniaque font de lui le seul lanceur de sorts qui encaisse ce que
        // Vek'lor rend.
        bool const luiDemoniste = membre->getClass() == CLASS_WARLOCK;
        if (luiDemoniste && !jeSuisDemoniste)
            return false;
        if (jeSuisDemoniste && !luiDemoniste)
            continue;

        if (membre->GetGUID().GetCounter() < bot->GetGUID().GetCounter())
            return false;
    }

    return true;
}

void RaidAq40Utils::GetMarks(Position& marqueA, Position& marqueB)
{
    // Des constantes, donc aucune creature a chercher. Appelee par tout le
    // chemin d'avant-pull, pour chaque bot, a chaque tick : une recherche en
    // grille a 250 yards couterait cher pour repondre une chose qui ne change
    // jamais.
    //
    // ET AUCUNE DES DEUX N'EST "CELLE DE" QUI QUE CE SOIT ICI. Qui est de quel
    // cote se lit sur la position des Empereurs, pas sur une lettre : voir
    // GetMarkNear.
    marqueA.Relocate(MARQUE_A.x, MARQUE_A.y, MARQUE_A.z);
    marqueB.Relocate(MARQUE_B.x, MARQUE_B.y, MARQUE_B.z);
}

void RaidAq40Utils::GetMiddle(Position& out)
{
    out.Relocate((MARQUE_A.x + MARQUE_B.x) / 2.0f,
                 (MARQUE_A.y + MARQUE_B.y) / 2.0f,
                 (MARQUE_A.z + MARQUE_B.z) / 2.0f);
}

namespace
{
    float EcartPlan(Position const& a, Position const& b)
    {
        float const dX = a.GetPositionX() - b.GetPositionX();
        float const dY = a.GetPositionY() - b.GetPositionY();
        return std::sqrt(dX * dX + dY * dY);
    }
}

bool RaidAq40Utils::GetMarkNear(Unit* jumeau, Position& out)
{
    if (!jumeau)
        return false;

    Position marqueA;
    Position marqueB;
    GetMarks(marqueA, marqueB);

    // 82 yards d'un cote contre 168 de l'autre : la reponse n'est jamais
    // serree, et elle reste juste si un jour les marques changent de nom.
    out = (EcartPlan(jumeau->GetPosition(), marqueA) <= EcartPlan(jumeau->GetPosition(), marqueB))
              ? marqueA
              : marqueB;
    return true;
}

bool RaidAq40Utils::IsInTwinsRoom(Player* bot)
{
    if (!bot || bot->GetMapId() != TEMPLE_OF_AHNQIRAJ_MAP_ID)
        return false;

    Position milieu;
    GetMiddle(milieu);
    return bot->GetExactDist2d(milieu.GetPositionX(), milieu.GetPositionY()) <= PREPULL_GATHER_RANGE;
}

bool RaidAq40Utils::GetMyMark(Player* bot, Position& out)
{
    uint8 const rang = TankIndex(bot);
    if (rang == TANK_INDEX_NONE || rang == 2)
        return false;

    Position marqueA;
    Position marqueB;
    GetMarks(marqueA, marqueB);

    if (rang == 0)
    {
        out = marqueA;
        return true;
    }
    if (rang == 1)
    {
        out = marqueB;
        return true;
    }

    // Les tanks en surnombre n'ont pas de marque : ils suivent Vek'nilash, donc
    // leur destination est la marque de son cote a lui.
    Creature* const veknilash = GetVeknilash(bot);
    if (!veknilash)
        return false;

    out = (EcartPlan(veknilash->GetPosition(), marqueA) <= EcartPlan(veknilash->GetPosition(), marqueB))
              ? marqueA
              : marqueB;
    return true;
}

bool RaidAq40Utils::IsVeknilashOnMySide(Player* bot)
{
    uint8 const rang = TankIndex(bot);
    if (rang == TANK_INDEX_NONE || rang == 2)
        return false;

    // Un tank en surnombre est toujours "de son cote" : il n'a pas de marque a
    // garder, il va ou Vek'nilash est.
    if (rang > 2)
        return true;

    Creature* const veknilash = GetVeknilash(bot);
    if (!veknilash)
        return false;

    Position marqueA;
    Position marqueB;
    GetMarks(marqueA, marqueB);

    bool const enA = EcartPlan(veknilash->GetPosition(), marqueA) <= EcartPlan(veknilash->GetPosition(), marqueB);
    return (rang == 0) ? enA : !enA;
}

bool RaidAq40Utils::GetVeklorStation(Player* bot, Position& out)
{
    Position marqueA;
    Position marqueB;
    GetMarks(marqueA, marqueB);

    Creature* const veklor = GetVeklor(bot);
    if (!veklor)
        return false;

    // La marque du cote de Vek'lor, et l'autre pour donner la direction du
    // milieu.
    bool const enA = EcartPlan(veklor->GetPosition(), marqueA) <= EcartPlan(veklor->GetPosition(), marqueB);

    Position const& mienne = enA ? marqueA : marqueB;
    Position const& autre = enA ? marqueB : marqueA;

    float dX = autre.GetPositionX() - mienne.GetPositionX();
    float dY = autre.GetPositionY() - mienne.GetPositionY();
    float const ecart = std::sqrt(dX * dX + dY * dY);
    if (ecart < 1.0f)
        return false;

    out.Relocate(mienne.GetPositionX() + VEKLOR_HOLDER_OFFSET * (dX / ecart),
                 mienne.GetPositionY() + VEKLOR_HOLDER_OFFSET * (dY / ecart),
                 mienne.GetPositionZ());
    return true;
}

bool RaidAq40Utils::GetPrePullStation(Player* bot, Position& out)
{
    if (!bot)
        return false;

    // Les trois tanks d'abord.
    if (IsBugTank(bot))
    {
        GetMiddle(out);
        return true;
    }

    if (IsVeknilashTank(bot))
        return GetMyMark(bot, out);

    // Puis celui qui tient Vek'lor.
    if (IsVeklorHolder(bot))
        return GetVeklorStation(bot, out);

    // Les soigneurs ne sont pas places : ils suivent le raid et soignent.
    bool const sorts = IsSpellDamageDealer(bot);
    bool const physique = IsPhysicalDamageDealer(bot);
    if (!sorts && !physique)
        return false;

    // CHACUN DU COTE DE CELUI QU'IL PEUT BLESSER, et c'est la position de cet
    // Empereur-la qui le dit. Les corps-a-corps vont donc du cote de
    // Vek'nilash, les lanceurs de sorts du cote de Vek'lor - sans qu'une
    // lettre ecrite ici ait son mot a dire.
    Unit* const assigne = GetAssignedTwin(bot);
    Position marque;
    if (!assigne || !GetMarkNear(assigne, marque))
        return false;

    // Puis un decalage VERS LE MILIEU pour les corps-a-corps, qui ne doivent
    // pas se tenir sur leur tank - les lanceurs de sorts sont deja en retrait -
    // et un ecartement lateral propre a chaque bot, pour qu'ils ne se marchent
    // pas dessus : la perpendiculaire, graduee sur son GUID, donc stable d'un
    // tick a l'autre puisqu'un GUID ne change jamais.
    Position milieu;
    GetMiddle(milieu);

    float dX = milieu.GetPositionX() - marque.GetPositionX();
    float dY = milieu.GetPositionY() - marque.GetPositionY();
    float const axe = std::sqrt(dX * dX + dY * dY);
    if (axe < 1.0f)
    {
        out = marque;
        return true;
    }

    dX /= axe;
    dY /= axe;

    float const lateral = (float(bot->GetGUID().GetCounter() % 7u) - 3.0f) * PREPULL_SPREAD_STEP;
    float const recul = physique ? MELEE_PREPULL_OFFSET : 0.0f;

    out.Relocate(marque.GetPositionX() + recul * dX - lateral * dY,
                 marque.GetPositionY() + recul * dY + lateral * dX,
                 marque.GetPositionZ());
    return true;
}

bool RaidAq40Utils::AllTanksPosted(Player* bot)
{
    if (!bot)
        return false;

    Group* groupe = bot->GetGroup();
    if (!groupe)
        return false;

    for (GroupReference* ref = groupe->GetFirstMember(); ref; ref = ref->next())
    {
        Player* membre = ref->GetSource();
        if (!membre || !membre->IsAlive() || !GET_PLAYERBOT_AI(membre))
            continue;

        // Seuls les tanks comptent. Un corps-a-corps en retard rejoindra sa
        // place pendant que le boss marche vers son tank; un tank en retard,
        // lui, c'est un Empereur qui part sur un soigneur.
        if (TankIndex(membre) == TANK_INDEX_NONE)
            continue;

        Position poste;
        if (!GetPrePullStation(membre, poste))
            continue;

        // Deux fois la tolerance pour les AUTRES : un bot pose a trois yards et
        // demi de sa marque est arrive, et exiger de lui la precision qu'on
        // exige de soi-meme ferait osciller la condition d'un tick a l'autre.
        if (membre->GetExactDist2d(poste.GetPositionX(), poste.GetPositionY()) > MARK_TOLERANCE * 2.0f)
            return false;
    }

    return true;
}

bool RaidAq40Utils::IsBugOnMe(Player* bot)
{
    if (!bot)
        return false;

    // getAttackers() est exactement la question : qui a ce bot en melee en ce
    // moment. La poser bat le fait de chercher la bestiole la plus proche en
    // esperant que ce soit celle qui mord - une seconde derriere la premiere
    // faisait decrocher tout le raid du boss.
    for (Unit* attaquant : bot->getAttackers())
    {
        if (!attaquant)
            continue;

        uint32 const entry = attaquant->GetEntry();
        if (entry == NPC_QIRAJI_SCARAB || entry == NPC_QIRAJI_SCORPION)
            return true;
    }

    return false;
}

Unit* RaidAq40Utils::GetBugToTank(Player* bot)
{
    if (!bot)
        return nullptr;

    std::list<Creature*> bestioles;
    bot->GetCreatureListWithEntryInGrid(bestioles, NPC_QIRAJI_SCARAB, BUG_SCAN_RANGE);

    std::list<Creature*> scorpions;
    bot->GetCreatureListWithEntryInGrid(scorpions, NPC_QIRAJI_SCORPION, BUG_SCAN_RANGE);
    bestioles.splice(bestioles.end(), scorpions);

    Unit* meilleure = nullptr;
    uint8 meilleurRang = 255;
    float meilleureDistance = 0.0f;

    for (Creature* bestiole : bestioles)
    {
        if (!bestiole || !bestiole->IsAlive() || !bestiole->IsInCombat())
            continue;

        // Le IsInCombat() ci-dessus est deja tout le tri : le script du sort
        // fait SetInCombatWithZone() sur celle qu'il retourne, et c'est la
        // difference entre une bestiole reveillee et les dizaines qui dorment
        // dans la salle depuis toujours. Un test de faction en plus ne
        // repondrait rien de neuf, et repondrait faux le jour ou ces bestioles
        // naissent hostiles dans la base.

        Unit* victime = bestiole->GetVictim();

        uint8 rang = 2;
        if (Player* joueur = victime ? victime->ToPlayer() : nullptr)
        {
            if (PlayerbotAI::IsHeal(joueur, true))
                rang = 0;
            else if (joueur != bot && !PlayerbotAI::IsTank(joueur, false))
                rang = 1;
        }

        float const distance = bot->GetExactDist2d(bestiole);
        if (rang < meilleurRang || (rang == meilleurRang && distance < meilleureDistance))
        {
            meilleurRang = rang;
            meilleureDistance = distance;
            meilleure = bestiole;
        }
    }

    return meilleure;
}

float RaidAq40Utils::Separation(Unit* veklor, Unit* veknilash)
{
    if (!veklor || !veknilash)
        return 0.0f;

    return veklor->GetExactDist2d(veknilash);
}
