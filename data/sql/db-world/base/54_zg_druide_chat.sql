-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P4 ZG (wowtbc.gg). Classe 11, spe 1, palier 40.
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
( 0, 2, 'Blooddrenched Mask'),
( 0, 3, 'Lizardscale Eyepatch'),
( 0, 3, 'Mask of the Unforgiven'),
( 0, 3, 'Eye of Rend'),
( 1, 1, 'Prestor''s Talisman of Connivery'),
( 1, 2, 'Onyxia Tooth Pendant'),
( 1, 3, 'The Eye of Hakkar'),
( 1, 3, 'Beads of Ogre Might'),
( 1, 3, 'Mark of Fordring'),
( 2, 1, 'Wyrmtongue Shoulders'),
( 2, 2, 'Truestrike Shoulders'),
( 2, 3, 'Flamescarred Shoulders'),
( 2, 3, 'Wyrmhide Spaulders'),
(14, 1, 'Cloak of Draconic Might'),
(14, 2, 'Zulian Tigerhide Cloak'),
(14, 3, 'Puissant Cape'),
(14, 3, 'Cloak of the Shrouded Mists'),
(14, 3, 'Cape of the Black Baron'),
(14, 3, 'Blackveil Cape'),
( 4, 1, 'Malfurion''s Blessed Bulwark'),
( 4, 2, 'Primal Batskin Jerkin'),
( 4, 3, 'Cadaverous Armor'),
( 4, 3, 'Breastplate of Bloodthirst'),
( 4, 3, 'Grizzled Pelt'),
( 8, 1, 'Wristguards of Stability'),
( 8, 2, 'Primal Batskin Bracers'),
( 8, 3, 'Deepfury Bracers'),
( 8, 3, 'Bracers of the Eclipse'),
( 8, 3, 'Blackmist Armguards'),
( 9, 1, 'Devilsaur Gauntlets'),
( 9, 2, 'Primal Batskin Gloves'),
( 9, 3, 'Doomhide Gauntlets'),
( 9, 3, 'Gargoyle Slashers'),
( 9, 3, 'Gloves of the Pathfinder'),
( 5, 1, 'Belt of Preserved Heads'),
( 5, 2, 'Cloudrunner Girdle'),
( 5, 3, 'Shadow Panther Hide Belt'),
( 5, 3, 'Shadowcraft Belt'),
( 6, 1, 'Devilsaur Leggings'),
( 6, 2, 'Plaguehound Leggings'),
( 6, 3, 'Shadowcraft Pants'),
( 6, 3, 'Blooddrenched Leggings'),
( 6, 3, 'Dark Heart Pants'),
( 7, 1, 'Boots of the Shadow Flame'),
( 7, 2, 'Blooddrenched Footpads'),
( 7, 3, 'Swiftwalker Boots'),
( 7, 3, 'Mongoose Boots'),
( 7, 3, 'Swiftfoot Treads'),
( 7, 3, 'Sandstalker Ankleguards'),
(10, 1, 'Circle of Applied Force'),
(10, 2, 'Band of Accuria'),
(10, 3, 'Tarnished Elven Ring'),
(10, 3, 'Band of Jin'),
(10, 3, 'Master Dragonslayer''s Ring'),
(12, 1, 'Drake Fang Talisman'),
(12, 2, 'Blackhand''s Breadth'),
(12, 3, 'Hand of Justice'),
(12, 3, 'Rune of the Guard Captain'),
(12, 3, 'Counterattack Lodestone'),
(12, 3, 'Ramstein''s Lightning Bolts'),
(15, 1, 'Manual Crowd Pummeler'),
(15, 2, 'Hammer of Bestial Fury'),
(15, 3, 'Bonecrusher'),
(15, 3, 'Impervious Giant');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 11 AND `spec` = 1 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 1, s.`slot`, 0, 40, r.entry, s.`rank`,
       CONCAT('Vanilla P4 ZG (wowtbc.gg) - ', s.`item_name`)
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
WHERE `class` = 11 AND `spec` IN (1) AND `tier_id` = 40
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
