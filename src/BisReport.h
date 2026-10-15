/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_REPORT_H
#define MOD_PLAYERBOTS_BIS_REPORT_H

class ChatHandler;

// Which of a bot's best-in-slot pieces it actually owns.
//
// Nothing outside the running server can work this out on its own: the spec a
// list is keyed by is never persisted - AiFactory recomputes it from the
// talents on demand - so the answer has to be produced here and written down.
namespace BisReport
{
    // args: empty for the caller's guild, "all" for every bot the module
    // applies to. Writes characters.playerbots_bis_report and prints a summary.
    bool HandleReport(ChatHandler* handler, char const* args);

    // args: a bot name. Lists that bot's missing pieces in chat, with links.
    bool HandleMissing(ChatHandler* handler, char const* args);

    // Ressuscite les bots morts du groupe, les ramene aupres du joueur, et
    // remet tout le monde a plein hors combat.
    //
    // POURQUOI CECI EXISTE. mod-dungeon-clear tient le raid en place entre deux
    // combats tant que chacun n'a pas atteint ses seuils de repos - sa propre
    // documentation le dit : "the tank holds the advance until every mana user
    // reaches it". Avec quarante bots, c'est le plus lent qui decide pour tout
    // le monde, et apres un boss ils sont tous a sec. Aucune de ses commandes
    // ne relache cette attente : ".dc skip" met le boss COURANT dans la liste
    // des sautes, ce qui est l'inverse de ce qu'on veut.
    //
    // La seule prise qui reste de l'exterieur, c'est la condition elle-meme.
    // Des que tout le monde est a plein, la porte s'ouvre et le tank avance.
    //
    // Les morts suivent la meme logique : le coeur n'a pas de commande pour
    // relever un groupe entier - ".revive" ne touche que la cible - et un
    // ressuscite arrive a vingt pour cent, donc relever sans remplir ne
    // reglerait que la moitie du probleme.
    bool HandleAdvance(ChatHandler* handler, char const* args);
}

#endif
