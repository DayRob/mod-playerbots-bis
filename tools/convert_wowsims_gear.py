#!/usr/bin/env python3
"""Convertit les sets d'equipement de WoWSims Classic en lignes playerbots_bis_item.

    python3 tools/convert_wowsims_gear.py /chemin/vers/wowsims-classic 30 \
        > data/sql/db-world/base/18_bwl_wowsims.sql

Source : https://github.com/wowsims/classic (licence MIT). Le projet demande un
lien visible vers l'original dans tout travail qui reutilise ses donnees : il
figure dans l'en-tete de chaque fichier genere et dans le README.

LA NUMEROTATION DES PHASES N'EST PAS LA NOTRE
---------------------------------------------
WoWSims suit le calendrier de sortie de Classic 2019, pas le decoupage par raid :

    phase_1 / p1  -> Molten Core + Onyxia      -> notre palier 20
    phase_2 / p2  -> Dire Maul (meme palier d'objets que MC)
    phase_3 / p3  -> BLACKWING LAIR            -> notre palier 30
    phase_4 / p4  -> Zul'Gurub / AQ20
    phase_5 / p5  -> Ahn'Qiraj 40              -> notre palier 60
    phase_6 / p6  -> Naxxramas 40              -> notre palier 70

Verifie par le contenu : phase_2 du guerrier contient Don Julio's Band (Dire
Maul), phase_3 contient Cloak of Draconic Might et Chromatically Tempered Sword
(Blackwing Lair). Mapper phase_2 sur BWL donnerait du stuff de Dire Maul.

CE QUE CES SETS NE SONT PAS
---------------------------
Un set de simulateur donne UN objet par emplacement, pas une liste classee. Tout
sort donc en rang 1, sans repli - contrairement aux fichiers ecrits depuis les
guides Wowhead, qui portent des alternatives.

Le PvP present dans les sets d'origine est ecarte a la generation (PVP_ITEMS).
La reputation, elle, demande npc_vendor et item_template, donc la base monde :
c'est le role du fichier 17, a rejouer apres celui-ci. Il est idempotent.
"""
import json
import os
import sys

# L'ordre du tableau "items" d'un set est celui du personnage a l'ecran. On le
# traduit vers l'enumeration EquipmentSlots d'AzerothCore.
SLOT_ORDER = [0, 1, 2, 14, 4, 8, 9, 5, 6, 7, 10, 11, 12, 13, 15, 16, 17]

# Les anneaux et les bijoux n'occupent qu'un emplacement dans nos tables : le
# module apparie lui-meme le second. Le premier prend le rang 1, le second le
# rang 2 - ils se valent, mais deux rangs 1 dans un meme creneau n'auraient plus
# de sens pour qui lit la liste.
PAIRED = {11: (10, 2), 13: (12, 2)}

# Repertoire wowsims -> (classe, [specs], rang de depart)
#
# Un repertoire couvrant plusieurs onglets de talents produit la meme liste pour
# chacun : c'est le cas du chasseur, du mage et du demoniste, dont WoWSims ne
# publie qu'un set par phase.
SPECS = {
    "warrior":            (1,  [0, 1]),    # Armes et Fureur partagent le set DPS
    "tank_warrior":       (1,  [2]),
    "hunter":             (3,  [0, 1, 2]),
    "shadow_priest":      (5,  [2]),
    "elemental_shaman":   (7,  [0]),
    "enhancement_shaman": (7,  [1]),
    "mage":               (8,  [0, 1, 2]),
    "warlock":            (9,  [0, 1, 2]),
    "balance_druid":      (11, [0]),
    "feral_druid":        (11, [1]),
}

# Notre palier -> les noms de fichiers possibles, dans l'ordre de preference.
# Plusieurs fichiers peuvent decrire la MEME epoque d'objets : phase_1 est Molten
# Core, phase_2 y ajoute Dire Maul sans changer de palier. On prend le plus
# complet des deux - Dire Maul est un donjon, rien dans la regle du projet ne
# l'exclut, et un set de 17 pieces vaut mieux qu'un set de 8.
#
# Le palier 30 ne prend PAS phase_2 : ce serait du Dire Maul etiquete Blackwing
# Lair.
TIER_FILES = {
    10: ["p0.bis.gear.json", "prebis.gear.json"],
    20: ["phase_1.gear.json", "phase_2.gear.json",
         "p1.bis.gear.json", "p2.bis.gear.json", "mc.gear.json"],
    30: ["phase_3.gear.json", "p3.bis.gear.json"],
    60: ["phase_5.gear.json", "p5.bis.gear.json"],
    70: ["phase_6.gear.json", "p6.bis.gear.json"],
}

# En dessous, le set n'est pas une liste d'equipement : c'est le set de raid de
# la classe et rien d'autre. Le reprendre effacerait, pour les creneaux qu'il ne
# couvre pas, ce que la conversion d'origine fournit deja. On laisse la spe
# tranquille jusqu'a ce qu'un guide arrive.
MIN_SLOTS = 12

