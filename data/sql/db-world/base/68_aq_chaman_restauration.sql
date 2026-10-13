-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P5 AQ (wowtbc.gg). Classe 7, spe 2, palier 60.
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
( 0, 1, 'Stormcaller''s Diadem', NULL),
( 0, 2, 'Don Rigoberto''s Lost Hat', NULL),
( 0, 3, 'Deviate Growth Cap', NULL),
( 0, 3, 'Crystal Adorned Crown', NULL),
( 0, 3, 'Creeping Vine Helm', NULL),
( 0, 3, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 1, 1, 'Amulet of the Fallen God', NULL),
( 1, 2, 'Amulet of the Shifting Sands', NULL),
( 1, 3, 'Jin''do''s Evil Eye', NULL),
( 1, 3, 'Choker of the Fire Lord', NULL),
( 1, 3, 'Pendant of the Fallen Dragon', NULL),
( 1, 3, 'Animated Chain Necklace', NULL),
( 2, 1, 'Stormcaller''s Pauldrons', NULL),
( 2, 2, 'Wild Growth Spaulders', NULL),
( 2, 3, 'Ternary Mantle', NULL),
( 2, 3, 'Animist''s Spaulders', NULL),
( 2, 3, 'Mantle of Lost Hope', NULL),
( 2, 3, 'Earthfury Epaulets', NULL),
(14, 1, 'Cloak of Clarity', NULL),
(14, 2, 'Shroud of Pure Thought', NULL),
(14, 3, 'Hide of the Wild', NULL),
(14, 3, 'Drape of Benediction', NULL),
(14, 3, 'Cloak of the Brood Lord', NULL),
(14, 3, 'Hakkari Loa Cloak', NULL),
( 4, 1, 'Stormcaller''s Hauberk', NULL),
( 4, 2, 'Robes of the Guardian Saint', NULL),
( 4, 3, 'Robes of the Exalted', NULL),
( 4, 3, 'Red Dragonscale Breastplate', NULL),
( 4, 3, 'Jade Inlaid Vestments', NULL),
( 4, 3, 'Zandalar Augur''s Hauberk', NULL),
( 8, 1, 'Bracers of Ten Storms', NULL),
( 8, 2, 'Bracelets of Royal Redemption', NULL),
( 8, 3, 'Loomguard Armbraces', NULL),
( 8, 3, 'Zandalar Augur''s Bracers', NULL),
( 8, 3, 'Flarecore Wraps', NULL),
( 9, 1, 'Gauntlets of Ten Storms', NULL),
( 9, 2, 'Gloves of the Messiah', NULL),
( 9, 3, 'Wasphide Gauntlets', NULL),
( 9, 3, 'Gloves of Dark Wisdom', NULL),
( 9, 3, 'Harmonious Gauntlets', NULL),
( 9, 3, 'Gloves of Delusional Power', NULL),
( 5, 1, 'Belt of Ten Storms', NULL),
( 5, 2, 'Grasp of the Old God', NULL),
( 5, 3, 'Regenerating Belt of Vek''nilash', NULL),
( 5, 3, 'Firemaw''s Clutch', NULL),
( 5, 3, 'Sash of Mercy', NULL),
( 6, 1, 'Stormcaller''s Leggings', NULL),
( 6, 2, 'Empowered Leggings', NULL),
( 6, 3, 'Salamander Scale Pants', NULL),
( 6, 3, 'Padre''s Trousers', NULL),
( 6, 3, 'Leggings of Immersion', NULL),
( 6, 3, 'Leggings of the Demented Mind', NULL),
( 7, 1, 'Stormcaller''s Footguards', NULL),
( 7, 2, 'Boots of Pure Thought', NULL),
( 7, 3, 'Snowblind Shoes', NULL),
( 7, 3, 'Treads of the Wandering Nomad', NULL),
( 7, 3, 'Boots of Fright', NULL),
( 7, 3, 'Animist''s Boots', NULL),
(10, 1, 'Ring of the Martyr', NULL),
(10, 2, 'Pure Elementium Band', NULL),
(10, 3, 'Cauterizing Band', NULL),
(10, 3, 'Signet Ring of the Bronze Dragonflight', NULL),
(10, 3, 'Rosewine Circle', NULL),
(10, 3, 'Ring of Blackrock', NULL),
(12, 1, 'Rejuvenating Gem', NULL),
(12, 2, 'Hibernation Crystal', NULL),
(12, 3, 'Scarab Brooch', NULL),
(12, 3, 'Natural Alignment Crystal', NULL),
(12, 3, 'Draconic Infused Emblem', NULL),
(12, 3, 'Talisman of Ephemeral Power', NULL),
(15, 1, 'Scepter of the False Prophet', NULL),
(15, 2, 'Fang of Korialstrasz', NULL),
(15, 3, 'Blessed Qiraji Augur Staff', NULL),
(15, 3, 'Lok''amir il Romathis', NULL),
(15, 3, 'Claw of Chromaggus', NULL),
(15, 3, 'Fang of the Mystics', NULL),
(16, 1, 'Sartura''s Might', NULL),
(16, 2, 'Wormscale Blocker', NULL),
(16, 3, 'Red Dragonscale Protector', NULL),
(16, 3, 'Master Dragonslayer''s Orb', NULL),
(16, 3, 'Tome of Divine Right', NULL),
(17, 1, 'Totem of Sustaining', NULL);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 7, 2, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 7 AND `spec` IN (2) AND `tier_id` = 60
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
