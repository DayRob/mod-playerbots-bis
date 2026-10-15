/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisReport.h"
#include "BisBotScan.h"
#include "BisPriorityMgr.h"
#include "Chat.h"
#include "ChatHelper.h"
#include "Group.h"
#include "Guild.h"
#include "GuildMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include <map>
#include <string>
#include <vector>

using namespace BisBotScan;

namespace
{
    // Au-dela, un bot ressuscite est rapatrie aupres de celui qui a lance la
    // commande. En deca il est deja sur place, et le teleporter ne ferait que
    // le faire sauter d'un pas.
    constexpr float RAPPEL_DISTANCE = 30.0f;

    // The marker the roster window watches for. The dungeon plan uses its own,
    // so one window never swallows the other's stream.
    char const* const ROSTER_MARKER = "PBBISREP;";

    // A burst is delivered in one tick, so the stream is capped. Forty guild
    // bots is a hundred-odd messages; five hundred would be well past what is
    // reasonable to push at a client at once.
    constexpr size_t ADDON_MAX_BOTS = 150;

    void SendAddon(ChatHandler* handler, std::string const& payload)
    {
        SendMarked(handler, ROSTER_MARKER, payload);
    }

    struct BotTally
    {
        uint32 equipped = 0;
        uint32 carried  = 0;
        uint32 missing  = 0;
        uint32 rows     = 0;
    };
}