# Les sets de WoWSims contiennent du PvP : le simulateur optimise les
# statistiques et se moque de la provenance. La regle du projet l'exclut, alors
# on l'ecarte ICI plutot que de laisser le fichier 17 l'arracher apres coup -
# sinon MIN_SLOTS serait calcule sur une liste qui perd ensuite des pieces, et
# une spe pourrait passer le seuil pour finir a neuf creneaux.
#
# Obtenue en croisant TOUS les sets du depot avec item_template : les seuls
# objets dont le nom commence par un titre de rang PvP de Vanilla.
PVP_ITEMS = {
    22852,  # Blood Guard's Dragonhide Treads
    23258,  # Champion's Leather Shoulders
    16555,  # General's Dragonhide Gloves
    16552,  # General's Dragonhide Leggings
    16543,  # General's Plate Leggings
    23451,  # Grand Marshal's Mageblade
    23298,  # Knight-Captain's Leather Chestpiece
    22877,  # Legionnaire's Dragonhide Chestpiece
    22879,  # Legionnaire's Leather Chestpiece
    23313,  # Lieutenant Commander's Leather Shoulders
    16551,  # Warlord's Dragonhide Epaulets
    16549,  # Warlord's Dragonhide Hauberk
    16580,  # Warlord's Mail Spaulders
    16544,  # Warlord's Plate Shoulders
}

# Les combinaisons deja ecrites A LA MAIN depuis un guide Wowhead. Un set de
# simulateur ne doit pas les remplacer : il ne donne qu'un objet par emplacement,
# la ou un guide classe des alternatives. On les saute, et on le dit.
CURATED = {
    20: {(1, 0), (1, 1),                        # fichier 05, guerrier Armes/Fureur
         (4, 0), (4, 1), (4, 2),                # fichier 05, voleur
         (5, 0), (5, 1),                        # fichier 05, pretre Discipline/Sacre
         (8, 0), (8, 1), (8, 2),                # fichier 16, mage
         (11, 2)},                              # fichier 15, druide Restauration
    10: set(),   # le pre-raid est deja couvert par les fichiers 03 a 13
    30: set(),
    60: set(),
    70: set(),
}

TIER_NAMES = {
    10: "Vanilla Pre-Raid",
    20: "Vanilla Phase 1 - Molten Core / Onyxia",
    30: "Vanilla Phase 2 - Blackwing Lair",
    60: "Vanilla Phase 5 - Ahn Qiraj 40",
    70: "Vanilla Phase 6 - Naxxramas 40",
}


def read_set(path):
    """Renvoie [(slot, item_id, rank)] pour un set, ou [] si le fichier est vide."""
    with open(path, encoding="utf-8") as fh:
        items = json.load(fh).get("items", [])

    out = []
    for i, entry in enumerate(items):
        if i >= len(SLOT_ORDER):
            break
        if not isinstance(entry, dict) or "id" not in entry:
            continue          # emplacement laisse vide par le set
        if int(entry["id"]) in PVP_ITEMS:
            continue          # regle du projet : pas de PvP

        slot = SLOT_ORDER[i]
        rank = 1
        if slot in PAIRED:
            slot, rank = PAIRED[slot]
        out.append((slot, int(entry["id"]), rank))
    return out


