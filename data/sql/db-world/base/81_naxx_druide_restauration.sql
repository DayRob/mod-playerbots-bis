-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 11, spe 2, palier 70.
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
( 0, 1, 'Dreamwalker Headpiece', NULL),
( 0, 2, 'Crystal Adorned Crown', NULL),
( 0, 3, 'Deviate Growth Cap', NULL),
( 0, 4, 'Don Rigoberto''s Lost Hat', NULL),
( 0, 5, 'Creeping Vine Helm', NULL),
( 0, 6, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 1, 1, 'Amulet of the Fallen God', NULL),
( 1, 2, 'Necklace of Necropsy', NULL),
( 1, 3, 'Jin''do''s Evil Eye', NULL),
( 1, 4, 'Amulet of the Shifting Sands', NULL),
( 1, 5, 'Amulet of Vek''nilash', NULL),
( 1, 6, 'Angelista''s Charm', NULL),
( 2, 1, 'Wild Growth Spaulders', NULL),
( 2, 2, 'Dreamwalker Spaulders', NULL),
( 2, 3, 'Ternary Mantle', NULL),
( 2, 4, 'Animist''s Spaulders', NULL),
( 2, 5, 'Stormrage Pauldrons', NULL),
( 2, 6, 'Mantle of the Blackwing Cabal', NULL),
(14, 1, 'Cloak of Suturing', NULL),
(14, 2, 'Cloak of Clarity', NULL),
(14, 3, 'Hide of the Wild', NULL),
(14, 4, 'Shroud of Pure Thought', NULL),
(14, 5, 'Drape of Benediction', NULL),
(14, 6, 'Hakkari Loa Cloak', NULL),
( 4, 1, 'Dreamwalker Tunic', NULL),
( 4, 2, 'Robes of the Guardian Saint', NULL),
( 4, 3, 'Robes of the Exalted', NULL),
( 4, 4, 'Stormrage Chestguard', NULL),
( 4, 5, 'Forest''s Embrace', NULL),
( 4, 6, 'Jade Inlaid Vestments', NULL),
( 8, 1, 'Bracelets of Royal Redemption', NULL),
( 8, 2, 'Dreamwalker Wristguards', NULL),
( 8, 3, 'Stormrage Bracers', NULL),
( 8, 4, 'Zandalar Haruspex''s Bracers', NULL),
( 8, 5, 'Burrower Bracers', NULL),
( 9, 1, 'Dreamwalker Handguards', NULL),
( 9, 2, 'Wasphide Gauntlets', NULL),
( 9, 3, 'Stormrage Handguards', NULL),
( 9, 4, 'Gloves of Dark Wisdom', NULL),
( 9, 5, 'Hands of the Exalted Herald', NULL),
( 5, 1, 'Dreamwalker Girdle', NULL),
( 5, 2, 'Grasp of the Old God', NULL),
( 5, 3, 'Regenerating Belt of Vek''nilash', NULL),
( 5, 4, 'Sash of Mercy', NULL),
( 5, 5, 'Eyestalk Waist Cord', NULL),
( 6, 1, 'Empowered Leggings', NULL),
( 6, 2, 'Dreamwalker Legguards', NULL),
( 6, 3, 'Salamander Scale Pants', NULL),
( 6, 4, 'Stormrage Legguards', NULL),
( 6, 5, 'Leggings of the Black Blizzard', NULL),
( 6, 6, 'Padre''s Trousers', NULL),
( 7, 1, 'Boots of Pure Thought', NULL),
( 7, 2, 'Dreamwalker Boots', NULL),
( 7, 3, 'Treads of the Wandering Nomad', NULL),
( 7, 4, 'Stormrage Boots', NULL),
( 7, 5, 'Snowblind Shoes', NULL),
( 7, 6, 'Boots of Fright', NULL),
(10, 1, 'Pure Elementium Band', NULL),
(10, 2, 'Band of Unanswered Prayers', NULL),
(10, 3, 'Ring of the Martyr', NULL),
(10, 4, 'Cauterizing Band', NULL),
(10, 5, 'Fordring''s Seal', NULL),
(10, 6, 'Rosewine Circle', NULL),
(12, 1, 'Eye of the Dead', NULL),
(12, 2, 'Rejuvenating Gem', NULL),
(12, 3, 'Hibernation Crystal', NULL),
(12, 4, 'Royal Seal of Eldre''Thalas', NULL),
(12, 5, 'Scarab Brooch', NULL),
(12, 6, 'Draconic Infused Emblem', NULL),
(15, 1, 'Hammer of the Twisting Nether', NULL),
(15, 2, 'Atiesh, Greatstaff of the Guardian', NULL),
(15, 3, 'Scepter of the False Prophet', NULL),
(15, 4, 'The Widow''s Embrace', NULL),
(15, 5, 'Fang of Korialstrasz', NULL),
(15, 6, 'Blessed Qiraji Augur Staff', NULL),
(16, 1, 'Sapphiron''s Right Eye', NULL),
(16, 2, 'Noth''s Frigid Heart', NULL),
(16, 3, 'Sartura''s Might', NULL),
(16, 4, 'Brightly Glowing Stone', NULL),
(16, 5, 'Tome of Divine Right', NULL),
(17, 1, 'Idol of Rejuvenation', NULL),
(17, 2, 'Idol of Health', NULL),
(17, 3, 'Idol of Longevity', NULL);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 2, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 11 AND `spec` IN (2) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