bool BisReport::HandleReport(ChatHandler* handler, char const* args)
{
    if (!sBisPriorityMgr->IsEnabled() || !sBisPriorityMgr->IsLoaded())
    {
        handler->PSendSysMessage("mod-playerbots-bis : module desactive ou tables non chargees.");
        return true;
    }

    std::string const arg = args ? args : "";
    bool const all = arg.find("all") != std::string::npos;

    Player* const viewer = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;

    uint32 guildId = 0;
    if (!all)
    {
        if (!viewer || !viewer->GetGuildId())
        {
            handler->PSendSysMessage("Tu n'es dans aucune guilde. Utilise .playerbotsbis report all "
                                     "pour couvrir tous les bots.");
            return true;
        }
        guildId = viewer->GetGuildId();
    }

    std::vector<std::string> skipped;
    std::vector<Player*> const bots = CollectBots(guildId, all, &skipped);
    if (bots.empty())
    {
        handler->PSendSysMessage("Aucun bot concerne. Les bots doivent etre connectes pour etre analyses.");
        return true;
    }

    std::string scope = "tous les bots";
    if (!all)
    {
        Guild* g = sGuildMgr->GetGuildById(guildId);
        scope = g ? g->GetName() : "guilde";
    }

    // The companion addon listens for these lines and opens its window on the
    // closing marker; it hides them from the chat frame as they arrive.
    SendAddon(handler, std::string("S") + FIELD_SEP + std::to_string(bots.size()) + FIELD_SEP + scope);

    uint32 analysed = 0;
    uint32 noList = 0;

    for (Player* bot : bots)
    {
        std::vector<BisItem> const list = sBisPriorityMgr->GetReachableList(bot);

        uint8 const cls = bot->getClass();
        uint8 const spec = sBisPriorityMgr->GetSpec(bot);
        uint8 const level = bot->GetLevel();

        if (list.empty())
        {
            ++noList;
            handler->PSendSysMessage("{} - {} {} niv {} : aucune liste a ce palier.",
                                     bot->GetName(), ClassName(cls), SpecName(cls, spec), uint32(level));
            continue;
        }

        ++analysed;

        // A slot is covered when the bot wears the piece the list picks for it at
        // the highest phase it can reach - that is what the ratio counts.
        std::map<uint8, BisItem> const targets = TargetsPerSlot(list);

        BotTally best;
        std::vector<std::string> addonItems;

        // Every reachable row travels, with its rank and a flag marking the
        // target. Only targets are tallied, but a slot whose rank-1 piece is
        // missing while its rank-2 is worn is half covered, and saying so needs
        // the fallbacks on screen.
        for (BisItem const& row : list)
        {
            // An off-hand under a two-hander is not missing, it is out of reach.
            // Counting it would charge the bot for a slot its own weapon closed,
            // and send the raid view hunting a drop nobody here can wear.
            if (sBisPriorityMgr->OffHandClosed(bot, row.slot))
                continue;

            // Les JETONS DE QUETE ne voyagent pas. Ils portent le creneau, le
            // palier et le RANG de la piece qu'ils achetent - c'est voulu, c'est
            // ce qui les fait reclamer a leur juste valeur - mais la fenetre
            // renumerote les rangs par creneau, donc le jeton et sa piece
            // sortaient en deux lignes voisines. Aux poignets d'un guerrier ca
            // donnait "rang 4 Brachiales primordiales hakkari - manquant" juste
            // au-dessus de "rang 5 Garde-bras zandalar - equipe" : le jeton de
            // la piece qu'il porte deja, compte comme un rang a prendre.
            //
            // TargetsPerSlot les ecarte deja, donc le rapport chiffre etait
            // juste ; seule la liste depliee les montrait. CanBeWorn est le meme
            // test, pour que les deux ne puissent pas diverger.
            if (!CanBeWorn(row.itemId))
                continue;

            uint8 const state = ResolveState(bot, row.itemId);

            auto target = targets.find(row.slot);
            bool const isTarget = target != targets.end() && target->second.itemId == row.itemId;

            if (isTarget)
            {
                ++best.rows;
                if (state == BIS_EQUIPPED)
                    ++best.equipped;
                else if (state == BIS_CARRIED)
                    ++best.carried;
                else
                    ++best.missing;
            }

            addonItems.push_back(std::to_string(row.itemId) + ":" + std::to_string(uint32(state)) +
                                 ":" + std::to_string(row.tierId) + ":" + std::to_string(uint32(row.slot)) +
                                 ":" + std::to_string(uint32(row.rank)) + ":" + (isTarget ? "1" : "0"));
        }

        handler->PSendSysMessage("{} - {} {} niv {} : {}/{} equipes, {} en sac, {} manquants.",
                                 bot->GetName(), ClassName(cls), SpecName(cls, spec), uint32(level),
                                 best.equipped, best.rows, best.carried, best.missing);

        if (analysed > uint32(ADDON_MAX_BOTS))
            continue;

        SendAddon(handler, std::string("B") + FIELD_SEP + bot->GetName() + FIELD_SEP +
                          std::to_string(uint32(cls)) + FIELD_SEP + std::to_string(uint32(spec)) + FIELD_SEP +
                          std::to_string(uint32(level)) + FIELD_SEP + std::to_string(best.equipped) + FIELD_SEP +
                          std::to_string(best.rows) + FIELD_SEP + std::to_string(best.carried) + FIELD_SEP +
                          std::to_string(best.missing));

        std::string chunk;
        for (std::string const& item : addonItems)
        {
            if (!chunk.empty() && chunk.size() + item.size() + 1 > PAYLOAD_MAX)
            {
                SendAddon(handler, std::string("I") + FIELD_SEP + bot->GetName() + FIELD_SEP + chunk);
                chunk.clear();
            }

            if (!chunk.empty())
                chunk += ",";
            chunk += item;
        }

        if (!chunk.empty())
            SendAddon(handler, std::string("I") + FIELD_SEP + bot->GetName() + FIELD_SEP + chunk);
    }

    SendAddon(handler, std::string("E") + FIELD_SEP);

    handler->PSendSysMessage("---");
    if (analysed > uint32(ADDON_MAX_BOTS))
        handler->PSendSysMessage("Fenetre limitee aux {} premiers bots ; le reste est ci-dessus.",
                                 uint32(ADDON_MAX_BOTS));
    handler->PSendSysMessage("{} : {} bot(s) analyses, {} sans liste.", scope, analysed, noList);

    // Named, not merely counted: "un bot manque" sends the player looking for a
    // bug, while the reason points at the one line of configuration to change.
    if (!skipped.empty())
    {
        constexpr size_t SKIPPED_MAX = 10;
        handler->PSendSysMessage("{} bot(s) ignore(s) :", uint32(skipped.size()));
        for (size_t i = 0; i < skipped.size() && i < SKIPPED_MAX; ++i)
            handler->PSendSysMessage("  {}", skipped[i]);
        if (skipped.size() > SKIPPED_MAX)
            handler->PSendSysMessage("  ... et {} autre(s).", uint32(skipped.size() - SKIPPED_MAX));
    }

    return true;
}

