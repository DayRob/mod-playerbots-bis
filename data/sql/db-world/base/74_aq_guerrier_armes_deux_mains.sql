-- mod-playerbots-bis : l'arme a deux mains du Guerrier Armes, palier 60 (AQ).
--
-- POURQUOI CE FICHIER EST SEPARE DU 57
-- ------------------------------------
-- Le fichier 57 fait le meme travail pour les paliers 30 et 40, et ce bloc
-- aurait sa place dedans. Il n'y est pas, pour une raison d'ORDRE D'IMPORT.
--
-- Le fichier 73 pose la liste d'Armes au palier 60, et comme tout fichier
-- genere il commence par effacer ce couple classe/spe/palier en entier :
--
--     DELETE FROM playerbots_bis_item
--     WHERE class = 1 AND spec = 0 AND tier_id = 60;
--
-- importer_tout.ps1 passe les fichiers dans l'ordre de leur numero. Un bloc
-- palier 60 ecrit dans le 57 serait donc pose, puis EFFACE par le 73 quelques
-- fichiers plus tard - sans un mot, puisque supprimer des lignes qui existent
-- n'est pas une erreur. D'ou ce fichier, numerote APRES le 73.
--
-- POURQUOI LE 73 N'A PAS DE CRENEAU 15 A LUI
-- ------------------------------------------
-- La page Arms de cette phase n'a pas ete relevee ; celle de Fury l'a ete, et
-- les deux spes portent la MEME armure. Le 73 est donc converti depuis la page
-- Fury - mais Fury se bat a deux armes a une main. Son creneau 15 ne vaut rien
-- pour Armes et son creneau 16 lui serait nuisible : les deux sont retires de
-- l'entree avant conversion. L'arme a deux mains arrive ici.
--
-- CE BLOC EST RESOLU PAR NOM, PAS PAR IDENTIFIANT
-- -----------------------------------------------
-- C'est la seule difference avec les paliers 30 et 40 du fichier 57, et elle
-- est volontaire : leurs identifiants viennent d'une requete passee sur la base
-- du serveur, celui-ci n'en a pas encore eu. Ecrire des identifiants de memoire
-- ferait reclamer au bot un objet qui n'est pas celui que je nomme. Un nom qui
-- ne se resout pas ne produit, lui, aucune ligne - et la verification en fin de
-- fichier le dit.
--
-- SUR QUOI LE CLASSEMENT REPOSE, ET CE QU'IL RESTE A VERIFIER
-- ----------------------------------------------------------
-- Meme critere que les paliers precedents : Frappe mortelle vit de la FORCE et
-- du DEGAT MAXIMUM, et la lenteur sert les coups blancs et Blessure profonde.
--
--   1. Dark Edge of Insanity                      AQ40, C'Thun
--   2. Ashkandi, Greatsword of the Brotherhood     BWL, Nefarian
--   3. The Untamed Blade                           BWL - gardee pour son proc de Force
--   4. Obsidian Edged Blade                        AQ40, butin de trash
--   5. Bonereaver's Edge                           MC, Ragnaros
--   6. Herald of Woe                               BWL - meilleure Force brute, sans proc
--   7. Drake Talon Cleaver                         BWL
--
-- Les paliers 30 et 40 ont ete classes sur les chiffres de la base. CELUI-CI
-- NE L'A PAS ETE : ses deux premieres places viennent des guides de la phase.
-- Ashkandi tient la tete d'Armes jusqu'a Ahn'Qiraj, Dark Edge of Insanity
-- passe devant en AQ40. Pour trancher sur la base plutot que sur un guide :
--
--   Get-Content tools\armes_deux_mains_palier_60.sql -Raw |
--     & $m -uacore -padmin acore_world --table
--
-- Si l'ordre de la requete contredit celui-ci, il faut corriger ce fichier.
--
-- Une liste de palier nomme ce qu'il y a de MIEUX a ce moment-la, pas ce qui
-- tombe dans ce raid-la : c'est pourquoi des armes de Blackwing Lair et de
-- Molten Core figurent dans une liste Ahn'Qiraj.

-- Rejouable, et sans toucher aux autres creneaux ni aux autres paliers.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 0 AND `slot` = 15 AND `tier_id` = 60;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_2h_aq`;
CREATE TEMPORARY TABLE `bis_seed_2h_aq` (
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_2h_aq` (`rank`, `item_name`) VALUES
(1, 'Dark Edge of Insanity'),
(2, 'Ashkandi, Greatsword of the Brotherhood'),
(3, 'The Untamed Blade'),
(4, 'Obsidian Edged Blade'),
(5, 'Bonereaver''s Edge'),
(6, 'Herald of Woe'),
(7, 'Drake Talon Cleaver');

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 0, 15, 0, 60, r.entry, s.`rank`, CONCAT('deduit des guides - ', s.`item_name`)
FROM `bis_seed_2h_aq` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- VERIFICATION 1 - un nom que la base ne connait pas (aucune ligne = bon).
--
-- TROIS COLONNES, ET CE N'EST PAS DECORATIF. importer_tout.ps1 ramasse les
-- noms perdus par la fonction Get-ColonneSignalee, qui s'arrete des qu'une
-- ligne n'a pas EXACTEMENT trois champs :
--
--     if ($champs.Count -ne 3) { break }
--
-- et lit le nom dans le TROISIEME. Une verification a deux colonnes defile a
-- l'ecran sans etre ramassee : le nom perdu ne remonte pas dans le bilan de
-- fin d'import, celui qu'on lit. C'est la meme classe de piege que l'alias
-- "nom_introuvable" du fichier 56 - un garde-fou correct, invisible.
SELECT 60 AS `palier`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_2h_aq` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE r.entry IS NULL;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_2h_aq`;

-- VERIFICATION 2 - ce que le creneau 15 d'Armes contient desormais, tous
-- paliers confondus : le 57 et ce fichier doivent s'y lire cote a cote.
SELECT b.`tier_id`, b.`rank`, i.`name`,
       ROUND(i.`delay` / 1000, 2) AS vitesse, i.`dmg_max1` AS degats_max
FROM `playerbots_bis_item` b
JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE b.`class` = 1 AND b.`spec` = 0 AND b.`slot` = 15
ORDER BY b.`tier_id`, b.`rank`;
