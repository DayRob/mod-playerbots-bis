-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 1, spe 0,1, palier 70.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.
-- La jointure des noms est restreinte a AllowableClass : quatre objets
-- s'appellent "Atiesh, Greatstaff of the Guardian" et MIN(entry) seul
-- donnait le meme baton a toutes les listes, dont la plupart ne peuvent
-- pas l'equiper. Un nom qui ne resout plus ressort en VERIFICATION 1.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL,
    `entry`     INT UNSIGNED NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`, `entry`) VALUES
( 0, 1, 'Lionheart Helm', NULL),
( 0, 2, 'Southwind Helm', NULL),
( 0, 3, 'Crown of Destruction', NULL),
( 0, 4, 'Helm of Endless Rage', NULL),
( 0, 5, 'Conqueror''s Crown', NULL),
( 1, 1, 'Stormrage''s Talisman of Seething', NULL),
( 1, 2, 'Barbed Choker', NULL),
( 1, 3, 'The Eye of Hakkar', NULL),
( 1, 4, 'Fury of the Forgotten Swarm', NULL),
( 1, 5, 'Onyxia Tooth Pendant', NULL),
( 1, 6, 'Mark of Fordring', NULL),
( 2, 1, 'Mantle of Wicked Revenge', NULL),
( 2, 2, 'Conqueror''s Spaulders', NULL),
( 2, 3, 'Truestrike Shoulders', NULL),
( 2, 4, 'Drake Talon Pauldrons', NULL),
( 2, 5, 'Bloodsoaked Pauldrons', NULL),
(14, 1, 'Shroud of Dominion', NULL),
(14, 2, 'Puissant Cape', NULL),
(14, 3, 'Drape of Unyielding Strength', NULL),
(14, 4, 'Cloak of Concentrated Hatred', NULL),
(14, 5, 'Cloak of the Scourge', NULL),
(14, 6, 'Cloak of the Fallen God', NULL),
( 4, 1, 'Ghoul Skin Tunic', NULL),
( 4, 2, 'Plated Abomination Ribcage', NULL),
( 4, 3, 'Breastplate of Annihilation', NULL),
( 4, 4, 'Obsidian Mail Tunic', NULL),
( 4, 5, 'Conqueror''s Breastplate', NULL),
( 4, 6, 'Vest of Swift Execution', NULL),
( 8, 1, 'Wristguards of Vengeance', NULL),
( 8, 2, 'Qiraji Execution Bracers', NULL),
( 8, 3, 'Hive Defiler Wristguards', NULL),
( 8, 4, 'Bracers of Brutality', NULL),
( 8, 5, 'Wristguards of Stability', NULL),
( 8, 6, 'Deeprock Bracers', NULL),
( 9, 1, 'Gauntlets of Annihilation', NULL),
( 9, 2, 'Gloves of Enforcement', NULL),
( 9, 3, 'Edgemaster''s Handguards', NULL),
( 9, 4, 'Sacrificial Gauntlets', NULL),
( 9, 5, 'Flameguard Gauntlets', NULL),
( 5, 1, 'Girdle of the Mentor', NULL),
( 5, 2, 'Onslaught Girdle', NULL),
( 5, 3, 'Belt of Never-ending Agony', NULL),
( 5, 4, 'Triad Girdle', NULL),
( 5, 5, 'Therazane''s Link', NULL),
( 5, 6, 'Belt of Preserved Heads', NULL),
( 6, 1, 'Legplates of Carnage', NULL),
( 6, 2, 'Titanic Leggings', NULL),
( 6, 3, 'Conqueror''s Legguards', NULL),
( 6, 4, 'Scaled Sand Reaver Leggings', NULL),
( 6, 5, 'Leggings of Apocalypse', NULL),
( 7, 1, 'Chromatic Boots', NULL),
( 7, 2, 'Boots of the Shadow Flame', NULL),
( 7, 3, 'Boots of the Fallen Hero', NULL),
( 7, 4, 'Slime Kickers', NULL),
( 7, 5, 'Boots of the Vanguard', NULL),
( 7, 6, 'Boots of Heroism', NULL),
(10, 1, 'Band of Unnatural Forces', NULL),
(10, 2, 'Master Dragonslayer''s Ring', NULL),
(10, 3, 'Ring of the Qiraji Fury', NULL),
(10, 4, 'Quick Strike Ring', NULL),
(10, 5, 'Band of Accuria', NULL),
(12, 1, 'Kiss of the Spider', NULL),
(12, 2, 'Mark of the Champion', 23206),
(12, 3, 'Drake Fang Talisman', NULL),
(12, 4, 'Fetish of the Sand Reaver', NULL),
(12, 5, 'Slayer''s Crest', NULL),
(12, 6, 'Diamond Flask', NULL),
(15, 1, 'Gressil, Dawn of Ruin', NULL),
(15, 2, 'Hatchet of Sundered Bone', NULL),
(15, 3, 'Crul''shorukh, Edge of Chaos', NULL),
(15, 4, 'Blessed Qiraji War Axe', NULL),
(15, 5, 'Doom''s Edge', NULL),
(15, 6, 'Deathbringer', NULL),
(16, 1, 'The Hungering Cold', NULL),
(16, 2, 'Blessed Qiraji War Axe', NULL),
(16, 3, 'Crul''shorukh, Edge of Chaos', NULL),
(16, 4, 'Sickle of Unyielding Strength', NULL),
(16, 5, 'Doom''s Edge', NULL),
(16, 6, 'Deathbringer', NULL),
(15, 7, 'The Castigator', NULL),
(15, 8, 'Empyrean Demolisher', NULL),
(15, 9, 'Chromatically Tempered Sword', NULL),
(15, 10, 'Ravencrest''s Legacy', NULL),
(15, 11, 'Ancient Qiraji Ripper', NULL),
(16, 7, 'Maladath, Runed Blade of the Black Flight', NULL),
(16, 8, 'Chromatically Tempered Sword', NULL),
(16, 9, 'Ravencrest''s Legacy', NULL),
(16, 10, 'Ancient Qiraji Ripper', NULL),
(16, 11, 'Brutality Blade', NULL),
(17, 1, 'Nerubian Slavemaker', NULL),
(17, 2, 'Striker''s Mark', NULL),
(17, 3, 'Larvae of the Great Worm', NULL),
(17, 4, 'Crossbow of Imminent Doom', NULL),
(17, 5, 'Soulstring', NULL),
(17, 6, 'Gurubashi Dwarf Destroyer', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 0 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 0, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 1) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 1 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 1, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 1) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 1) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` IN (0,1) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
