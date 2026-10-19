/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include <algorithm>
#include "BisEquipAction.h"
#include "BisBotScan.h"
#include "BisPriorityMgr.h"
#include "Chat.h"
#include "ChatHelper.h"
#include "Event.h"
#include "Item.h"
#include "ItemPackets.h"
#include "ItemVisitors.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include <sstream>
#include <string>
#include <vector>

namespace
{
    // LA MEME PHRASE, QUEL QUE SOIT LE CHEMIN QUI A EQUIPE LA PIECE.
    //
    // Trois chemins equipent : la passe du module, l'action d'origine de
    // playerbots, et la commande du maitre. Le maitre, lui, n'a pas a deviner
    // lequel a parle - il lit toujours la meme ligne, avec le rang de ce qui
    // arrive, le rang de ce qui part, et le palier pour fermer.
    //
    // "hors liste" se decide sur la PRIORITE, pas sur le rang : une ligne dont
    // le rang vaut zero est une ligne quand meme, et l'appeler "hors liste"
    // serait un mensonge sur la seule chose que cette phrase doit garantir.
    std::string PhraseEquipement(Player* bot, ItemTemplate const* arrive, ItemTemplate const* parti,
                                 ItemTemplate const* mainGaucheRangee)
    {
        uint16 palier = 0;
        uint8 rang = 0;
        uint32 const priorite = sBisPriorityMgr->GetItemPriority(bot, arrive->ItemId, nullptr, &palier, &rang);

        std::ostringstream out;
        out << "J'equipe " << ChatHelper::FormatItem(arrive);
        if (rang)
            out << " rang " << uint32(rang);
        else if (!priorite)
            out << " hors liste";

        if (parti)
        {
            uint8 rangParti = 0;
            uint32 const prioriteParti =
                sBisPriorityMgr->GetItemPriority(bot, parti->ItemId, nullptr, nullptr, &rangParti);

            out << " a la place de " << ChatHelper::FormatItem(parti);
            if (rangParti)
                out << " rang " << uint32(rangParti);
            else if (!prioriteParti)
                out << " hors liste";
        }
        else
            out << " sur un creneau vide";

        if (mainGaucheRangee)
            out << ", et je range " << ChatHelper::FormatItem(mainGaucheRangee);

        // Le palier seul en fin de phrase : chaque piece porte deja son rang
        // juste apres son nom, le repeter ici brouillerait la lecture.
        std::string const nomDuPalier = sBisPriorityMgr->GetTierName(palier);
        if (!nomDuPalier.empty())
            out << " (" << nomDuPalier << ")";

        return out.str();
    }
}

bool BisWornSnapshot::TakeIfAnnouncing(Player* bot, PlayerbotAI* botAI)
{
    _taken = false;

    if (!bot || !botAI)
        return false;

    if (!sBisPriorityMgr->IsEnabled() || !sBisPriorityMgr->IsLoaded() || !sBisPriorityMgr->AnnounceOwnBis())
        return false;

    if (!sBisPriorityMgr->AppliesTo(bot))
        return false;

    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        Item const* const porte = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        _worn[slot] = porte ? porte->GetEntry() : 0;
    }

    _taken = true;
    return true;
}

