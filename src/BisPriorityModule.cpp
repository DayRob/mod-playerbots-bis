/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisActionContext.h"
#include "BisPriorityMgr.h"
#include "BisReport.h"
#include "BisValueContext.h"
#include "Chat.h"
#include "Config.h"
#include "DKAiObjectContext.h"
#include "DruidAiObjectContext.h"
#include "HunterAiObjectContext.h"
#include "Log.h"
#include "MageAiObjectContext.h"
#include "PaladinAiObjectContext.h"
#include "PriestAiObjectContext.h"
#include "RogueAiObjectContext.h"
#include "ScriptMgr.h"
#include <string>
#include "ShamanAiObjectContext.h"
#include "WarlockAiObjectContext.h"
#include "WarriorAiObjectContext.h"

namespace
{
    // Append our contexts to one class's shared lists. Add() assigns into each
    // list's creator map, so our "item usage" / "item upgrade" values and our
    // "loot roll" action replace playerbots'. Per-bot context lists hold the
    // maps by reference, so
    // bots that already exist pick this up as soon as they next resolve the
    // value by name.
    template <class Ctx>
    void RegisterClassContexts()
    {
        Ctx::sharedValueContexts.Add(new BisValueContext());
        Ctx::sharedActionContexts.Add(new BisActionContext());
    }
}

// Registration happens on the first world tick rather than at load time, for
// two reasons. The module config is certainly loaded by then, and script
// registration order is alphabetical - registering here guarantees we land
// AFTER mod-playerbots' own ValueContext, which is what makes the override win.
// It is also still before any bot logs in, so no bot has cached the old value.
class BisPriorityWorldScript : public WorldScript
{
public:
    BisPriorityWorldScript() : WorldScript("BisPriorityWorldScript") {}

    void OnUpdate(uint32 /*diff*/) override
    {
        if (_registered)
            return;
        _registered = true;

        sBisPriorityMgr->LoadConfig();
        sBisPriorityMgr->LoadTables();

        if (!sBisPriorityMgr->IsLoaded())
        {
            LOG_ERROR("server.loading", "[mod-playerbots-bis] Tables unavailable - bot itemisation left untouched");
            return;
        }

        // Registration happens even when the module is switched off, so that
        // PlayerbotsBis.Enable can be toggled at runtime with ".playerbotsbis
        // reload". This is the only moment at which registering is safe (after
        // playerbots, before any bot exists), so skipping it here would leave
        // the module permanently inert until the next restart.
        //
        // A disabled module costs one delegated virtual call per gear decision:
        // BisPriorityMgr::AppliesTo() returns false, and the replacement values
        // hand back exactly what playerbots would have answered.

        RegisterClassContexts<WarriorAiObjectContext>();
        RegisterClassContexts<PaladinAiObjectContext>();
        RegisterClassContexts<HunterAiObjectContext>();
        RegisterClassContexts<RogueAiObjectContext>();
        RegisterClassContexts<PriestAiObjectContext>();
        RegisterClassContexts<DKAiObjectContext>();
        RegisterClassContexts<ShamanAiObjectContext>();
        RegisterClassContexts<MageAiObjectContext>();
        RegisterClassContexts<WarlockAiObjectContext>();
        RegisterClassContexts<DruidAiObjectContext>();

        if (sBisPriorityMgr->IsEnabled())
            LOG_INFO("server.loading",
                     "[mod-playerbots-bis] Active - BiS ladder governs bot gear and loot rolls ({} tiers, {} items)",
                     static_cast<uint32>(sBisPriorityMgr->TierCount()),
                     static_cast<uint32>(sBisPriorityMgr->ItemCount()));
        else
            LOG_INFO("server.loading",
                     "[mod-playerbots-bis] Dormant (PlayerbotsBis.Enable = 0) - set it to 1 and run "
                     "\".playerbotsbis reload\" to activate without a restart");
    }

private:
    bool _registered = false;
};

// ".playerbotsbis reload" re-reads the module conf files FROM DISK and both
// tables, so a tier row, an item row or a setting can be edited and tried
// immediately. The conf part is not optional: sConfigMgr answers from what it
// read at startup, so without an explicit reload the command would quietly
// hand back the old settings while claiming to have reloaded them.
class BisPriorityCommandScript : public CommandScript
{
public:
    BisPriorityCommandScript() : CommandScript("BisPriorityCommandScript") {}

    Acore::ChatCommands::ChatCommandTable GetCommands() const override
    {
        using namespace Acore::ChatCommands;

        static ChatCommandTable bisCommandTable = {
            {"reload",  HandleBisReloadCommand,  SEC_GAMEMASTER, Console::Yes},
            {"report",  HandleBisReportCommand,  SEC_GAMEMASTER, Console::No},
            {"missing", HandleBisMissingCommand, SEC_GAMEMASTER, Console::No},
        };

        static ChatCommandTable commandTable = {
            {"playerbotsbis", bisCommandTable},
        };

        return commandTable;
    }

    static bool HandleBisReloadCommand(ChatHandler* handler, char const* /*args*/)
    {
        // Les tables viennent de la base, mais les reglages viennent de
        // sConfigMgr, qui garde ce qu'il a lu sur le disque AU DEMARRAGE du
        // serveur. Sans cette relecture, editer playerbots_bis.conf puis lancer
        // cette commande ne changeait rien : LoadConfig() relisait la meme
        // valeur en memoire, et la commande promettait un rechargement qu'elle
        // ne faisait pas.
        sConfigMgr->LoadModulesConfigs(true, false);

        sBisPriorityMgr->LoadConfig();
        sBisPriorityMgr->LoadTables();

        handler->PSendSysMessage("mod-playerbots-bis: reloaded {} tiers, {} item rows (enabled: {})",
                                 static_cast<uint32>(sBisPriorityMgr->TierCount()),
                                 static_cast<uint32>(sBisPriorityMgr->ItemCount()),
                                 sBisPriorityMgr->IsEnabled() ? "yes" : "no");

        // The ceiling decides everything the bots chase, and it is the one
        // setting whose effect is invisible until something does not happen.
        // Printing it also answers a question the file browser cannot: whether
        // the conf file you just edited is the one the server actually reads.
        uint16 const configured = sBisPriorityMgr->GetConfiguredMaxTier();
        uint16 const effective = configured ? configured : sBisPriorityMgr->GetLadderTop();
        std::string const name = sBisPriorityMgr->GetTierName(effective);

        if (configured)
            handler->PSendSysMessage("Palier maximum : {} - {}", configured,
                                     name.empty() ? "palier inconnu" : name);
        else
            handler->PSendSysMessage("Palier maximum : aucun plafond, soit {} - {}", effective,
                                     name.empty() ? "palier inconnu" : name);

        return true;
    }

    // Both need a player: the report defaults to the caller's guild, and either
    // way only bots currently in the world can be inspected.
    static bool HandleBisReportCommand(ChatHandler* handler, char const* args)
    {
        return BisReport::HandleReport(handler, args);
    }

    static bool HandleBisMissingCommand(ChatHandler* handler, char const* args)
    {
        return BisReport::HandleMissing(handler, args);
    }
};

// Defined in BisMasterLootAnnounce.cpp.
void AddSC_playerbots_bis_masterloot();

void AddSC_playerbots_bis()
{
    new BisPriorityWorldScript();
    new BisPriorityCommandScript();
    AddSC_playerbots_bis_masterloot();
}