bool BisReport::HandleMissing(ChatHandler* handler, char const* args)
{
    std::string name = args ? args : "";
    while (!name.empty() && name.back() == ' ')
        name.pop_back();

    if (name.empty())
    {
        handler->PSendSysMessage("usage : .playerbotsbis missing <nom du bot>");
        return true;
    }

    Player* bot = ObjectAccessor::FindPlayerByName(name, false);
    if (!bot)
    {
        handler->PSendSysMessage("{} n'est pas connecte.", name);
        return true;
    }

    if (!sBisPriorityMgr->AppliesTo(bot))
    {
        handler->PSendSysMessage("{} n'est pas un bot suivi par le module.", bot->GetName());
        return true;
    }

    std::vector<BisItem> const list = sBisPriorityMgr->GetReachableList(bot);
    if (list.empty())
    {
        handler->PSendSysMessage("{} : aucune liste a ce palier.", bot->GetName());
        return true;
    }

    uint8 const cls = bot->getClass();
    uint8 const spec = sBisPriorityMgr->GetSpec(bot);

    handler->PSendSysMessage("{} - {} {} niv {} :", bot->GetName(), ClassName(cls),
                             SpecName(cls, spec), uint32(bot->GetLevel()));

    std::map<uint8, BisItem> const targets = TargetsPerSlot(list);

    uint32 shown = 0;
    for (BisItem const& row : list)
    {
        auto target = targets.find(row.slot);
        bool const isTarget = target != targets.end() && target->second.itemId == row.itemId;

        // A fallback is only worth a line when it is the one the bot actually
        // wears: it explains why a slot is not empty despite its target missing.
        uint8 const state = ResolveState(bot, row.itemId);
        if (state == BIS_EQUIPPED && isTarget)
            continue;
        if (!isTarget && state != BIS_EQUIPPED)
            continue;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(row.itemId);
        if (!proto)
            continue;

        std::string const tier = sBisPriorityMgr->GetTierName(row.tierId);
        char const* tag;
        if (state == BIS_EQUIPPED)
            tag = "|cff1eff00(porte, repli)|r";
        else if (state == BIS_CARRIED)
            tag = "|cffffcc00(dans ses sacs)|r";
        else
            tag = "|cffff2020(manquant)|r";

        handler->PSendSysMessage("  rang {} {} {} - {}", uint32(row.rank), ChatHelper::FormatItem(proto),
                                 tag, tier.empty() ? "?" : tier);
        ++shown;
    }

    if (!shown)
        handler->PSendSysMessage("  rien ne manque a ce palier.");

    return true;
}

