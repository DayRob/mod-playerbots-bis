-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P3 BWL (wowtbc.gg). Classe 1, spe 0, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
--
-- ARMES : wowtbc.gg ne publie pas cette spe - son menu ne propose que fury et
-- fury protection. La liste est donc celle de Fureur, dont elle ne differe que
-- par l'arme, et les creneaux 15 et 16 en ont ete RETIRES : un guerrier Armes
-- tient une arme a deux mains, pas deux armes a une main. Poser le set de
-- Fureur tel quel lui aurait fait porter exactement ce qu'il ne doit pas.
--
-- Ces deux creneaux restent donc sans ligne a ce palier, et c'est la logique
-- d'origine de playerbots qui les decide, jusqu'a ce qu'un classement deux
-- mains soit ajoute.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Lionheart Helm'),
( 0, 2, 'Crown of Destruction'),
( 0, 3, 'Helm of Endless Rage'),
( 0, 3, 'Eye of Rend'),
( 0, 3, 'Mask of the Unforgiven'),
( 0, 3, 'Crown of Tyranny'),
( 1, 1, 'Onyxia Tooth Pendant'),
( 1, 2, 'Mark of Fordring'),
( 1, 3, 'Prismatic Pendant of the Tiger'),
( 1, 3, 'Imperial Jewel'),
( 1, 3, 'Will of the Martyr'),
( 1, 3, 'Conqueror''s Medallion'),
( 2, 1, 'Drake Talon Pauldrons'),
( 2, 2, 'Truestrike Shoulders'),
( 2, 3, 'Hyperion Pauldrons of the Tiger'),
( 2, 3, 'Black Dragonscale Shoulders'),
( 2, 3, 'Wyrmhide Spaulders'),
(14, 1, 'Cloak of Draconic Might'),
(14, 2, 'Puissant Cape'),
(14, 3, 'Cloak of Firemaw'),
(14, 3, 'Cape of the Black Baron'),
(14, 3, 'Blackveil Cape'),
(14, 3, 'Shadewood Cloak'),
( 4, 1, 'Savage Gladiator Chain'),
( 4, 2, 'Malfurion''s Blessed Bulwark'),
( 4, 3, 'Cadaverous Armor'),
( 4, 3, 'Breastplate of Bloodthirst'),
( 4, 3, 'Tombstone Breastplate'),
( 4, 3, 'Hyperion Armor of Strength'),
( 8, 1, 'Wristguards of Stability'),
( 8, 2, 'Battleborn Armbraces'),
( 8, 3, 'Wristguards of True Flight'),
( 8, 3, 'Vambraces of the Sadist'),
( 9, 1, 'Flameguard Gauntlets'),
( 9, 2, 'Edgemaster''s Handguards'),
( 9, 3, 'Gauntlets of Might'),
( 9, 3, 'Doomhide Gauntlets'),
( 9, 3, 'Aged Core Leather Gloves'),
( 5, 1, 'Onslaught Girdle'),
( 5, 2, 'Therazane''s Link'),
( 5, 3, 'Taut Dragonhide Belt'),
( 5, 3, 'Girdle of the Fallen Crusader'),
( 5, 3, 'Omokk''s Girth Restrainer'),
( 5, 3, 'Brigam Girdle'),
( 6, 1, 'Legguards of the Fallen Crusader'),
( 6, 2, 'Devilsaur Leggings'),
( 6, 3, 'Cloudkeeper Legplates'),
( 6, 3, 'Eldritch Reinforced Legplates'),
( 6, 3, 'Handcrafted Mastersmith Leggings'),
( 7, 1, 'Chromatic Boots'),
( 7, 2, 'Boots of the Shadow Flame'),
( 7, 3, 'Bloodmail Boots'),
( 7, 3, 'Exalted Sabatons of the Tiger'),
( 7, 3, 'Battlechaser''s Greaves'),
( 7, 3, 'Pads of the Dread Wolf'),
(10, 1, 'Master Dragonslayer''s Ring'),
(10, 2, 'Quick Strike Ring'),
(10, 3, 'Band of Accuria'),
(10, 3, 'Circle of Applied Force'),
(10, 3, 'Blackstone Ring'),
(12, 1, 'Drake Fang Talisman'),
(12, 2, 'Diamond Flask'),
(12, 3, 'Hand of Justice'),
(12, 3, 'Blackhand''s Breadth'),
(12, 3, 'Rune of the Guard Captain'),
(12, 3, 'Counterattack Lodestone'),
(17, 1, 'Striker''s Mark'),
(17, 2, 'Heartstriker'),
(17, 3, 'Blackcrow'),
(17, 3, 'Satyr''s Bow'),
(17, 3, 'Riphook');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 0 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 0, s.`slot`, 0, 30, r.entry, s.`rank`,
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
WHERE `class` = 1 AND `spec` IN (0) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
