/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisDungeonPlan.h"
#include "BisBotScan.h"
#include "BisPriorityMgr.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Guild.h"
#include "GuildMgr.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include "QueryResult.h"
#include <algorithm>
#include <cstdlib>
#include <map>
#include <string>
#include <unordered_map>
#include <vector>

using namespace BisBotScan;

namespace
{
    char const* const PLAN_MARKER = "PBBISPLN;";

    // A five-man group, minus the player who runs the command.
    constexpr size_t GROUP_SLOTS = 4;

    // How many instances the window lists. Past a dozen the tail is all
    // one-piece runs, which is noise rather than a plan.
    constexpr size_t MAX_DUNGEONS = 15;

    // Beyond the proposed group, a handful of replacements is useful; the whole
    // roster is not.
    constexpr size_t MAX_ALTERNATES = 6;

    // A reinforcement tank or healer brought along for a run it gains nothing
    // from should at least survive it. No table in the world database gives an
    // instance's intended level, so this leans on the group it joins: within
    // five levels of the average of the bots that do have something to win.
    constexpr uint8 REINFORCEMENT_LEVEL_SLACK = 5;

    void SendPlan(ChatHandler* handler, std::string const& payload)
    {
        SendMarked(handler, PLAN_MARKER, payload);
    }

    // ';' separates the fields of the stream, so it must not survive inside one.
    std::string Sanitise(std::string text)
    {
        for (char& c : text)
            if (c == ';' || c == '\n' || c == '\r')
                c = ' ';
        return text;
    }

    // A creature or object name travels INSIDE a field, alongside the item id
    // and the drop chance, so it must also spare the two separators that field
    // uses. Nothing in the game is called "Jed, Runewatcher", but the stream
    // should not be the thing that finds out.
    std::string SanitiseInline(std::string text)
    {
        for (char& c : text)
            if (c == ';' || c == ',' || c == ':' || c == '\n' || c == '\r')
                c = ' ';
        return text;
    }

    // ---------------------------------------------------------------------
    // Item -> instance index
    // ---------------------------------------------------------------------

    struct Drop
    {
        uint16 mapId = 0;
        uint32 chanceTenths = 0;   // percent x10, so 1.2% travels as 12
        std::string source;        // the creature or object with the best odds
    };

    std::unordered_map<uint32, std::vector<Drop>> _index;
    std::unordered_map<uint16, std::string> _mapNames;
    bool _indexed = false;

    // The queries below are assembled by hand rather than through the database
    // layer's formatting overload. Every value substituted here is a literal
    // this file owns - a table name, a column name - so there is nothing to
    // escape, and plain concatenation works the same on every AzerothCore
    // revision, whichever formatting helper the pool happens to expose.
    bool HasColumn(char const* table, char const* column)
    {
        std::string const sql =
            "SELECT COUNT(*) FROM `information_schema`.`COLUMNS` "
            "WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = '" + std::string(table) +
            "' AND `COLUMN_NAME` = '" + std::string(column) + "'";
        QueryResult result = WorldDatabase.Query(sql.c_str());
        return result && (*result)[0].Get<uint64>() > 0;
    }

    bool HasTable(char const* table)
    {
        std::string const sql =
            "SELECT COUNT(*) FROM `information_schema`.`TABLES` "
            "WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = '" + std::string(table) + "'";
        QueryResult result = WorldDatabase.Query(sql.c_str());
        return result && (*result)[0].Get<uint64>() > 0;
    }

    // Computed columns come back with a type the driver did not expect -
    // ROUND() yields a DECIMAL, and AzerothCore's Field::Get<uint32> complains
    // about the mismatch. Reading the text and converting here sidesteps the
    // question entirely and behaves the same on every database version.
    uint32 ReadNumber(Field& field)
    {
        std::string const text = field.Get<std::string>();
        return text.empty() ? 0 : uint32(std::strtoul(text.c_str(), nullptr, 10));
    }

    void Record(uint32 itemId, uint16 mapId, uint32 chanceTenths, std::string source)
    {
        std::vector<Drop>& drops = _index[itemId];
        for (Drop& existing : drops)
        {
            if (existing.mapId != mapId)
                continue;

            // Same instance reached by two different routes - a boss and the
            // chest behind it, say. Keep the better odds and the name that goes
            // with them.
            if (chanceTenths > existing.chanceTenths)
            {
                existing.chanceTenths = chanceTenths;
                existing.source = std::move(source);
            }
            return;
        }

        drops.push_back({ mapId, chanceTenths, std::move(source) });
    }

