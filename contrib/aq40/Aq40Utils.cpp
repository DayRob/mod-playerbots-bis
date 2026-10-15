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

bool RaidAq40Utils::GetPosts(Player* bot, Position& poste0, Position& poste1)
{
    Creature* const veklor = GetVeklor(bot);
    Creature* const veknilash = GetVeknilash(bot);
    if (!veklor || !veknilash)
        return false;

    // La plateforme d'apparition de Vek'nilash sert de reference, pour une
    // seule raison : elle ne bouge jamais. Le rang 0 tient le poste qui en est
    // le plus proche, donc chaque tank garde son cote du debut a la fin.
    Position const& plateformeZero = veknilash->GetHomePosition();

    auto defini = [](Aq40TankPost const& poste) { return poste.x != 0.0f || poste.y != 0.0f; };

    // Postes non renseignes : on se rabat sur les plateformes d'apparition.
    // 158,2 yards les separent, donc Heal Brother ne part pas - mais les
    // Empereurs restent sur leurs socles au lieu d'etre tires contre les murs.
    if (!defini(TANK_POST_A) || !defini(TANK_POST_B))
    {
        poste0 = plateformeZero;
        poste1 = veklor->GetHomePosition();
        return true;
    }

    auto ecart = [](Aq40TankPost const& poste, Position const& repere)
    {
        float const dX = poste.x - repere.GetPositionX();
        float const dY = poste.y - repere.GetPositionY();
        return dX * dX + dY * dY;
    };

    bool const aEstLePremier = ecart(TANK_POST_A, plateformeZero) <= ecart(TANK_POST_B, plateformeZero);

    Aq40TankPost const& premier = aEstLePremier ? TANK_POST_A : TANK_POST_B;
    Aq40TankPost const& second = aEstLePremier ? TANK_POST_B : TANK_POST_A;

    poste0.Relocate(premier.x, premier.y, premier.z);
    poste1.Relocate(second.x, second.y, second.z);
    return true;
}

bool RaidAq40Utils::GetAnchor(Player* bot, Position& out)
{
    uint8 const rang = TankIndex(bot);
    if (rang > 1)
        return false;

    Position poste0;
    Position poste1;
    if (!GetPosts(bot, poste0, poste1))
        return false;

    out = (rang == 0) ? poste0 : poste1;
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

    Position poste0;
    Position poste1;
    if (!GetPosts(bot, poste0, poste1))
        return nullptr;

    // LE PARTAGE SE FAIT EN UNE SEULE COMPARAISON, et les deux tanks font la
    // meme : le jumeau le plus proche du poste du rang 0 lui revient, l'autre
    // va au rang 1. Donner a chacun "le jumeau le plus proche de MON poste"
    // aurait donne le meme aux deux le jour ou les deux Empereurs se retrouvent
    // au meme endroit - c'est-a-dire exactement le jour ou cette regle doit
    // servir.
    bool const veklorAuPosteZero =
        veklor->GetExactDist2d(poste0.GetPositionX(), poste0.GetPositionY()) <
        veknilash->GetExactDist2d(poste0.GetPositionX(), poste0.GetPositionY());

    if (rang == 0)
        return veklorAuPosteZero ? static_cast<Unit*>(veklor) : static_cast<Unit*>(veknilash);

    return veklorAuPosteZero ? static_cast<Unit*>(veknilash) : static_cast<Unit*>(veklor);
}

bool RaidAq40Utils::IsOnAnchorDuty(Player* bot)
{
    return TankIndex(bot) <= 1 && AreTwinsEngaged(bot);
}

bool RaidAq40Utils::IsVeklorHolder(Player* bot)
{
    // Le test le moins cher d'abord : tout le raid sauf les lanceurs de sorts
    // s'arrete ici, et la liste du groupe n'est jamais parcourue pour eux.
    if (!bot || !bot->IsAlive() || !IsSpellDamageDealer(bot) || !GET_PLAYERBOT_AI(bot))
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

        // UN DEMONISTE PASSE AVANT TOUT LE MONDE. C'est le tank de Vek'lor de
        // la strategie d'origine : Drain de vie, Lien spirituel et une armure
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
    // UN POSTE, PAS UNE REACTION. La premiere version ne rendait vrai que
    // lorsqu'une bestiole etait deja reveillee - donc entre deux, le tank
    // repartait sur Vek'nilash, a quatre-vingts yards de la ou la suivante
    // allait tomber. Elle en reveille une toutes les quelques secondes : le
    // temps qu'il revienne, le soigneur avait deja ete mordu.
    //
    // Il tient donc le milieu tout le combat, comme sur le schema : les
    // bestioles y sont, les soigneurs aussi.
    return IsBugTank(bot) && AreTwinsEngaged(bot);
}

