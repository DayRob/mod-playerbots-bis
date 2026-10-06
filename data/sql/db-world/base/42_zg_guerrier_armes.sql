-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P4 ZG (wowtbc.gg). Classe 1, spe 0, palier 40.
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
( 0, 2, 'Crown of Destruction', NULL),
( 0, 3, 'Helm of Endless Rage', NULL),
( 0, 3, 'Eye of Rend', NULL),
( 0, 3, 'Gurubashi Helm', NULL),
( 1, 1, 'The Eye of Hakkar', NULL),
( 1, 2, 'Onyxia Tooth Pendant', NULL),
( 1, 3, 'Mark of Fordring', NULL),
( 1, 3, 'Imperial Jewel', NULL),
( 1, 3, 'Will of the Martyr', NULL),
( 2, 1, 'Drake Talon Pauldrons', NULL),
( 2, 2, 'Truestrike Shoulders', NULL),
( 2, 3, 'Bloodsoaked Pauldrons', NULL),
( 2, 3, 'Black Dragonscale Shoulders', NULL),
(14, 1, 'Cloak of Draconic Might', NULL),
(14, 2, 'Puissant Cape', NULL),
(14, 3, 'Cloak of Firemaw', NULL),
(14, 3, 'Cape of the Black Baron', NULL),
(14, 3, 'Zulian Tigerhide Cloak', NULL),
( 4, 1, 'Savage Gladiator Chain', NULL),
( 4, 2, 'Malfurion''s Blessed Bulwark', NULL),
( 4, 3, 'Cadaverous Armor', NULL),
( 4, 3, 'Runed Bloodstained Hauberk', NULL),
( 4, 3, 'Breastplate of Bloodthirst', NULL),
( 4, 3, 'Tombstone Breastplate', NULL),
( 8, 1, 'Wristguards of Stability', NULL),
( 8, 2, 'Battleborn Armbraces', NULL),
( 8, 3, 'Zandalar Vindicator''s Armguards', NULL),
( 8, 3, 'Wristguards of True Flight', NULL),
( 9, 1, 'Flameguard Gauntlets', NULL),
( 9, 2, 'Edgemaster''s Handguards', NULL),
( 9, 3, 'Sacrificial Gauntlets', NULL),
( 9, 3, 'Chromatic Gauntlets', NULL),
( 9, 3, 'Gauntlets of Might', NULL),
( 9, 3, 'Doomhide Gauntlets', NULL),
( 5, 1, 'Onslaught Girdle', NULL),
( 5, 2, 'Therazane''s Link', NULL),
( 5, 3, 'Belt of Preserved Heads', NULL),
( 5, 3, 'Taut Dragonhide Belt', NULL),
( 5, 3, 'Belt of Shrunken Heads', NULL),
( 6, 1, 'Legguards of the Fallen Crusader', NULL),
( 6, 2, 'Dark Heart Pants', NULL),
( 6, 3, 'Bloodsoaked Legplates', NULL),
( 6, 3, 'Devilsaur Leggings', NULL),
( 6, 3, 'Cloudkeeper Legplates', NULL),
( 7, 1, 'Chromatic Boots', NULL),
( 7, 2, 'Boots of the Shadow Flame', NULL),
( 7, 3, 'Boots of Heroism', NULL),
( 7, 3, 'Bloodmail Boots', NULL),
( 7, 3, 'Battlechaser''s Greaves', NULL),
(10, 1, 'Master Dragonslayer''s Ring', NULL),
(10, 2, 'Quick Strike Ring', NULL),
(10, 3, 'Band of Accuria', NULL),
(10, 3, 'Circle of Applied Force', NULL),
(10, 3, 'Blackstone Ring', NULL),
(12, 1, 'Drake Fang Talisman', NULL),
(12, 2, 'Diamond Flask', NULL),
(12, 3, 'Hand of Justice', NULL),
(12, 3, 'Blackhand''s Breadth', NULL),
(12, 3, 'Rune of the Guard Captain', NULL),
(12, 3, 'Counterattack Lodestone', NULL),
(17, 1, 'Striker''s Mark', NULL),
(17, 2, 'Gurubashi Dwarf Destroyer', NULL),
(17, 3, 'Heartstriker', NULL),
(17, 3, 'Blackcrow', NULL),
(17, 3, 'Satyr''s Bow', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 0 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 0, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('Vanilla P4 ZG (wowtbc.gg) - ', s.`item_name`)
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
WHERE `class` = 1 AND `spec` IN (0) AND `tier_id` = 40
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