bool BisReport::HandleAdvance(ChatHandler* handler, char const* /*args*/)
{
    Player* maitre = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!maitre)
        return false;

    Group* groupe = maitre->GetGroup();
    if (!groupe)
    {
        handler->PSendSysMessage("Tu n'es pas en groupe : il n'y a personne a faire avancer.");
        return true;
    }

    uint32 remplis = 0;
    uint32 releves = 0;
    uint32 ramenes = 0;
    uint32 ailleurs = 0;
    uint32 enCombat = 0;
    uint32 joueurs = 0;

    for (GroupReference* ref = groupe->GetFirstMember(); ref; ref = ref->next())
    {
        Player* membre = ref->GetSource();
        if (!membre || membre == maitre)
            continue;

        // JAMAIS UN JOUEUR. Remplir la vie et le mana de quelqu'un qui tient
        // son clavier, c'est decider a sa place; et son repos a lui ne retient
        // de toute facon pas le tank de la meme maniere.
        if (!GET_PLAYERBOT_AI(membre))
        {
            ++joueurs;
            continue;
        }

        // ── LES MORTS D'ABORD ────────────────────────────────────────────
        //
        // Un raid a terre ne repart pas tout seul : mod-dungeon-clear tient la
        // place pendant que son ressusciteur boit de quoi payer le sort, et
        // abandonne le run passe son delai. Le coeur n'a pas de commande pour
        // relever un groupe entier - ".revive" ne touche que la cible.
        //
        // Un mort n'est jamais "en combat", donc cette branche ne peut pas
        // etre confondue avec le soin refuse plus bas : elle releve, point.
        if (!membre->IsAlive())
        {
            membre->ResurrectPlayer(1.0f, false);  // false : pas de mal de resurrection
            membre->SpawnCorpseBones();
            ++releves;

            // ET ON LE RAMENE. Un bot qui a deja relache son esprit revient a
            // la vie LA OU SON FANTOME SE TROUVE, c'est-a-dire au cimetiere.
            // Le relever sans le ramener, c'est echanger quarante cadavres
            // contre quarante bots qui traversent le donjon a pied.
            //
            // Meme carte seulement : un passage d'une carte a l'autre vers une
            // instance peut echouer sur le verrou, et un echec silencieux au
            // milieu d'une boucle de quarante est pire que l'aveu.
            if (membre->GetMapId() != maitre->GetMapId())
                ++ailleurs;
            else if (membre->GetExactDist2d(maitre) > RAPPEL_DISTANCE)
            {
                membre->TeleportTo(maitre->GetMapId(), maitre->GetPositionX(), maitre->GetPositionY(),
                                   maitre->GetPositionZ(), maitre->GetOrientation());
                ++ramenes;
            }

            // Puis il tombe dans la remise a plein ci-dessous : un ressuscite
            // arrive a vingt pour cent, et c'est exactement ce qui retiendrait
            // le tank au repos juste apres.
        }

        // HORS COMBAT SEULEMENT. En combat, ce serait un soin gratuit au milieu
        // d'un boss - ce n'est pas ce qu'on demande ici, et personne ne devrait
        // pouvoir le faire par megarde avec une commande qui parle d'avancer.
        if (membre->IsInCombat())
        {
            ++enCombat;
            continue;
        }

        membre->SetFullHealth();

        if (membre->getPowerType() == POWER_MANA)
            membre->SetPower(POWER_MANA, membre->GetMaxPower(POWER_MANA));

        // Debout. La nourriture et la boisson s'interrompent d'elles-memes des
        // que le personnage se leve, donc il n'y a aucune aura a retirer a la
        // main - et en retirer par type risquerait d'en emporter d'autres.
        if (membre->IsSitState())
            membre->SetStandState(UNIT_STAND_STATE_STAND);

        ++remplis;
    }

    if (releves)
        handler->PSendSysMessage("{} bot(s) ressuscite(s), dont {} rapatrie(s) aupres de toi.",
                                 releves, ramenes);

    handler->PSendSysMessage("{} bot(s) remis a plein et debout.", remplis);

    // Ce qui n'a PAS ete fait, et pourquoi. Sans ca, un raid qui n'avance
    // toujours pas laisse chercher du cote du module alors que la reponse est
    // qu'il reste un mort ou un bot encore accroche a un scarabee.
    if (enCombat)
        handler->PSendSysMessage("  {} encore en combat : ils ne sont pas touches.", enCombat);
    if (ailleurs)
        handler->PSendSysMessage("  {} ressuscite(s) sur une AUTRE carte : non rapatrie(s), le passage "
                                 "d'une carte a l'autre peut echouer sur le verrou d'instance.", ailleurs);
    if (joueurs)
        handler->PSendSysMessage("  {} joueur(s) dans le groupe : jamais touches.", joueurs);

    return true;
}
