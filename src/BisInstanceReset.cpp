/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisInstanceReset.h"
#include "Config.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "InstanceSaveMgr.h"
#include "Log.h"
#include "QueryResult.h"
#include <vector>

namespace
{
    struct InstanceRow
    {
        uint32 id;
        uint32 locks;
    };

    // The ids come from the DB rather than from the manager because
    // m_instanceSaveById is private and no public accessor walks it. Reading
    // the table is equivalent: LoadInstances built the saves from these very
    // rows moments earlier.
    //
    // The lock count is taken here too, and not from the save, because
    // InstanceSave keeps m_playerList private and exposes no count. Counting
    // after the unbind would be worse than unavailable: RemovePlayer deletes
    // the save once its last player leaves, so the read would land in freed
    // memory.
    std::vector<InstanceRow> CollectInstances()
    {
        std::vector<InstanceRow> rows;

        QueryResult result = CharacterDatabase.Query(
            "SELECT i.id, COUNT(ci.guid) FROM instance i "
            "LEFT JOIN character_instance ci ON ci.instance = i.id GROUP BY i.id");

        if (!result)
            return rows;

        do
        {
            Field* fields = result->Fetch();

            // COUNT() comes back as a BIGINT, so it is read as one: asking
            // Field for a uint32 on a 64-bit column trips the type check in a
            // debug build.
            rows.push_back({fields[0].Get<uint32>(),
                            static_cast<uint32>(fields[1].Get<uint64>())});
        } while (result->NextRow());

        return rows;
    }

    // MapEntry::IsDungeon() is true for raids as well, hence the order: a raid
    // answers on the first test, and the second only ever sees five-mans.
    // Battlegrounds and arenas fail both, which is correct - they hold no
    // lockout worth clearing.
    bool InScope(uint32 mapId, uint8 scope)
    {
        MapEntry const* entry = sMapStore.LookupEntry(mapId);
        if (!entry)
            return false;

        if (entry->IsRaid())
            return true;

        return scope == BisInstanceReset::SCOPE_ALL && entry->IsDungeon();
    }
}

void BisInstanceReset::RunOnce()
{
    uint8 const scope =
        static_cast<uint8>(sConfigMgr->GetOption<uint32>("PlayerbotsBis.ResetInstancesOnStartup", 0));

    if (scope == SCOPE_OFF)
        return;

    std::vector<InstanceRow> const rows = CollectInstances();

    uint32 cleared = 0;
    uint32 freed = 0;

    for (InstanceRow const& row : rows)
    {
        InstanceSave* save = sInstanceSaveMgr->GetInstanceSave(row.id);
        if (!save)
            continue;

        if (!InScope(save->GetMapId(), scope))
            continue;

        // UnbindAllFor walks a copy of the player list and unbinds each one
        // with deleteFromDB = true, so character_instance is cleaned as it
        // goes. Taking the last player off the save also deletes the instance
        // row, its saved data and its respawn times - the core does that on
        // its own in DeleteInstanceSaveIfNeeded.
        //
        // The save may therefore be gone when this returns. Nothing below
        // touches it.
        sInstanceSaveMgr->UnbindAllFor(save);
        save = nullptr;

        // A save nobody was bound to survives the call above, because that loop
        // had nothing to iterate. Ask for it by id, which tolerates a save that
        // has just been deleted.
        sInstanceSaveMgr->DeleteInstanceSaveIfNeeded(row.id, false);

        freed += row.locks;
        ++cleared;
    }

    if (!cleared)
    {
        LOG_INFO("server.loading", "[mod-playerbots-bis] Startup instance reset: nothing to clear");
        return;
    }

    LOG_INFO("server.loading",
             "[mod-playerbots-bis] Startup instance reset: {} instance(s) cleared, {} character lock(s) freed ({})",
             cleared, freed, scope == SCOPE_ALL ? "raids and dungeons" : "raids only");
}
