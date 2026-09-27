-- mod-playerbots-bis : palier 10 (Vanilla Pre-Raid) - Pretre Ombre (5/2).
--
-- PORTEE : cette combinaison SEULEMENT. 03_vanilla_preraid.sql donne deja des
-- listes a plusieurs rangs au pretre Discipline (5/0) et Sacre (5/1) ; seule
-- Ombre etait ecrasee par 04_vanilla_preraid_wowsims.sql.
--
-- IMPORTANT - ORDRE D'IMPORT : apres 03 ET 04.
--
-- Ce guide ne propose aucun objet PvP ni de reputation : la regle du projet
-- s'applique ici sans rien retirer.
--
-- Le set Tier 0.5 (Virtuous) vient de la longue chaine de quetes T0.5, hors de
-- portee d'un bot : il est classe 2, visible au depliage mais jamais compte
-- comme objectif.
--
-- Les objets d'artisanat sont gardes et peuvent etre rang 1 - Felcloth
-- Shoulders, Robe of Winter Night, Felcloth Gloves. Un bot ne monte pas un
-- metier, mais tu peux les fabriquer pour lui : le creneau reste rouge tant que
-- ce n'est pas fait, ce qui est une tache reelle, pas un blocage.
--
-- Les objets a suffixe aleatoire sont entres sous leur nom de base ; seuls ceux
-- que le guide met en avant sont repris, pas la longue traine de butin
-- aleatoire du monde.
--
-- "Nacreous Shell Necklace" est entre sous son nom WotLK, "Diana's Pearl
-- Necklace".
--
-- Les batons a deux mains sont en rang 3 : le guide dit lui-meme qu'ils sont
-- tous eclipses par la combinaison main droite + main gauche.
--
-- rank : 1 = premier choix, 2 = alternative, 3 = depannage.
-- faction : 0 = les deux, 1 = Alliance, 2 = Horde.
--
-- Source : guide Best-in-Slot Pre-Raid "Shadow Priest DPS" de Wowhead Classic.

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 5 AND `spec` = 2;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_spriest`;
CREATE TEMPORARY TABLE `bis_seed_spriest` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_spriest` (`slot`, `faction`, `rank`, `item_name`) VALUES
-- Tete (0)
( 0, 0, 1, 'Spellweaver''s Turban'),
( 0, 0, 2, 'Crimson Felt Hat'),
( 0, 0, 2, 'Felcloth Hood'),
( 0, 0, 2, 'Virtuous Crown'),
( 0, 0, 3, 'Green Lens'),
( 0, 0, 3, 'Dreamweave Circlet'),
( 0, 0, 3, 'Shadoweave Mask'),
( 0, 0, 3, 'Eternal Crown'),
-- Cou (1)
( 1, 0, 1, 'Diana''s Pearl Necklace'),
( 1, 0, 1, 'Dark Advisor''s Pendant'),
( 1, 0, 2, 'Chains of the Lich'),
( 1, 0, 2, 'Beads of Ogre Mojo'),
( 1, 0, 2, 'Tooth of Gnarr'),
( 1, 0, 3, 'Anastari Heirloom'),
( 1, 0, 3, 'Lady Maye''s Pendant'),
-- Epaules (2)
( 2, 0, 1, 'Felcloth Shoulders'),
( 2, 0, 2, 'Burial Shawl'),
( 2, 0, 2, 'Kentic Amice'),
( 2, 0, 2, 'Elder Wizard''s Mantle'),
( 2, 0, 2, 'Virtuous Mantle'),
( 2, 0, 3, 'Shadoweave Shoulders'),
( 2, 0, 3, 'Deadwalker Mantle'),
-- Torse (4)
( 4, 0, 1, 'Robe of Winter Night'),
( 4, 0, 2, 'Felcloth Robe'),
( 4, 0, 2, 'Robe of Everlasting Night'),
( 4, 0, 2, 'Virtuous Robe'),
( 4, 0, 3, 'Robe of the Magi'),
( 4, 0, 3, 'Shadoweave Robe'),
-- Ceinture (5)
( 5, 0, 1, 'Ban''thok Sash'),
( 5, 0, 2, 'Thuzadin Sash'),
( 5, 0, 2, 'Oddly Magical Belt'),
( 5, 0, 2, 'Clutch of Andros'),
( 5, 0, 2, 'Virtuous Belt'),
-- Jambes (6)
( 6, 0, 1, 'Leggings of Torment'),
( 6, 0, 2, 'Skyshroud Leggings'),
( 6, 0, 2, 'Spiritshroud Leggings'),
( 6, 0, 2, 'Felcloth Pants'),
( 6, 0, 2, 'Virtuous Skirt'),
-- Pieds (7)
( 7, 0, 1, 'Maleki''s Footwraps'),
( 7, 0, 2, 'Omnicast Boots'),
( 7, 0, 2, 'Dragonrider Boots'),
( 7, 0, 2, 'Virtuous Sandals'),
-- Poignets (8)
( 8, 0, 1, 'Sublime Wristguards'),
( 8, 0, 1, 'Flameweave Cuffs'),
( 8, 0, 2, 'Shadowy Bracers'),
( 8, 0, 2, 'Wyrmthalak''s Shackles'),
( 8, 0, 2, 'Virtuous Bracers'),
-- Mains (9)
( 9, 0, 1, 'Felcloth Gloves'),
( 9, 0, 2, 'Hands of Power'),
( 9, 0, 2, 'The Shadow''s Grasp'),
( 9, 0, 2, 'Gloves of Shadowy Mist'),
( 9, 0, 2, 'Earth Warder''s Gloves'),
( 9, 0, 2, 'Virtuous Gloves'),
( 9, 0, 3, 'Dreamweave Gloves'),
( 9, 0, 3, 'Shadoweave Gloves'),
-- Anneaux (10) - le module compare automatiquement avec l'emplacement 11
(10, 0, 1, 'Rune Band of Wizardry'),
(10, 0, 1, 'Maiden''s Circle'),
(10, 2, 1, 'Eye of Orgrimmar'),   -- Horde uniquement
(10, 1, 1, 'Songstone of Ironforge'),   -- Alliance uniquement
(10, 0, 2, 'Cyclopean Band'),
(10, 0, 3, 'Underworld Band'),
(10, 0, 3, 'Band of the Unicorn'),
-- Bijoux (12) - le module compare automatiquement avec l'emplacement 13
(12, 0, 1, 'Draconic Infused Emblem'),
(12, 0, 1, 'Briarwood Reed'),
(12, 0, 2, 'Mindtap Talisman'),
(12, 0, 2, 'Second Wind'),
(12, 0, 2, 'Burst of Knowledge'),
(12, 0, 2, 'Eye of the Beast'),
(12, 0, 2, 'Blessed Prayer Beads'),
(12, 1, 3, 'Shard of the Splithooves'),   -- Alliance uniquement
-- Dos (14)
(14, 0, 1, 'Archivist Cape'),
(14, 0, 2, 'Amplifying Cloak'),
(14, 0, 2, 'Spritecaster Cape'),
(14, 0, 3, 'Master''s Cloak'),
-- Main droite (15)
(15, 0, 1, 'Scepter of the Unholy'),
(15, 0, 2, 'Witchblade'),
(15, 0, 2, 'Mastersmith''s Hammer'),
(15, 0, 3, 'Lord Valthalak''s Staff of Command'),
(15, 0, 3, 'Staff of Balzaphon'),
(15, 0, 3, 'Staff of Jordan'),
(15, 0, 3, 'Zum''rah''s Vexing Cane'),
-- Main gauche (16)
(16, 0, 1, 'Drakestone'),
(16, 0, 2, 'Scepter of Interminable Focus'),
(16, 0, 2, 'Tome of the Lost'),
(16, 0, 2, 'Spirit of Aquementas'),
(16, 0, 3, 'Umbral Crystal'),
-- Distance (baguette)
(17, 0, 1, 'Skul''s Ghastly Touch'),
(17, 0, 2, 'Bonecreeper Stylus'),
(17, 0, 2, 'Ritssyn''s Wand of Bad Mojo'),
(17, 0, 2, 'Woestave'),
(17, 0, 3, 'Lethtendris''s Wand'),
(17, 0, 3, 'Lunar Wand');

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 5, 2, s.`slot`, s.`faction`, 10, r.entry, s.`rank`,
       CONCAT('Vanilla Pre-Raid - ', s.`item_name`)
FROM `bis_seed_spriest` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms non resolus.
-- ---------------------------------------------------------------------
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_spriest` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement.
-- ---------------------------------------------------------------------
SELECT s.`slot` AS emplacement_declare, it.`InventoryType` AS emplacement_reel,
       s.`item_name`
FROM `bis_seed_spriest` s
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

DROP TEMPORARY TABLE IF EXISTS `bis_seed_spriest`;
