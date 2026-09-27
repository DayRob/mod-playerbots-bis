-- mod-playerbots-bis : palier 10 (Vanilla Pre-Raid) - Druide Farouche chat (11/1).
--
-- PORTEE : la spe chat seulement. L'ours porte la sentinelle 10 du module et
-- garde sa liste de 03_vanilla_preraid.sql ; seule 11/1 etait ecrasee par
-- 04_vanilla_preraid_wowsims.sql.
--
-- IMPORTANT - ORDRE D'IMPORT : apres 03 ET 04.
--
-- Ce guide ecarte lui-meme le PvP, pour la raison exacte qui vaut ici : trop
-- long a obtenir pour la periode consideree. Les insignes de rang sont donc
-- absents, comme partout ailleurs dans le projet.
--
-- ABSENTS : les objets a suffixe aleatoire "of the Tiger", que le guide
-- propose en nombre comme alternatives. Un meme nom de base y couvre des
-- dizaines de suffixes, sans identifiant unique a pointer. Cela retire
-- l'essentiel des alternatives de plusieurs creneaux - ceinture et tete en
-- restent a un seul objet, ce qui reflete fidelement l'etat de l'offre.
--
-- SET BONUS IGNORE : le guide prefere Devilsaur aux mains et aux jambes pour
-- le bonus d'ensemble. Le module raisonne piece par piece et ne sait pas
-- evaluer un ensemble, donc le rang 1 revient a la piece la meilleure
-- individuellement - Slaghide Gauntlets et Plaguehound Leggings - et le cuir
-- Devilsaur passe en rang 2.
--
-- Gnomish Battle Chicken demande la specialisation gnome en ingenierie pour
-- etre UTILISE : classe 3, il ne sera jamais une cible.
--
-- rank : 1 = premier choix, 2 = alternative, 3 = depannage.
-- faction : 0 = les deux, 1 = Alliance, 2 = Horde.
--
-- Source : guide Best-in-Slot Pre-Raid "Feral Druid DPS" de Wowhead Classic.

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 11 AND `spec` = 1;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_feral`;
CREATE TEMPORARY TABLE `bis_seed_feral` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_feral` (`slot`, `faction`, `rank`, `item_name`) VALUES
-- Tete (0)
( 0, 0, 1, 'Wolfshead Helm'),
-- Cou (1)
( 1, 0, 1, 'Pendant of Celerity'),
( 1, 0, 2, 'Beads of Ogre Might'),
( 1, 0, 2, 'Mark of Fordring'),
-- Epaules (2)
( 2, 0, 1, 'Truestrike Shoulders'),
( 2, 0, 2, 'Dark Warder''s Pauldrons'),
( 2, 0, 2, 'Wyrmhide Spaulders'),
( 2, 0, 2, 'Flamescarred Shoulders'),
( 2, 1, 2, 'Clouddrift Mantle'),   -- Alliance uniquement
( 2, 0, 3, 'Wyrmtongue Shoulders'),
-- Torse (4)
( 4, 0, 1, 'Cadaverous Armor'),
( 4, 0, 2, 'Breastplate of Bloodthirst'),
( 4, 0, 2, 'Grizzled Pelt'),
( 4, 0, 2, 'Tombstone Breastplate'),
-- Ceinture (5)
( 5, 0, 1, 'Cloudrunner Girdle'),
-- Jambes (6)
( 6, 0, 1, 'Plaguehound Leggings'),
( 6, 0, 2, 'Devilsaur Leggings'),
( 6, 0, 2, 'Shadowcraft Pants'),
( 6, 0, 3, 'Traveler''s Leggings'),
-- Pieds (7)
( 7, 0, 1, 'Boots of Ferocity'),
( 7, 0, 2, 'Swiftwalker Boots'),
( 7, 0, 2, 'Mongoose Boots'),
( 7, 0, 2, 'Swiftfoot Treads'),
( 7, 0, 3, 'Sandstalker Ankleguards'),
-- Poignets (8)
( 8, 0, 1, 'Bracers of the Eclipse'),
( 8, 0, 1, 'Wristguards of Renown'),
( 8, 0, 2, 'Deepfury Bracers'),
( 8, 0, 2, 'Blackmist Armguards'),
-- Mains (9)
( 9, 0, 1, 'Slaghide Gauntlets'),
( 9, 0, 2, 'Devilsaur Gauntlets'),
-- Anneaux (10) - le module compare automatiquement avec l'emplacement 11
(10, 0, 1, 'Tarnished Elven Ring'),
(10, 0, 2, 'Blackstone Ring'),
(10, 0, 2, 'Magma Forged Band'),
(10, 0, 3, 'Drakeclaw Band'),
-- Bijoux (12) - le module compare automatiquement avec l'emplacement 13
(12, 0, 1, 'Blackhand''s Breadth'),
(12, 0, 1, 'Hand of Justice'),
(12, 2, 1, 'Rune of the Guard Captain'),   -- Horde uniquement
(12, 0, 2, 'Counterattack Lodestone'),
(12, 0, 2, 'Heart of Wyrmthalak'),
(12, 0, 2, 'Mark of Tyranny'),
(12, 0, 3, 'Glimmering Mithril Insignia'),
(12, 0, 3, 'Gnomish Battle Chicken'),
-- Dos (14)
(14, 0, 1, 'Cape of the Black Baron'),
(14, 0, 2, 'Blackveil Cape'),
(14, 0, 2, 'Shadow Prowler''s Cloak'),
(14, 0, 2, 'Shifting Cloak'),
(14, 0, 2, 'Shroud of Domination'),
-- Main droite (15)
(15, 0, 1, 'Manual Crowd Pummeler'),
(15, 0, 2, 'Bonecrusher'),
(15, 0, 3, 'Impervious Giant'),
-- Distance - idole (17)
(17, 0, 1, 'Idol of Brutality');

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 1, s.`slot`, s.`faction`, 10, r.entry, s.`rank`,
       CONCAT('Vanilla Pre-Raid - ', s.`item_name`)
FROM `bis_seed_feral` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms non resolus.
-- ---------------------------------------------------------------------
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_feral` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement.
-- ---------------------------------------------------------------------
SELECT s.`slot` AS emplacement_declare, it.`InventoryType` AS emplacement_reel,
       s.`item_name`
FROM `bis_seed_feral` s
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

DROP TEMPORARY TABLE IF EXISTS `bis_seed_feral`;
