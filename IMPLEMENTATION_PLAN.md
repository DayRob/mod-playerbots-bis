# IMPLEMENTATION PLAN — mod-playerbots-bis

## Phases

| # | Phase | Contenu | Statut |
|---|---|---|---|
| 1 | Moteur | Surcharge de `item usage` / `item upgrade`, `BisPriorityMgr`, échelle de paliers | ✅ Fait |
| 2 | Données de base | Conversion de `playerbots_bis_gear`, palier 10 complet (Wowhead + WoWSims) | ✅ Fait |
| 3 | Butin | Need réservé au BiS, BiS des autres spés laissé, butin de maître | ✅ Fait |
| 4 | Robustesse | Protection des pièces listées, anneaux/bijoux appariés, objets multi-paliers, niveau requis | ✅ Fait |
| 5 | Annonces | Revendication, équipement, pièce remplacée, arme à deux mains | ✅ Fait |
| 6 | Outillage & addons | Import ordonné, audit PvP, noms absents, infobulle, navigateur, compositions, recensement | ✅ Fait |
| 7 | Phase 1-2 Vanilla | Listes MC/Ony et BWL par spé (fichiers 05 à 39) | 🔄 Partiel |
| 8 | Zul'Gurub | Listes par spé et jetons Hakkari (fichiers 40 à 56) | 🔄 En cours |
| 9 | AQ20 / AQ40 / Naxx40 | Paliers 50 à 70 | ⏳ À faire |
| 10 | TBC | Compléter les paliers 100 à 120 (spés manquantes) | ⏳ |
| 11 | WotLK | Pre-Raid (130) et Ruby Sanctum (180) | ⏳ |
| 12 | Qualité | Tests automatisés de `BisPriorityMgr`, CI de compilation | ⏳ |

## Lacunes de données prioritaires

- Palier 20 : Voleur Assassinat, Voleur Subtilité, Prêtre Discipline sans ligne ; 22 spés encore issues de la conversion sans guide.
- Listes WoWSims sans alternative au palier 10 (Mage ×3, Démoniste ×3, Prêtre Ombre).
- Paladin Protection sans libram au palier 10.

## Procédure pour ajouter une liste

1. Copier la page source dans `data/pages/` (indispensable pour régénérer plus tard).
2. Convertir avec `tools/convert_wowtbc_bis.py` (ou `convert_wowsims_gear.py`).
3. Vérifier le SQL généré : objets résolus **par nom**, requête de vérification en fin de fichier.
4. Importer (`tools/importer_tout.ps1`), puis `tools/noms_absents.ps1`.
5. `python3 tools/audit_quetes.py` pour la règle « pas de PvP ».
6. Réexporter l'addon et relancer le client.

## Passage à la phase suivante

Voir `tools/changer_de_phase.md` : mise à jour du code, `MaxTier`, rebuild (*Clean Full Build* si des fichiers C++ ont été ajoutés ou retirés), import, `.playerbotsbis reload`.
