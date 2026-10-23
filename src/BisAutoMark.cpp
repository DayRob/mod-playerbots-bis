/*
 * mod-playerbots-bis — released under GNU GPL v2, matching mod-playerbots and
 * AzerothCore. Redistribute/modify under version 2 of the License, or (at your
 * option) any later version.
 */

#include "BisPriorityMgr.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Group.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include "ScriptMgr.h"
#include <cctype>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

// LE MARQUAGE AUTOMATIQUE, et pourquoi il existe.
//
// mod-playerbots suit les icones de raid pour choisir ses cibles : la tete de
// mort d'abord. C'est le levier manuel prevu pour les cas que l'IA ne sait pas
// trancher seule.
//
// Or plusieurs fichiers d'action de la strategie naxx sont des coquilles vides
// - Faerlina, Noth, Gothik, Patchwerk ne contiennent qu'un commentaire
// "Reserved for ...-specific actions". Sur ces combats, les bots n'ont aucune
// priorite de cible, et sur Gothik c'est pire : il reste sur son balcon, donc
// l'IA generique envoie le tank chercher un chemin qui n'existe pas et il
// finit coince en l'air.
//
// Poser la tete de mort a la main regle tout ca. Ce script se contente de le
// faire a ta place, des que la creature entre dans ton champ de vision.
//
// UNE SEULE FOIS PAR CREATURE. Le script marque, puis n'y revient plus : si tu
// deplaces l'icone, il ne te la reprend pas. Une marque qu'on ne peut pas
// enlever serait pire que pas de marque du tout.

namespace
{
    // Les icones de raid de 3.3.5, dans l'ordre du client.
    //   0 etoile  1 cercle  2 diamant  3 triangle
    //   4 lune    5 carre   6 croix    7 tete de mort
    uint8 const ICONE_PAR_DEFAUT = 7;
    uint8 const DERNIERE_ICONE   = 7;

    // La portee de recherche. Au-dela, la creature n'est pas chargee pour le
    // client et l'icone n'aurait rien a designer.
    float constexpr PORTEE = 100.0f;

    std::unordered_map<uint32, uint8> cibles;  // entry -> icone
    bool charge = false;

    // Ce qu'on a deja marque, par groupe. Sert a ne poser l'icone qu'une fois
    // par creature : sans ca, le balayage la reposerait toutes les secondes et
    // tu ne pourrais plus jamais marquer autre chose.
    std::unordered_map<ObjectGuid, std::unordered_set<ObjectGuid>> dejaMarque;

    std::string Nettoyer(std::string texte)
    {
        size_t const debut = texte.find_first_not_of(" \t");
        if (debut == std::string::npos)
            return "";

        size_t const fin = texte.find_last_not_of(" \t");
        return texte.substr(debut, fin - debut + 1);
    }

    bool EstUnNombre(std::string const& texte)
    {
        if (texte.empty())
            return false;

        for (char const c : texte)
            if (!std::isdigit(static_cast<unsigned char>(c)))
                return false;

        return true;
    }

