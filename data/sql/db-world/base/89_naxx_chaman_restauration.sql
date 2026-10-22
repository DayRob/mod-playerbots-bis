-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 7, spe 2, palier 70.
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
( 0, 1, 'Stormcaller''s Diadem', NULL),
( 0, 2, 'Earthshatter Headpiece', NULL),
( 0, 3, 'Don Rigoberto''s Lost Hat', NULL),
( 0, 4, 'Deviate Growth Cap', NULL),
( 0, 5, 'Crystal Adorned Crown', NULL),
( 0, 6, 'Creeping Vine Helm', NULL),
( 1, 1, 'Amulet of the Fallen God', NULL),
( 1, 2, 'Necklace of Necropsy', NULL),
( 1, 3, 'Amulet of the Shifting Sands', NULL),
( 1, 4, 'Jin''do''s Evil Eye', NULL),
( 1, 5, 'Choker of the Fire Lord', NULL),
( 1, 6, 'Pendant of the Fallen Dragon', NULL),
( 2, 1, 'Stormcaller''s Pauldrons', NULL),
( 2, 2, 'Earthshatter Spaulders', NULL),
( 2, 3, 'Wild Growth Spaulders', NULL),
( 2, 4, 'Ternary Mantle', NULL),
( 2, 5, 'Animist''s Spaulders', NULL),
( 2, 6, 'Pauldrons of Elemental Fury', NULL),
(14, 1, 'Cloak of Suturing', NULL),
(14, 2, 'Cloak of Clarity', NULL),
(14, 3, 'Shroud of Pure Thought', NULL),
(14, 4, 'Hide of the Wild', NULL),
(14, 5, 'Drape of Benediction', NULL),
(14, 6, 'Cloak of the Brood Lord', NULL),
( 4, 1, 'Stormcaller''s Hauberk', NULL),
( 4, 2, 'Earthshatter Tunic', NULL),
( 4, 3, 'Robes of the Guardian Saint', NULL),
( 4, 4, 'Robes of the Exalted', NULL),
( 4, 5, 'Crystal Webbed Robe', NULL),
( 4, 6, 'Red Dragonscale Breastplate', NULL),
( 8, 1, 'Bracers of Ten Storms', NULL),
( 8, 2, 'Bracelets of Royal Redemption', NULL),
( 8, 3, 'Earthshatter Wristguards', NULL),
( 8, 4, 'Loomguard Armbraces', NULL),
( 8, 5, 'Zandalar Augur''s Bracers', NULL),
( 9, 1, 'Gauntlets of Ten Storms', NULL),
( 9, 2, 'Earthshatter Handguards', NULL),
( 9, 3, 'Gloves of the Messiah', NULL),
( 9, 4, 'Wasphide Gauntlets', NULL),
( 9, 5, 'Gloves of Dark Wisdom', NULL),
( 9, 6, 'Harmonious Gauntlets', NULL),
( 5, 1, 'Belt of Ten Storms', NULL),
( 5, 2, 'Grasp of the Old God', NULL),
( 5, 3, 'Earthshatter Girdle', NULL),
( 5, 4, 'Regenerating Belt of Vek''nilash', NULL),
( 5, 5, 'Girdle of Elemental Fury', NULL),
( 6, 1, 'Stormcaller''s Leggings', NULL),
( 6, 2, 'Earthshatter Legguards', NULL),
( 6, 3, 'Empowered Leggings', NULL),
( 6, 4, 'Salamander Scale Pants', NULL),
( 6, 5, 'Padre''s Trousers', NULL),
( 6, 6, 'Leggings of Immersion', NULL),
( 7, 1, 'Stormcaller''s Footguards', NULL),
( 7, 2, 'Earthshatter Boots', NULL),
( 7, 3, 'Boots of Pure Thought', NULL),
( 7, 4, 'Snowblind Shoes', NULL),
( 7, 5, 'Treads of the Wandering Nomad', NULL),
( 7, 6, 'Boots of Fright', NULL),
(10, 1, 'Pure Elementium Band', NULL),
(10, 2, 'Band of Unanswered Prayers', NULL),
(10, 3, 'Ring of the Martyr', NULL),
(10, 4, 'Cauterizing Band', NULL),
(10, 5, 'Signet Ring of the Bronze Dragonflight', NULL),
(10, 6, 'Rosewine Circle', NULL),
(12, 1, 'Eye of the Dead', NULL),
(12, 2, 'Rejuvenating Gem', NULL),
(12, 3, 'Hibernation Crystal', NULL),
(12, 4, 'Scarab Brooch', NULL),
(12, 5, 'Natural Alignment Crystal', NULL),
(12, 6, 'Draconic Infused Emblem', NULL),
(15, 1, 'Hammer of the Twisting Nether', NULL),
(15, 2, 'Scepter of the False Prophet', NULL),
(15, 3, 'The Widow''s Embrace', NULL),
(15, 4, 'Spire of Twilight', NULL),
(15, 5, 'Fang of Korialstrasz', NULL),
(15, 6, 'Blessed Qiraji Augur Staff', NULL),
(16, 1, 'Sapphiron''s Right Eye', NULL),
(16, 2, 'Shield of Condemnation', NULL),
(16, 3, 'Sartura''s Might', NULL),
(16, 4, 'Noth''s Frigid Heart', NULL),
(16, 5, 'Wormscale Blocker', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 7 AND `spec` = 2 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 7, 2, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 64) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 64) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 7 AND `spec` IN (2) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