uint32 BisWornSnapshot::TellWhatChanged(Player* bot, PlayerbotAI* botAI) const
{
    if (!_taken || !bot || !botAI)
        return 0;

    // La main gauche qu'une arme a deux mains fait ranger : son creneau est
    // VIDE apres coup, donc il n'aura pas de ligne a lui. Elle se dit dans la
    // ligne de la main droite, qui est la raison de son depart - sinon elle
    // cesse simplement d'etre portee, sans un mot.
    ItemTemplate const* mainGaucheRangee = nullptr;
    if (_worn[EQUIPMENT_SLOT_OFFHAND] && !bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND))
        mainGaucheRangee = sObjectMgr->GetItemTemplate(_worn[EQUIPMENT_SLOT_OFFHAND]);

    uint32 dites = 0;

    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        Item const* const maintenant = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        uint32 const apres = maintenant ? maintenant->GetEntry() : 0;

        if (apres == _worn[slot])
            continue;

        // Un creneau devenu vide n'est pas un equipement : c'est une piece qui
        // sort, et elle est deja nommee par la ligne du creneau qui l'a fait
        // sortir. Une ligne a elle se lirait comme un second equipement.
        if (!apres)
            continue;

        ItemTemplate const* const arrive = maintenant->GetTemplate();
        if (!arrive)
            continue;

        // Le MODELE de la piece qui part, pas l'objet : apres l'echange il est
        // quelque part dans les sacs, ou detruit. Un ItemTemplate, lui, vit
        // dans le gestionnaire d'objets pour toute la duree du serveur.
        ItemTemplate const* const parti = _worn[slot] ? sObjectMgr->GetItemTemplate(_worn[slot]) : nullptr;

        botAI->TellMaster(PhraseEquipement(bot, arrive, parti,
                                           slot == EQUIPMENT_SLOT_MAINHAND ? mainGaucheRangee : nullptr));
        ++dites;
    }

    return dites;
}

bool BisEquipUpgradesAction::Execute(Event event)
{
    // CE QUE PLAYERBOTS EQUIPE LUI-MEME SE DIT AUSSI.
    //
    // L'originale ci-dessous equipe une bonne part des pieces, et elle l'annonce
    // dans ses propres mots : "Equipping [X]", sans rang ni piece remplacee. Le
    // releve pris ici, puis compare juste apres, rend cette ligne-la au meme
    // format que les autres : le maitre voit par quoi la piece est remplacee
    // quel que soit celui des deux qui a tranche.
    BisWornSnapshot avant;
    bool const releve = avant.TakeIfAnnouncing(bot, botAI);

    // The original keeps every case it already handles well - armour, rings,
    // trinkets, and the weapon arbitration when its own score agrees with us.
    // This only picks up what it leaves behind.
    bool const acted = EquipUpgradesPacketAction::Execute(event);

    // AVANT la passe du module, qui annonce ses propres pieces elle-meme : ce
    // qu'elle equipera n'a pas encore bouge, donc chaque piece est nommee une
    // fois et une seule.
    if (releve)
        avant.TellWhatChanged(bot, botAI);

    if (!sBisPriorityMgr->IsEnabled() || !sBisPriorityMgr->IsLoaded() ||
        !sBisPriorityMgr->AppliesTo(bot))
        return acted;

    return EquipBisFromBags() || acted;
}

