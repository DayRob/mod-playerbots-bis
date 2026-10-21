/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_WORLD_BUFFS_H
#define MOD_PLAYERBOTS_BIS_WORLD_BUFFS_H

class ChatHandler;

// Les buffs de monde, poses sur tout le raid d'un coup.
//
// POURQUOI CECI EXISTE. Un buff de monde ne s'obtient pas : il se recoit. Le
// Cri de ralliement du tueur de dragons vient du heraut qui crie en ville apres
// une remise de tete, la Benediction du chef de guerre d'un evenement
// d'Orgrimmar, l'Esprit de Zandalar d'une remise a Yojamba. Aucun bot ne les
// aura jamais : ils ne font pas la queue en ville, et personne ne va rendre une
// tete d'Onyxia toutes les deux heures pour quarante d'entre eux.
//
// Du cote maitre de jeu, ".cast" refuse ces sorts - ils sont lances par un PNJ
// et exigent une cible - et ".aura" ne touche QUE la selection. Trente-neuf
// bots, trente-neuf selections, toutes les deux heures.
//
// Cette commande applique la liste configuree a tout le groupe d'un coup.
namespace BisWorldBuffs
{
    // args : vide pour la liste de PlayerbotsBis.WorldBuffs, une suite
    // d'identifiants de sorts pour ne poser que ceux-la, ou "retire" pour
    // enlever la liste configuree.
    bool HandleBuff(ChatHandler* handler, char const* args);
}

#endif
