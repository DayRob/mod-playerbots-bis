/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisWorldBuffs.h"
#include "BisPriorityMgr.h"
#include "Chat.h"
#include "Group.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <sstream>
#include <string>
#include <vector>

namespace
{
    // La liste par defaut, si le fichier de configuration n'en donne pas : les
    // sept buffs de monde de l'ere Vanilla.
    char const* const LISTE_PAR_DEFAUT =
        "22888 16609 24425 15366 22817 22818 22820";

    std::vector<uint32> Decouper(std::string const& texte)
    {
        std::vector<uint32> sorts;
        std::istringstream flux(texte);
        std::string mot;

        // Espaces, virgules ou points-virgules : on accepte les trois plutot
        // que d'imposer une syntaxe qu'il faudrait retenir.
        while (flux >> mot)
        {
            for (char& c : mot)
                if (c == ',' || c == ';')
                    c = ' ';

            std::istringstream sous(mot);
            uint32 id = 0;
            while (sous >> id)
                if (id)
                    sorts.push_back(id);
        }

        return sorts;
    }

    std::string NomDuSort(uint32 spellId)
    {
        SpellInfo const* const info = sSpellMgr->GetSpellInfo(spellId);
        if (!info)
            return "";

        // SpellName est indexe par locale ; l'anglais suffit ici, le message
        // sert a verifier qu'on a bien le sort qu'on croyait.
        return info->SpellName[0] ? info->SpellName[0] : "";
    }
}

bool BisWorldBuffs::HandleBuff(ChatHandler* handler, char const* args)
{
    Player* maitre = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!maitre)
        return false;

    std::string const argument = args ? args : "";

    bool retirer = false;
    std::string liste = argument;

    if (argument.rfind("retire", 0) == 0 || argument.rfind("clear", 0) == 0)
    {
        retirer = true;
        liste.clear();
    }

    if (liste.empty())
        liste = sBisPriorityMgr->WorldBuffs();
    if (liste.empty())
        liste = LISTE_PAR_DEFAUT;

    std::vector<uint32> const sorts = Decouper(liste);
    if (sorts.empty())
    {
        handler->PSendSysMessage("Aucun sort a poser. Donne des identifiants, ou renseigne "
                                 "PlayerbotsBis.WorldBuffs.");
        return true;
    }

    // Les sorts inconnus sont ecartes AVANT la boucle sur les bots : sinon le
    // meme avertissement sortirait quarante fois.
    std::vector<uint32> valides;
    for (uint32 const spellId : sorts)
    {
        if (sSpellMgr->GetSpellInfo(spellId))
        {
            valides.push_back(spellId);
            continue;
        }

        handler->PSendSysMessage("Sort {} inconnu - ignore.", spellId);
    }

    if (valides.empty())
        return true;

    // Le groupe, et non la guilde. Un buff de monde sert au raid qui part
    // maintenant ; le poser sur trente bots restes en ville ne sert personne,
    // et ces buffs ont une duree.
    Group* groupe = maitre->GetGroup();

    uint32 touches = 0;
    uint32 poses = 0;
    uint32 joueurs = 0;

    auto traiter = [&](Player* cible)
    {
        if (!cible)
            return;

        // JAMAIS UN AUTRE JOUEUR. Celui qui tape la commande se l'applique a
        // lui-meme, c'est sa decision ; decider pour quelqu'un d'autre qui
        // tient son clavier n'en est pas une.
        if (cible != maitre && !GET_PLAYERBOT_AI(cible))
        {
            ++joueurs;
            return;
        }

        bool fait = false;
        for (uint32 const spellId : valides)
        {
            if (retirer)
            {
                if (!cible->HasAura(spellId))
                    continue;

                cible->RemoveAurasDueToSpell(spellId);
                ++poses;
                fait = true;
                continue;
            }

            // Deja en place : on ne le repose pas. Reposer remettrait la duree
            // a zero, ce qui est en general voulu - mais pas quand la commande
            // est lancee deux fois de suite par reflexe.
            if (cible->HasAura(spellId))
                continue;

            cible->AddAura(spellId, cible);
            ++poses;
            fait = true;
        }

        if (fait)
            ++touches;
    };

    if (groupe)
    {
        for (GroupReference* ref = groupe->GetFirstMember(); ref; ref = ref->next())
            traiter(ref->GetSource());
    }
    else
    {
        // Hors groupe, la commande garde un sens : se buffer soi-meme avant de
        // rassembler le raid.
        traiter(maitre);
    }

    if (retirer)
        handler->PSendSysMessage("{} aura(s) retiree(s) sur {} membre(s).", poses, touches);
    else
        handler->PSendSysMessage("{} aura(s) posee(s) sur {} membre(s).", poses, touches);

    if (joueurs)
        handler->PSendSysMessage("{} joueur(s) ignore(s) - un buff ne se decide pas a leur place.",
                                 joueurs);

    // Ce qui a ete pose, nomme. Un identifiant juste mais pas celui qu'on
    // croyait est l'erreur la plus facile a commettre ici, et la plus longue a
    // voir : l'aura apparait, simplement ce n'est pas la bonne.
    std::ostringstream resume;
    for (size_t i = 0; i < valides.size(); ++i)
    {
        if (i)
            resume << ", ";

        std::string const nom = NomDuSort(valides[i]);
        resume << valides[i];
        if (!nom.empty())
            resume << " (" << nom << ")";
    }
    handler->PSendSysMessage("Sorts : {}", resume.str());

    return true;
}
