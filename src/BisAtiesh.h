/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_ATIESH_H
#define MOD_PLAYERBOTS_BIS_ATIESH_H

#include "Define.h"

class Player;

// Atiesh, le baton legendaire de Naxxramas.
//
// Il ne tombe pas : il se CONSTRUIT. Quarante Eclats d'Atiesh ramasses sur les
// boss du raid, plus la Base d'Atiesh sur Kel'Thuzad, puis la chaine de quetes
// d'Anachronos a Tanaris - qu'aucun bot ne saura parcourir.
//
// Ni l'echelle BiS ni la table des jetons ne savent compter des fragments vers
// un objet a fabriquer : l'echelle compare des pieces portables, et un jeton
// s'echange un pour un. Il fallait donc un mecanisme a part.
//
// LE PRINCIPE, et c'est tout le module en une phrase : UN SEUL collecteur,
// nomme dans le fichier de configuration. Lui seul reclame les composants au
// jet de butin ; les autres bots passent explicitement. Quarante eclats
// disperses sur trente-neuf bots ne donnent jamais un baton.
namespace BisAtiesh
{
    // Ce bot est-il le collecteur designe, et cet objet un composant qu'il lui
    // manque encore ? Sert au jet de butin : un eclat n'est ni arme ni armure,
    // donc aucun chemin d'equipement ne le voit.
    bool Reclame(Player* bot, uint32 itemId);

    // Cet objet est-il un composant d'Atiesh ? Vrai pour tout le monde, le
    // collecteur compris. Les autres bots s'en servent pour PASSER de facon
    // explicite plutot que de laisser le jet ouvert jusqu'a expiration.
    bool EstUnComposant(uint32 itemId);
}

#endif
