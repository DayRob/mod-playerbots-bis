-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P3 BWL (wowtbc.gg). Classe 11, spe 1, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Wolfshead Helm'),
( 0, 2, 'Mask of the Unforgiven'),
( 0, 3, 'Eye of Rend'),
( 0, 3, 'Shadowcraft Cap'),
( 0, 3, 'Ghostshroud'),
( 1, 1, 'Prestor''s Talisman of Connivery'),
( 1, 2, 'Onyxia Tooth Pendant'),
( 1, 3, 'Beads of Ogre Might'),
( 1, 3, 'Mark of Fordring'),
( 1, 3, 'Skibi''s Pendant'),
( 2, 1, 'Wyrmtongue Shoulders'),
( 2, 2, 'Truestrike Shoulders'),
( 2, 3, 'Flamescarred Shoulders'),
( 2, 3, 'Wyrmhide Spaulders'),
(14, 1, 'Cloak of Draconic Might'),
(14, 2, 'Puissant Cape'),
(14, 3, 'Cloak of the Shrouded Mists'),
(14, 3, 'Cape of the Black Baron'),
(14, 3, 'Blackveil Cape'),
(14, 3, 'Shifting Cloak'),
( 4, 1, 'Malfurion''s Blessed Bulwark'),
( 4, 2, 'Cadaverous Armor'),
( 4, 3, 'Breastplate of Bloodthirst'),
( 4, 3, 'Grizzled Pelt'),
( 8, 1, 'Wristguards of Stability'),
( 8, 2, 'Deepfury Bracers'),
( 8, 3, 'Bracers of the Eclipse'),
( 8, 3, 'Blackmist Armguards'),
( 9, 1, 'Devilsaur Gauntlets'),
( 9, 2, 'Doomhide Gauntlets'),
( 9, 3, 'Gargoyle Slashers'),
( 9, 3, 'Gloves of the Pathfinder'),
( 9, 3, 'Aged Core Leather Gloves'),
( 5, 1, 'Cloudrunner Girdle'),
( 5, 2, 'Shadowcraft Belt'),
( 5, 3, 'Serpentine Sash'),
( 6, 1, 'Devilsaur Leggings'),
( 6, 2, 'Plaguehound Leggings'),
( 6, 3, 'Shadowcraft Pants'),
( 6, 3, 'Traveler''s Leggings'),
( 7, 1, 'Boots of the Shadow Flame'),
( 7, 2, 'Swiftwalker Boots'),
( 7, 3, 'Mongoose Boots'),
( 7, 3, 'Swiftfoot Treads'),
( 7, 3, 'Sandstalker Ankleguards'),
( 7, 3, 'Shadowcraft Boots'),
(10, 1, 'Circle of Applied Force'),
(10, 2, 'Band of Accuria'),
(10, 3, 'Tarnished Elven Ring'),
(10, 3, 'Master Dragonslayer''s Ring'),
(10, 3, 'Quick Strike Ring'),
(12, 1, 'Drake Fang Talisman'),
(12, 2, 'Blackhand''s Breadth'),
(12, 3, 'Hand of Justice'),
(12, 3, 'Rune of the Guard Captain'),
(12, 3, 'Counterattack Lodestone'),
(12, 3, 'Ramstein''s Lightning Bolts'),
(15, 1, 'Manual Crowd Pummeler'),
(15, 2, 'Bonecrusher'),
(15, 3, 'Impervious Giant'),
(15, 3, 'Skullcracking Mace');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 11 AND `spec` = 1 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 1, s.`slot`, 0, 30, r.entry, s.`rank`,
       CONCAT('Vanilla P3 BWL (wowtbc.gg) - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE r.entry IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 11 AND `spec` IN (1) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
