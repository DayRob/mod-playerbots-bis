-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P4 ZG (wowtbc.gg). Classe 7, spe 2, palier 40.
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
( 0, 1, 'Helmet of Ten Storms', NULL),
( 0, 2, 'Deviate Growth Cap', NULL),
( 0, 3, 'Crystal Adorned Crown', NULL),
( 0, 4, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 0, 5, 'Zulian Headdress', NULL),
( 0, 6, 'Helm of the Lifegiver', NULL),
( 1, 1, 'Jin''do''s Evil Eye', NULL),
( 1, 2, 'Choker of the Fire Lord', NULL),
( 1, 3, 'Pendant of the Fallen Dragon', NULL),
( 1, 4, 'Animated Chain Necklace', NULL),
( 1, 5, 'Jeklik''s Opaline Talisman', NULL),
( 1, 6, 'Choker of Enlightenment', NULL),
( 2, 1, 'Wild Growth Spaulders', NULL),
( 2, 2, 'Animist''s Spaulders', NULL),
( 2, 3, 'Earthfury Epaulets', NULL),
( 2, 4, 'Royal Cap Spaulders', NULL),
( 2, 5, 'Living Shoulders', NULL),
( 2, 6, 'Burial Shawl', NULL),
(14, 1, 'Shroud of Pure Thought', NULL),
(14, 2, 'Hide of the Wild', NULL),
(14, 3, 'Drape of Benediction', NULL),
(14, 4, 'Cloak of the Brood Lord', NULL),
(14, 5, 'Hakkari Loa Cloak', NULL),
(14, 6, 'Cloak of the Cosmos', NULL),
( 4, 1, 'Robes of the Exalted', NULL),
( 4, 2, 'Red Dragonscale Breastplate', NULL),
( 4, 3, 'Jade Inlaid Vestments', NULL),
( 4, 4, 'Zandalar Augur''s Hauberk', NULL),
( 4, 5, 'Robe of Volatile Power', NULL),
( 4, 6, 'Earthfury Vestments', NULL),
( 8, 1, 'Bracers of Ten Storms', NULL),
( 8, 2, 'Loomguard Armbraces', NULL),
( 8, 3, 'Zandalar Augur''s Bracers', NULL),
( 8, 4, 'Flarecore Wraps', NULL),
( 8, 5, 'Bracers of Prosperity', NULL),
( 9, 1, 'Gauntlets of Ten Storms', NULL),
( 9, 2, 'Harmonious Gauntlets', NULL),
( 9, 3, 'Gloves of Delusional Power', NULL),
( 9, 4, 'Gloves of Restoration', NULL),
( 9, 5, 'Hands of the Exalted Herald', NULL),
( 9, 6, 'Gauntlets of The Five Thunders', NULL),
( 5, 1, 'Corehound Belt', NULL),
( 5, 2, 'Firemaw''s Clutch', NULL),
( 5, 3, 'Sash of Mercy', NULL),
( 5, 4, 'Belt of Ten Storms', NULL),
( 5, 5, 'Eyestalk Cord', NULL),
( 6, 1, 'Empowered Leggings', NULL),
( 6, 2, 'Salamander Scale Pants', NULL),
( 6, 3, 'Padre''s Trousers', NULL),
( 6, 4, 'Leggings of the Demented Mind', NULL),
( 6, 5, 'Ghoul Skin Leggings', NULL),
( 7, 1, 'Boots of Pure Thought', NULL),
( 7, 2, 'Snowblind Shoes', NULL),
( 7, 3, 'Boots of Fright', NULL),
( 7, 4, 'Animist''s Boots', NULL),
( 7, 5, 'Verdant Footpads', NULL),
( 7, 6, 'Boots of the Full Moon', NULL),
(10, 1, 'Pure Elementium Band', NULL),
(10, 2, 'Cauterizing Band', NULL),
(10, 3, 'Rosewine Circle', NULL),
(10, 4, 'Ring of Blackrock', NULL),
(10, 5, 'Fordring''s Seal', NULL),
(10, 6, 'Primalist''s Seal', NULL),
(12, 1, 'Rejuvenating Gem', NULL),
(12, 2, 'Hibernation Crystal', NULL),
(12, 3, 'Natural Alignment Crystal', NULL),
(12, 4, 'Talisman of Ephemeral Power', NULL),
(12, 5, 'Shard of the Scale', NULL),
(12, 6, 'Briarwood Reed', NULL),
(15, 1, 'Lok''amir il Romathis', NULL),
(15, 2, 'Claw of Chromaggus', NULL),
(15, 3, 'Fang of the Mystics', NULL),
(15, 4, 'Jin''do''s Hexxer', NULL),
(15, 5, 'Staff of the Shadow Flame', NULL),
(15, 6, 'Aurastone Hammer', NULL),
(16, 1, 'Red Dragonscale Protector', NULL),
(16, 2, 'Master Dragonslayer''s Orb', NULL),
(16, 3, 'Brightly Glowing Stone', NULL),
(16, 4, 'Arlokk''s Hoodoo Stick', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 7 AND `spec` = 2 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 7, 2, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 7 AND `spec` IN (2) AND `tier_id` = 40
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
