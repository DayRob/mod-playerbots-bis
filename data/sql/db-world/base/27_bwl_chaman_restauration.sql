-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P3 BWL (wowtbc.gg). Classe 7, spe 2, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Helmet of Ten Storms'),
( 0, 2, 'Crystal Adorned Crown'),
( 0, 3, 'Mish''undare, Circlet of the Mind Flayer'),
( 0, 3, 'Helm of the Lifegiver'),
( 0, 3, 'Earthfury Helmet'),
( 1, 1, 'Choker of the Fire Lord'),
( 1, 2, 'Pendant of the Fallen Dragon'),
( 1, 3, 'Animated Chain Necklace'),
( 1, 3, 'Choker of Enlightenment'),
( 1, 3, 'Beads of Ogre Mojo'),
( 2, 1, 'Wild Growth Spaulders'),
( 2, 2, 'Earthfury Epaulets'),
( 2, 3, 'Royal Cap Spaulders'),
( 2, 3, 'Living Shoulders'),
( 2, 3, 'Burial Shawl'),
(14, 1, 'Shroud of Pure Thought'),
(14, 2, 'Hide of the Wild'),
(14, 3, 'Drape of Benediction'),
(14, 3, 'Cloak of the Brood Lord'),
(14, 3, 'Cloak of the Cosmos'),
( 4, 1, 'Robes of the Exalted'),
( 4, 2, 'Red Dragonscale Breastplate'),
( 4, 3, 'Robe of Volatile Power'),
( 4, 3, 'Earthfury Vestments'),
( 4, 3, 'Breastplate of Ten Storms'),
( 4, 3, 'Chestplate of Tranquility'),
( 8, 1, 'Bracers of Ten Storms'),
( 8, 2, 'Loomguard Armbraces'),
( 8, 3, 'Flarecore Wraps'),
( 8, 3, 'Bracers of Prosperity'),
( 9, 1, 'Gauntlets of Ten Storms'),
( 9, 2, 'Harmonious Gauntlets'),
( 9, 3, 'Gloves of Restoration'),
( 9, 3, 'Hands of the Exalted Herald'),
( 9, 3, 'Hands of Power'),
( 9, 3, 'Greenleaf Handwraps'),
( 5, 1, 'Firemaw''s Clutch'),
( 5, 2, 'Sash of Mercy'),
( 5, 3, 'Belt of Ten Storms'),
( 5, 3, 'Eyestalk Cord'),
( 6, 1, 'Empowered Leggings'),
( 6, 2, 'Salamander Scale Pants'),
( 6, 3, 'Padre''s Trousers'),
( 6, 3, 'Ghoul Skin Leggings'),
( 6, 3, 'Legplates of Ten Storms'),
( 7, 1, 'Boots of Pure Thought'),
( 7, 2, 'Snowblind Shoes'),
( 7, 3, 'Verdant Footpads'),
( 7, 3, 'Boots of the Full Moon'),
( 7, 3, 'Merciful Greaves'),
(10, 1, 'Pure Elementium Band'),
(10, 2, 'Cauterizing Band'),
(10, 3, 'Rosewine Circle'),
(10, 3, 'Ring of Blackrock'),
(10, 3, 'Fordring''s Seal'),
(10, 3, 'Ring of Spell Power'),
(12, 1, 'Rejuvenating Gem'),
(12, 2, 'Natural Alignment Crystal'),
(12, 3, 'Talisman of Ephemeral Power'),
(12, 3, 'Shard of the Scale'),
(12, 3, 'Briarwood Reed'),
(12, 3, 'Second Wind'),
(15, 1, 'Lok''amir il Romathis'),
(15, 2, 'Claw of Chromaggus'),
(15, 3, 'Fang of the Mystics'),
(15, 3, 'Staff of the Shadow Flame'),
(15, 3, 'Aurastone Hammer'),
(15, 3, 'Sorcerous Dagger'),
(16, 1, 'Red Dragonscale Protector'),
(16, 2, 'Master Dragonslayer''s Orb'),
(16, 3, 'Brightly Glowing Stone'),
(16, 3, 'Thaurissan''s Royal Scepter');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 7 AND `spec` = 2 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 7, 2, s.`slot`, 0, 30, r.entry, s.`rank`,
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
WHERE `class` = 7 AND `spec` IN (2) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
