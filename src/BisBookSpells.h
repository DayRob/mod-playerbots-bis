/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_BOOKSPELLS_H
#define MOD_PLAYERBOTS_BIS_BOOKSPELLS_H

#include "Define.h"

class Player;

// Les livres de sort - Codex, Grimoire, Tome, Tablette, Manuel, Guide.
//
// A niveau 60, le maitre de classe s'arrete la ou le livre prend le relais :
// TBC a bien reverse ces rangs sur les maitres, mais a ReqLevel 61, pour que le
// livre garde sa valeur. C'est le jeu, pas un trou de donnees.
//
//     SELECT TrainerId, ReqLevel FROM trainer_spell WHERE SpellId = 25316;
//     -> 11 | 61            -- Priere de soins V, les 36 maitres pretres
//
// Ce que le module corrige n'est donc pas le verrou, mais le fait qu'un bot qui
// RAMASSE le livre ne s'en sert pas : il le garde en sac, ou le vend.
namespace BisBookSpells
{
    // Cet objet est-il un livre que CE bot peut apprendre maintenant ? Sert au
    // jet de butin : un livre n'est ni arme ni armure, donc sans ce test aucun
    // bot ne vote dessus et il part au premier venu.
    bool PeutApprendre(Player* bot, uint32 itemId);
}

#endif
