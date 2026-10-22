-- mod-playerbots-bis : les jetons de Naxxramas deviennent reclamables.
--
-- LE MEME PROBLEME QU'A ZUL'GURUB ET A AHN'QIRAJ
-- ----------------------------------------------
-- Les listes nomment la piece FINIE - "Plagueheart Robe", "Bonescythe
-- Helmet", "Cryptstalker Legguards" - parce que c'est elle que la page classe.
-- Le jeton qui l'achete porte un AUTRE identifiant et n'est dans aucune liste.
-- Quand il tombe, le module cherche son identifiant dans playerbots_bis_item,
-- ne le trouve pas, et aucun bot ne le reclame : il part au premier venu alors
-- qu'il vaut une piece de rang 1.
--
-- Les fichiers 56 et 75 ont resolu ca pour Zul'Gurub et Ahn'Qiraj. Celui-ci
-- fait la meme chose pour Naxxramas, avec les deux memes moities :
--
--   1. des lignes dans playerbots_bis_item, pour que le bot RECLAME le jeton
--      (BisPriorityMgr::WantsQuestToken, utilise par BisLootRollAction)
--   2. des lignes dans playerbots_bis_quest_token, pour qu'il le CONVERTISSE
--      des qu'il le tient (BisEquipUpgradesAction::ConvertQuestTokens)
--
-- Aucun code n'est ajoute : les deux mecanismes existent et sont generiques.
-- Ce fichier n'apporte que des donnees.
--
-- CE QUE CELUI-CI FAIT MIEUX QUE LE 75
-- ------------------------------------
-- Le fichier 75 ecrit les DIX NOMS DE JETON a la main, parce que les jetons
-- d'Ahn'Qiraj n'ont aucun nom commun - "Carapace of the Old God" et "Qiraji
-- Bindings of Command" n'ont rien qui les relie.
--
-- Les jetons de Naxxramas, eux, partagent tous un prefixe : ils s'appellent
-- "Desecrated <creneau>". La liste n'est donc PAS ecrite ici - elle est lue.
-- Un jeton ajoute a la base entre tout seul ; aucun nom ne peut etre mal
-- orthographie, puisqu'aucun n'est ecrit.
--
-- LA REGLE RESTE CELLE DU 75 : un jeton herite EXACTEMENT des creneau, palier,
-- spe et rang de la piece qu'il achete, la ou cette piece est deja listee. Pas
-- de piece listee, pas de jeton.
--
-- POURQUOI LES AUTRES COMPOSANTS DE LA QUETE NE GENENT PAS
-- --------------------------------------------------------
-- Une quete de tier 3 exige le jeton ET des materiaux. Ca ne change rien ici,
-- pour une raison simple : le module ne FAIT PAS la quete. ConvertQuestTokens
-- detruit le jeton et donne les pieces directement, parce qu'un bot ne va pas
-- en ville voir un pnj. Les materiaux ne sont donc jamais demandes.
--
-- C'est aussi ce qui distingue ce fichier du 77 : les scarabes qirajis
-- coutent PLUSIEURS jetons a la fois pour une seule piece, et la conversion
-- "un jeton, ses pieces" ne s'y applique pas.
--
-- POURQUOI AUCUN BOT N'ESSAIERA DE L'EQUIPER
-- ------------------------------------------
-- BisEquipAction.cpp ecarte tout ce qui n'est ni ITEM_CLASS_WEAPON ni
-- ITEM_CLASS_ARMOR. Un jeton est un objet de quete : il entre dans la logique
-- de reclamation et de conversion, jamais dans celle d'equipement.
--
-- REJOUABLE : les lignes posees par ce fichier partent avant d'etre reposees.