// Les jetons de quete deviennent la piece qu'ils achetent.
//
// POURQUOI ICI. Un jeton hakkari n'est ni arme ni armure : la passe
// d'equipement ci-dessous l'ecarte, a juste titre - il ne s'equipe pas. Le bot
// le gagnait donc au jet, puis le gardait pour toujours, et la ceinture rang 1
// qu'il achete n'arrivait jamais. Le vrai chemin du jeu passe par l'ile de
// Yojamba et demande une reputation Zandalar que les bots ne montent pas, donc
// l'echange se fait ici, directement.
//
// L'ORDRE compte deux fois. Avant la collecte des sacs, pour que la piece
// obtenue entre dans la passe du meme coup au lieu d'attendre l'objet suivant.
// Et l'emplacement est reserve AVANT de detruire le jeton : un echange qui
// echouerait entre les deux aurait detruit du butin.
bool BisEquipUpgradesAction::ConvertQuestTokens(ChatHandler* report)
{
    CollectItemsVisitor visitor;
    IterateItems(&visitor, ITERATE_ITEMS_IN_BAGS);

    bool converted = false;

    for (Item* item : visitor.items)
    {
        if (!item)
            continue;

        // Pas de filtre sur la classe d'objet : les jetons du tier 2.5 d'AQ40
        // sont ITEM_CLASS_MISCELLANEOUS, pas ITEM_CLASS_QUEST. QuestTokenRewards
        // rend une liste VIDE pour tout ce qui n'est pas un jeton, donc c'est
        // elle qui tranche, et elle ne se trompe pas de classe.
        ItemTemplate const* const proto = item->GetTemplate();
        if (!proto)
            continue;

        // La SPE compte autant que la classe : Imperial Qiraji Armaments donne
        // une hache a un guerrier Fureur et un BOUCLIER a un Protection.
        //
        // ET UN JETON PEUT EN OUVRIR PLUSIEURS. Les jetons epaules/bottes
        // d'Ahn'Qiraj rendent DEUX pieces a la meme classe - Qiraji Bindings of
        // Command donne au guerrier les Conqueror's Spaulders et les
        // Conqueror's Greaves. Le bot les prend toutes, et ne garde que celles
        // qui lui manquent : une seule quete dans le jeu d'origine, mais ici un
        // jeton rendu doit laisser le bot complet, sinon la seconde piece reste
        // hors d'atteinte pour toujours.
        std::vector<uint32> const& pieces = sBisPriorityMgr->QuestTokenRewards(
            proto->ItemId, bot->getClass(), sBisPriorityMgr->GetSpec(bot));
        if (pieces.empty())
            continue;

        // ── CE QU'IL VA RECEVOIR, DECIDE AVANT DE DETRUIRE QUOI QUE CE SOIT ──
        //
        // Le jeton ne part qu'une fois la liste arretee. L'ordre inverse -
        // detruire puis distribuer - perdrait le jeton ET les pieces le jour ou
        // un controle echoue a mi-chemin.
        std::vector<ItemTemplate const*> aRemettre;

        for (uint32 const pieceId : pieces)
        {
            ItemTemplate const* const piece = sObjectMgr->GetItemTemplate(pieceId);
            if (!piece)
                continue;

            // La piece doit etre sur la liste du bot A SON PALIER. C'est la
            // meme condition que celle qui lui a fait reclamer le jeton; si le
            // plafond a baisse depuis, le jeton reste un objet de quete
            // ordinaire que le maitre peut toujours rendre lui-meme.
            if (!sBisPriorityMgr->GetItemPriority(bot, pieceId))
                continue;

            if (bot->CanUseItem(piece) != EQUIP_ERR_OK)
                continue;

            // Deja porte, en sac ou en banque : un second exemplaire ne sert a
            // rien. GetItemCount part de EQUIPMENT_SLOT_START, donc la piece
            // sur le dos compte aussi.
            if (bot->GetItemCount(pieceId, true) > 0)
                continue;

            aRemettre.push_back(piece);
        }

        if (aRemettre.empty())
            continue;

        // La place pour TOUT, avant d'echanger. Un sac qui ne tient qu'une des
        // deux pieces fait remettre l'echange entier a plus tard : mieux vaut
        // un jeton qui attend qu'une piece perdue.
        bool placeSuffisante = true;
        for (ItemTemplate const* const piece : aRemettre)
        {
            ItemPosCountVec essai;
            if (bot->CanStoreNewItem(NULL_BAG, NULL_SLOT, essai, piece->ItemId, 1) != EQUIP_ERR_OK)
            {
                placeSuffisante = false;
                break;
            }
        }

        if (!placeSuffisante)
        {
            if (report)
                report->PSendSysMessage("  {} : sacs pleins, echange remis a plus tard",
                                        ChatHelper::FormatItem(proto));
            continue;
        }

        bot->DestroyItemCount(proto->ItemId, 1, true);

        for (ItemTemplate const* const piece : aRemettre)
        {
            ItemPosCountVec place;
            if (bot->CanStoreNewItem(NULL_BAG, NULL_SLOT, place, piece->ItemId, 1) != EQUIP_ERR_OK)
            {
                LOG_ERROR("playerbots", "[mod-playerbots-bis] {} : jeton {} detruit mais piece {} sans place",
                          bot->GetName(), proto->ItemId, piece->ItemId);
                continue;
            }

            Item* const reward = bot->StoreNewItem(place, piece->ItemId, true);
            if (!reward)
            {
                LOG_ERROR("playerbots", "[mod-playerbots-bis] {} : jeton {} detruit mais piece {} non remise",
                          bot->GetName(), proto->ItemId, piece->ItemId);
                continue;
            }

            bot->SendNewItem(reward, 1, true, false);
            converted = true;

            if (report)
                report->PSendSysMessage("  {} echange contre {}",
                                        ChatHelper::FormatItem(proto), ChatHelper::FormatItem(piece));
        }
    }

    return converted;
}

