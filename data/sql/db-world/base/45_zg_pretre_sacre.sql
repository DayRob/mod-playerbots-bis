-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P4 ZG (wowtbc.gg). Classe 5, spe 1, palier 40.
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
( 0, 1, 'Zulian Headdress', NULL),
( 0, 2, 'Crystal Adorned Crown', NULL),
( 0, 3, 'Halo of Transcendence', NULL),
( 0, 3, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 0, 3, 'Cassandra''s Grace', NULL),
( 1, 1, 'Jin''do''s Evil Eye', NULL),
( 1, 2, 'Animated Chain Necklace', NULL),
( 1, 3, 'Choker of the Fire Lord', NULL),
( 1, 3, 'Choker of Enlightenment', NULL),
( 1, 3, 'Beads of Ogre Mojo', NULL),
( 1, 3, 'Lady Maye''s Pendant', NULL),
( 2, 1, 'Pauldrons of Transcendence', NULL),
( 2, 2, 'Mantle of the Blackwing Cabal', NULL),
( 2, 3, 'Mantle of Prophecy', NULL),
( 2, 3, 'Virtuous Mantle', NULL),
( 2, 3, 'Burial Shawl', NULL),
(14, 1, 'Hide of the Wild', NULL),
(14, 2, 'Drape of Benediction', NULL),
(14, 3, 'Shroud of Pure Thought', NULL),
(14, 3, 'Hakkari Loa Cloak', NULL),
( 4, 1, 'Truefaith Vestments', NULL),
( 4, 2, 'Robes of Transcendence', NULL),
( 4, 3, 'Robes of the Exalted', NULL),
( 4, 3, 'Jade Inlaid Vestments', NULL),
( 4, 3, 'Robes of Prophecy', NULL),
( 4, 3, 'Alanna''s Embrace', NULL),
( 8, 1, 'Bindings of Transcendence', NULL),
( 8, 2, 'Vambraces of Prophecy', NULL),
( 8, 3, 'Sublime Wristguards', NULL),
( 8, 3, 'Wyrmthalak''s Shackles', NULL),
( 9, 1, 'Handguards of Transcendence', NULL),
( 9, 2, 'Hands of the Exalted Herald', NULL),
( 9, 3, 'Gloves of Prophecy', NULL),
( 9, 3, 'Hands of Power', NULL),
( 9, 3, 'Virtuous Gloves', NULL),
( 5, 1, 'Firemaw''s Clutch', NULL),
( 5, 2, 'Belt of Transcendence', NULL),
( 5, 3, 'Whipvine Cord', NULL),
( 5, 3, 'Mana Igniting Cord', NULL),
( 5, 3, 'Girdle of Prophecy', NULL),
( 6, 1, 'Empowered Leggings', NULL),
( 6, 2, 'Leggings of Transcendence', NULL),
( 6, 3, 'Senior Designer''s Pantaloons', NULL),
( 6, 3, 'Padre''s Trousers', NULL),
( 6, 3, 'Pants of Prophecy', NULL),
( 7, 1, 'Boots of Pure Thought', NULL),
( 7, 2, 'Boots of Transcendence', NULL),
( 7, 3, 'Betrayer''s Boots', NULL),
( 7, 3, 'Boots of Prophecy', NULL),
( 7, 3, 'Boots of the Full Moon', NULL),
( 7, 3, 'Virtuous Sandals', NULL),
(10, 1, 'Pure Elementium Band', NULL),
(10, 2, 'Cauterizing Band', NULL),
(10, 3, 'Primalist''s Seal', NULL),
(10, 3, 'Fordring''s Seal', NULL),
(10, 3, 'Rosewine Circle', NULL),
(10, 3, 'Ring of Spell Power', NULL),
(12, 1, 'Rejuvenating Gem', NULL),
(12, 2, 'Hibernation Crystal', NULL),
(12, 3, 'Zandalarian Hero Charm', NULL),
(12, 3, 'Blessed Prayer Beads', NULL),
(12, 3, 'Talisman of Ephemeral Power', NULL),
(12, 3, 'Royal Seal of Eldre''Thalas', NULL),
(15, 1, 'Benediction', NULL),
(15, 2, 'Lok''amir il Romathis', NULL),
(15, 3, 'Claw of Chromaggus', NULL),
(15, 3, 'Staff of the Shadow Flame', NULL),
(15, 3, 'Jin''do''s Hexxer', NULL),
(15, 3, 'Fang of the Mystics', NULL),
(16, 1, 'Brightly Glowing Stone', NULL),
(16, 2, 'Master Dragonslayer''s Orb', NULL),
(16, 3, 'Thaurissan''s Royal Scepter', NULL),
(17, 1, 'Touch of Chaos', NULL),
(17, 2, 'Bonecreeper Stylus', NULL),
(17, 3, 'Lethtendris''s Wand', NULL),
(17, 3, 'Oblivion''s Touch', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 5 AND `spec` = 1 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 5, 1, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 5 AND `spec` IN (1) AND `tier_id` = 40
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
