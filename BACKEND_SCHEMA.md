# BACKEND SCHEMA — mod-playerbots-bis

> Tables MySQL dans la base `acore_world`, importées depuis `data/sql/db-world/base/`.

## 1. Vue d'ensemble

```
playerbots_bis_tier 1 ──── n playerbots_bis_item     (FK tier_id, ON DELETE CASCADE)
playerbots_bis_quest_token                           (jeton → pièce, par classe)
item_template (AzerothCore) ◄── résolution des objets par nom à l'import
```

## 2. `playerbots_bis_tier` — l'échelle

| Colonne | Type | Rôle |
|---|---|---|
| `tier_id` | SMALLINT UNSIGNED, PK | Ordre de progression, par pas de 10 (place pour des paliers intercalaires) |
| `expansion` | TINYINT | 0 = Vanilla, 1 = TBC, 2 = WotLK |
| `name` | VARCHAR(64) | Ex. « Vanilla Phase 2 - Blackwing Lair » |
| `required_progression` | TINYINT | État mod-individual-progression requis, 0 = jamais bloqué |

Paliers : 10 Vanilla Pre-Raid · 20 MC/Ony · 30 BWL · 40 ZG · 50 AQ20 · 60 AQ40 · 70 Naxx40 · TBC Pre-Raid · Karazhan · SSC/TK · Hyjal/BT · Sunwell · WotLK Pre-Raid · Naxx · Ulduar · ToC · ICC · Ruby Sanctum (18 au total).

## 3. `playerbots_bis_item` — les listes

| Colonne | Type | Rôle |
|---|---|---|
| `class` | TINYINT | Classe WoW |
| `spec` | TINYINT | Onglet de talents 0/1/2 ; **10 = druide ours** |
| `slot` | TINYINT | `EquipmentSlots` : head=0 neck=1 shoulders=2 chest=4 waist=5 legs=6 feet=7 wrists=8 hands=9 finger=10/11 trinket=12/13 back=14 mainhand=15 offhand=16 ranged=17 |
| `faction` | TINYINT | 0 = les deux, 1 = Alliance, 2 = Horde (une ligne de faction écrase la neutre) |
| `tier_id` | SMALLINT | FK → `playerbots_bis_tier` |
| `item_id` | INT | Objet |
| `rank` | TINYINT | 1 = meilleur, à palier et emplacement égaux |
| `comment` | VARCHAR(160) | Nom de l'objet, source |

PK (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`) ; index `idx_lookup` (`class`, `spec`, `faction`).

Anneaux et bijoux : une seule ligne suffit, le module compare avec les deux emplacements.

## 4. `playerbots_bis_quest_token`

| Colonne | Type | Rôle |
|---|---|---|
| `token_id` | INT, PK | Objet de quête tenu par le bot |
| `class` | TINYINT, PK | Classe du bot |
| `piece_id` | INT | Pièce que le jeton achète |
| `comment` | VARCHAR(120) | |

## 5. Ordre d'import

`01` (paliers) → `02` (items, FK) → listes par phase → `20_specs_partagees.sql` **après** les listes qu'il recopie → `17_purge_pvp_reputation.sql` **en dernier** (via `tools/importer_tout.ps1`).

## 6. Données client

`addon/PlayerbotsBisTooltip/BisData.lua` : export des tables par `tools/export_bis_tooltip.ps1`, copié dans le client par `install_addon.ps1`.

## 7. Couverture actuelle

- Palier 10 (Vanilla Pre-Raid) : complet, 28 spés.
- Paliers 20 et 30 : partiels ; 40 (ZG) en cours.
- Vides : AQ20 (50), WotLK Pre-Raid (130), Ruby Sanctum (180).
- TBC 100 à 120 : 15 à 16 combinaisons classe/spé sur 24.
