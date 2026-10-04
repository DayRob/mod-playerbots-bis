-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P2 BWL (icy-veins). Classe 8, spe 0, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Mish''undare, Circlet of the Mind Flayer'),
( 0, 2, 'Eternal Crown of Frozen Wrath'),
( 0, 3, 'Netherwind Crown'),
( 0, 3, 'Arcanist Crown'),
( 0, 3, 'Crimson Felt Hat'),
( 1, 1, 'Choker of the Fire Lord'),
( 1, 2, 'Diana''s Pearl Necklace'),
( 1, 3, 'Choker of Enlightenment'),
( 1, 3, 'Beads of Ogre Mojo'),
( 1, 3, 'Star of Mystaria'),
( 1, 3, 'Tempest Talisman'),
( 2, 1, 'Mantle of the Blackwing Cabal'),
( 2, 2, 'Boreal Mantle'),
( 2, 3, 'Eternal Spaulders of Frozen Wrath'),
( 2, 3, 'Burial Shawl'),
( 2, 3, 'Arcanist Mantle'),
(14, 1, 'Cloak of the Brood Lord'),
(14, 2, 'Master''s Cloak of Frozen Wrath'),
(14, 3, 'Amplifying Cloak'),
(14, 3, 'Sapphiron Drape'),
(14, 3, 'Spritecaster Cape'),
( 4, 1, 'Robe of the Archmage'),
( 4, 2, 'Netherwind Robes'),
( 4, 3, 'Robe of Volatile Power'),
( 4, 3, 'Freezing Lich Robes'),
( 4, 3, 'Robe of Winter Night'),
( 4, 3, 'Eternal Chestguard of Frozen Wrath'),
( 8, 1, 'Bracers of Arcane Accuracy'),
( 8, 2, 'Master''s Bracers of Frozen Wrath'),
( 8, 3, 'Arcanist Bindings'),
( 8, 3, 'Sublime Wristguards'),
( 8, 3, 'Blacklight Bracer'),
( 9, 1, 'Netherwind Gloves'),
( 9, 2, 'Hands of Power'),
( 9, 3, 'Earth Warder''s Gloves'),
( 9, 3, 'Frostweave Gloves'),
( 9, 3, 'Gloves of Spell Mastery'),
( 5, 1, 'Mana Igniting Cord'),
( 5, 2, 'Firemaw''s Clutch'),
( 5, 3, 'Netherwind Belt'),
( 5, 3, 'Angelista''s Grasp'),
( 5, 3, 'Ban''thok Sash'),
( 6, 1, 'Netherwind Pants'),
( 6, 2, 'Skyshroud Leggings'),
( 6, 3, 'Arcanist Leggings'),
( 7, 1, 'Ringo''s Blizzard Boots'),
( 7, 2, 'Master''s Boots of Frozen Wrath'),
( 7, 3, 'Snowblind Shoes'),
( 7, 3, 'Omnicast Boots'),
( 7, 3, 'Arcanist Boots'),
(10, 1, 'Band of Forced Concentration'),
(10, 2, 'Ring of Spell Power'),
(10, 3, 'Freezing Band'),
(10, 3, 'Maiden''s Circle'),
(10, 3, 'Eye of Orgrimmar'),
(10, 3, 'Frigid Ring'),
(12, 1, 'Neltharion''s Tear'),
(12, 2, 'Mind Quickening Gem'),
(12, 3, 'Talisman of Ephemeral Power'),
(12, 3, 'Briarwood Reed'),
(12, 3, 'Eye of the Beast'),
(12, 3, 'Burst of Knowledge'),
(15, 1, 'Staff of the Shadow Flame'),
(15, 2, 'Claw of Chromaggus'),
(15, 3, 'Azuresong Mageblade'),
(15, 3, 'Fang of the Mystics'),
(15, 3, 'Sorcerous Dagger'),
(15, 3, 'Staff of Dominance'),
(16, 1, 'Master Dragonslayer''s Orb'),
(16, 2, 'Eternal Rod of Frozen Wrath'),
(16, 3, 'Spirit of Aquementas'),
(16, 3, 'Fire Runed Grimoire'),
(17, 1, 'Cold Snap'),
(17, 2, 'Lunar Wand of Frozen Wrath'),
(17, 3, 'Bonecreeper Stylus'),
(17, 3, 'Freezing Shard'),
(17, 3, 'Icefury Wand');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 8 AND `spec` = 0 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 8, 0, s.`slot`, 0, 30, r.entry, s.`rank`,
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
WHERE `class` = 8 AND `spec` IN (0) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
