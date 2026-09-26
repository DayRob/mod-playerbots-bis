/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef MOD_PLAYERBOTS_BIS_REPORT_H
#define MOD_PLAYERBOTS_BIS_REPORT_H

class ChatHandler;

// Which of a bot's best-in-slot pieces it actually owns.
//
// Nothing outside the running server can work this out on its own: the spec a
// list is keyed by is never persisted - AiFactory recomputes it from the
// talents on demand - so the answer has to be produced here and written down.
namespace BisReport
{
    // args: empty for the caller's guild, "all" for every bot the module
    // applies to. Writes characters.playerbots_bis_report and prints a summary.
    bool HandleReport(ChatHandler* handler, char const* args);

    // args: a bot name. Lists that bot's missing pieces in chat, with links.
    bool HandleMissing(ChatHandler* handler, char const* args);
}

#endif
