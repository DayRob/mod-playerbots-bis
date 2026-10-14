/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Aq40Utils.h"
#include "Group.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include <initializer_list>

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
    Creature* veklor = GetVeklor(bot);
    Creature* veknilash = GetVeknilash(bot);
    if (!veklor || !veknilash)
        return false;

    return veklor->IsInCombat() || veknilash->IsInCombat();
}

bool RaidAq40Utils::IsSpellDamageDealer(Player* bot)
{
    if (!bot)
        return false;

    // bySpec on purpose: the answer has to match the character's talents, not
    // whichever strategies happen to be loaded on it right now.
    return PlayerbotAI::IsCaster(bot, true) && !PlayerbotAI::IsHeal(bot, true);
}

bool RaidAq40Utils::IsPhysicalDamageDealer(Player* bot)
{
    if (!bot)
        return false;

    // Hunters count here: their shots are physical, so Vek'lor is immune to them
    // even though they fight at range. Tanks count too - Vek'nilash is the twin a
    // warrior can hold.
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

float RaidAq40Utils::Separation(Unit* veklor, Unit* veknilash)
{
    if (!veklor || !veknilash)
        return 0.0f;

    return veklor->GetExactDist2d(veknilash);
}

bool RaidAq40Utils::IsBugOnMe(Player* bot)
{
    if (!bot)
        return false;

    // Unit::getAttackers() is exactly the question: who has this bot in melee
    // right now. Asking it beats looking for the nearest bug and hoping it is
    // the one doing the biting - a second bug behind the first used to make the
    // whole raid stand down from the boss.
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

uint8 RaidAq40Utils::TankIndex(Player* bot)
{
    // LE ROLE TENU, PAS LA SPECIALISATION. Partout ailleurs dans ce dossier la
    // question se pose "bySpec", parce qu'elle porte sur ce qu'un personnage
    // PEUT faire - un mage reste un mage. Ici elle porte sur ce qu'un bot FAIT :
    // celui qui tiendra un Empereur est celui qui tourne avec la strategie de
    // tank, pas celui dont les talents disent "protection". C'est aussi la
    // reponse qui ne coute rien, et elle est demandee pour chaque membre du
    // groupe a chaque tick.
    if (!bot || !bot->IsAlive() || !PlayerbotAI::IsTank(bot, false) || !GET_PLAYERBOT_AI(bot))
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
        // donner un poste reviendrait a ne donner ce poste a personne.
        if (!GET_PLAYERBOT_AI(membre) || !PlayerbotAI::IsTank(membre, false))
            continue;

        if (membre->GetGUID().GetCounter() < bot->GetGUID().GetCounter())
            ++rang;
    }

    return rang;
}

bool RaidAq40Utils::GetAnchor(Player* bot, Position& out)
{
    uint8 const rang = TankIndex(bot);
    if (rang > 1)
        return false;

    // Rang 0 sur le socle de Vek'nilash : c'est le jumeau qu'un tank peut
    // vraiment tenir, donc le poste qui compte quand il n'y a qu'un seul tank.
    Creature* const socle = (rang == 0) ? GetVeknilash(bot) : GetVeklor(bot);
    if (!socle)
        return false;

    out = socle->GetHomePosition();
    return true;
}

Unit* RaidAq40Utils::GetTwinForTank(Player* bot)
{
    uint8 const rang = TankIndex(bot);
    if (rang > 1)
        return nullptr;

    Creature* const veklor = GetVeklor(bot);
    Creature* const veknilash = GetVeknilash(bot);
    if (!veklor || !veknilash)
        return nullptr;

    // LE PARTAGE SE FAIT EN UNE SEULE COMPARAISON, et les deux tanks font la
    // meme : le jumeau le plus proche du socle du rang 0 lui revient, l'autre
    // va au rang 1. Donner a chacun "le jumeau le plus proche de MON socle"
    // aurait donne le meme aux deux le jour ou les deux Empereurs se retrouvent
    // sur le meme piedestal - c'est-a-dire exactement le jour ou cette regle
    // doit servir.
    Position const& socleZero = veknilash->GetHomePosition();

    bool const veklorAuSocleZero =
        veklor->GetExactDist2d(socleZero.GetPositionX(), socleZero.GetPositionY()) <
        veknilash->GetExactDist2d(socleZero.GetPositionX(), socleZero.GetPositionY());

    if (rang == 0)
        return veklorAuSocleZero ? static_cast<Unit*>(veklor) : static_cast<Unit*>(veknilash);

    return veklorAuSocleZero ? static_cast<Unit*>(veknilash) : static_cast<Unit*>(veklor);
}

bool RaidAq40Utils::IsOnAnchorDuty(Player* bot)
{
    return TankIndex(bot) <= 1 && AreTwinsEngaged(bot);
}

bool RaidAq40Utils::IsBugTank(Player* bot)
{
    return TankIndex(bot) == 2;
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

        // CE QUI DISTINGUE UNE BESTIOLE REVEILLEE. Les scarabees de la salle
        // sont la depuis toujours et ne mordent personne; le script du sort leur
        // met FACTION_HOSTILE au moment ou elles se retournent, et c'est la
        // seule difference lisible d'ici.
        if (!bestiole->IsHostileTo(bot))
            continue;

        Unit* victime = bestiole->GetVictim();

        // L'ORDRE D'URGENCE. Un soigneur mort coute le raid; un attaquant mordu
        // peut encore reculer; une bestiole deja sur le tank, ou qui n'a encore
        // personne, attend son tour.
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

bool RaidAq40Utils::IsOnBugDuty(Player* bot)
{
    // IsBugTank d'abord, et TankIndex rend son verdict sans rien chercher en
    // grille pour tout le monde sauf les tanks : la recherche ci-dessous ne
    // tourne donc que pour un seul bot du raid.
    return IsBugTank(bot) && GetBugToTank(bot) != nullptr;
}
