/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisUnbind.h"
#include "Chat.h"
#include "Group.h"
#include "InstanceSaveMgr.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include <cstdlib>
#include <sstream>
#include <string>
#include <vector>

namespace
{
    // Deliberately NOT BisPriorityMgr::AppliesTo. That test says whether the
    // ladder governs a bot's gear, which has nothing to do with where the core
    // sends it on a teleport. A bot the module ignores - an addclass bot, an alt,
    // one the random manager has dropped from currentBots - still lands in its
    // own copy of the instance and still breaks the raid.
    //
    // Being a bot at all is the only thing that matters here: a real player's
    // lock is his own business and is never touched.
    bool IsBot(Player* player)
    {
        return player && player->IsInWorld() && GET_PLAYERBOT_AI(player) != nullptr;
    }

    // Mirrors cs_instance.cpp, including the detail that makes it correct:
    // PlayerUnbindInstance mutates the very map being walked, so the iterator is
    // restarted after every removal instead of advanced.
    uint32 FreeBot(Player* bot, uint32 mapId)
    {
        uint32 freed = 0;

        for (uint8 i = 0; i < MAX_DIFFICULTY; ++i)
        {
            BoundInstancesMap const& binds =
                sInstanceSaveMgr->PlayerGetBoundInstances(bot->GetGUID(), Difficulty(i));

            for (BoundInstancesMap::const_iterator itr = binds.begin(); itr != binds.end();)
            {
                // The map a character is standing on is never unbound - the core
                // refuses it too, and for good reason: it is inside that copy.
                if (itr->first != bot->GetMapId() && (!mapId || mapId == itr->first))
                {
                    sInstanceSaveMgr->PlayerUnbindInstance(bot->GetGUID(), itr->first,
                                                           Difficulty(i), true, bot);
                    itr = binds.begin();
                    ++freed;
                }
                else
                {
                    ++itr;
                }
            }
        }

        return freed;
    }
}

bool BisUnbind::HandleUnbind(ChatHandler* handler, char const* args)
{
    Player* const viewer = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!viewer)
    {
        handler->PSendSysMessage("Cette commande doit etre lancee en jeu.");
        return true;
    }

    std::string const arg = args ? args : "";
    bool const guildScope = arg.find("guilde") != std::string::npos;

    // "moi" frees the caller too. Opt-in, and never the default: his lock IS the
    // raid's progress, and wiping it mid-clear would put Ragnaros back on his
    // feet. Asked for explicitly, it makes the whole thing one command.
    bool const includeSelf = arg.find("moi") != std::string::npos;

    uint32 mapId = 0;
    {
        std::istringstream in(arg);
        std::string token;
        while (in >> token)
        {
            uint32 const value = static_cast<uint32>(atoi(token.c_str()));
            if (value)
            {
                mapId = value;
                break;
            }
        }
    }

    // Two scopes, because the fix is needed at two different moments: before the
    // raid is formed (nobody is grouped yet, so the guild is the only handle),
    // and once it is (the group is exactly who will follow you in).
    std::vector<Player*> targets;
    if (guildScope)
    {
        uint32 const guildId = viewer->GetGuildId();
        if (!guildId)
        {
            handler->PSendSysMessage("Tu n'es dans aucune guilde.");
            return true;
        }

        for (auto const& pair : ObjectAccessor::GetPlayers())
        {
            Player* const bot = pair.second;
            if (bot != viewer && IsBot(bot) && bot->GetGuildId() == guildId)
                targets.push_back(bot);
        }
    }
    else
    {
        Group* const group = viewer->GetGroup();
        if (!group)
        {
            handler->PSendSysMessage("Tu n'es pas en groupe. Utilise |cffffd100.playerbotsbis libere guilde|r "
                                     "pour liberer les bots de ta guilde.");
            return true;
        }

        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* const member = ref->GetSource();
            if (member != viewer && IsBot(member))
                targets.push_back(member);
        }
    }

    if (includeSelf)
        targets.push_back(viewer);

    if (targets.empty())
    {
        handler->PSendSysMessage("Aucun bot a liberer.");
        return true;
    }

    uint32 totalFreed = 0;
    uint32 botsFreed = 0;
    uint32 inside = 0;

    for (Player* bot : targets)
    {
        // Counted separately: a bot still standing in the instance cannot be
        // freed, and saying "0 verrou" without that would look like a failure.
        if (mapId && bot->GetMapId() == mapId)
        {
            ++inside;
            continue;
        }

        uint32 const freed = FreeBot(bot, mapId);
        if (freed)
        {
            ++botsFreed;
            totalFreed += freed;
        }
    }

    if (mapId)
        handler->PSendSysMessage("Carte {} : {} verrou(s) liberes sur {} bot(s), {} bots examines.",
                                 mapId, totalFreed, botsFreed, uint32(targets.size()));
    else
        handler->PSendSysMessage("{} verrou(s) liberes sur {} bot(s), {} bots examines.",
                                 totalFreed, botsFreed, uint32(targets.size()));

    if (inside)
        handler->PSendSysMessage("{} bot(s) sont DANS cette instance : sors-les d'abord "
                                 "(|cffffd100.summon <nom>|r depuis l'exterieur), puis relance.", inside);

    if (includeSelf)
        handler->PSendSysMessage("Ton verrou est compris : la prochaine entree cree une copie neuve.");
    else
        handler->PSendSysMessage("Ton propre verrou n'a pas ete touche - ajoute |cffffd100moi|r pour "
                                 "l'inclure. Sinon : entre le premier, puis |cffffd100summon|r "
                                 "en tchat de raid.");

    return true;
}
