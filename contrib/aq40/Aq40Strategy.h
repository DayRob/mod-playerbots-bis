/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef PLAYERBOTS_AQ40STRATEGY_H
#define PLAYERBOTS_AQ40STRATEGY_H

#include "Strategy.h"

// LES EMPEREURS JUMEAUX, EN UNE SEULE STRATEGIE.
//
// Installee toute seule en entrant sur la carte 531, et il n'y a RIEN A ARMER.
// mod-playerbots la pose lui-meme, dans les DEUX moteurs - c'est ecrit noir sur
// blanc a la fin de ApplyInstanceStrategies (src/Bot/PlayerbotAI.cpp) :
//
//     engines[BOT_STATE_COMBAT]->addStrategy(strategyName);
//     engines[BOT_STATE_NON_COMBAT]->addStrategy(strategyName);
//
// D'ou vient qu'elle a ete coupee en deux, et pourquoi c'etait une erreur : la
// mise en place et le pull avaient ete sortis dans une seconde strategie,
// "aq40danse", que le joueur devait armer depuis le chat de groupe. Or rien
// n'arme une strategie que la carte n'apporte pas : "+aq40danse" dit dans le
// chat de groupe est reste du chat de groupe, et avec lui sont partis le
// placement, le pull, et la consigne de laisser les bestioles tranquilles.
// Observe en jeu : quarante bots qui engagent Vek'nilash a 35 yards de sa
// plateforme, personne sur les marques, et dix-neuf empiles sur un scarabe qui
// n'avait pas bouge de son point d'apparition.
//
// Donc tout revient ici. Ce qui se declenche avant le combat ne se declenche
// que quand le raid est ARRIVE (un Empereur a portee) et DANS la salle, jamais
// en chemin : le chemin appartient a mod-dungeon-clear.
class RaidAq40Strategy : public Strategy
{
public:
    RaidAq40Strategy(PlayerbotAI* botAI) : Strategy(botAI) {}
    virtual std::string const getName() override { return "aq40"; }
    virtual void InitTriggers(std::vector<TriggerNode*>& triggers) override;
};

#endif