bool BisEquipUpgradesAction::EquipBisFromBags(ChatHandler* report)
{
    // Les jetons d'abord : la piece qu'ils donnent est alors dans les sacs
    // quand la collecte ci-dessous a lieu, et s'equipe dans la meme passe.
    bool const convertedToken = ConvertQuestTokens(report);

    CollectItemsVisitor visitor;
    IterateItems(&visitor, ITERATE_ITEMS_IN_BAGS);

    // Off-hands go last. The sweep takes the bags in their own order, so a bot
    // trading a two-hander for a one-hander in this very pass would only reach
    // its off-hand if the bags happened to hold it further along - and stay a
    // weapon short until the next item arrived otherwise. Handling the main hand
    // first makes the off-hand's own test read a hand that is already settled.
    std::stable_sort(visitor.items.begin(), visitor.items.end(),
                     [](Item const* a, Item const* b)
                     {
                         auto offHand = [](Item const* item)
                         {
                             ItemTemplate const* const proto = item ? item->GetTemplate() : nullptr;
                             if (!proto)
                                 return 0;

                             switch (proto->InventoryType)
                             {
                                 case INVTYPE_SHIELD:
                                 case INVTYPE_WEAPONOFFHAND:
                                 case INVTYPE_HOLDABLE:
                                     return 1;
                                 default:
                                     return 0;
                             }
                         };

                         return offHand(a) < offHand(b);
                     });

    // ── FAUT-IL OUVRIR LA MAIN GAUCHE ? ───────────────────────────────────
    //
    // Un bot qui porte une arme a deux mains ne peut rien mettre en main
    // gauche, et la comparaison piece par piece ne voit pas le probleme : la
    // main gauche est mieux classee que ce qu'il porte a CE creneau - rien -
    // et le baton occupe un AUTRE creneau. Vu en jeu : un soigneur avec le
    // Baton beni d'augure qiraji, rang 3, et le Pouvoir de Sartura, rang 1,
    // qui dormait dans ses sacs.
    //
    // La question se pose UNE FOIS, avant la boucle, et elle se pose en rangs :
    // si la main gauche qui attend est mieux classee que l'arme a deux mains
    // portee, alors la paire vaut mieux que le baton, et il faut une arme a une
    // main pour la porter. On autorise alors une une-main que les listes ne
    // nomment pas - elle n'est pas la pour etre bonne, elle est la pour ouvrir
    // la main gauche.
    uint8 rangMainGauche = 255;  // la meilleure main gauche qui attend en sac
    uint8 rangDeuxMains = 255;   // le rang de l'arme a deux mains portee
    bool deuxMainsPortee = false;

    {
        Item const* const enMain = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND);
        ItemTemplate const* const protoMain = enMain ? enMain->GetTemplate() : nullptr;
        if (protoMain && protoMain->InventoryType == INVTYPE_2HWEAPON)
        {
            deuxMainsPortee = true;

            uint8 rang = 0;
            if (sBisPriorityMgr->GetItemPriority(bot, protoMain->ItemId, nullptr, nullptr, &rang) && rang)
                rangDeuxMains = rang;
        }
    }

    if (deuxMainsPortee)
    {
        for (Item const* sac : visitor.items)
        {
            ItemTemplate const* const p = sac ? sac->GetTemplate() : nullptr;
            if (!p)
                continue;

            if (p->InventoryType != INVTYPE_SHIELD && p->InventoryType != INVTYPE_WEAPONOFFHAND &&
                p->InventoryType != INVTYPE_HOLDABLE)
                continue;

            uint8 rang = 0;
            if (!sBisPriorityMgr->GetItemPriority(bot, p->ItemId, nullptr, nullptr, &rang) || !rang)
                continue;

            if (bot->CanUseItem(p) != EQUIP_ERR_OK)
                continue;

            if (rang < rangMainGauche)
                rangMainGauche = rang;
        }
    }

    // Strictement mieux : a rang egal on ne touche a rien, le baton a l'avantage
    // de ne demander aucune seconde piece.
    bool ouvrirLaMainGauche = deuxMainsPortee && rangMainGauche < rangDeuxMains;

    bool equipped = false;

    for (Item* item : visitor.items)
    {
        if (!item)
            continue;

        ItemTemplate const* proto = item->GetTemplate();
        if (!proto)
            continue;

        // Only gear. Everything else keeps playerbots' own handling. Not
        // reported either: a report naming every reagent and potion in the
        // bags would bury the lines that matter.
        if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR)
            continue;

        uint8 slot = 0;
        uint16 tierId = 0;
        uint8 rank = 0;
        uint32 const priority = sBisPriorityMgr->GetItemPriority(bot, proto->ItemId, &slot, &tierId, &rank);

        // CELLE QUI OUVRE LA MAIN GAUCHE N'A PAS BESOIN D'ETRE LISTEE. Elle
        // n'est pas choisie pour sa valeur mais pour ce qu'elle libere : une
        // main gauche mieux classee que le baton qu'elle remplace. Sans cette
        // porte, un bot sans une-main EN LISTE restait bloque avec son arme a
        // deux mains et sa main gauche dormait dans les sacs pour toujours.
        bool const ouvreur = ouvrirLaMainGauche && !priority &&
                             (proto->InventoryType == INVTYPE_WEAPON ||
                              proto->InventoryType == INVTYPE_WEAPONMAINHAND) &&
                             bot->CanUseItem(proto) == EQUIP_ERR_OK;

        if (!priority && !ouvreur)
        {
            // No list names it AT THIS BOT'S CAP - which is not the same as
            // "no list names it at all". A piece listed only for Blackwing Lair
            // lands here for a bot whose ceiling stops at Molten Core, and that
            // distinction is the whole reason this report exists.
            if (report)
                report->PSendSysMessage("  {} : aucune ligne a son palier", ChatHelper::FormatItem(proto));
            continue;
        }

        // Unlike the claim made at loot time, a missing level is disqualifying
        // here: the core refuses the equip outright, so forcing it would only
        // spend a packet per tick until the bot grows into the piece.
        if (InventoryResult const canUse = bot->CanUseItem(proto); canUse != EQUIP_ERR_OK)
        {
            if (report)
                report->PSendSysMessage("  {} : ne peut pas l'equiper (code {})",
                                        ChatHelper::FormatItem(proto), uint32(canUse));
            continue;
        }

        uint8 targetSlot = slot;
        uint32 const worn = ouvreur ? 0u : sBisPriorityMgr->GetWornPriorityPaired(bot, slot, &targetSlot);
        if (ouvreur)
            targetSlot = EQUIPMENT_SLOT_MAINHAND;

        // A two-hander fills both hands, so the core refuses this one every
        // single time. Sending the packet anyway spent a refusal per item
        // received and answered the master in the core's own words, which read
        // like a module failure rather than what it is: a slot the bot's own
        // weapon closed.
        if (sBisPriorityMgr->OffHandClosed(bot, targetSlot))
        {
            if (report)
                report->PSendSysMessage("  {} : main gauche fermee par l'arme a deux mains portee"
                                        " - en attente d'une arme a une main",
                                        ChatHelper::FormatItem(proto));
            continue;
        }

        // Celle qui ouvre la main gauche echappe a la comparaison : elle est
        // peut-etre moins bonne que le baton prise seule, et c'est justement le
        // calcul - une main gauche mieux classee la compense.
        if (!ouvreur && priority <= worn)
        {
            if (report)
                report->PSendSysMessage("  {} : deja mieux au creneau {} (porte {}, sac {})",
                                        ChatHelper::FormatItem(proto), uint32(slot), worn, priority);
            continue;  // already wearing this piece, or something higher up the ladder
        }

        // What goes away, read BEFORE the swap - afterwards the slot holds the
        // new piece and the old one is somewhere in the bags, indistinguishable
        // from everything else the bot carries. Only the template is kept: the
        // Item object may move or be destroyed by the equip, while an
        // ItemTemplate lives in the object manager's store for the run.
        Item const* const previous = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, targetSlot);
        ItemTemplate const* const replaced = previous ? previous->GetTemplate() : nullptr;

        // The off-hand a two-hander pushes out is a second loss, and the one a
        // master notices least: nothing names it, it simply stops being worn.
        bool const twoHander = proto->InventoryType == INVTYPE_2HWEAPON;
        ItemTemplate const* displacedOffHand = nullptr;
        if (twoHander && targetSlot == EQUIPMENT_SLOT_MAINHAND)
        {
            Item const* const offHand = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
            displacedOffHand = offHand ? offHand->GetTemplate() : nullptr;
        }

        // A two-hander goes to the main hand with an off-hand still on: the
        // core moves that off-hand to the bags when there is room, and refuses
        // the whole thing when there is none. Either way it answers for itself,
        // and a refusal simply means the next item received tries again.
        WorldPacket packet(CMSG_AUTOEQUIP_ITEM_SLOT, 2);
        ObjectGuid const guid = item->GetGUID();
        packet << guid << targetSlot;

        WorldPackets::Item::AutoEquipItemSlot equipPacket(std::move(packet));
        // Demander au coeur AVANT d'envoyer le paquet.
        //
        // HandleAutoEquipItemSlotOpcode ne rend rien et decline en silence : la
        // seule chose lisible apres coup est que le creneau ne porte pas la
        // piece, ce qui ne dit pas POURQUOI. Le message se rabattait donc sur
        // une supposition - "sacs pleins ?" - qui envoie chercher au mauvais
        // endroit des que la cause est ailleurs : un anneau unique deja porte a
        // l'autre doigt refuse exactement pareil.
        //
        // CanEquipItem rend le code d'erreur du coeur lui-meme, et couvre
        // l'unicite par CanEquipUniqueItem. On le lit d'abord, on le rapporte
        // tel quel, et on n'envoie le paquet que s'il dit oui.
        uint16 dest = 0;
        if (InventoryResult const canEquip = bot->CanEquipItem(targetSlot, dest, item, true);
            canEquip != EQUIP_ERR_OK)
        {
            if (report)
                report->PSendSysMessage("  {} : le coeur refuse le creneau {} (code {})",
                                        ChatHelper::FormatItem(proto), uint32(targetSlot),
                                        uint32(canEquip));
            continue;
        }

        equipPacket.Read();
        bot->GetSession()->HandleAutoEquipItemSlotOpcode(equipPacket);

        // The handler answers by changing the inventory, not by returning
        // anything, and it declines in silence - a full bag with no room for
        // the piece coming off, an off-hand that cannot be put away. Counting
        // the packet as a success would report work that never happened, so
        // the result is read back from the slot itself.
        Item* const now = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, targetSlot);
        if (!now || now->GetEntry() != proto->ItemId)
        {
            // CanEquipItem vient de dire oui, et pourtant le creneau n'a pas
            // change. Il reste les refus que le controle prealable ne couvre
            // pas - la place pour ressortir la piece remplacee, notamment.
            if (report)
                report->PSendSysMessage("  {} : accepte au creneau {} mais le coeur n'a rien "
                                        "change (place pour la piece qui sort ?)",
                                        ChatHelper::FormatItem(proto), uint32(targetSlot));
            continue;
        }

        // Said out loud for the same reason the claim is: the bot is putting on
        // something playerbots' own score had just declined, and without a word
        // that reads as the item jumping slots by itself.
        // The off-hand is only reported as displaced if it actually left: with
        // the bags full the core refuses the whole swap, and that case already
        // returned above - but a stale claim here would be worse than silence.
        if (displacedOffHand && bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND))
            displacedOffHand = nullptr;

        // UNE SEULE SUFFIT. Sans ca, une seconde arme a une main plus loin dans
        // les sacs se croirait elle aussi chargee d'ouvrir la main gauche, et
        // les deux se remplaceraient a chaque passage.
        if (ouvreur)
            ouvrirLaMainGauche = false;

        // LE RANG DES DEUX PIECES. Celui qui arrive ne dit que la moitie de
        // l'echange : "rang 3 a la place de rang 7" se lit d'un coup d'oeil,
        // "rang 3" seul oblige a aller chercher l'autre.
        //
        // Le rang de la piece qui part se relit dans la liste du bot. Elle n'y
        // est pas toujours - un bot peut porter n'importe quoi sur un creneau
        // que sa liste ne couvre pas encore - et c'est alors "hors liste", ce
        // qui est une information en soi.
        //
        // Pour la ligne de rapport uniquement : l'annonce au maitre, elle, tire
        // les deux rangs de PhraseEquipement.
        uint8 rangRemplace = 0;
        if (report && replaced)
            sBisPriorityMgr->GetItemPriority(bot, replaced->ItemId, nullptr, nullptr, &rangRemplace);

        // Said out loud for the same reason the claim is: the bot is putting on
        // something playerbots' own score had just declined, and without a word
        // that reads as the item jumping slots by itself. Naming what leaves
        // matters as much as naming what arrives - on a paired slot it is the
        // only way to know WHICH ring went.
        //
        // LA PHRASE EST CELLE DU HAUT DU FICHIER, partagee avec le releve qui
        // rend compte des pieces equipees par playerbots lui-meme : le maitre
        // lit la meme ligne dans les deux cas, et une correction apportee a
        // l'une ne peut plus oublier l'autre.
        if (sBisPriorityMgr->AnnounceOwnBis() && botAI)
            botAI->TellMaster(PhraseEquipement(bot, proto, replaced, displacedOffHand));

        if (report)
        {
            // Meme forme que l'annonce : chaque piece porte son rang juste
            // apres son nom, et le palier ferme la ligne.
            std::ostringstream line;
            line << "  " << ChatHelper::FormatItem(proto);
            if (rank)
                line << " rang " << uint32(rank);
            line << " : EQUIPE au creneau " << uint32(targetSlot);
            if (replaced)
            {
                line << ", a la place de " << ChatHelper::FormatItem(replaced);
                if (rangRemplace)
                    line << " rang " << uint32(rangRemplace);
                else
                    line << " hors liste";
            }
            else
                line << " (creneau vide)";
            if (displacedOffHand)
                line << ", main gauche rangee : " << ChatHelper::FormatItem(displacedOffHand);
            line << " (" << sBisPriorityMgr->GetTierName(tierId) << ")";
            report->PSendSysMessage("{}", line.str());
        }

        equipped = true;
    }

    // Un jeton echange est un acte, meme quand la piece obtenue ne se revele
    // pas meilleure que ce que le bot porte deja.
    return equipped || convertedToken;
}

