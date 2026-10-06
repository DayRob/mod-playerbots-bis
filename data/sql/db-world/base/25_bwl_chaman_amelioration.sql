-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P3 BWL (wowtbc.gg). Classe 7, spe 1, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Crown of Destruction'),
( 0, 2, 'Eye of Rend'),
( 0, 3, 'Mask of the Unforgiven'),
( 0, 3, 'Crown of Tyranny'),
( 0, 3, 'Ragefury Eyepatch'),
( 1, 1, 'Mark of Fordring'),
( 1, 2, 'Onyxia Tooth Pendant'),
( 1, 3, 'Prestor''s Talisman of Connivery'),
( 1, 3, 'Beads of Ogre Might'),
( 1, 3, 'Imperial Jewel'),
( 2, 1, 'Taut Dragonhide Shoulderpads'),
( 2, 2, 'Truestrike Shoulders'),
( 2, 3, 'Wyrmhide Spaulders'),
( 2, 3, 'Flamescarred Shoulders'),
( 2, 3, 'Black Dragonscale Shoulders'),
( 2, 3, 'Failed Flying Experiment'),
(14, 1, 'Cloak of Draconic Might'),
(14, 2, 'Puissant Cape'),
(14, 3, 'Cloak of Firemaw'),
(14, 3, 'Cape of the Black Baron'),
(14, 3, 'Blackveil Cape'),
(14, 3, 'Cloak of the Shrouded Mists'),
( 4, 1, 'Savage Gladiator Chain'),
( 4, 2, 'Cadaverous Armor'),
( 4, 3, 'Malfurion''s Blessed Bulwark'),
( 4, 3, 'Breastplate of Bloodthirst'),
( 4, 3, 'Tombstone Breastplate'),
( 4, 3, 'Deathdealer Breastplate'),
( 8, 1, 'Wristguards of Stability'),
( 8, 2, 'Wristguards of True Flight'),
( 8, 3, 'Bracers of the Eclipse'),
( 8, 3, 'Blackmist Armguards'),
( 9, 1, 'Doomhide Gauntlets'),
( 9, 2, 'Aged Core Leather Gloves'),
( 9, 3, 'Devilsaur Gauntlets'),
( 9, 3, 'Gargoyle Slashers'),
( 9, 3, 'Voone''s Vice Grips'),
( 5, 1, 'Therazane''s Link'),
( 5, 2, 'Taut Dragonhide Belt'),
( 5, 3, 'Cloudrunner Girdle'),
( 5, 3, 'Primalist''s Linked Waistguard'),
( 5, 3, 'Warpwood Binding'),
( 6, 1, 'Devilsaur Leggings'),
( 6, 2, 'Legguards of the Chromatic Defier'),
( 6, 3, 'Plaguehound Leggings'),
( 6, 3, 'Shadowcraft Pants'),
( 6, 3, 'Traveler''s Leggings'),
( 7, 1, 'Boots of the Shadow Flame'),
( 7, 2, 'Bloodmail Boots'),
( 7, 3, 'Windreaver Greaves'),
( 7, 3, 'Savage Gladiator Greaves'),
( 7, 3, 'Pads of the Dread Wolf'),
(10, 1, 'Master Dragonslayer''s Ring'),
(10, 2, 'Quick Strike Ring'),
(10, 3, 'Band of Accuria'),
(10, 3, 'Circle of Applied Force'),
(10, 3, 'Painweaver Band'),
(12, 1, 'Blackhand''s Breadth'),
(12, 2, 'Drake Fang Talisman'),
(12, 3, 'Hand of Justice'),
(12, 3, 'Rune of the Guard Captain'),
(12, 3, 'Counterattack Lodestone'),
(12, 3, 'Briarwood Reed'),
(15, 1, 'Drake Talon Cleaver'),
(15, 2, 'Spinal Reaper'),
(15, 3, 'Draconic Avenger'),
(15, 3, 'Arcanite Reaper'),
(15, 3, 'Dreadforge Retaliator');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 7 AND `spec` = 1 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 7, 1, s.`slot`, 0, 30, r.entry, s.`rank`,
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
WHERE `class` = 7 AND `spec` IN (1) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