bool RaidAq40Utils::GetBugStation(Player* bot, Position& out)
{
    // LE MILIEU DES DEUX POSTES, pas des deux Empereurs. Les postes ne bougent
    // jamais; les Empereurs, eux, s'echangent toutes les trente secondes et se
    // promenent entre-temps, donc un milieu calcule sur eux ferait marcher le
    // tank sans raison a chaque tick.
    Position poste0;
    Position poste1;
    if (!GetPosts(bot, poste0, poste1))
        return false;

    out.Relocate((poste0.GetPositionX() + poste1.GetPositionX()) / 2.0f,
                 (poste0.GetPositionY() + poste1.GetPositionY()) / 2.0f,
                 (poste0.GetPositionZ() + poste1.GetPositionZ()) / 2.0f);
    return true;
}

bool RaidAq40Utils::GetPrePullStation(Player* bot, Position& out)
{
    Position poste0;
    Position poste1;
    if (!GetPosts(bot, poste0, poste1))
        return false;

    uint8 const rang = TankIndex(bot);
    if (rang == 0)
    {
        out = poste0;
        return true;
    }
    if (rang == 1)
    {
        out = poste1;
        return true;
    }
    if (rang == 2)
        return GetBugStation(bot, out);

    // Les soigneurs ne sont pas places. Ils suivent le raid et soignent; les
    // pousser quelque part ne ferait que les couper de ce qu'ils doivent voir.
    bool const sorts = IsSpellDamageDealer(bot);
    bool const physique = IsPhysicalDamageDealer(bot);
    if (!sorts && !physique)
        return false;

    // Le poste du jumeau qu'il pourra blesser. Vek'nilash sera tenu au poste 0
    // - c'est celui qui est le plus proche de sa plateforme - donc les
    // corps-a-corps y vont, et les lanceurs de sorts vont en face.
    Position const& poste = physique ? poste0 : poste1;
    Position const& autre = physique ? poste1 : poste0;

    float dX = autre.GetPositionX() - poste.GetPositionX();
    float dY = autre.GetPositionY() - poste.GetPositionY();
    float const ecart = std::sqrt(dX * dX + dY * dY);
    if (ecart < 1.0f)
        return false;

    dX /= ecart;
    dY /= ecart;

    float const recul = physique ? MELEE_PREPULL_OFFSET : CASTER_PREPULL_OFFSET;

    // L'ecartement lateral, gradue sur le GUID : sept rangs de part et d'autre
    // de l'axe, stables d'un tick a l'autre puisqu'un GUID ne change jamais.
    float const lateral = (float(bot->GetGUID().GetCounter() % 7u) - 3.0f) * PREPULL_SPREAD_STEP;

    out.Relocate(poste.GetPositionX() + recul * dX - lateral * dY,
                 poste.GetPositionY() + recul * dY + lateral * dX,
                 poste.GetPositionZ());
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

        // Seuls les trois postes comptent. Un corps-a-corps en retard rejoindra
        // le sien pendant que le boss marche vers son tank; un tank en retard,
        // lui, c'est un Empereur qui part sur un soigneur.
        if (TankIndex(membre) > 2)
            continue;

        Position poste;
        if (!GetPrePullStation(membre, poste))
            continue;

        // Deux fois la tolerance pour les AUTRES : un bot pose a trois yards et
        // demi de sa marque est arrive, et exiger la precision qu'on exige de
        // soi-meme ferait osciller la condition d'un tick a l'autre.
        if (membre->GetExactDist2d(poste.GetPositionX(), poste.GetPositionY()) > TANK_ANCHOR_TOLERANCE * 2.0f)
            return false;
    }

    return true;
}
