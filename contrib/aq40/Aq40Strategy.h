/*
 * This file is part of the mod-playerbots module for AzerothCore. See AUTHORS file for Copyright
 * information; released under GNU GPL v2 license, redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef PLAYERBOTS_AQ40STRATEGY_H
#define PLAYERBOTS_AQ40STRATEGY_H

#include "Strategy.h"

// LE COMBAT. Installee toute seule en entrant sur la carte 531, et inerte tant
// qu'un Empereur n'est pas en combat : elle ne deplace personne, ne choisit
// aucune cible et ne bloque aucune action en dehors du combat lui-meme.
class RaidAq40Strategy : public Strategy
{
public:
    RaidAq40Strategy(PlayerbotAI* botAI) : Strategy(botAI) {}
    virtual std::string const getName() override { return "aq40"; }
    virtual void InitTriggers(std::vector<TriggerNode*>& triggers) override;
};

// LA DANSE : se placer avant le pull, puis puller ensemble.
//
// SEPAREE DU COMBAT, ET PAS INSTALLEE TOUTE SEULE. C'est la seule partie qui
// deplace des bots avant que quoi que ce soit ait commence, donc la seule qui
// puisse se disputer avec mod-dungeon-clear - qui, lui, a aussi un avis sur ou
// le raid doit se tenir et par ou il doit passer. Le joueur l'arme quand il est
// dans la salle et qu'il a decide que c'etait a elle de conduire :
//
//     /p +aq40danse      (dans le chat de groupe ou de raid : tous les bots)
//     /p -aq40danse      pour la desarmer
//
// Les regles de combat, elles, n'ont jamais besoin d'etre armees.
class RaidAq40DanceStrategy : public Strategy
{
public:
    RaidAq40DanceStrategy(PlayerbotAI* botAI) : Strategy(botAI) {}
    virtual std::string const getName() override { return "aq40danse"; }
    virtual void InitTriggers(std::vector<TriggerNode*>& triggers) override;
};

#endif
