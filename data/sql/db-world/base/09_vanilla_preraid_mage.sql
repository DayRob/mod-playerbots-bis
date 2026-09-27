-- mod-playerbots-bis : palier 10 (Vanilla Pre-Raid) - Mage (classe 8).
--
-- Complete 04_vanilla_preraid_wowsims.sql pour les trois specialisations, qui
-- n'avaient qu'un objet par creneau. Arcanes, Feu et Givre partagent la meme
-- liste : en pre-raid elles courent toutes apres puissance des sorts, critique
-- et toucher.
--
-- IMPORTANT - ORDRE D'IMPORT : apres 04.
--
-- CLASSEMENT : ce guide est le plus oriente PvP des quatre, et la regle du rang
-- 1 atteignable y redistribue beaucoup. Rang 10 d'honneur, exalte au Goulet des
-- Chanteguerres, au bassin d'Arathi ou a Alterac : un bot ne fera rien de tout
-- cela. Le set PvP de rang, que le guide donne en tete pour les jambes et les
-- pieds, passe donc en rang 2, et le rang 1 revient aux drops de donjon. Meme
-- chose pour la couture - Robe de l'archimage comprise, que le guide juge
-- pourtant imbattable : un bot ne monte pas un metier.
--
-- ABSENTS : rien. Les objets a suffixe aleatoire du guide ("... of Frozen
-- Wrath") sont entres sous leur NOM DE BASE - Archivist Cape, Flameweave Cuffs,
-- Master's Bracers... - qui existe bien dans item_template. Le bot visera donc
-- la piece sans exiger le bon suffixe, ce qui est le comportement voulu : un
-- suffixe median vaut mieux que rien.
--
-- "Nacreous Shell Necklace" du guide Classic s'appelle "Diana's Pearl Necklace"
-- en WotLK, et c'est ce nom-la qui est utilise ici.
--
-- Les baton a deux mains sont en rang 3 : le guide lui-meme dit qu'ils sont tous
-- battus par la combinaison main droite + main gauche.
--
-- rank : 1 = premier choix, 2 = alternative, 3 = depannage.
-- faction : 0 = les deux, 1 = Alliance, 2 = Horde.
--
-- Source : guide Best-in-Slot Pre-Raid "Mage DPS" de Wowhead Classic.

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 8 AND `spec` IN (0, 1, 2);

DROP TEMPORARY TABLE IF EXISTS `bis_seed_mage`;
CREATE TEMPORARY TABLE `bis_seed_mage` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_mage` (`slot`, `faction`, `rank`, `item_name`) VALUES
-- Tete (0)
( 0, 0, 1, 'Spellweaver''s Turban'),
( 0, 0, 2, 'Crimson Felt Hat'),
( 0, 0, 3, 'Eternal Crown'),
-- Cou (1)
( 1, 0, 1, 'Diana''s Pearl Necklace'),
( 1, 0, 2, 'Arcane Crystal Pendant'),
( 1, 0, 2, 'Star of Mystaria'),
-- Epaules (2)
( 2, 0, 1, 'Boreal Mantle'),
( 2, 0, 3, 'Eternal Spaulders'),
-- Torse (4)
( 4, 0, 1, 'Freezing Lich Robes'),
( 4, 0, 2, 'Robe of the Archmage'),
( 4, 0, 2, 'Robe of Everlasting Night'),
-- Ceinture (5)
( 5, 0, 1, 'Ban''thok Sash'),
( 5, 0, 2, 'Clutch of Andros'),
( 5, 0, 2, 'Thuzadin Sash'),
-- Jambes (6)
( 6, 0, 1, 'Skyshroud Leggings'),
( 6, 0, 2, 'Frostweave Pants'),
-- Pieds (7)
( 7, 0, 1, 'Omnicast Boots'),
( 7, 0, 1, 'Dragonrider Boots'),
( 7, 0, 3, 'Master''s Boots'),
-- Poignets (8)
( 8, 0, 1, 'Sublime Wristguards'),
( 8, 0, 2, 'Tearfall Bracers'),
( 8, 0, 2, 'Flameweave Cuffs'),
( 8, 0, 3, 'Master''s Bracers'),
-- Mains (9)
( 9, 0, 1, 'Hands of Power'),
( 9, 0, 2, 'Sorcerer''s Gloves'),
( 9, 0, 2, 'Earth Warder''s Gloves'),
( 9, 0, 2, 'Frostweave Gloves'),
-- Anneaux (10) - le module compare automatiquement avec l'emplacement 11
(10, 0, 1, 'Rune Band of Wizardry'),
(10, 0, 2, 'Freezing Band'),
(10, 2, 2, 'Eye of Orgrimmar'),   -- Horde uniquement
(10, 1, 2, 'Songstone of Ironforge'),   -- Alliance uniquement
(10, 0, 2, 'Maiden''s Circle'),
-- Bijoux (12) - le module compare automatiquement avec l'emplacement 13
(12, 0, 1, 'Briarwood Reed'),
(12, 0, 1, 'Draconic Infused Emblem'),
(12, 0, 2, 'Eye of the Beast'),
(12, 0, 2, 'Burst of Knowledge'),
-- Dos (14)
(14, 0, 1, 'Archivist Cape'),
(14, 0, 2, 'Amplifying Cloak'),
(14, 0, 3, 'Master''s Cloak'),
-- Main droite (15)
(15, 0, 1, 'Witchblade'),
(15, 0, 3, 'Bloodstrike Dagger'),
(15, 0, 3, 'Lord Valthalak''s Staff of Command'),
(15, 0, 3, 'Rod of the Ogre Magi'),
(15, 0, 3, 'Solstice Staff'),
-- Main gauche (16)
(16, 0, 1, 'Scepter of Interminable Focus'),
(16, 0, 2, 'Spirit of Aquementas'),
-- Distance (baguette)
(17, 0, 1, 'Bonecreeper Stylus'),
(17, 0, 2, 'Icefury Wand'),
(17, 0, 3, 'Lunar Wand');

-- Les trois specialisations partagent la liste.
DROP TEMPORARY TABLE IF EXISTS `bis_specs_mage`;
CREATE TEMPORARY TABLE `bis_specs_mage` (`spec` TINYINT UNSIGNED NOT NULL) ENGINE=MEMORY;
INSERT INTO `bis_specs_mage` (`spec`) VALUES (0), (1), (2);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 8, sp.`spec`, s.`slot`, s.`faction`, 10, r.entry, s.`rank`,
       CONCAT('Vanilla Pre-Raid - ', s.`item_name`)
FROM `bis_seed_mage` s
CROSS JOIN `bis_specs_mage` sp
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms non resolus.
-- ---------------------------------------------------------------------
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_mage` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement.
-- ---------------------------------------------------------------------
SELECT s.`slot` AS emplacement_declare, it.`InventoryType` AS emplacement_reel,
       s.`item_name`
FROM `bis_seed_mage` s
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

DROP TEMPORARY TABLE IF EXISTS `bis_seed_mage`;
DROP TEMPORARY TABLE IF EXISTS `bis_specs_mage`;
