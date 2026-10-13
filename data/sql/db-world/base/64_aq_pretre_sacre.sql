-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P5 AQ (wowtbc.gg). Classe 5, spe 1, palier 60.
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
( 0, 1, 'Don Rigoberto''s Lost Hat', NULL),
( 0, 2, 'Crystal Adorned Crown', NULL),
( 0, 3, 'Zulian Headdress', NULL),
( 0, 4, 'Halo of Transcendence', NULL),
( 0, 5, 'Dustwind Turban', NULL),
( 0, 6, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 1, 1, 'Amulet of the Fallen God', NULL),
( 1, 2, 'Jin''do''s Evil Eye', NULL),
( 1, 3, 'Amulet of the Shifting Sands', NULL),
( 1, 4, 'Angelista''s Charm', NULL),
( 1, 5, 'Animated Chain Necklace', NULL),
( 1, 6, 'Choker of the Fire Lord', NULL),
( 2, 1, 'Ternary Mantle', NULL),
( 2, 2, 'Pauldrons of Transcendence', NULL),
( 2, 3, 'Mantle of the Blackwing Cabal', NULL),
( 2, 4, 'Mantle of Lost Hope', NULL),
( 2, 5, 'Mantle of the Oracle', NULL),
( 2, 6, 'Mantle of the Scarlet Crusade', NULL),
(14, 1, 'Cloak of Clarity', NULL),
(14, 2, 'Hide of the Wild', NULL),
(14, 3, 'Drape of Benediction', NULL),
(14, 4, 'Shroud of Pure Thought', NULL),
(14, 5, 'Hakkari Loa Cloak', NULL),
(14, 6, 'Shroud of Infinite Wisdom', NULL),
( 4, 1, 'Robes of the Guardian Saint', NULL),
( 4, 2, 'Truefaith Vestments', NULL),
( 4, 3, 'Robes of Transcendence', NULL),
( 4, 4, 'Robes of the Exalted', NULL),
( 4, 5, 'Vestments of the Oracle', NULL),
( 4, 6, 'Jade Inlaid Vestments', NULL),
( 8, 1, 'Bracelets of Royal Redemption', NULL),
( 8, 2, 'Bindings of Transcendence', NULL),
( 8, 3, 'Vambraces of Prophecy', NULL),
( 8, 4, 'Burrower Bracers', NULL),
( 9, 1, 'Desert Bloom Gloves', NULL),
( 9, 2, 'Handguards of Transcendence', NULL),
( 9, 3, 'Hands of the Exalted Herald', NULL),
( 9, 4, 'Gloves of Dark Wisdom', NULL),
( 9, 5, 'Gloves of Prophecy', NULL),
( 5, 1, 'Grasp of the Old God', NULL),
( 5, 2, 'Belt of Transcendence', NULL),
( 5, 3, 'Eyestalk Waist Cord', NULL),
( 5, 4, 'Firemaw''s Clutch', NULL),
( 5, 5, 'Whipvine Cord', NULL),
( 6, 1, 'Empowered Leggings', NULL),
( 6, 2, 'Leggings of Transcendence', NULL),
( 6, 3, 'Trousers of the Oracle', NULL),
( 6, 4, 'Senior Designer''s Pantaloons', NULL),
( 6, 5, 'Padre''s Trousers', NULL),
( 7, 1, 'Boots of Pure Thought', NULL),
( 7, 2, 'Boots of Transcendence', NULL),
( 7, 3, 'Treads of the Wandering Nomad', NULL),
( 7, 4, 'Betrayer''s Boots', NULL),
( 7, 5, 'Boots of Epiphany', NULL),
( 7, 6, 'Faith Healer''s Boots', NULL),
(10, 1, 'Pure Elementium Band', NULL),
(10, 2, 'Ring of the Martyr', NULL),
(10, 3, 'Cauterizing Band', NULL),
(10, 4, 'Primalist''s Seal', NULL),
(10, 5, 'Fordring''s Seal', NULL),
(10, 6, 'Band of Mending', NULL),
(12, 1, 'Rejuvenating Gem', NULL),
(12, 2, 'Hibernation Crystal', NULL),
(12, 3, 'Zandalarian Hero Charm', NULL),
(12, 4, 'Blessed Prayer Beads', NULL),
(12, 5, 'Draconic Infused Emblem', NULL),
(12, 6, 'Scarab Brooch', NULL),
(15, 1, 'Scepter of the False Prophet', NULL),
(15, 2, 'Fang of Korialstrasz', NULL),
(15, 3, 'Blessed Qiraji Augur Staff', NULL),
(15, 4, 'Gavel of Infinite Wisdom', NULL),
(15, 5, 'Benediction', NULL),
(15, 6, 'Lok''amir il Romathis', NULL),
(16, 1, 'Sartura''s Might', NULL),
(16, 2, 'Brightly Glowing Stone', NULL),
(16, 3, 'Master Dragonslayer''s Orb', NULL),
(16, 4, 'Thaurissan''s Royal Scepter', NULL),
(17, 1, 'Wand of Qiraji Nobility', NULL),
(17, 2, 'Touch of Chaos', NULL),
(17, 3, 'Antenna of Invigoration', NULL),
(17, 4, 'Bonecreeper Stylus', NULL),
(17, 5, 'Wand of Eternal Light', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 5 AND `spec` = 1 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 5, 1, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 5 AND `spec` IN (1) AND `tier_id` = 60
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
