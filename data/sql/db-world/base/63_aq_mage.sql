-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P5 AQ (wowtbc.gg). Classe 8, spe 0,1,2, palier 60.
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
( 0, 1, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 0, 2, 'Enigma Circlet', NULL),
( 0, 3, 'Spellweaver''s Turban', NULL),
( 0, 4, 'The Hexxer''s Cover', NULL),
( 0, 5, 'Netherwind Crown', NULL),
( 1, 1, 'Amulet of Vek''nilash', NULL),
( 1, 2, 'Choker of the Fire Lord', NULL),
( 1, 3, 'Charm of the Shifting Sands', NULL),
( 1, 4, 'Jeklik''s Opaline Talisman', NULL),
( 1, 5, 'Diana''s Pearl Necklace', NULL),
( 1, 6, 'Choker of Enlightenment', NULL),
( 2, 1, 'Mantle of the Blackwing Cabal', NULL),
( 2, 2, 'Enigma Shoulderpads', NULL),
( 2, 3, 'Boreal Mantle', NULL),
( 2, 4, 'Mantle of Maz''Nadir', NULL),
(14, 1, 'Cloak of the Devoured', NULL),
(14, 2, 'Cloak of Consumption', NULL),
(14, 3, 'Cloak of the Brood Lord', NULL),
(14, 4, 'Cloak of the Hakkari Worshippers', NULL),
(14, 5, 'Cape of the Trinity', NULL),
( 4, 1, 'Enigma Robes', NULL),
( 4, 2, 'Garb of Royal Ascension', NULL),
( 4, 3, 'Bloodvine Vest', NULL),
( 4, 4, 'Robe of the Archmage', NULL),
( 4, 5, 'Jade Inlaid Vestments', NULL),
( 4, 6, 'Netherwind Robes', NULL),
( 8, 1, 'Rockfury Bracers', NULL),
( 8, 2, 'Bracers of Arcane Accuracy', NULL),
( 8, 3, 'Burrower Bracers', NULL),
( 8, 4, 'Black Bark Wristbands', NULL),
( 9, 1, 'Dark Storm Gauntlets', NULL),
( 9, 2, 'Bloodtinged Gloves', NULL),
( 9, 3, 'Netherwind Gloves', NULL),
( 9, 4, 'Gloves of Delusional Power', NULL),
( 9, 5, 'Sandworm Skin Gloves', NULL),
( 9, 6, 'Hands of Power', NULL),
( 5, 1, 'Eyestalk Waist Cord', NULL),
( 5, 2, 'Mana Igniting Cord', NULL),
( 5, 3, 'Firemaw''s Clutch', NULL),
( 5, 4, 'Belt of Untapped Power', NULL),
( 5, 5, 'Netherwind Belt', NULL),
( 5, 6, 'Angelista''s Grasp', NULL),
( 6, 1, 'Leggings of the Black Blizzard', NULL),
( 6, 2, 'Bloodvine Leggings', NULL),
( 6, 3, 'Enigma Leggings', NULL),
( 6, 4, 'Netherwind Pants', NULL),
( 6, 5, 'Skyshroud Leggings', NULL),
( 7, 1, 'Ringo''s Blizzard Boots', NULL),
( 7, 2, 'Enigma Boots', NULL),
( 7, 3, 'Boots of Epiphany', NULL),
( 7, 4, 'Bloodvine Boots', NULL),
(10, 1, 'Ring of the Fallen God', NULL),
(10, 2, 'Ritssyn''s Ring of Chaos', NULL),
(10, 3, 'Band of Forced Concentration', NULL),
(10, 4, 'Ring of Spell Power', NULL),
(10, 5, 'Mindtear Band', NULL),
(10, 6, 'Signet Ring of the Bronze Dragonflight', NULL),
(12, 1, 'Neltharion''s Tear', NULL),
(12, 2, 'Mind Quickening Gem', NULL),
(12, 3, 'Zandalarian Hero Charm', NULL),
(12, 4, 'Talisman of Ephemeral Power', NULL),
(12, 5, 'Draconic Infused Emblem', NULL),
(12, 6, 'Briarwood Reed', NULL),
(15, 1, 'Sharpened Silithid Femur', NULL),
(15, 2, 'Blessed Qiraji Acolyte Staff', NULL),
(15, 3, 'Staff of the Shadow Flame', NULL),
(15, 4, 'Claw of Chromaggus', NULL),
(15, 5, 'Runesword of the Red', NULL),
(15, 6, 'Blade of Vaulted Secrets', NULL),
(16, 1, 'Royal Scepter of Vek''lor', NULL),
(16, 2, 'Talon of Furious Concentration', NULL),
(16, 3, 'Jin''do''s Bag of Whammies', NULL),
(16, 4, 'Master Dragonslayer''s Orb', NULL),
(16, 5, 'Scepter of Interminable Focus', NULL),
(17, 1, 'Wand of Qiraji Nobility', NULL),
(17, 2, 'Cold Snap', NULL),
(17, 3, 'Touch of Chaos', NULL),
(17, 4, 'Bonecreeper Stylus', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 8 AND `spec` = 0 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 8, 0, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 8 AND `spec` = 1 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 8, 1, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 8 AND `spec` = 2 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 8, 2, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 8 AND `spec` IN (0,1,2) AND `tier_id` = 60
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
