-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P3 BWL (wowtbc.gg). Classe 11, spe 10, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Mask of the Unforgiven'),
( 0, 2, 'Eye of Rend'),
( 0, 3, 'Ragefury Eyepatch'),
( 0, 3, 'Shadowcraft Cap'),
( 0, 3, 'Tattered Leather Hood'),
( 1, 1, 'Onyxia Tooth Pendant'),
( 1, 2, 'Prestor''s Talisman of Connivery'),
( 1, 3, 'Master Dragonslayer''s Medallion'),
( 1, 3, 'Eskhandar''s Collar'),
( 1, 3, 'Beads of Ogre Might'),
( 1, 3, 'Mark of Fordring'),
( 2, 1, 'Taut Dragonhide Shoulderpads'),
( 2, 2, 'Truestrike Shoulders'),
( 2, 3, 'Fireguard Shoulders'),
( 2, 3, 'Flamescarred Shoulders'),
( 2, 3, 'Stormshroud Shoulders'),
(14, 1, 'Dragon''s Blood Cape'),
(14, 2, 'Puissant Cape'),
(14, 3, 'Cloak of Firemaw'),
(14, 3, 'Eskhandar''s Pelt'),
(14, 3, 'Phantasmal Cloak'),
(14, 3, 'Stoneshield Cloak'),
( 4, 1, 'Malfurion''s Blessed Bulwark'),
( 4, 2, 'Breastplate of Bloodthirst'),
( 4, 3, 'Tombstone Breastplate'),
( 4, 3, 'Interlaced Shadow Jerkin'),
( 4, 3, 'Cadaverous Armor'),
( 8, 1, 'Wristguards of Stability'),
( 8, 2, 'Blackmist Armguards'),
( 8, 3, 'Bracers of the Eclipse'),
( 8, 3, 'Malefic Bracers'),
( 9, 1, 'Devilsaur Gauntlets'),
( 9, 2, 'Aged Core Leather Gloves'),
( 9, 3, 'Doomhide Gauntlets'),
( 9, 3, 'Gargoyle Slashers'),
( 9, 3, 'Stormshroud Gloves'),
( 5, 1, 'Taut Dragonhide Belt'),
( 5, 2, 'Cloudrunner Girdle'),
( 5, 3, 'Mugger''s Belt'),
( 5, 3, 'Cadaverous Belt'),
( 5, 3, 'Girdle of Beastial Fury'),
( 6, 1, 'Devilsaur Leggings'),
( 6, 2, 'Cadaverous Leggings'),
( 6, 3, 'Plaguehound Leggings'),
( 6, 3, 'Shadowcraft Pants'),
( 7, 1, 'Boots of the Shadow Flame'),
( 7, 2, 'Pads of the Dread Wolf'),
( 7, 3, 'Cadaverous Walkers'),
(10, 1, 'Quick Strike Ring'),
(10, 2, 'Master Dragonslayer''s Ring'),
(10, 3, 'Band of Accuria'),
(10, 3, 'Circle of Applied Force'),
(10, 3, 'Heavy Dark Iron Ring'),
(12, 1, 'Drake Fang Talisman'),
(12, 2, 'Blackhand''s Breadth'),
(12, 3, 'Mark of the Chosen'),
(12, 3, 'Mark of Tyranny'),
(12, 3, 'Rune of the Guard Captain'),
(12, 3, 'Smoking Heart of the Mountain'),
(15, 1, 'Manual Crowd Pummeler'),
(15, 2, 'Draconic Maul'),
(15, 3, 'Herald of Woe'),
(15, 3, 'Warden Staff'),
(15, 3, 'Impervious Giant');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 11 AND `spec` = 10 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 10, s.`slot`, 0, 30, r.entry, s.`rank`,
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
WHERE `class` = 11 AND `spec` IN (10) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
