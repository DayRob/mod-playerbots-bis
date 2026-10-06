-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P4 ZG (wowtbc.gg). Classe 1, spe 1, palier 40.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Lionheart Helm'),
( 0, 2, 'Lizardscale Eyepatch'),
( 0, 3, 'Crown of Destruction'),
( 0, 3, 'Helm of Endless Rage'),
( 0, 3, 'Eye of Rend'),
( 0, 3, 'Gurubashi Helm'),
( 1, 1, 'The Eye of Hakkar'),
( 1, 2, 'Onyxia Tooth Pendant'),
( 1, 3, 'Mark of Fordring'),
( 1, 3, 'Imperial Jewel'),
( 1, 3, 'Will of the Martyr'),
( 2, 1, 'Drake Talon Pauldrons'),
( 2, 2, 'Truestrike Shoulders'),
( 2, 3, 'Bloodsoaked Pauldrons'),
( 2, 3, 'Black Dragonscale Shoulders'),
(14, 1, 'Cloak of Draconic Might'),
(14, 2, 'Puissant Cape'),
(14, 3, 'Cloak of Firemaw'),
(14, 3, 'Cape of the Black Baron'),
(14, 3, 'Zulian Tigerhide Cloak'),
( 4, 1, 'Savage Gladiator Chain'),
( 4, 2, 'Malfurion''s Blessed Bulwark'),
( 4, 3, 'Cadaverous Armor'),
( 4, 3, 'Runed Bloodstained Hauberk'),
( 4, 3, 'Breastplate of Bloodthirst'),
( 4, 3, 'Tombstone Breastplate'),
( 8, 1, 'Wristguards of Stability'),
( 8, 2, 'Battleborn Armbraces'),
( 8, 3, 'Zandalar Vindicator''s Armguards'),
( 8, 3, 'Wristguards of True Flight'),
( 9, 1, 'Flameguard Gauntlets'),
( 9, 2, 'Edgemaster''s Handguards'),
( 9, 3, 'Sacrificial Gauntlets'),
( 9, 3, 'Gauntlets of Might'),
( 9, 3, 'Doomhide Gauntlets'),
( 5, 1, 'Onslaught Girdle'),
( 5, 2, 'Therazane''s Link'),
( 5, 3, 'Belt of Preserved Heads'),
( 5, 3, 'Taut Dragonhide Belt'),
( 5, 3, 'Belt of Shrunken Heads'),
( 6, 1, 'Legguards of the Fallen Crusader'),
( 6, 2, 'Dark Heart Pants'),
( 6, 3, 'Bloodsoaked Legplates'),
( 6, 3, 'Devilsaur Leggings'),
( 6, 3, 'Cloudkeeper Legplates'),
( 7, 1, 'Chromatic Boots'),
( 7, 2, 'Boots of the Shadow Flame'),
( 7, 3, 'Boots of Heroism'),
( 7, 3, 'Bloodmail Boots'),
( 7, 3, 'Battlechaser''s Greaves'),
(10, 1, 'Master Dragonslayer''s Ring'),
(10, 2, 'Quick Strike Ring'),
(10, 3, 'Band of Accuria'),
(10, 3, 'Circle of Applied Force'),
(10, 3, 'Blackstone Ring'),
(12, 1, 'Drake Fang Talisman'),
(12, 2, 'Diamond Flask'),
(12, 3, 'Hand of Justice'),
(12, 3, 'Blackhand''s Breadth'),
(12, 3, 'Rune of the Guard Captain'),
(12, 3, 'Counterattack Lodestone'),
(15, 1, 'Crul''shorukh, Edge of Chaos'),
(15, 2, 'Doom''s Edge'),
(15, 3, 'Deathbringer'),
(15, 3, 'Annihilator'),
(15, 3, 'Rivenspike'),
(16, 1, 'Doom''s Edge'),
(16, 2, 'Crul''shorukh, Edge of Chaos'),
(16, 3, 'Deathbringer'),
(16, 3, 'Bone Slicing Hatchet'),
(16, 3, 'Serathil'),
(15, 3, 'Chromatically Tempered Sword'),
(15, 3, 'Empyrean Demolisher'),
(15, 3, 'Vis''kag the Bloodletter'),
(15, 3, 'Maladath, Runed Blade of the Black Flight'),
(15, 3, 'Brutality Blade'),
(15, 3, 'Sword of Zeal'),
(16, 3, 'Maladath, Runed Blade of the Black Flight'),
(16, 3, 'Chromatically Tempered Sword'),
(16, 3, 'Brutality Blade'),
(16, 3, 'Vis''kag the Bloodletter'),
(16, 3, 'Dal''Rend''s Tribal Guardian'),
(17, 1, 'Striker''s Mark'),
(17, 2, 'Gurubashi Dwarf Destroyer'),
(17, 3, 'Heartstriker'),
(17, 3, 'Blackcrow'),
(17, 3, 'Satyr''s Bow');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 1 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 1, s.`slot`, 0, 40, r.entry, s.`rank`,
       CONCAT('Vanilla P4 ZG (wowtbc.gg) - ', s.`item_name`)
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
WHERE `class` = 1 AND `spec` IN (1) AND `tier_id` = 40
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