    // Instance names, best source first.
    //
    // The world database has no map names at all - they live in the client's
    // DBC files - so the module ships its own table for the instances that
    // matter, and falls back to whatever areatrigger_teleport calls the
    // destination. A map neither knows is shown by its id, which is ugly but
    // never wrong.
    void LoadMapNames()
    {
        _mapNames.clear();

        if (HasTable("areatrigger_teleport"))
        {
            if (QueryResult result = WorldDatabase.Query(
                    "SELECT `target_map`, MIN(`Name`) FROM `areatrigger_teleport` GROUP BY `target_map`"))
            {
                do
                {
                    Field* fields = result->Fetch();
                    _mapNames[uint16(ReadNumber(fields[0]))] = Sanitise(fields[1].Get<std::string>());
                } while (result->NextRow());
            }
        }

        // Ours wins where it exists: it is in French, and it names the instance
        // rather than the doorway the trigger happens to sit in.
        if (HasTable("playerbots_bis_map_name"))
        {
            if (QueryResult result = WorldDatabase.Query(
                    "SELECT `map_id`, `name` FROM `playerbots_bis_map_name`"))
            {
                do
                {
                    Field* fields = result->Fetch();
                    _mapNames[fields[0].Get<uint16>()] = Sanitise(fields[1].Get<std::string>());
                } while (result->NextRow());
            }
        }
    }

    std::string MapName(uint16 mapId)
    {
        auto it = _mapNames.find(mapId);
        if (it != _mapNames.end() && !it->second.empty())
            return it->second;
        return "carte " + std::to_string(uint32(mapId));
    }

    void Absorb(QueryResult result, uint32& rows)
    {
        if (!result)
            return;

        do
        {
            Field* fields = result->Fetch();
            Record(ReadNumber(fields[0]), uint16(ReadNumber(fields[1])), ReadNumber(fields[2]),
                   SanitiseInline(fields[3].Get<std::string>()));
            ++rows;
        } while (result->NextRow());
    }

    // Builds item -> instances, restricted to items some BiS list actually
    // names.
    //
    // The restriction is inside each branch of the UNION rather than around it,
    // so the database narrows the loot tables before joining them to the spawn
    // points. Filtering afterwards means materialising every drop in the game
    // first, which is the difference between a query that takes a moment and one
    // that hangs the command.
    //
    // The join against instance_template is what removes world drops. An item
    // that only falls off wandering wildlife has no instance row and disappears
    // on its own, with no hand-written exclusion list to maintain.
    void BuildIndex()
    {
        _index.clear();
        LoadMapNames();
        _indexed = true;

        // AzerothCore renamed creature.id to id1 when random-entry spawns
        // arrived. Both are still in the wild, so ask rather than assume.
        char const* const creatureIdColumn = HasColumn("creature", "id1") ? "id1" : "id";

        uint32 rows = 0;

        // Percent x10 as an integer: chances like 1.2% would otherwise round to
        // nothing, and the client only ever shows one decimal.
        std::string const creatureSql = std::string(
            "SELECT l.`item`, sp.`map`, ROUND(MAX(l.`chance`) * 10), "
            "       SUBSTRING_INDEX(GROUP_CONCAT(ct.`name` ORDER BY l.`chance` DESC SEPARATOR '\\n'), '\\n', 1) "
            "FROM ( "
            "      SELECT clt.`Item` AS `item`, clt.`Entry` AS `entry`, clt.`Chance` AS `chance` "
            "        FROM `creature_loot_template` clt "
            "       WHERE clt.`Item` IN (SELECT DISTINCT `item_id` FROM `playerbots_bis_item`) "
            "      UNION ALL "
            "      SELECT rlt.`Item`, clt.`Entry`, rlt.`Chance` "
            "        FROM `reference_loot_template` rlt "
            "        JOIN `creature_loot_template` clt ON clt.`Reference` = rlt.`Entry` "
            "       WHERE rlt.`Item` IN (SELECT DISTINCT `item_id` FROM `playerbots_bis_item`) "
            "     ) l "
            "JOIN `creature` sp ON sp.`") + creatureIdColumn + "` = l.`entry` "
            "JOIN `instance_template` i ON i.`map` = sp.`map` "
            "JOIN `creature_template` ct ON ct.`entry` = l.`entry` "
            "GROUP BY l.`item`, sp.`map`";

        Absorb(WorldDatabase.Query(creatureSql.c_str()), rows);

        // Chests and the like: Gordok Tribute and the Arena treasure chest carry
        // real pre-raid pieces, and missing them would quietly understate two
        // instances.
        Absorb(WorldDatabase.Query(
            "SELECT l.`item`, sp.`map`, ROUND(MAX(l.`chance`) * 10), "
            "       SUBSTRING_INDEX(GROUP_CONCAT(gt.`name` ORDER BY l.`chance` DESC SEPARATOR '\\n'), '\\n', 1) "
            "FROM ( "
            "      SELECT glt.`Item` AS `item`, glt.`Entry` AS `entry`, glt.`Chance` AS `chance` "
            "        FROM `gameobject_loot_template` glt "
            "       WHERE glt.`Item` IN (SELECT DISTINCT `item_id` FROM `playerbots_bis_item`) "
            "      UNION ALL "
            "      SELECT rlt.`Item`, glt.`Entry`, rlt.`Chance` "
            "        FROM `reference_loot_template` rlt "
            "        JOIN `gameobject_loot_template` glt ON glt.`Reference` = rlt.`Entry` "
            "       WHERE rlt.`Item` IN (SELECT DISTINCT `item_id` FROM `playerbots_bis_item`) "
            "     ) l "
            "JOIN `gameobject` sp ON sp.`id` = l.`entry` "
            "JOIN `instance_template` i ON i.`map` = sp.`map` "
            "JOIN `gameobject_template` gt ON gt.`entry` = l.`entry` "
            "GROUP BY l.`item`, sp.`map`"), rows);

        LOG_INFO("server.loading",
                 "[mod-playerbots-bis] Dungeon index built: {} item(s) locatable in an instance, from {} row(s)",
                 static_cast<uint32>(_index.size()), rows);
    }

