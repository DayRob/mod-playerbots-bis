-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 5, spe 0,1, palier 70.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.
-- La jointure des noms est restreinte a AllowableClass : quatre objets
-- s'appellent "Atiesh, Greatstaff of the Guardian" et MIN(entry) seul
-- donnait le meme baton a toutes les listes, dont la plupart ne peuvent
-- pas l'equiper. Un nom qui ne resout plus ressort en VERIFICATION 1.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL,
    `entry`     INT UNSIGNED NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`, `entry`) VALUES
( 0, 1, 'Circlet of Faith', NULL),
( 0, 2, 'Crystal Adorned Crown', NULL),
( 0, 3, 'Don Rigoberto''s Lost Hat', NULL),
( 0, 4, 'Zulian Headdress', NULL),
( 0, 5, 'Preceptor''s Hat', NULL),
( 0, 6, 'Halo of Transcendence', NULL),
( 1, 1, 'Amulet of the Fallen God', NULL),
( 1, 2, 'Necklace of Necropsy', NULL),
( 1, 3, 'Jin''do''s Evil Eye', NULL),
( 1, 4, 'Amulet of the Shifting Sands', NULL),
( 1, 5, 'Angelista''s Charm', NULL),
( 1, 6, 'Animated Chain Necklace', NULL),
( 2, 1, 'Shoulderpads of Faith', NULL),
( 2, 2, 'Ternary Mantle', NULL),
( 2, 3, 'Pauldrons of Transcendence', NULL),
( 2, 4, 'Mantle of the Blackwing Cabal', NULL),
( 2, 5, 'Mantle of Lost Hope', NULL),
( 2, 6, 'Mantle of the Oracle', NULL),
(14, 1, 'Cloak of Suturing', NULL),
(14, 2, 'Cloak of Clarity', NULL),
(14, 3, 'Hide of the Wild', NULL),
(14, 4, 'Drape of Benediction', NULL),
(14, 5, 'Shroud of Pure Thought', NULL),
(14, 6, 'Hakkari Loa Cloak', NULL),
( 4, 1, 'Robe of Faith', NULL),
( 4, 2, 'Robes of the Guardian Saint', NULL),
( 4, 3, 'Truefaith Vestments', NULL),
( 4, 4, 'Robes of Transcendence', NULL),
( 4, 5, 'Robes of the Exalted', NULL),
( 4, 6, 'Crystal Webbed Robe', NULL),
( 8, 1, 'Bindings of Faith', NULL),
( 8, 2, 'Bracelets of Royal Redemption', NULL),
( 8, 3, 'Bindings of Transcendence', NULL),
( 8, 4, 'Vambraces of Prophecy', NULL),
( 8, 5, 'Burrower Bracers', NULL),
( 9, 1, 'Gloves of Faith', NULL),
( 9, 2, 'Desert Bloom Gloves', NULL),
( 9, 3, 'Handguards of Transcendence', NULL),
( 9, 4, 'Hands of the Exalted Herald', NULL),
( 9, 5, 'Gloves of Dark Wisdom', NULL),
( 5, 1, 'Belt of Faith', NULL),
( 5, 2, 'Grasp of the Old God', NULL),
( 5, 3, 'Belt of Transcendence', NULL),
( 5, 4, 'Eyestalk Waist Cord', NULL),
( 5, 5, 'Firemaw''s Clutch', NULL),
( 6, 1, 'Leggings of Faith', NULL),
( 6, 2, 'Empowered Leggings', NULL),
( 6, 3, 'Leggings of Transcendence', NULL),
( 6, 4, 'Trousers of the Oracle', NULL),
( 6, 5, 'Senior Designer''s Pantaloons', NULL),
( 7, 1, 'Boots of Pure Thought', NULL),
( 7, 2, 'Sandals of Faith', NULL),
( 7, 3, 'Boots of Transcendence', NULL),
( 7, 4, 'Treads of the Wandering Nomad', NULL),
( 7, 5, 'Betrayer''s Boots', NULL),
( 7, 6, 'Boots of Epiphany', NULL),
(10, 1, 'Ring of Faith', NULL),
(10, 2, 'Band of Unanswered Prayers', NULL),
(10, 3, 'Pure Elementium Band', NULL),
(10, 4, 'Ring of the Martyr', NULL),
(10, 5, 'Cauterizing Band', NULL),
(10, 6, 'Primalist''s Seal', NULL),
(12, 1, 'Eye of the Dead', NULL),
(12, 2, 'Hibernation Crystal', NULL),
(12, 3, 'Zandalarian Hero Charm', NULL),
(12, 4, 'Blessed Prayer Beads', NULL),
(12, 5, 'Draconic Infused Emblem', NULL),
(12, 6, 'Rejuvenating Gem', NULL),
(15, 1, 'Hammer of the Twisting Nether', NULL),
(15, 2, 'Atiesh, Greatstaff of the Guardian', NULL),
(15, 3, 'Scepter of the False Prophet', NULL),
(15, 4, 'The Widow''s Embrace', NULL),
(15, 5, 'Fang of Korialstrasz', NULL),
(15, 6, 'Spire of Twilight', NULL),
(16, 1, 'Sapphiron''s Right Eye', NULL),
(16, 2, 'Noth''s Frigid Heart', NULL),
(16, 3, 'Sartura''s Might', NULL),
(16, 4, 'Brightly Glowing Stone', NULL),
(16, 5, 'Master Dragonslayer''s Orb', NULL),
(17, 1, 'Wand of the Whispering Dead', NULL),
(17, 2, 'Wand of Qiraji Nobility', NULL),
(17, 3, 'Touch of Chaos', NULL),
(17, 4, 'Antenna of Invigoration', NULL),
(17, 5, 'Doomfinger', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 5 AND `spec` = 0 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 5, 0, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 16) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 5 AND `spec` = 1 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 5, 1, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 16) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 16) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 5 AND `spec` IN (0,1) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
