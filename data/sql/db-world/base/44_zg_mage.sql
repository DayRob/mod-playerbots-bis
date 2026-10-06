-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P4 ZG (wowtbc.gg). Classe 8, spe 0,1,2, palier 40.
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
( 0, 2, 'The Hexxer''s Cover', NULL),
( 0, 3, 'Netherwind Crown', NULL),
( 0, 3, 'Arcanist Crown', NULL),
( 1, 1, 'Choker of the Fire Lord', NULL),
( 1, 2, 'Jeklik''s Opaline Talisman', NULL),
( 1, 3, 'Diana''s Pearl Necklace', NULL),
( 1, 3, 'Choker of Enlightenment', NULL),
( 1, 3, 'Beads of Ogre Mojo', NULL),
( 1, 3, 'Soul Corrupter''s Necklace', NULL),
( 2, 1, 'Mantle of the Blackwing Cabal', NULL),
( 2, 2, 'Boreal Mantle', NULL),
( 2, 3, 'Burial Shawl', NULL),
( 2, 3, 'Arcanist Mantle', NULL),
(14, 1, 'Cloak of Consumption', NULL),
(14, 2, 'Cloak of the Brood Lord', NULL),
(14, 3, 'Cloak of the Hakkari Worshippers', NULL),
(14, 3, 'Amplifying Cloak', NULL),
(14, 3, 'Sapphiron Drape', NULL),
( 4, 1, 'Bloodvine Vest', NULL),
( 4, 2, 'Robe of the Archmage', NULL),
( 4, 3, 'Jade Inlaid Vestments', NULL),
( 4, 3, 'Netherwind Robes', NULL),
( 4, 3, 'Robe of Volatile Power', NULL),
( 4, 3, 'Freezing Lich Robes', NULL),
( 8, 1, 'Bracers of Arcane Accuracy', NULL),
( 8, 2, 'Black Bark Wristbands', NULL),
( 8, 3, 'Arcanist Bindings', NULL),
( 8, 3, 'Sublime Wristguards', NULL),
( 9, 1, 'Netherwind Gloves', NULL),
( 9, 2, 'Bloodtinged Gloves', NULL),
( 9, 3, 'Gloves of Delusional Power', NULL),
( 9, 3, 'Hands of Power', NULL),
( 9, 3, 'Earth Warder''s Gloves', NULL),
( 9, 3, 'Frostweave Gloves', NULL),
( 5, 1, 'Mana Igniting Cord', NULL),
( 5, 2, 'Firemaw''s Clutch', NULL),
( 5, 3, 'Belt of Untapped Power', NULL),
( 5, 3, 'Netherwind Belt', NULL),
( 5, 3, 'Angelista''s Grasp', NULL),
( 5, 3, 'Ban''thok Sash', NULL),
( 6, 1, 'Bloodvine Leggings', NULL),
( 6, 2, 'Flarecore Leggings', NULL),
( 6, 3, 'Netherwind Pants', NULL),
( 6, 3, 'Skyshroud Leggings', NULL),
( 6, 3, 'Arcanist Leggings', NULL),
( 7, 1, 'Bloodvine Boots', NULL),
( 7, 2, 'Ringo''s Blizzard Boots', NULL),
( 7, 3, 'Snowblind Shoes', NULL),
( 7, 3, 'Betrayer''s Boots', NULL),
(10, 1, 'Band of Forced Concentration', NULL),
(10, 2, 'Ring of Spell Power', NULL),
(10, 3, 'Mindtear Band', NULL),
(10, 3, 'Band of Servitude', NULL),
(10, 3, 'Zanzil''s Seal', NULL),
(10, 3, 'Freezing Band', NULL),
(12, 1, 'Neltharion''s Tear', NULL),
(12, 2, 'Mind Quickening Gem', NULL),
(12, 3, 'Zandalarian Hero Charm', NULL),
(12, 3, 'Talisman of Ephemeral Power', NULL),
(12, 3, 'Briarwood Reed', NULL),
(12, 3, 'Eye of the Beast', NULL),
(15, 1, 'Staff of the Shadow Flame', NULL),
(15, 2, 'Claw of Chromaggus', NULL),
(15, 3, 'Azuresong Mageblade', NULL),
(15, 3, 'Fang of the Mystics', NULL),
(15, 3, 'Sorcerous Dagger', NULL),
(16, 1, 'Jin''do''s Bag of Whammies', NULL),
(16, 2, 'Master Dragonslayer''s Orb', NULL),
(16, 3, 'Spirit of Aquementas', NULL),
(17, 1, 'Touch of Chaos', NULL),
(17, 2, 'Cold Snap', NULL),
(17, 3, 'Bonecreeper Stylus', NULL),
(17, 3, 'Freezing Shard', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 8 AND `spec` = 0 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 8, 0, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('Vanilla P4 ZG (wowtbc.gg) - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 8 AND `spec` = 1 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 8, 1, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('Vanilla P4 ZG (wowtbc.gg) - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 8 AND `spec` = 2 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 8, 2, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 8 AND `spec` IN (0,1,2) AND `tier_id` = 40
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