    // ---------------------------------------------------------------------
    // Crossing the index with what the bots are missing
    // ---------------------------------------------------------------------

    struct BotNeed
    {
        Player* bot = nullptr;
        uint8 cls = 0;
        uint8 spec = 0;
        uint8 level = 0;
        Role role = ROLE_DPS;
        uint32 targets = 0;        // missing pieces its list picks for a slot
        uint32 pieces = 0;         // every missing piece, fallbacks included
        bool chosen = false;
        bool reinforcement = false;
        std::vector<std::string> items;
    };

    struct Dungeon
    {
        uint16 mapId = 0;
        uint32 targets = 0;
        uint32 pieces = 0;
        // Bots with something to win here, counted BEFORE the group is picked:
        // a reinforcement is appended to the same vector and would otherwise
        // inflate the headline figure with bots that gain nothing.
        uint32 interested = 0;
        std::vector<BotNeed> bots;
    };

    // Returns the index rather than a reference: push_back invalidates every
    // reference into the vector, and the group chooser holds on to several at
    // once while adding reinforcements.
    size_t NeedIndex(Dungeon& dungeon, Player* bot, uint8 cls, uint8 spec, uint8 level)
    {
        for (size_t i = 0; i < dungeon.bots.size(); ++i)
            if (dungeon.bots[i].bot == bot)
                return i;

        BotNeed fresh;
        fresh.bot = bot;
        fresh.cls = cls;
        fresh.spec = spec;
        fresh.level = level;
        fresh.role = RoleOf(cls, spec);
        dungeon.bots.push_back(fresh);
        return dungeon.bots.size() - 1;
    }

    // Targets first: a bot missing three of the pieces its list actually picks
    // is worth more than one missing three fallbacks for the same slot.
    bool MoreDeserving(BotNeed const& a, BotNeed const& b)
    {
        if (a.targets != b.targets) return a.targets > b.targets;
        if (a.pieces != b.pieces)   return a.pieces > b.pieces;
        return a.bot->GetName() < b.bot->GetName();
    }

