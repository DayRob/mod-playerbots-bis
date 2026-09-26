/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisReport.h"
#include "BisPriorityMgr.h"
#include "Chat.h"
#include "ChatHelper.h"
#include "Guild.h"
#include "GuildMgr.h"
#include "Item.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include <algorithm>
#include <string>
#include <vector>

namespace
{
    enum BisState : uint8
    {
        BIS_MISSING  = 0,
        BIS_CARRIED  = 1,
        BIS_EQUIPPED = 2,
    };

    char const* const CLASS_NAME[MAX_CLASSES] = {
        "", "Guerrier", "Paladin", "Chasseur", "Voleur", "Pretre",
        "Chevalier de la mort", "Chaman", "Mage", "Demoniste", "", "Druide",
    };

    // Spec 10 on the Druid is the module's Bear sentinel: Bear and Cat share
    // talent tab 1, so the list separates them by a value the tab cannot produce.
    char const* SpecName(uint8 cls, uint8 spec)
    {
        switch (cls)
        {
            case CLASS_WARRIOR:      return spec == 0 ? "Armes" : spec == 1 ? "Fureur" : "Protection";
            case CLASS_PALADIN:      return spec == 0 ? "Sacre" : spec == 1 ? "Protection" : "Vindicte";
            case CLASS_HUNTER:       return spec == 0 ? "Maitrise des betes" : spec == 1 ? "Precision" : "Survie";
            case CLASS_ROGUE:        return spec == 0 ? "Assassinat" : spec == 1 ? "Combat" : "Finesse";
            case CLASS_PRIEST:       return spec == 0 ? "Discipline" : spec == 1 ? "Sacre" : "Ombre";
            case CLASS_DEATH_KNIGHT: return spec == 0 ? "Sang" : spec == 1 ? "Givre" : "Impie";
            case CLASS_SHAMAN:       return spec == 0 ? "Elementaire" : spec == 1 ? "Amelioration" : "Restauration";
            case CLASS_MAGE:         return spec == 0 ? "Arcanes" : spec == 1 ? "Feu" : "Givre";
            case CLASS_WARLOCK:      return spec == 0 ? "Affliction" : spec == 1 ? "Demonologie" : "Destruction";
            case CLASS_DRUID:
                if (spec == BIS_SPEC_DRUID_BEAR)
                    return "Farouche (ours)";
                return spec == 0 ? "Equilibre" : spec == 1 ? "Farouche" : "Restauration";
            default: return "?";
        }
    }

    char const* ClassName(uint8 cls)
    {
        return (cls < MAX_CLASSES && CLASS_NAME[cls][0]) ? CLASS_NAME[cls] : "?";
    }

    // Equipped beats carried: an item found on the bot's body is reported as
    // worn even though GetItemCount would also count it.
    uint8 ResolveState(Player* bot, uint32 itemId)
    {
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
            if (Item* worn = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                if (worn->GetEntry() == itemId)
                    return BIS_EQUIPPED;

        return bot->GetItemCount(itemId, true) > 0 ? BIS_CARRIED : BIS_MISSING;
    }

    // The addon channel the companion window listens on. A server-built addon
    // message is "PREFIX\tPAYLOAD"; the client splits on the tab and hands the
    // two halves to CHAT_MSG_ADDON.
    char const* const ADDON_PREFIX = "PBBISREP";

    // Fields are separated by ';', never '|'. The client runs chat text through
    // its escape parser before an addon ever sees it, and '|' opens an escape
    // sequence: "B|Cruvmarl" reads as the start of a colour code |c......, and a
    // malformed one kills the client outright (ERROR #134). ChatHandler doubles
    // '|' into '||' in system messages for exactly this reason.
    char const FIELD_SEP = ';';

    // A burst is delivered in one tick, so the stream is capped. Forty guild
    // bots is a hundred-odd messages; five hundred would be well past what is
    // reasonable to push at a client at once.
    constexpr size_t ADDON_MAX_BOTS = 150;

    // Addon messages cap at 255 bytes including the prefix, so payloads stay
    // well under that and a long item list travels in several pieces.
    constexpr size_t ADDON_PAYLOAD_MAX = 200;

    void SendAddon(Player* to, std::string const& payload)
    {
        if (!to)
            return;

        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_ADDON, LANG_ADDON, to->GetGUID(), to->GetGUID(),
                                     std::string(ADDON_PREFIX) + "\t" + payload, CHAT_TAG_NONE);
        to->SendDirectMessage(&data);
    }

    struct BotTally
    {
        uint32 equipped = 0;
        uint32 carried  = 0;
        uint32 missing  = 0;
        uint32 rows     = 0;
    };