def main(root, tier):
    tier = int(tier)
    if tier not in TIER_FILES:
        sys.exit("palier %d non gere - ajoute-le a TIER_FILES" % tier)

    rows, covered, missing, curated, partial = [], [], [], [], []

    for spec_dir in sorted(SPECS):
        cls, specs = SPECS[spec_dir]
        gear_dir = os.path.join(root, "ui", spec_dir, "gear_sets")

        # Le plus complet des candidats de cette epoque, pas le premier venu.
        chosen, pieces = None, []
        for candidate in TIER_FILES[tier]:
            path = os.path.join(gear_dir, candidate)
            if not os.path.exists(path):
                continue
            found = read_set(path)
            if len(found) > len(pieces):
                chosen, pieces = path, found

        if not chosen or not pieces:
            missing.append(spec_dir)
            continue

        slots = len({slot for slot, _, _ in pieces})
        if slots < MIN_SLOTS:
            partial.append("%s : %d creneaux seulement (%s)"
                           % (spec_dir, slots, os.path.basename(chosen)))
            continue

        keep = [sp for sp in specs if (cls, sp) not in CURATED[tier]]
        skipped = [sp for sp in specs if (cls, sp) in CURATED[tier]]

        if skipped:
            curated.append("classe %d spe %s (%s)"
                           % (cls, ",".join(map(str, skipped)), spec_dir))
        if not keep:
            continue

        covered.append("%s -> classe %d spe %s, %s"
                       % (spec_dir, cls, ",".join(map(str, keep)),
                          os.path.basename(chosen)))
        for spec in keep:
            for slot, item_id, rank in pieces:
                rows.append((cls, spec, slot, item_id, rank))

    if not rows:
        sys.exit("aucun set trouve pour le palier %d" % tier)

    # Deux anneaux peuvent tomber sur le meme creneau avec le meme rang si le set
    # en repete un : on garde la premiere occurrence.
    seen, unique = set(), []
    for row in rows:
        key = (row[0], row[1], row[2], row[3])
        if key in seen:
            continue
        seen.add(key)
        unique.append(row)

    by_class = {}
    for cls, spec, _, _, _ in unique:
        by_class.setdefault(cls, set()).add(spec)

    out = sys.stdout.write
    out("-- mod-playerbots-bis : palier %d (%s), sets de simulateur.\n--\n"
        % (tier, TIER_NAMES[tier]))
    out("-- GENERE par tools/convert_wowsims_gear.py - ne pas editer a la main.\n")
    out("--\n-- SOURCE : WoWSims Classic, https://github.com/wowsims/classic\n")
    out("--          (licence MIT ; le projet demande ce lien visible).\n--\n")
    out("-- Un set de simulateur donne UN objet par emplacement, pas une liste\n")
    out("-- classee : tout sort en rang 1, sans repli. Les anneaux et les bijoux\n")
    out("-- font exception - le second de la paire prend le rang 2, puisque le\n")
    out("-- module apparie lui-meme les deux emplacements.\n--\n")
    out("-- Le PvP des sets d'origine est ecarte a la generation. La reputation\n")
    out("-- demande la base monde : rejoue le fichier 17 apres celui-ci.\n--\n")
    out("-- Couvert par ce fichier :\n")
    for line in covered:
        out("--   %s\n" % line)
    if curated:
        out("--\n-- Laisse aux fichiers ecrits a la main, qui classent des alternatives\n")
        out("-- la ou un set de simulateur n'offre qu'un objet par emplacement :\n")
        for name in curated:
            out("--   %s\n" % name)
    if partial:
        out("--\n-- Set trop partiel pour remplacer l'existant - c'est le set de raid de\n")
        out("-- la classe, pas une liste d'equipement. Laisse tel quel :\n")
        for name in partial:
            out("--   %s\n" % name)
    if missing:
        out("--\n-- Sans set a ce palier chez WoWSims (donc inchange ici) :\n")
        for name in missing:
            out("--   %s\n" % name)
    out("\n")

    for cls in sorted(by_class):
        specs = sorted(by_class[cls])
        clause = ("`spec` = %d" % specs[0] if len(specs) == 1
                  else "`spec` IN (%s)" % ", ".join(map(str, specs)))
        out("DELETE FROM `playerbots_bis_item` WHERE `tier_id` = %d AND `class` = %d AND %s;\n"
            % (tier, cls, clause))

    out("\nDROP TEMPORARY TABLE IF EXISTS `bis_seed_wowsims`;\n")
    out("CREATE TEMPORARY TABLE `bis_seed_wowsims` (\n"
        "    `class`   TINYINT UNSIGNED NOT NULL,\n"
        "    `spec`    TINYINT UNSIGNED NOT NULL,\n"
        "    `slot`    TINYINT UNSIGNED NOT NULL,\n"
        "    `item_id` INT UNSIGNED NOT NULL,\n"
        "    `rank`    TINYINT UNSIGNED NOT NULL\n"
        ") ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;\n\n")

    out("INSERT INTO `bis_seed_wowsims` (`class`, `spec`, `slot`, `item_id`, `rank`) VALUES\n")
    out(",\n".join("(%d, %d, %d, %d, %d)" % row for row in unique))
    out(";\n\n")

    out("INSERT IGNORE INTO `playerbots_bis_item`\n"
        "    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)\n"
        "SELECT s.`class`, s.`spec`, s.`slot`, 0, %d, s.`item_id`, s.`rank`,\n"
        "       CONCAT('%s (wowsims) - ', it.`name`)\n"
        "FROM `bis_seed_wowsims` s\n"
        "JOIN `item_template` it ON it.`entry` = s.`item_id`;\n\n"
        % (tier, TIER_NAMES[tier]))

    out("-- ---------------------------------------------------------------------\n"
        "-- VERIFICATION 1 - identifiants absents de ta base (aucune ligne = bon).\n"
        "-- ---------------------------------------------------------------------\n"
        "SELECT s.`class`, s.`spec`, s.`slot`, s.`item_id` AS id_introuvable\n"
        "FROM `bis_seed_wowsims` s\n"
        "LEFT JOIN `item_template` it ON it.`entry` = s.`item_id`\n"
        "WHERE it.`entry` IS NULL;\n\n")

    out("-- ---------------------------------------------------------------------\n"
        "-- VERIFICATION 2 - creneaux couverts par spe a ce palier.\n"
        "-- ---------------------------------------------------------------------\n"
        "SELECT `class`, `spec`, COUNT(DISTINCT `slot`) AS creneaux, COUNT(*) AS lignes\n"
        "FROM `playerbots_bis_item` WHERE `tier_id` = %d\n"
        "GROUP BY `class`, `spec` ORDER BY `class`, `spec`;\n\n"
        "DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowsims`;\n" % tier)

    sys.stderr.write("palier %d : %d lignes, %d spes couvertes\n"
                     % (tier, len(unique), sum(len(s) for s in by_class.values())))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
