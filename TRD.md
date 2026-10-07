# TRD — mod-playerbots-bis

## 1. Environnement

| Élément | Détail |
|---|---|
| Serveur | AzerothCore (WotLK 3.3.5a), module chargé à la compilation |
| Dépendance | mod-playerbots, présent et activé |
| Optionnel | mod-individual-progression (aucune dépendance de compilation) |
| Langage | C++ (CMake via le système de modules d'AzerothCore) |
| Base | MySQL / MariaDB, base `acore_world` |
| Client | Addons Lua pour le client 3.3.5a |
| Outils | Python 3 (conversion, audit), PowerShell (import, export, diagnostic sous Windows) |

## 2. Principe d'intégration

Le moteur de mod-playerbots résout ses valeurs **par nom**, et `SharedNamedObjectContextList::Add()` *assigne* au lieu d'insérer : le dernier contexte enregistré pour un nom l'emporte. Le module enregistre ses propres valeurs `"item usage"` et `"item upgrade"` **au premier tick du monde**, après mod-playerbots et avant la connexion du moindre bot.

Ces valeurs délèguent d'abord aux valeurs d'origine, puis ne restreignent le verdict que pour les **armes et armures**. Le verdict est consulté à neuf endroits par mod-playerbots (roll, ramassage, récompense de quête, échange, achat, vente, comparaison sac/équipé…), ce qui évite de toucher à l'équipement lui-même.

## 3. Composants (`src/`)

| Fichier | Rôle |
|---|---|
| `mod_playerbots_bis_loader.cpp` | Point d'entrée du module |
| `BisPriorityModule.cpp` | Scripts monde (enregistrement au premier tick) et commandes `.playerbotsbis` |
| `BisPriorityMgr.{h,cpp}` | Chargement des tables, `GetItemPriority`, `WantsAsUpgrade`, `WouldReplace`, `HasReachableList`, `GetWornPriorityPaired`, jetons de quête |
| `BisItemUsageValue.{h,cpp}` | Surcharge de `"item usage"` / `"item upgrade"` |
| `BisLootRollAction.{h,cpp}` | Vote Greed sur les rolls à rétrograder, puis délègue à `LootRollAction::Execute()` |
| `BisMasterLootAnnounce.cpp` | Hook `OnPlayerBeforeSendLoot` : chuchotements au maître du butin |
| `BisEquipAction.{h,cpp}` | Équipement au balayage des sacs, annonces détaillées |
| `BisReport.{h,cpp}` | Relevés `report` / `missing` |
| `BisUnbind.{h,cpp}` | Commande `libere` |
| `BisInstanceReset.{h,cpp}` | Réinitialisation des instances au démarrage (option) |
| `BisActionContext.h`, `BisValueContext.h`, `BisBotScan.h` | Contextes nommés et balayage des bots |

## 4. Règles de décision

- **Priorité** : palier (`tier_id`) d'abord, `rank` ensuite. Un objet listé à plusieurs paliers garde toutes ses lignes ; on retient le palier le plus haut **atteignable** par le bot.
- **Anneaux et bijoux** : une seule ligne ; comparaison avec les deux emplacements, cible = le plus faible de la paire.
- **Équipabilité** vérifiée avant tout verdict ; l'exigence de niveau est traitée comme temporaire (`ClaimBelowRequiredLevel`).
- **Arme à deux mains** : la main gauche délogée est nommée dans l'annonce, seulement si elle a réellement quitté le créneau.
- **Spé sans liste atteignable** : logique d'origine intégrale.

## 5. Configuration (`conf/playerbots_bis.conf.dist`)

| Clé | Défaut | Rôle |
|---|---|---|
| `PlayerbotsBis.Enable` | 0 | Active le module |
| `ApplyToRandomBots` / `ApplyToAddClassBots` / `ApplyToAltBots` | 1 / 0 / 0 | Bots concernés |
| `LeaveOtherSpecsBis` | 1 | Laisser le BiS d'une autre spé |
| `AnnounceOwnBis`, `AnnounceOnRoll`, `AnnounceMasterLoot` | 1 | Annonces |
| `ClaimBelowRequiredLevel` | 1 | Revendiquer sous le niveau requis |
| `NeedOnlyForBis` | 0 | Need réservé au BiS |
| `ForceNeedForBis` | 1 | Forcer Need sur le BiS |
| `ClaimClassRestricted` | 1 | Revendiquer les pièces réservées à la classe |
| `MaxTier` | 0 | Plafond de palier (0 = aucun) |
| `UseIndividualProgression` | 0 | Paliers débloqués par personnage |
| `ProgressionCacheSeconds` | 300 | Cache de progression |
| `ResetInstancesOnStartup` | 0 | Réinitialiser les instances au démarrage |

Réglage côté mod-playerbots : `AiPlayerbot.LootNeedRollLevel = 2`, sinon tout Need est converti en Greed.

## 6. Données

Import automatique par le système de mises à jour d'AzerothCore (`data/sql/db-world/`, ordre alphabétique). Les listes récentes résolvent les objets **par nom** contre `item_template` : un nom erroné n'insère rien, et une requête de vérification liste les noms non résolus.

## 7. Qualité

- Démarrage : le worldserver affiche `Active`, `Dormant` ou `Tables unavailable`.
- `tools/audit_quetes.py` : contrôle de la règle « pas de PvP » sur les récompenses de quête.
- `tools/noms_absents.ps1` : noms absents de la base monde.
- `tools/diagnostic_addon.ps1` : vérifie la chaîne base → `BisData.lua` → client.