    // Bots the module applies to, optionally narrowed to one guild. Only bots in
    // the world can be inspected: the answer comes from their live inventory.
    std::vector<Player*> CollectBots(uint32 guildId, bool all)
    {
        std::vector<Player*> bots;
        for (auto const& pair : ObjectAccessor::GetPlayers())
        {
            Player* bot = pair.second;
            if (!bot || !bot->IsInWorld())
                continue;

            if (!sBisPriorityMgr->AppliesTo(bot))
                continue;

            if (!all && bot->GetGuildId() != guildId)
                continue;

            bots.push_back(bot);
        }

        std::sort(bots.begin(), bots.end(), [](Player* a, Player* b)
        {
            if (a->getClass() != b->getClass())
                return a->getClass() < b->getClass();
            return a->GetName() < b->GetName();
        });

        return bots;
    }
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

    std::vector<Player*> const bots = CollectBots(guildId, all);
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

    // The companion addon listens for this stream and opens its window on the
    // closing marker.
    SendAddon(viewer, std::string("S") + FIELD_SEP + std::to_string(bots.size()) + FIELD_SEP + scope);

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

        // Only rank 1 counts: a slot is covered when the bot wears the piece the
        // list actually picks for it, not one of its fallbacks.
        BotTally best;
        std::vector<std::string> addonItems;

        for (BisItem const& row : list)
        {
            if (row.rank != 1)
                continue;

            uint8 const state = ResolveState(bot, row.itemId);

            ++best.rows;
            if (state == BIS_EQUIPPED)
                ++best.equipped;
            else if (state == BIS_CARRIED)
                ++best.carried;
            else
                ++best.missing;

            addonItems.push_back(std::to_string(row.itemId) + ":" + std::to_string(uint32(state)) +
                                 ":" + std::to_string(row.tierId) + ":" + std::to_string(uint32(row.slot)));
        }

        handler->PSendSysMessage("{} - {} {} niv {} : {}/{} equipes, {} en sac, {} manquants.",
                                 bot->GetName(), ClassName(cls), SpecName(cls, spec), uint32(level),
                                 best.equipped, best.rows, best.carried, best.missing);

        if (!viewer || analysed > uint32(ADDON_MAX_BOTS))
            continue;

        SendAddon(viewer, std::string("B") + FIELD_SEP + bot->GetName() + FIELD_SEP +
                          std::to_string(uint32(cls)) + FIELD_SEP + std::to_string(uint32(spec)) + FIELD_SEP +
                          std::to_string(uint32(level)) + FIELD_SEP + std::to_string(best.equipped) + FIELD_SEP +
                          std::to_string(best.rows) + FIELD_SEP + std::to_string(best.carried) + FIELD_SEP +
                          std::to_string(best.missing));

        std::string chunk;
        for (std::string const& item : addonItems)
        {
            if (!chunk.empty() && chunk.size() + item.size() + 1 > ADDON_PAYLOAD_MAX)
            {
                SendAddon(viewer, std::string("I") + FIELD_SEP + bot->GetName() + FIELD_SEP + chunk);
                chunk.clear();
            }

            if (!chunk.empty())
                chunk += ",";
            chunk += item;
        }

        if (!chunk.empty())
            SendAddon(viewer, std::string("I") + FIELD_SEP + bot->GetName() + FIELD_SEP + chunk);
    }

    SendAddon(viewer, std::string("E") + FIELD_SEP);

    handler->PSendSysMessage("---");
    if (analysed > uint32(ADDON_MAX_BOTS))
        handler->PSendSysMessage("Fenetre limitee aux {} premiers bots ; le reste est ci-dessus.",
                                 uint32(ADDON_MAX_BOTS));
    handler->PSendSysMessage("{} : {} bot(s) analyses, {} sans liste.", scope, analysed, noList);

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

    uint32 shown = 0;
    for (BisItem const& row : list)
    {
        if (row.rank != 1)
            continue;  // the pick for the slot, not its fallbacks

        uint8 const state = ResolveState(bot, row.itemId);
        if (state == BIS_EQUIPPED)
            continue;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(row.itemId);
        if (!proto)
            continue;

        std::string const tier = sBisPriorityMgr->GetTierName(row.tierId);
        handler->PSendSysMessage("  {} {} - {}", ChatHelper::FormatItem(proto),
                                 state == BIS_CARRIED ? "|cffffcc00(dans ses sacs)|r" : "|cffff2020(manquant)|r",
                                 tier.empty() ? "?" : tier);
        ++shown;
    }

    if (!shown)
        handler->PSendSysMessage("  rien ne manque a ce palier.");

    return true;
}
