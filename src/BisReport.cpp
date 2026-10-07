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
