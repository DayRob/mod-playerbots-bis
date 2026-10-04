-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P2 BWL (icy-veins). Classe 11, spe 2, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Stormrage Cover'),
( 0, 2, 'Crystal Adorned Crown'),
( 0, 3, 'Mish''undare, Circlet of the Mind Flayer'),
( 0, 3, 'Supreme Crown of Healing'),
( 0, 3, 'Insightful Hood'),
( 0, 3, 'Cassandra''s Grace'),
( 1, 1, 'Animated Chain Necklace'),
( 1, 2, 'Choker of the Fire Lord'),
( 1, 3, 'Choker of Enlightenment'),
( 1, 3, 'Beads of Ogre Mojo'),
( 1, 3, 'Tempest Talisman'),
( 2, 1, 'Wild Growth Spaulders'),
( 2, 2, 'Stormrage Pauldrons'),
( 2, 3, 'Mantle of the Blackwing Cabal'),
( 2, 3, 'Living Shoulders'),
( 2, 3, 'Burial Shawl'),
( 2, 3, 'Cyclone Spaulders'),
(14, 1, 'Hide of the Wild'),
(14, 2, 'Shroud of Pure Thought'),
(14, 3, 'Drape of Benediction'),
(14, 3, 'Master''s Cloak of Healing'),
(14, 3, 'Cloak of the Cosmos'),
( 4, 1, 'Robes of the Exalted'),
( 4, 2, 'Stormrage Chestguard'),
( 4, 3, 'Forest''s Embrace'),
( 4, 3, 'Robe of Volatile Power'),
( 4, 3, 'Cenarion Vestments'),
( 4, 3, 'Living Breastplate'),
( 8, 1, 'Stormrage Bracers'),
( 8, 2, 'Adventurer''s Bracers of Healing'),
( 8, 3, 'Bracers of Prosperity'),
( 8, 3, 'Bleak Howler Armguards'),
( 8, 3, 'Sublime Wristguards'),
( 9, 1, 'Stormrage Handguards'),
( 9, 2, 'Adventurer''s Gloves of Healing'),
( 9, 3, 'Hands of the Exalted Herald'),
( 9, 3, 'Gloves of Restoration'),
( 9, 3, 'Hands of Power'),
( 9, 3, 'Cenarion Gloves'),
( 5, 1, 'Sash of Mercy'),
( 5, 2, 'Adventurer''s Belt of Healing'),
( 5, 3, 'Eyestalk Cord'),
( 5, 3, 'Mana Igniting Cord'),
( 5, 3, 'Stormrage Belt'),
( 6, 1, 'Empowered Leggings'),
( 6, 2, 'Salamander Scale Pants'),
( 6, 3, 'Stormrage Legguards'),
( 6, 3, 'Padre''s Trousers'),
( 6, 3, 'Adventurer''s Legguards of Healing'),
( 6, 3, 'Cenarion Leggings'),
( 7, 1, 'Boots of Pure Thought'),
( 7, 2, 'Stormrage Boots'),
( 7, 3, 'Snowblind Shoes'),
( 7, 3, 'Verdant Footpads'),
( 7, 3, 'Cenarion Boots'),
( 7, 3, 'Boots of the Full Moon'),
(10, 1, 'Pure Elementium Band'),
(10, 2, 'Cauterizing Band'),
(10, 3, 'Fordring''s Seal'),
(10, 3, 'Rosewine Circle'),
(10, 3, 'Ring of Spell Power'),
(12, 1, 'Rejuvenating Gem'),
(12, 2, 'Royal Seal of Eldre''Thalas'),
(12, 3, 'Briarwood Reed'),
(12, 3, 'Talisman of Ephemeral Power'),
(12, 3, 'Second Wind'),
(12, 3, 'Eye of the Beast'),
(15, 1, 'Lok''amir il Romathis'),
(15, 2, 'Staff of the Shadow Flame'),
(15, 3, 'Claw of Chromaggus'),
(15, 3, 'Fang of the Mystics'),
(15, 3, 'Aurastone Hammer'),
(15, 3, 'Shadow Wing Focus Staff'),
(16, 1, 'Brightly Glowing Stone'),
(16, 2, 'Eternal Rod of Healing'),
(16, 3, 'Thaurissan''s Royal Scepter');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 11 AND `spec` = 2 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 2, s.`slot`, 0, 30, r.entry, s.`rank`,
       CONCAT('Vanilla P2 BWL (icy-veins) - ', s.`item_name`)
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
WHERE `class` = 11 AND `spec` IN (2) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
