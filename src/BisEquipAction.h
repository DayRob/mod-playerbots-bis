/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_EQUIPACTION_H
#define MOD_PLAYERBOTS_BIS_EQUIPACTION_H

#include "EquipAction.h"
#include "Player.h"

class ChatHandler;

// CE QUE LE BOT PORTAIT, CRENEAU PAR CRENEAU, A UN INSTANT DONNE.
//
// POURQUOI CECI EXISTE. Playerbots equipe lui-meme une bonne part des pieces -
// c'est son EquipAction qui le fait - et il l'annonce dans ses propres mots :
// "Equipping [X]". Sans rang, sans palier, et sans nommer la piece qui part.
// Le module ne peut pas reprendre cette phrase a la source : EquipItem() est
// privee et non virtuelle, il n'y a rien a redefinir.
//
// Mais ce que l'equipement a CHANGE se lit toujours : on releve les creneaux
// avant de laisser l'action agir, on les compare apres, et chaque creneau qui
// a change se dit alors dans les mots du module - rang de la piece qui arrive,
// rang de celle qui part, palier - et TOUJOURS apres l'equipement, puisque la
// comparaison n'est possible qu'une fois la piece en place.
class BisWornSnapshot
{
public:
    // Releve les creneaux d'equipement si - et seulement si - le module a
    // quelque chose a dire pour ce bot : tables chargees, module actif, bot
    // concerne, annonces autorisees. Renvoie vrai quand le releve a eu lieu.
    //
    // Le gardien est ICI et pas chez l'appelant pour une raison simple : trois
    // actions differentes font ce releve, et une condition oubliee dans l'une
    // des trois ferait parler un bot dont le maitre a demande le silence.
    bool TakeIfAnnouncing(Player* bot, PlayerbotAI* botAI);

    // Compare le port actuel au releve et annonce chaque creneau qui a change.
    // Renvoie le nombre de creneaux annonces. Ne dit rien quand le releve n'a
    // pas eu lieu, donc l'appel est toujours sans danger.
    uint32 TellWhatChanged(Player* bot, PlayerbotAI* botAI) const;

private:
    uint32 _worn[EQUIPMENT_SLOT_END] = {};
    bool _taken = false;
};

// LES DEUX AUTRES CHEMINS PAR LESQUELS PLAYERBOTS EQUIPE.
//
// "equip" est la commande du maitre ("equip [objet]"), "equip upgrade" la passe
// que playerbots declenche lui-meme - au sortir d'un combat de raid, par
// exemple. Les deux finissent dans le meme EquipItem() muet sur les rangs.
//
// Rien ne change ici du comportement de l'action : l'originale decide seule, et
// seule l'annonce s'ajoute, apres coup.
template <class Base>
class BisAnnonceEquipement : public Base
{
public:
    explicit BisAnnonceEquipement(PlayerbotAI* botAI) : Base(botAI) {}

    bool Execute(Event event) override
    {
        BisWornSnapshot avant;
        bool const releve = avant.TakeIfAnnouncing(this->bot, this->botAI);

        bool const acted = Base::Execute(event);

        if (releve)
            avant.TellWhatChanged(this->bot, this->botAI);

        return acted;
    }
};

// Replacement for playerbots' "equip upgrades packet action", the action that
// runs when a bot receives an item.
//
// WHY THIS EXISTS. Replacing the "item usage" and "item upgrade" values is
// enough to decide what a bot ROLLS on, but not what it PUTS ON. For weapons,
// EquipAction takes the decision itself:
//
//     bool canDualWieldOrTG = (canDualWield || isTwoHander);
//     if (isWeapon && canDualWieldOrTG)
//     {
//         StatsWeightCalculator calculator(bot);
//         ...
//         else { /* No improvement, do nothing */ return; }
//     }
//
// Being two-handed is enough to enter that branch, and from there only
// playerbots' stat score has a say - it weighs a two-hander against the sum of
// both hands and the ladder is never consulted. A shaman would announce a
// two-handed axe as its best in slot, roll on it, win it, and leave it in its
// bags for ever.
//
// So this runs the original first, unchanged, and then makes one pass of its
// own over the bags for pieces the ladder claims and the original left behind.
class BisEquipUpgradesAction : public EquipUpgradesPacketAction
{
public:
    explicit BisEquipUpgradesAction(PlayerbotAI* botAI)
        : EquipUpgradesPacketAction(botAI, "equip upgrades packet action") {}

    bool Execute(Event event) override;

    // Puts on every bagged piece the lists rank above what the bot wears in
    // that slot. Returns true when at least one was equipped.
    //
    // Public because of WHEN this action runs: it is a packet action, fired as
    // an item arrives. A piece already sitting in the bags is never looked at
    // again until the next item lands - so a quest reward handed to forty bots
    // at once, or anything received while the module was off, stays there.
    // ".playerbotsbis equipe" calls this directly to sweep that up.
    //
    // report, when given, prints one line per piece of gear in the bags with
    // the verdict and its reason. Without it the sweep is silent, which is what
    // the packet path wants; with it the command can say why nothing moved,
    // instead of leaving "0 ont equipe" to be guessed at.
    bool EquipBisFromBags(ChatHandler* report = nullptr);

    // Echange chaque jeton de quete des sacs contre la piece qu'il achete pour
    // la classe du bot, quand la liste nomme cette piece a son palier. Renvoie
    // vrai des qu'un echange a eu lieu.
    //
    // Appelee par EquipBisFromBags avant sa propre passe, donc les deux chemins
    // - l'arrivee d'un objet et ".playerbotsbis equipe" - la declenchent.
    bool ConvertQuestTokens(ChatHandler* report = nullptr);
};

namespace BisEquipCommand
{
    // args: empty for the caller's guild, "all" for every bot the module
    // applies to, or a bot NAME for the detailed verdict on that one bot.
    bool HandleEquipNow(ChatHandler* handler, char const* args);
}

#endif