    // Picks the four bots to bring.
    //
    // Pure greed would happily send four clothies into Stratholme, so one tank
    // and one healer are reserved first, and only then does the rest go to
    // whoever gains the most. When nobody in the running fills a role, a
    // reinforcement is pulled from the wider roster: it wins nothing there, but
    // the run happens, which is the point - and it takes a seat rather than
    // adding one, because a five-man group does not grow just because the plan
    // would like it to.
    void ChooseGroup(Dungeon& dungeon, std::vector<Player*> const& roster,
                     std::unordered_map<Player*, std::pair<uint8, uint8>> const& specs)
    {
        std::sort(dungeon.bots.begin(), dungeon.bots.end(), MoreDeserving);

        size_t seats = 0;

        auto takeFirstWithRole = [&](Role role) -> bool
        {
            for (BotNeed& need : dungeon.bots)
            {
                if (need.chosen || need.role != role)
                    continue;
                need.chosen = true;
                ++seats;
                return true;
            }
            return false;
        };

        bool const haveTank = takeFirstWithRole(ROLE_TANK);
        bool const haveHealer = takeFirstWithRole(ROLE_HEALER);

        for (BotNeed& need : dungeon.bots)
        {
            if (seats >= GROUP_SLOTS)
                break;
            if (need.chosen)
                continue;
            need.chosen = true;
            ++seats;
        }

        // Average level of the bots that actually gain something, so a
        // reinforcement is not dragged twenty levels out of its depth.
        uint32 levelSum = 0;
        uint32 counted = 0;
        for (BotNeed const& need : dungeon.bots)
        {
            if (!need.chosen)
                continue;
            levelSum += need.level;
            ++counted;
        }
        uint8 const reference = counted ? uint8(levelSum / counted) : 0;

        // Frees a seat by dropping the least deserving damage dealer, so the
        // group never exceeds its size. Returns false when there is nothing to
        // give up, in which case the reinforcement is not worth forcing.
        auto freeSeat = [&]() -> bool
        {
            if (seats < GROUP_SLOTS)
                return true;

            for (size_t i = dungeon.bots.size(); i-- > 0; )
            {
                BotNeed& need = dungeon.bots[i];
                if (!need.chosen || need.reinforcement || need.role != ROLE_DPS)
                    continue;
                need.chosen = false;
                --seats;
                return true;
            }
            return false;
        };

        auto addReinforcement = [&](Role role)
        {
            Player* best = nullptr;
            uint8 bestLevel = 0;

            for (Player* candidate : roster)
            {
                auto spec = specs.find(candidate);
                if (spec == specs.end())
                    continue;
                if (RoleOf(spec->second.first, spec->second.second) != role)
                    continue;

                bool already = false;
                for (BotNeed const& need : dungeon.bots)
                    if (need.bot == candidate && need.chosen)
                        already = true;
                if (already)
                    continue;

                uint8 const level = candidate->GetLevel();
                if (reference > REINFORCEMENT_LEVEL_SLACK &&
                    uint32(level) + REINFORCEMENT_LEVEL_SLACK < uint32(reference))
                    continue;

                if (!best || level > bestLevel)
                {
                    best = candidate;
                    bestLevel = level;
                }
            }

            if (!best || !freeSeat())
                return;

            auto spec = specs.find(best);
            size_t const index = NeedIndex(dungeon, best, spec->second.first, spec->second.second,
                                           best->GetLevel());
            dungeon.bots[index].chosen = true;
            dungeon.bots[index].reinforcement = true;
            ++seats;
        };

        if (!haveTank)
            addReinforcement(ROLE_TANK);
        if (!haveHealer)
            addReinforcement(ROLE_HEALER);

        // Chosen first, so the stream can stop early without ever cutting off a
        // reinforcement, which was appended to the back of the vector.
        std::stable_sort(dungeon.bots.begin(), dungeon.bots.end(),
                         [](BotNeed const& a, BotNeed const& b)
        {
            if (a.chosen != b.chosen) return a.chosen;
            return MoreDeserving(a, b);
        });
    }
}

void BisDungeonPlan::Invalidate()
{
    _index.clear();
    _mapNames.clear();
    _indexed = false;
}

