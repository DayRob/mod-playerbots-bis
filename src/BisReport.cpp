/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisReport.h"
#include "BisPriorityMgr.h"
#include "Chat.h"
#include "ChatHelper.h"
#include "DatabaseEnv.h"
#include "Guild.h"
#include "GuildMgr.h"
#include "Item.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include <algorithm>
#include <sstream>
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

    // Created on demand so the report needs no manual SQL import. It holds
    // nothing that cannot be rebuilt by running the command again.
    void EnsureTable()
    {
        CharacterDatabase.DirectExecute(
            "CREATE TABLE IF NOT EXISTS `playerbots_bis_report` ("
            "`guid` INT UNSIGNED NOT NULL,"
            "`name` VARCHAR(12) NOT NULL,"
            "`guild_id` INT UNSIGNED NOT NULL DEFAULT 0,"
            "`class` TINYINT UNSIGNED NOT NULL,"
            "`spec` TINYINT UNSIGNED NOT NULL,"
            "`level` TINYINT UNSIGNED NOT NULL,"
            "`slot` TINYINT UNSIGNED NOT NULL,"
            "`item_id` INT UNSIGNED NOT NULL,"
            "`tier_id` SMALLINT UNSIGNED NOT NULL,"
            "`rank` TINYINT UNSIGNED NOT NULL,"
            "`state` TINYINT UNSIGNED NOT NULL COMMENT '0 manquant, 1 en sac, 2 equipe',"
            "`updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,"
            "PRIMARY KEY (`guid`,`item_id`),"
            "KEY `guild_id` (`guild_id`),"
            "KEY `state` (`state`),"
            "KEY `item_id` (`item_id`)"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='mod-playerbots-bis : couverture BiS par bot'");
    }

    struct BotTally
    {
        uint32 equipped = 0;
        uint32 carried  = 0;
        uint32 missing  = 0;
        uint32 rows     = 0;
    };

    // Returns the bots the module applies to, optionally narrowed to one guild.
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

    uint32 guildId = 0;
    if (!all)
    {
        Player* me = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!me || !me->GetGuildId())
        {
            handler->PSendSysMessage("Tu n'es dans aucune guilde. Utilise .playerbotsbis report all "
                                     "pour couvrir tous les bots.");
            return true;
        }
        guildId = me->GetGuildId();
    }

    std::vector<Player*> const bots = CollectBots(guildId, all);
    if (bots.empty())
    {
        handler->PSendSysMessage("Aucun bot concerne. Les bots doivent etre connectes pour etre analyses.");
        return true;
    }

    EnsureTable();

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();

    uint32 totalRows = 0;
    uint32 analysed = 0;
    uint32 noList = 0;

    for (Player* bot : bots)
    {
        std::vector<BisItem> const list = sBisPriorityMgr->GetReachableList(bot);

        uint32 const guid = bot->GetGUID().GetCounter();
        trans->Append("DELETE FROM playerbots_bis_report WHERE guid = {}", guid);

        if (list.empty())
        {
            ++noList;
            handler->PSendSysMessage("{} - {} {} niv {} : aucune liste a ce palier.",
                                     bot->GetName(), ClassName(bot->getClass()),
                                     SpecName(bot->getClass(), sBisPriorityMgr->GetSpec(bot)),
                                     uint32(bot->GetLevel()));
            continue;
        }

        ++analysed;

        uint8 const cls = bot->getClass();
        uint8 const spec = sBisPriorityMgr->GetSpec(bot);
        uint8 const level = bot->GetLevel();
        uint32 const botGuild = bot->GetGuildId();

        std::string name = bot->GetName();
        CharacterDatabase.EscapeString(name);

        // Only rank 1 counts towards the headline number: a slot is covered when
        // the bot wears the piece the list actually picks for it, not a fallback.
        BotTally best;

        std::ostringstream values;
        uint32 pending = 0;

        for (BisItem const& row : list)
        {
            uint8 const state = ResolveState(bot, row.itemId);

            if (row.rank == 1)
            {
                ++best.rows;
                if (state == BIS_EQUIPPED)
                    ++best.equipped;
                else if (state == BIS_CARRIED)
                    ++best.carried;
                else
                    ++best.missing;
            }

            if (pending)
                values << ",";
            values << "(" << guid << ",'" << name << "'," << botGuild << "," << uint32(cls) << ","
                   << uint32(spec) << "," << uint32(level) << "," << uint32(row.slot) << ","
                   << row.itemId << "," << row.tierId << "," << uint32(row.rank) << ","
                   << uint32(state) << ",NOW())";
            ++pending;
            ++totalRows;

            // Flushed in batches so one bot with a long list never builds a
            // single enormous statement.
            if (pending >= 200)
            {
                trans->Append("INSERT INTO playerbots_bis_report "
                              "(guid,name,guild_id,class,spec,level,slot,item_id,tier_id,`rank`,state,updated) "
                              "VALUES {}", values.str());
                values.str("");
                values.clear();
                pending = 0;
            }
        }

        if (pending)
            trans->Append("INSERT INTO playerbots_bis_report "
                          "(guid,name,guild_id,class,spec,level,slot,item_id,tier_id,`rank`,state,updated) "
                          "VALUES {}", values.str());

        handler->PSendSysMessage("{} - {} {} niv {} : {}/{} equipes, {} en sac, {} manquants.",
                                 bot->GetName(), ClassName(cls), SpecName(cls, spec), uint32(level),
                                 best.equipped, best.rows, best.carried, best.missing);
    }

    CharacterDatabase.CommitTransaction(trans);

    handler->PSendSysMessage("---");
    if (all)
        handler->PSendSysMessage("{} bot(s) analyses, {} sans liste, {} lignes ecrites dans "
                                 "characters.playerbots_bis_report.", analysed, noList, totalRows);
    else
    {
        Guild* guild = sGuildMgr->GetGuildById(guildId);
        handler->PSendSysMessage("Guilde {} : {} bot(s) analyses, {} sans liste, {} lignes ecrites dans "
                                 "characters.playerbots_bis_report.",
                                 guild ? guild->GetName() : std::string("?"), analysed, noList, totalRows);
    }
    handler->PSendSysMessage(".playerbotsbis missing <nom> pour le detail d'un bot.");

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