    void Charger()
    {
        charge = true;
        cibles.clear();
        dejaMarque.clear();

        std::string const reglage = sBisPriorityMgr->AutoMark();
        if (reglage.empty())
            return;

        // Separateur point-virgule et non espace : un nom de creature en
        // contient presque toujours un - "Gothik the Harvester".
        std::istringstream flux(reglage);
        std::string morceau;
        while (std::getline(flux, morceau, ';'))
        {
            morceau = Nettoyer(morceau);
            if (morceau.empty())
                continue;

            uint8 icone = ICONE_PAR_DEFAUT;

            // Suffixe ":n" facultatif. Cherche depuis la FIN : un nom peut
            // contenir un deux-points, le numero d'icone non.
            size_t const sep = morceau.rfind(':');
            if (sep != std::string::npos && EstUnNombre(Nettoyer(morceau.substr(sep + 1))))
            {
                int const demande = std::stoi(Nettoyer(morceau.substr(sep + 1)));
                if (demande < 0 || demande > DERNIERE_ICONE)
                {
                    LOG_ERROR("server.loading",
                              "[mod-playerbots-bis] AutoMark : icone {} hors de 0-7, entree ignoree",
                              demande);
                    continue;
                }

                icone = static_cast<uint8>(demande);
                morceau = Nettoyer(morceau.substr(0, sep));
            }

            if (morceau.empty())
                continue;

            // Un nombre est un identifiant de creature, le reste est un nom.
            if (EstUnNombre(morceau))
            {
                cibles[static_cast<uint32>(std::stoul(morceau))] = icone;
                continue;
            }

            // Resolution par nom. Plusieurs identifiants peuvent repondre - la
            // version 10, 25 et 40 d'un meme boss portent le meme nom - et
            // c'est voulu : on les marque toutes.
            std::string echappe;
            for (char const c : morceau)
            {
                if (c == '\'' || c == '\\')
                    echappe += '\\';
                echappe += c;
            }

            QueryResult res = WorldDatabase.Query(
                "SELECT `entry` FROM `creature_template` WHERE `name` = '{}'", echappe);
            if (!res)
            {
                LOG_ERROR("server.loading",
                          "[mod-playerbots-bis] AutoMark : aucune creature nommee \"{}\"",
                          morceau);
                continue;
            }

            do
            {
                cibles[res->Fetch()[0].Get<uint32>()] = icone;
            } while (res->NextRow());
        }

        LOG_INFO("server.loading", "[mod-playerbots-bis] AutoMark : {} creature(s) a marquer",
                 static_cast<uint32>(cibles.size()));
    }

    // Le marquage pour UN joueur reel, chef de son groupe.
    void Marquer(Player* player)
    {
        Group* group = player->GetGroup();
        if (!group || group->GetLeaderGUID() != player->GetGUID())
            return;

        std::unordered_set<ObjectGuid>& vus = dejaMarque[group->GetGUID()];

        for (auto const& paire : cibles)
        {
            Creature* creature = player->FindNearestCreature(paire.first, PORTEE);
            if (!creature)
                continue;

            // Deja marquee : on passe. C'est ce qui rend l'icone deplacable a
            // la main - le script ne la reprend jamais.
            if (!vus.insert(creature->GetGUID()).second)
                continue;

            group->SetTargetIcon(paire.second, player->GetGUID(), creature->GetGUID());

            LOG_INFO("server.loading", "[mod-playerbots-bis] AutoMark : {} marque {} (icone {})",
                     player->GetName(), creature->GetName(), static_cast<uint32>(paire.second));
        }
    }

}

class BisAutoMarkWorldScript : public WorldScript
{
public:
    BisAutoMarkWorldScript() : WorldScript("BisAutoMarkWorldScript") {}

    void OnUpdate(uint32 diff) override
    {
        // Eteint : une lecture de chaine et on sort.
        if (sBisPriorityMgr->AutoMark().empty())
            return;

        _depuis += diff;
        if (_depuis < INTERVALLE_MS)
            return;
        _depuis = 0;

        if (!charge)
            Charger();

        if (cibles.empty())
            return;

        for (auto const& paire : ObjectAccessor::GetPlayers())
        {
            Player* player = paire.second;

            // Un joueur REEL, et seulement en instance. Marquer dans le monde
            // ouvert poserait des icones sur tout ce qui passe, et un bot qui
            // mene son propre groupe n'a rien a decider pour toi.
            if (!player || !player->IsInWorld() || GET_PLAYERBOT_AI(player))
                continue;

            if (!player->GetMap() || !player->GetMap()->IsDungeon())
                continue;

            Marquer(player);
        }
    }

private:
    // Deux secondes. L'icone doit apparaitre quand tu entres dans la salle,
    // pas au bout d'une minute - et le balayage ne coute qu'une recherche de
    // creature par entree configuree, pour les seuls joueurs reels en instance.
    static constexpr uint32 INTERVALLE_MS = 2000;

    uint32 _depuis = 0;
};

void AddSC_playerbots_bis_automark()
{
    new BisAutoMarkWorldScript();
}