// ---------------------------------------------------------------------------
// ".playerbotsbis equipe" - the same sweep, on demand.
//
// The action above is a packet action: it answers an arriving item. That is the
// right moment in normal play, and the wrong one for everything that lands
// outside it - a quest reward turned in by forty bots at once, a piece looted
// while the module was switched off, a list that changed under a bot that has
// received nothing since. In all of those the gear sits in the bags, correct and
// unworn, with nothing scheduled to look at it again.
// ---------------------------------------------------------------------------


namespace
{
    bool ReportOne(ChatHandler* handler, std::string const& name)
    {
        Player* bot = ObjectAccessor::FindPlayerByName(name, false);
        if (!bot)
        {
            handler->PSendSysMessage("{} n'est pas connecte.", name);
            return true;
        }

        PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot);
        if (!botAI)
        {
            handler->PSendSysMessage("{} n'est pas un bot.", bot->GetName());
            return true;
        }

        if (char const* why = sBisPriorityMgr->WhyNotFollowed(bot))
        {
            handler->PSendSysMessage("{} n'est pas suivi : {}", bot->GetName(), why);
            return true;
        }

        // The three values that decide everything downstream, printed before
        // any verdict. A wrong spec or a ceiling below the phase explains a
        // whole bot at once, where the per-item lines would only repeat it.
        uint8 const spec = sBisPriorityMgr->GetSpec(bot);
        uint16 const cap = sBisPriorityMgr->GetEffectiveTierCap(bot);
        std::string const capName = sBisPriorityMgr->GetTierName(cap);

