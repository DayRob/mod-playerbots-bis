-- mod-playerbots-bis : palier 10 - Guerrier Protection (1/2), les REPLIS.
--
-- Source : la liste wowtbc.gg "Fury Protection Warrior", dont les menus
-- deroulants proposent plusieurs objets par creneau. Les rangs 1 de cette page
-- sont deja tous dans 07_vanilla_preraid_warrior_prot.sql ; seules les
-- alternatives manquaient. Ce fichier les ajoute en RANG 3.
--
-- A QUOI SERT UN REPLI. La cible d'un creneau est la meilleure piece
-- atteignable, et c'est elle que la fenetre d'etat compte. Un repli ne change
-- donc aucun ratio. Il sert quand le bot n'a pas la cible : au lieu de ne rien
-- convoiter du tout, il reclame et equipe ce qui vient. Plus la liste d'un
-- creneau est fournie, moins un bot reste les mains vides.
--
-- RANG 3 ET PAS MIEUX : ce sont les choix de repli du guide, pas ses
-- recommandations. Les mettre au-dessus de ce que 07 classe deja ferait
-- regresser des bots correctement equipes.
--
-- INSERT IGNORE : une ligne deja presente n'est jamais remplacee. Le fichier
-- est rejouable et ne peut pas abimer le travail de 07.
--
-- CE QUI EST ECARTE, ET POURQUOI
--
-- Les armes de main gauche. La page est celle d'un tank qui prend des talents
-- Fureur, et elle propose Dal'Rend's Tribal Guardian en main gauche. Le
-- creneau 16 est celui du BOUCLIER pour cette spe - c'est la regle posee par
-- 07 - et y mettre une epee ferait lacher le bouclier a un tank. Dal'Rend's
-- Sacred Charge reste, en main droite.
--
-- A passer apres 03, 04 et 07.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_prot_replis`;
CREATE TEMPORARY TABLE `bis_seed_prot_replis` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 3,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_prot_replis` (`slot`, `faction`, `rank`, `item_name`) VALUES
-- tete
( 0, 0, 3, 'Mask of the Unforgiven'),
( 0, 0, 3, 'Eye of Rend'),
( 0, 0, 3, 'Ragefury Eyepatch'),
-- cou
( 1, 0, 3, 'Imperial Jewel'),
( 1, 2, 3, 'Conqueror''s Medallion'),
( 1, 0, 3, 'Skibi''s Pendant'),
-- epaules
( 2, 0, 3, 'Truestrike Shoulders'),
( 2, 0, 3, 'Wyrmhide Spaulders'),
( 2, 0, 3, 'Black Dragonscale Shoulders'),
( 2, 1, 3, 'Clouddrift Mantle'),
-- dos
(14, 0, 3, 'Cape of the Black Baron'),
(14, 0, 3, 'Blackveil Cape'),
-- torse
( 4, 0, 3, 'Cadaverous Armor'),
( 4, 0, 3, 'Breastplate of Bloodthirst'),
( 4, 0, 3, 'Tombstone Breastplate'),
( 4, 0, 3, 'Deathdealer Breastplate'),
-- taille
( 5, 0, 3, 'Girdle of Beastial Fury'),
( 5, 0, 3, 'Chiselbrand Girdle'),
( 5, 0, 3, 'Cloudrunner Girdle'),
-- jambes
( 6, 0, 3, 'Cloudkeeper Legplates'),
( 6, 0, 3, 'Plaguehound Leggings'),
-- pieds
( 7, 0, 3, 'Windreaver Greaves'),
( 7, 0, 3, 'Battlechaser''s Greaves'),
( 7, 0, 3, 'Pads of the Dread Wolf'),
-- bijou
(12, 2, 3, 'Mark of Tyranny'),
-- bouclier
(16, 0, 3, 'Intricately Runed Shield'),
(16, 0, 3, 'Avalanchion''s Stony Hide'),
-- main droite
(15, 0, 3, 'Dark Iron Destroyer'),
(15, 0, 3, 'Iceblade Hacker'),
(15, 0, 3, 'Dal''Rend''s Sacred Charge'),
(15, 0, 3, 'Teebu''s Blazing Longsword'),
(15, 0, 3, 'Krol Blade'),
-- distance
(17, 0, 3, 'Riphook'),
(17, 0, 3, 'Skull Splitting Crossbow'),
(17, 0, 3, 'Stinging Bow');

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 2, s.`slot`, s.`faction`, 10, r.entry, s.`rank`,
       CONCAT('Vanilla Pre-Raid (repli) - ', s.`item_name`)
FROM `bis_seed_prot_replis` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
-- ---------------------------------------------------------------------
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_prot_replis` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE r.entry IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - le creneau par creneau du guerrier Protection au pre-raid.
-- ---------------------------------------------------------------------
SELECT `slot`, `rank`, COUNT(*) AS objets
FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 2 AND `tier_id` = 10
GROUP BY `slot`, `rank` ORDER BY `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_prot_replis`;
