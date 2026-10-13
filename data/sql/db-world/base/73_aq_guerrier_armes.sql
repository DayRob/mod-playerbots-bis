-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P5 AQ (wowtbc.gg), page Fury sans ses armes. Classe 1, spe 0, palier 60.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

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
( 0, 3, 'Helm of Endless Rage', NULL),
( 0, 3, 'Conqueror''s Crown', NULL),
( 1, 1, 'Barbed Choker', NULL),
( 1, 2, 'The Eye of Hakkar', NULL),
( 1, 3, 'Fury of the Forgotten Swarm', NULL),
( 1, 3, 'Onyxia Tooth Pendant', NULL),
( 1, 3, 'Mark of Fordring', NULL),
( 2, 1, 'Conqueror''s Spaulders', NULL),
( 2, 2, 'Truestrike Shoulders', NULL),
( 2, 3, 'Mantle of Wicked Revenge', NULL),
( 2, 3, 'Drake Talon Pauldrons', NULL),
( 2, 3, 'Bloodsoaked Pauldrons', NULL),
(14, 1, 'Cloak of the Fallen God', NULL),
(14, 2, 'Puissant Cape', NULL),
(14, 3, 'Drape of Unyielding Strength', NULL),
(14, 3, 'Cloak of Concentrated Hatred', NULL),
(14, 3, 'Cloak of Draconic Might', NULL),
(14, 3, 'Cloak of Firemaw', NULL),
( 4, 1, 'Breastplate of Annihilation', NULL),
( 4, 2, 'Obsidian Mail Tunic', NULL),
( 4, 3, 'Conqueror''s Breastplate', NULL),
( 4, 3, 'Vest of Swift Execution', NULL),
( 4, 3, 'Savage Gladiator Chain', NULL),
( 4, 3, 'Malfurion''s Blessed Bulwark', NULL),
( 8, 1, 'Qiraji Execution Bracers', NULL),
( 8, 2, 'Hive Defiler Wristguards', NULL),
( 8, 3, 'Bracers of Brutality', NULL),
( 8, 3, 'Wristguards of Stability', NULL),
( 8, 3, 'Deeprock Bracers', NULL),
( 9, 1, 'Gauntlets of Annihilation', NULL),
( 9, 2, 'Gloves of Enforcement', NULL),
( 9, 3, 'Edgemaster''s Handguards', NULL),
( 9, 3, 'Sacrificial Gauntlets', NULL),
( 9, 3, 'Flameguard Gauntlets', NULL),
( 5, 1, 'Onslaught Girdle', NULL),
( 5, 2, 'Belt of Never-ending Agony', NULL),
( 5, 3, 'Triad Girdle', NULL),
( 5, 3, 'Therazane''s Link', NULL),
( 5, 3, 'Belt of Preserved Heads', NULL),
( 5, 3, 'Taut Dragonhide Belt', NULL),
( 6, 1, 'Conqueror''s Legguards', NULL),
( 6, 2, 'Titanic Leggings', NULL),
( 6, 3, 'Scaled Sand Reaver Leggings', NULL),
( 6, 3, 'Dark Heart Pants', NULL),
( 6, 3, 'Legplates of the Qiraji Command', NULL),
( 7, 1, 'Chromatic Boots', NULL),
( 7, 2, 'Boots of the Shadow Flame', NULL),
( 7, 3, 'Boots of the Fallen Hero', NULL),
( 7, 3, 'Slime Kickers', NULL),
( 7, 3, 'Boots of the Vanguard', NULL),
( 7, 3, 'Boots of Heroism', NULL),
(10, 1, 'Ring of the Qiraji Fury', NULL),
(10, 2, 'Master Dragonslayer''s Ring', NULL),
(10, 3, 'Quick Strike Ring', NULL),
(10, 3, 'Band of Accuria', NULL),
(10, 3, 'Band of Earthen Might', NULL),
(12, 1, 'Drake Fang Talisman', NULL),
(12, 2, 'Fetish of the Sand Reaver', NULL),
(12, 3, 'Diamond Flask', NULL),
(12, 3, 'Jom Gabbar', NULL),
(12, 3, 'Earthstrike', NULL),
(12, 3, 'Hand of Justice', NULL),
(17, 1, 'Larvae of the Great Worm', NULL),
(17, 2, 'Striker''s Mark', NULL),
(17, 3, 'Crossbow of Imminent Doom', NULL),
(17, 3, 'Gurubashi Dwarf Destroyer', NULL),
(17, 3, 'Heartstriker', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 0 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 0, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` IN (0) AND `tier_id` = 60
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