-- ---------------------------------------------------------------------
-- 1. Les jetons, lus et non ecrits.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_jetons_t3_noms`;
CREATE TEMPORARY TABLE `bis_jetons_t3_noms` (
    `nom_jeton` VARCHAR(60) NOT NULL,
    PRIMARY KEY (`nom_jeton`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `bis_jetons_t3_noms` (`nom_jeton`)
SELECT `name` FROM `item_template` WHERE `name` LIKE 'Desecrated %';

-- ---------------------------------------------------------------------
-- 2. Le jeton et la piece qu'il achete, lus dans quest_template.
--
--    Les dix colonnes de recompense sont depliees par UNION ALL : une quete
--    de jeton rend soit une piece fixe, soit un CHOIX. Les deux doivent etre
--    lus, et NULLIF ecarte les emplacements vides - qui valent 0 et non NULL.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_jetons_t3`;
CREATE TEMPORARY TABLE `bis_jetons_t3` (
    `jeton`     INT UNSIGNED NOT NULL,
    `nom_jeton` VARCHAR(60)  NOT NULL,
    `piece`     INT UNSIGNED NOT NULL,
    PRIMARY KEY (`jeton`, `piece`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `bis_jetons_t3` (`jeton`, `nom_jeton`, `piece`)
SELECT j.`entry`, j.`name`, r.`piece`
FROM `bis_jetons_t3_noms` n
JOIN `item_template` j
  ON j.`name` COLLATE utf8mb4_general_ci = n.`nom_jeton` COLLATE utf8mb4_general_ci
JOIN `quest_template` q
  ON j.`entry` IN (q.`RequiredItemId1`, q.`RequiredItemId2`, q.`RequiredItemId3`,
                   q.`RequiredItemId4`, q.`RequiredItemId5`, q.`RequiredItemId6`)
JOIN (
    SELECT `ID` AS quete, NULLIF(`RewardItem1`, 0)         AS piece FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardItem2`, 0)         FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardItem3`, 0)         FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardItem4`, 0)         FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID1`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID2`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID3`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID4`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID5`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID6`, 0) FROM `quest_template`
) r ON r.`quete` = q.`ID` AND r.`piece` IS NOT NULL;

-- ---------------------------------------------------------------------
-- 3. Les lignes de liste que les jetons vont copier, FIGEES d'abord.
--
--    On lit avant d'ecrire : playerbots_bis_item est a la fois la source du
--    creneau et la cible des lignes de jeton.
--
--    PALIER 70 UNIQUEMENT. Une piece de Naxxramas peut figurer dans d'autres
--    paliers ; sans ce filtre, le jeton s'y poserait aussi et serait reclame
--    dans un raid ou il ne tombe pas.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_listes_t3`;
CREATE TEMPORARY TABLE `bis_listes_t3` (
    `item_id` INT UNSIGNED NOT NULL,
    `class`   TINYINT UNSIGNED NOT NULL,
    `spec`    TINYINT UNSIGNED NOT NULL,
    `slot`    TINYINT UNSIGNED NOT NULL,
    `tier_id` SMALLINT UNSIGNED NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`item_id`, `class`, `spec`, `slot`, `tier_id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `bis_listes_t3` (`item_id`, `class`, `spec`, `slot`, `tier_id`, `rank`)
SELECT b.`item_id`, b.`class`, b.`spec`, b.`slot`, b.`tier_id`, b.`rank`
FROM `playerbots_bis_item` b
JOIN `bis_jetons_t3` j ON j.`piece` = b.`item_id`
WHERE b.`tier_id` = 70;

-- ---------------------------------------------------------------------
-- 4. PREMIERE MOITIE : le bot reclame le jeton.
-- ---------------------------------------------------------------------
DELETE FROM `playerbots_bis_item`
WHERE `tier_id` = 70
  AND `item_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_t3`);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT b.`class`, b.`spec`, b.`slot`, 0, b.`tier_id`, j.`jeton`, b.`rank`,
       CONCAT('jeton ', j.`nom_jeton`, ' -> ', i.`name`)
FROM `bis_jetons_t3` j
JOIN `bis_listes_t3` b ON b.`item_id` = j.`piece`
JOIN `item_template` i ON i.`entry` = j.`piece`;

-- ---------------------------------------------------------------------
-- 5. SECONDE MOITIE : le bot convertit le jeton des qu'il le tient.
--
--    La table et sa cle sont creees par les fichiers 56 et 75 ; ce CREATE IF
--    NOT EXISTS la repete a l'identique pour que ce fichier reste jouable
--    seul. La migration de cle vit dans le 75 et n'est pas reprise : jouer le
--    75 avant celui-ci est de toute facon l'ordre des numeros.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `playerbots_bis_quest_token` (
    `token_id` INT UNSIGNED NOT NULL COMMENT 'objet de quete tenu par le bot',
    `class`    TINYINT UNSIGNED NOT NULL COMMENT 'classe du bot',
    `spec`     TINYINT UNSIGNED NOT NULL COMMENT 'spe du bot - 10 = ours druide',
    `piece_id` INT UNSIGNED NOT NULL COMMENT 'piece que le jeton achete',
    `comment`  VARCHAR(120) NOT NULL DEFAULT '',
    PRIMARY KEY (`token_id`, `class`, `spec`, `piece_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='mod-playerbots-bis : jeton de quete -> pieces, par classe et par spe';

DELETE FROM `playerbots_bis_quest_token`
WHERE `token_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_t3`);

-- TOUTES LES PIECES QUE LE JETON OUVRE, PLUS UNE SEULE. Le bot ne garde que ce
-- qui lui manque - ConvertQuestTokens ecarte ce qu'il porte deja - et il
-- continue de reclamer le jeton tant qu'une seule des pieces lui fait defaut.
--
-- L'ORDRE COMPTE : les pieces sont rangees par rang, la meilleure d'abord.
-- WantsQuestToken rend le palier de la premiere qui manque.
INSERT IGNORE INTO `playerbots_bis_quest_token` (`token_id`, `class`, `spec`, `piece_id`, `comment`)
SELECT j.`jeton`, b.`class`, b.`spec`, j.`piece`,
       CONCAT(t.`name`, ' -> ', i.`name`)
FROM `bis_jetons_t3` j
JOIN `bis_listes_t3` b ON b.`item_id` = j.`piece`
JOIN `item_template` i ON i.`entry` = j.`piece`
JOIN `item_template` t ON t.`entry` = j.`jeton`
ORDER BY j.`jeton`, b.`class`, b.`spec`, b.`rank`, j.`piece`;

-- ---------------------------------------------------------------------
-- VERIFICATIONS
-- ---------------------------------------------------------------------

-- 1 - LE PREFIXE N'A RIEN TROUVE (aucune ligne = bon).
--
--     C'est le seul risque de ce fichier : la liste de jetons etant LUE, un
--     prefixe qui ne correspond a rien ne produit aucune erreur - il produit
--     le silence, et le fichier s'importe "avec succes" sans rien faire.
--
--     Trois colonnes, et l'alias nom_non_resolu : importer_tout.ps1 repere les
--     noms perdus par CE libelle et lit le nom dans le TROISIEME champ. Un
--     alias different, ou deux colonnes, rendraient ce garde-fou muet dans le
--     bilan d'import.
SELECT 'jeton' AS `objet`, 70 AS `palier`,
       'aucun objet nomme "Desecrated ..." dans item_template' AS nom_non_resolu
FROM DUAL
WHERE (SELECT COUNT(*) FROM `bis_jetons_t3_noms`) = 0;

-- 2 - un jeton que la base connait mais dont AUCUNE quete ne depend : il ne
--     s'echange contre rien, donc il ne sera pas pose (aucune ligne = bon).
SELECT j.`name` AS jeton_sans_quete
FROM `bis_jetons_t3_noms` n
JOIN `item_template` j
  ON j.`name` COLLATE utf8mb4_general_ci = n.`nom_jeton` COLLATE utf8mb4_general_ci
LEFT JOIN `bis_jetons_t3` p ON p.`jeton` = j.`entry`
WHERE p.`jeton` IS NULL
ORDER BY j.`name`;

-- 3 - les jetons effectivement poses, et ce qu'ils rapportent.
SELECT b.`tier_id`, b.`class`, b.`spec`, b.`slot`, b.`rank`, b.`comment`
FROM `playerbots_bis_item` b
WHERE b.`item_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_t3`)
ORDER BY b.`comment`, b.`class`, b.`spec`;

-- 4 - un jeton reclamable DOIT avoir sa conversion, sinon le bot le gagne et
--     ne peut rien en faire (aucune ligne = bon). C'est la verification qui
--     compte le plus : les deux moities de ce fichier doivent se repondre.
SELECT DISTINCT b.`item_id` AS jeton_sans_conversion, b.`class`, b.`comment`
FROM `playerbots_bis_item` b
LEFT JOIN `playerbots_bis_quest_token` t
  ON t.`token_id` = b.`item_id` AND t.`class` = b.`class` AND t.`spec` = b.`spec`
WHERE b.`item_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_t3`)
  AND t.`piece_id` IS NULL
ORDER BY b.`item_id`, b.`class`;

-- 5 - une piece achetable par un jeton qu'aucune liste ne classe : son jeton
--     ne sera pas reclame. Ce n'est pas une anomalie, c'est la regle du
--     fichier - mais autant savoir lesquelles.
SELECT j.`nom_jeton`, i.`name` AS piece_absente_des_listes
FROM `bis_jetons_t3` j
JOIN `item_template` i ON i.`entry` = j.`piece`
LEFT JOIN `bis_listes_t3` b ON b.`item_id` = j.`piece`
WHERE b.`item_id` IS NULL
ORDER BY j.`nom_jeton`, i.`name`;

DROP TEMPORARY TABLE IF EXISTS `bis_listes_t3`;
DROP TEMPORARY TABLE IF EXISTS `bis_jetons_t3`;
DROP TEMPORARY TABLE IF EXISTS `bis_jetons_t3_noms`;
