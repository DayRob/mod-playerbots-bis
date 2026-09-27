-- mod-playerbots-bis : palier 10 (Vanilla Pre-Raid) - Voleur Combat (4/1).
--
-- PORTEE : cette combinaison SEULEMENT. 03_vanilla_preraid.sql donne deja des
-- listes a plusieurs rangs au voleur Assassinat (4/0) et Finesse (4/2) ; seul
-- Combat est ecrase par 04_vanilla_preraid_wowsims.sql et retombe a un objet
-- par creneau. Ce fichier ne touche donc pas aux deux autres specialisations.
--
-- IMPORTANT - ORDRE D'IMPORT : apres 03 ET 04.
--
-- CLASSEMENT : le rang 1 doit rester atteignable par un bot, et ce guide en est
-- l'illustration la plus nette. Il construit tout autour du set Darkmantle, qui
-- vient de la chaine de quetes T0.5 - des heures de jeu et plusieurs centaines
-- de pieces d'or. Un bot ne la fera jamais. Le rang 1 revient donc au set
-- Tier 0 (Shadowcraft) et aux drops de donjon, qui tombent d'eux-memes ; le
-- Darkmantle et le cuir Devilsaur, qui demande le Travail du cuir tribal,
-- passent en rang 2.
--
-- Consequence assumee : le bot ne cherchera pas les bonus de set Darkmantle,
-- que le module ne sait de toute facon pas evaluer - il raisonne piece par
-- piece, pas par ensemble.
--
-- Les identifiants sont resolus par nom contre item_template a l'import.
--
-- rank : 1 = premier choix, 2 = alternative, 3 = depannage.
-- faction : 0 = les deux, 1 = Alliance, 2 = Horde.
--
-- Source : guide Best-in-Slot Pre-Raid "Rogue DPS" de Wowhead Classic.

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 4 AND `spec` = 1;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_rogue`;
CREATE TEMPORARY TABLE `bis_seed_rogue` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_rogue` (`slot`, `faction`, `rank`, `item_name`) VALUES
-- Tete (0)
( 0, 0, 1, 'Shadowcraft Cap'),
( 0, 0, 2, 'Darkmantle Cap'),
( 0, 0, 2, 'Mask of the Unforgiven'),
( 0, 0, 2, 'Eye of Rend'),
-- Cou (1)
( 1, 0, 1, 'Pendant of Celerity'),
( 1, 0, 2, 'Mark of Fordring'),
( 1, 0, 3, 'Beads of Ogre Might'),
-- Epaules (2)
( 2, 0, 1, 'Truestrike Shoulders'),
( 2, 0, 2, 'Shadowcraft Spaulders'),
( 2, 0, 2, 'Darkmantle Spaulders'),
( 2, 0, 3, 'Wyrmhide Spaulders'),
-- Torse (4)
( 4, 0, 1, 'Shadowcraft Tunic'),
( 4, 0, 2, 'Darkmantle Tunic'),
( 4, 0, 2, 'Cadaverous Armor'),
( 4, 0, 2, 'Traphook Jerkin'),
-- Ceinture (5)
( 5, 0, 1, 'Cloudrunner Girdle'),
( 5, 0, 2, 'Darkmantle Belt'),
( 5, 0, 2, 'Shadowcraft Belt'),
( 5, 0, 2, 'Mugger''s Belt'),
-- Jambes (6)
( 6, 0, 1, 'Shadowcraft Pants'),
( 6, 0, 2, 'Devilsaur Leggings'),
( 6, 0, 2, 'Darkmantle Pants'),
-- Pieds (7)
( 7, 0, 1, 'Swiftwalker Boots'),
( 7, 0, 2, 'Darkmantle Boots'),
( 7, 0, 2, 'Shadowcraft Boots'),
-- Poignets (8)
( 8, 0, 1, 'Bracers of the Eclipse'),
( 8, 0, 2, 'Darkmantle Bracers'),
( 8, 0, 2, 'Shadowcraft Bracers'),
( 8, 0, 3, 'Deepfury Bracers'),
-- Mains (9)
( 9, 0, 1, 'Shadowcraft Gloves'),
( 9, 0, 2, 'Devilsaur Gauntlets'),
( 9, 0, 2, 'Darkmantle Gloves'),
-- Anneaux (10) - le module compare automatiquement avec l'emplacement 11
(10, 0, 1, 'Tarnished Elven Ring'),
(10, 0, 2, 'Painweaver Band'),
(10, 0, 2, 'Blackstone Ring'),
-- Bijoux (12) - le module compare automatiquement avec l'emplacement 13
(12, 0, 1, 'Hand of Justice'),
(12, 0, 1, 'Blackhand''s Breadth'),
(12, 2, 2, 'Rune of the Guard Captain'),   -- Horde uniquement
(12, 0, 2, 'Royal Seal of Eldre''Thalas'),
-- Dos (14)
(14, 0, 1, 'Cape of the Black Baron'),
(14, 0, 2, 'Shadow Prowler''s Cloak'),
(14, 0, 2, 'Blackveil Cape'),
-- Main droite (15)
(15, 0, 1, 'Dal''Rend''s Sacred Charge'),
(15, 0, 2, 'Felstriker'),
(15, 0, 2, 'Heartseeker'),
(15, 0, 3, 'Sword of Zeal'),
-- Main gauche (16)
(16, 0, 1, 'Dal''Rend''s Tribal Guardian'),
(16, 0, 2, 'Distracting Dagger'),
(16, 0, 2, 'Mirah''s Song'),
(16, 0, 2, 'Bonescraper'),
-- Distance (17)
(17, 0, 1, 'Blackcrow'),
(17, 0, 2, 'Precisely Calibrated Boomstick'),
(17, 0, 2, 'Satyr''s Bow'),
(17, 0, 2, 'Ancient Bone Bow');

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 4, 1, s.`slot`, s.`faction`, 10, r.entry, s.`rank`,
       CONCAT('Vanilla Pre-Raid - ', s.`item_name`)
FROM `bis_seed_rogue` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms non resolus.
-- ---------------------------------------------------------------------
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_rogue` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement.
-- ---------------------------------------------------------------------
SELECT s.`slot` AS emplacement_declare, it.`InventoryType` AS emplacement_reel,
       s.`item_name`
FROM `bis_seed_rogue` s
JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE NOT (
       (s.`slot` =  0 AND it.`InventoryType` = 1)
    OR (s.`slot` =  1 AND it.`InventoryType` = 2)
    OR (s.`slot` =  2 AND it.`InventoryType` = 3)
    OR (s.`slot` =  4 AND it.`InventoryType` IN (5, 20))
    OR (s.`slot` =  5 AND it.`InventoryType` = 6)
    OR (s.`slot` =  6 AND it.`InventoryType` = 7)
    OR (s.`slot` =  7 AND it.`InventoryType` = 8)
    OR (s.`slot` =  8 AND it.`InventoryType` = 9)
    OR (s.`slot` =  9 AND it.`InventoryType` = 10)
    OR (s.`slot` IN (10, 11) AND it.`InventoryType` = 11)
    OR (s.`slot` IN (12, 13) AND it.`InventoryType` = 12)
    OR (s.`slot` = 14 AND it.`InventoryType` = 16)
    OR (s.`slot` = 15 AND it.`InventoryType` IN (13, 17, 21))
    OR (s.`slot` = 16 AND it.`InventoryType` IN (13, 14, 22, 23))
    OR (s.`slot` = 17 AND it.`InventoryType` IN (15, 25, 26, 28))
);

DROP TEMPORARY TABLE IF EXISTS `bis_seed_rogue`;
