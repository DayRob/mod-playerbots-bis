-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 1, spe 2, palier 70.
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
( 0, 1, 'Conqueror''s Crown', NULL),
( 0, 2, 'Helm of Endless Rage', NULL),
( 0, 3, 'Lionheart Helm', NULL),
( 0, 4, 'Southwind Helm', NULL),
( 0, 5, 'Crown of Destruction', NULL),
( 0, 6, 'Helm of Wrath', NULL),
( 1, 1, 'Stormrage''s Talisman of Seething', NULL),
( 1, 2, 'Onyxia Tooth Pendant', NULL),
( 1, 3, 'Fury of the Forgotten Swarm', NULL),
( 1, 4, 'Barbed Choker', NULL),
( 1, 5, 'The Eye of Hakkar', NULL),
( 1, 6, 'Prestor''s Talisman of Connivery', NULL),
( 2, 1, 'Conqueror''s Spaulders', NULL),
( 2, 2, 'Dreadnaught Pauldrons', NULL),
( 2, 3, 'Drake Talon Pauldrons', NULL),
( 2, 4, 'Pauldrons of Wrath', NULL),
( 2, 5, 'Pauldrons of Might', NULL),
( 2, 6, 'Spaulders of Valor', NULL),
(14, 1, 'Cloak of the Fallen God', NULL),
(14, 2, 'Puissant Cape', NULL),
(14, 3, 'Drape of Unyielding Strength', NULL),
(14, 4, 'Cloak of Concentrated Hatred', NULL),
(14, 5, 'Shroud of Dominion', NULL),
(14, 6, 'Cloak of Firemaw', NULL),
( 4, 1, 'Conqueror''s Breastplate', NULL),
( 4, 2, 'Dreadnaught Breastplate', NULL),
( 4, 3, 'plated Abomination Ribcage', NULL),
( 4, 4, 'Breastplate of Annihilation', NULL),
( 4, 5, 'Savage Gladiator Chain', NULL),
( 4, 6, 'Breastplate of Heroism', NULL),
( 8, 1, 'Wristguards of Vengeance', NULL),
( 8, 2, 'Hive Defiler Wristguards', NULL),
( 8, 3, 'Bracers of Brutality', NULL),
( 8, 4, 'Deeprock Bracers', NULL),
( 8, 5, 'Zandalar Vindicator''s Armguards', NULL),
( 9, 1, 'Gauntlets of Annihilation', NULL),
( 9, 2, 'Aged Core Leather Gloves', NULL),
( 9, 3, 'Edgemaster''s Handguards', NULL),
( 9, 4, 'Gauntlets of Might', NULL),
( 9, 5, 'Flameguard Gauntlets', NULL),
( 9, 6, 'Sacrificial Gauntlets', NULL),
( 5, 1, 'Girdle of the Mentor', NULL),
( 5, 2, 'Onslaught Girdle', NULL),
( 5, 3, 'Zandalar Vindicator''s Belt', NULL),
( 5, 4, 'Triad Girdle', NULL),
( 5, 5, 'Therazane''s Link', NULL),
( 5, 6, 'Brigam Girdle', NULL),
( 6, 1, 'Conqueror''s Legguards', NULL),
( 6, 2, 'Titanic Leggings', NULL),
( 6, 3, 'Legplates of Carnage', NULL),
( 6, 4, 'Legplates of the Qiraji Command', NULL),
( 6, 5, 'Legguards of the Fallen Crusader', NULL),
( 7, 1, 'Chromatic Boots', NULL),
( 7, 2, 'Boots of the Fallen Hero', NULL),
( 7, 3, 'Slime Kickers', NULL),
( 7, 4, 'Boots of Heroism', NULL),
( 7, 5, 'Conqueror''s Greaves', NULL),
( 7, 6, 'Sabatons of Might', NULL),
(10, 1, 'Band of Unnatural Forces', NULL),
(10, 2, 'Band of Accuria', NULL),
(10, 3, 'Master Dragonslayer''s Ring', NULL),
(10, 4, 'Circle of Applied Force', NULL),
(10, 5, 'Ring of the Godslayer', NULL),
(12, 1, 'Kiss of the Spider', NULL),
(12, 2, 'Mark of the Champion', 23206),
(12, 3, 'Diamond Flask', NULL),
(12, 4, 'Earthstrike', NULL),
(12, 5, 'Drake Fang Talisman', NULL),
(12, 6, 'Hand of Justice', NULL),
(16, 1, 'The Face of Death', NULL),
(16, 2, 'The Plague Bearer', NULL),
(16, 3, 'Elementium Reinforced Bulwark', NULL),
(16, 4, 'Blessed Qiraji Bulwark', NULL),
(16, 5, 'Buru''s Skull Fragment', NULL),
(16, 6, 'Aegis of the Blood God', NULL),
(15, 1, 'Thunderfury, Blessed Blade of the Windseeker', NULL),
(15, 2, 'Crul''shorukh, Edge of Chaos', NULL),
(15, 3, 'Blessed Qiraji War Axe', NULL),
(15, 4, 'Chromatically Tempered Sword', NULL),
(15, 5, 'Warblade of the Hakkari', 19865),
(15, 6, 'Death''s Sting', NULL),
(15, 7, 'Gressil, Dawn of Ruin', NULL),
(15, 8, 'Ancient Qiraji Ripper', NULL),
(15, 9, 'Ravencrest''s Legacy', NULL),
(15, 10, 'Maladath, Runed Blade of the Black Flight', NULL),
(17, 1, 'Nerubian Slavemaker', NULL),
(17, 2, 'Crossbow of Imminent Doom', NULL),
(17, 3, 'Striker''s Mark', NULL),
(17, 4, 'Soulstring', NULL),
(17, 5, 'Larvae of the Great Worm', NULL),
(17, 6, 'Fahrad''s Reloading Repeater', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 2 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 2, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 1 AND `spec` IN (2) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