bool BisDungeonPlan::HandlePlan(ChatHandler* handler, char const* args)
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
            handler->PSendSysMessage("Tu n'es dans aucune guilde. Utilise .playerbotsbis donjons all "
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

    if (!_indexed)
    {
        handler->PSendSysMessage("Construction de l'index des donjons, un instant...");
        BuildIndex();
    }

    if (_index.empty())
    {
        handler->PSendSysMessage("Aucun objet BiS n'a pu etre localise dans une instance. "
                                 "Verifie que les tables de butin sont peuplees.");
        return true;
    }

    std::string scope = "tous les bots";
    if (!all)
    {
        Guild* g = sGuildMgr->GetGuildById(guildId);
        scope = g ? Sanitise(g->GetName()) : "guilde";
    }

    std::unordered_map<uint16, Dungeon> found;
    std::unordered_map<Player*, std::pair<uint8, uint8>> specs;

    uint32 analysed = 0;
    uint32 unlocatable = 0;

    // Naming a few of them turns "88 targets are unlocatable" into something
    // actionable: a list of vendor rewards reads very differently from a list of
    // dungeon drops that should have been found.
    constexpr size_t UNLOCATABLE_SAMPLE = 8;
    std::vector<std::string> unlocatableNames;

    for (Player* bot : bots)
    {
        std::vector<BisItem> const list = sBisPriorityMgr->GetReachableList(bot);
        if (list.empty())
            continue;

        ++analysed;

        uint8 const cls = bot->getClass();
        uint8 const spec = sBisPriorityMgr->GetSpec(bot);
        uint8 const level = bot->GetLevel();
        specs[bot] = { cls, spec };

        std::map<uint8, BisItem> const targets = TargetsPerSlot(list);

        for (BisItem const& row : list)
        {
            if (ResolveState(bot, row.itemId) != BIS_MISSING)
                continue;

            auto target = targets.find(row.slot);
            bool const isTarget = target != targets.end() && target->second.itemId == row.itemId;

            auto drops = _index.find(row.itemId);
            if (drops == _index.end())
            {
                // Crafted, bought, quested or dropped in the open world: real
                // pieces, just not ones a dungeon run will produce.
                if (isTarget)
                {
                    ++unlocatable;
                    if (unlocatableNames.size() < UNLOCATABLE_SAMPLE)
                        if (ItemTemplate const* proto = sObjectMgr->GetItemTemplate(row.itemId))
                        {
                            std::string const name = proto->Name1;
                            if (std::find(unlocatableNames.begin(), unlocatableNames.end(), name)
                                == unlocatableNames.end())
                                unlocatableNames.push_back(name);
                        }
                }
                continue;
            }

            for (Drop const& drop : drops->second)
            {
                Dungeon& dungeon = found[drop.mapId];
                dungeon.mapId = drop.mapId;
                ++dungeon.pieces;
                if (isTarget)
                    ++dungeon.targets;

                size_t const index = NeedIndex(dungeon, bot, cls, spec, level);
                BotNeed& need = dungeon.bots[index];
                ++need.pieces;
                if (isTarget)
                    ++need.targets;

                // The source name rides along: it is the one thing the client
                // cannot work out on its own, since a 3.3.5 tooltip has never
                // carried where an item comes from.
                need.items.push_back(std::to_string(row.itemId) + ":" +
                                     std::to_string(drop.chanceTenths) + ":" +
                                     (isTarget ? "1" : "0") + ":" + drop.source);
            }
        }
    }

    if (found.empty())
    {
        handler->PSendSysMessage("Rien a aller chercher en donjon : {} bot(s) analyses, "
                                 "aucune piece manquante ne tombe en instance.", analysed);
        return true;
    }

    std::vector<Dungeon> plan;
    plan.reserve(found.size());
    for (auto& entry : found)
        plan.push_back(std::move(entry.second));

    std::sort(plan.begin(), plan.end(), [](Dungeon const& a, Dungeon const& b)
    {
        if (a.targets != b.targets) return a.targets > b.targets;
        if (a.pieces != b.pieces)   return a.pieces > b.pieces;
        return a.mapId < b.mapId;
    });

    // An instance where every piece on offer is a fallback is not a plan. It is
    // how Naxxramas ends up at the top of the list for level 60 bots: its trash
    // inherits world-drop loot tables, so a handful of rank-3 stand-ins turn up
    // there, and sorting by piece count alone puts the whole raid above the
    // dungeon that actually holds someone's best in slot.
    uint32 fallbackOnly = 0;
    for (Dungeon const& dungeon : plan)
        if (!dungeon.targets)
            ++fallbackOnly;

    plan.erase(std::remove_if(plan.begin(), plan.end(),
                              [](Dungeon const& d) { return d.targets == 0; }),
               plan.end());

    if (plan.empty())
    {
        handler->PSendSysMessage("Aucune instance ne contient de CIBLE pour ces bots.");
        handler->PSendSysMessage("{} instance(s) ne proposaient que des replis - des rangs 2 ou 3 "
                                 "ramasses au passage - et ne valent pas un run.", fallbackOnly);
        if (unlocatable)
        {
            handler->PSendSysMessage("{} cible(s) manquante(s) ne tombent dans aucune instance.",
                                     unlocatable);
            std::string sample;
            for (std::string const& name : unlocatableNames)
                sample += (sample.empty() ? "" : ", ") + name;
            if (!sample.empty())
                handler->PSendSysMessage("Par exemple : {}.", sample);
            handler->PSendSysMessage("Si ces pieces devraient tomber en donjon, lance "
                                     "tools/diagnostic_plan_donjons.sql sur ta base monde.");
        }
        return true;
    }

    if (plan.size() > MAX_DUNGEONS)
        plan.resize(MAX_DUNGEONS);

    for (Dungeon& dungeon : plan)
    {
        dungeon.interested = static_cast<uint32>(dungeon.bots.size());
        ChooseGroup(dungeon, bots, specs);
    }

    SendPlan(handler, std::string("S") + FIELD_SEP + std::to_string(plan.size()) + FIELD_SEP + scope);

    for (Dungeon const& dungeon : plan)
    {
        std::string const name = MapName(dungeon.mapId);
        std::string const mapField = std::to_string(uint32(dungeon.mapId));

        handler->PSendSysMessage("{} - {} cible(s), {} piece(s), {} bot(s) concernes.",
                                 name, dungeon.targets, dungeon.pieces, dungeon.interested);

        SendPlan(handler, std::string("D") + FIELD_SEP + mapField + FIELD_SEP +
                          std::to_string(dungeon.targets) + FIELD_SEP +
                          std::to_string(dungeon.pieces) + FIELD_SEP +
                          std::to_string(dungeon.interested) + FIELD_SEP + name);

        size_t streamed = 0;
        for (BotNeed const& need : dungeon.bots)
        {
            if (!need.chosen && streamed >= GROUP_SLOTS + MAX_ALTERNATES)
                break;
            ++streamed;

            if (need.chosen)
                handler->PSendSysMessage("   * {} - {} {} niv {} ({}) : {} cible(s), {} piece(s){}",
                                         need.bot->GetName(), ClassName(need.cls),
                                         SpecName(need.cls, need.spec), uint32(need.level),
                                         RoleName(need.role), need.targets, need.pieces,
                                         need.reinforcement ? " - renfort" : "");

            SendPlan(handler, std::string("R") + FIELD_SEP + mapField + FIELD_SEP +
                              std::to_string(uint32(need.cls)) + FIELD_SEP +
                              std::to_string(uint32(need.spec)) + FIELD_SEP +
                              std::to_string(uint32(need.level)) + FIELD_SEP +
                              std::to_string(need.targets) + FIELD_SEP +
                              std::to_string(need.pieces) + FIELD_SEP +
                              std::to_string(uint32(need.role)) + FIELD_SEP +
                              (need.chosen ? "1" : "0") + FIELD_SEP +
                              (need.reinforcement ? "1" : "0") + FIELD_SEP + need.bot->GetName());

            std::string chunk;
            for (std::string const& item : need.items)
            {
                if (!chunk.empty() && chunk.size() + item.size() + 1 > PAYLOAD_MAX)
                {
                    SendPlan(handler, std::string("J") + FIELD_SEP + mapField + FIELD_SEP +
                                      need.bot->GetName() + FIELD_SEP + chunk);
                    chunk.clear();
                }

                if (!chunk.empty())
                    chunk += ",";
                chunk += item;
            }

            if (!chunk.empty())
                SendPlan(handler, std::string("J") + FIELD_SEP + mapField + FIELD_SEP +
                                  need.bot->GetName() + FIELD_SEP + chunk);
        }
    }

    SendPlan(handler, std::string("E") + FIELD_SEP);

    handler->PSendSysMessage("---");
    handler->PSendSysMessage("{} : {} bot(s) analyses, {} instance(s) utiles.",
                             scope, analysed, static_cast<uint32>(plan.size()));
    if (fallbackOnly)
        handler->PSendSysMessage("{} instance(s) ecartees : elles ne proposaient que des replis.",
                                 fallbackOnly);
    if (unlocatable)
    {
        handler->PSendSysMessage("{} cible(s) manquante(s) ne tombent dans aucune instance "
                                 "(artisanat, vendeur, quete ou drop monde).", unlocatable);
        std::string sample;
        for (std::string const& name : unlocatableNames)
            sample += (sample.empty() ? "" : ", ") + name;
        if (!sample.empty())
            handler->PSendSysMessage("Par exemple : {}.", sample);
    }

    return true;
}