        handler->PSendSysMessage("{} - {} {} - palier plafond {} ({})", bot->GetName(),
                                 BisBotScan::ClassName(bot->getClass()),
                                 BisBotScan::SpecName(bot->getClass(), spec),
                                 uint32(cap), capName.empty() ? "sans nom" : capName);

        BisEquipUpgradesAction action(botAI);
        if (!action.EquipBisFromBags(handler))
            handler->PSendSysMessage("Rien equipe.");

        return true;
    }
}

bool BisEquipCommand::HandleEquipNow(ChatHandler* handler, char const* args)
{
    if (!sBisPriorityMgr->IsEnabled() || !sBisPriorityMgr->IsLoaded())
    {
        handler->PSendSysMessage("mod-playerbots-bis : module desactive ou tables non chargees.");
        return true;
    }

    std::string arg = args ? args : "";
    while (!arg.empty() && arg.back() == ' ')
        arg.pop_back();

    bool const all = arg == "all";

    // A name instead of a scope switches to the detailed mode. One bot, one
    // line per piece of gear it carries, with the reason it stayed in the bag.
    // "0 ont equipe" over 359 bots says nothing about which of the four tests
    // refused, and that is exactly what has to be known.
    if (!arg.empty() && !all)
        return ReportOne(handler, arg);

    Player* const viewer = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;

    uint32 guildId = 0;
    if (!all)
    {
        if (!viewer || !viewer->GetGuildId())
        {
            handler->PSendSysMessage("Tu n'es dans aucune guilde. Utilise |cffffd100.playerbotsbis equipe all|r "
                                     "pour couvrir tous les bots.");
            return true;
        }
        guildId = viewer->GetGuildId();
    }

    std::vector<std::string> skipped;
    std::vector<Player*> const bots = BisBotScan::CollectBots(guildId, all, &skipped);
    if (bots.empty())
    {
        handler->PSendSysMessage("Aucun bot concerne. Les bots doivent etre connectes.");
        for (std::string const& line : skipped)
            handler->PSendSysMessage("  ignore : {}", line);
        return true;
    }

    uint32 changed = 0;

    for (Player* bot : bots)
    {
        PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot);
        if (!botAI)
            continue;

        // Built on the stack for this one call. The action carries no state of
        // its own between invocations - it reads the bags, the worn gear and
        // the ladder, all of which live on the bot - so a temporary is exactly
        // as correct as the one the engine keeps.
        BisEquipUpgradesAction action(botAI);
        if (action.EquipBisFromBags())
            ++changed;
    }

    handler->PSendSysMessage("{} bot(s) examines, {} ont equipe au moins une piece.",
                             uint32(bots.size()), changed);

    if (!changed)
        handler->PSendSysMessage("Rien a equiper : soit les pieces sont deja portees, soit aucune "
                                 "liste ne les nomme a leur palier (|cffffd100.playerbotsbis missing "
                                 "<nom>|r pour le detail d'un bot).");

    for (std::string const& line : skipped)
        handler->PSendSysMessage("  ignore : {}", line);

    return true;
}
