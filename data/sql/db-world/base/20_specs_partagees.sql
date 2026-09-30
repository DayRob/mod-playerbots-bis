-- mod-playerbots-bis : aligne les spes qui visent le meme equipement.
--
--   Voleur Assassinat (4/0) et Subtilite (4/2) <- Voleur Combat (4/1)
--   Pretre Discipline (5/0)                    <- Pretre Sacre  (5/1)
--
-- En Vanilla les trois arbres de voleur cherchent le meme stuff DPS : WoWSims
-- lui-meme ne publie qu'un set de voleur par phase, comme pour le chasseur et
-- le mage. Et Discipline soigne avec l'equipement de Sacre. Laisser a ces spes
-- la liste issue de la conversion d'origine reviendrait a les envoyer sur des
-- objets moins bons que ceux que leur jumelle convoite.
--
-- PORTEE : tous les paliers, pas seulement Blackwing Lair.
--
-- CE FICHIER REMPLACE. Pour un palier ou la spe source a une liste, la liste de
-- la spe cible est effacee puis recopiee - c'est ce qui garantit que les deux
-- sont vraiment identiques. Un palier ou la source n'a rien n'est pas touche :
-- la cible y garde ce qu'elle avait.
--
-- Pour redonner plus tard une liste propre a une spe (un guide Assassinat par
-- exemple), retire sa ligne de la table bis_copie_spec ci-dessous, sinon le
-- prochain passage de ce fichier l'ecrasera.
--
-- Rejouable : deux passages donnent le meme resultat.
--
-- A passer APRES 18 et 19, et avant 17 lors d'un import a froid : les lignes
-- recopiees peuvent contenir du PvP ou de la reputation, que seul le fichier 17
-- sait reconnaitre.

-- ---------------------------------------------------------------------
-- Les couples source -> cible.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_copie_spec`;
CREATE TEMPORARY TABLE `bis_copie_spec` (
    `classe`      TINYINT UNSIGNED NOT NULL,
    `spec_source` TINYINT UNSIGNED NOT NULL,
    `spec_cible`  TINYINT UNSIGNED NOT NULL,
    `etiquette`   VARCHAR(32) NOT NULL,
    PRIMARY KEY (`classe`, `spec_cible`)
) ENGINE=MEMORY;

INSERT INTO `bis_copie_spec` (`classe`, `spec_source`, `spec_cible`, `etiquette`) VALUES
(4, 1, 0, 'set Combat'),
(4, 1, 2, 'set Combat'),
(5, 1, 0, 'set Sacre');

-- ---------------------------------------------------------------------
-- 1. La photo de ce qu'il faut poser.
--
-- On fige d'abord, on ecrit ensuite. Lire et ecrire playerbots_bis_item dans
-- une meme instruction donnerait un resultat qui depend de l'ordre de lecture
-- des lignes.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_lignes_a_copier`;
CREATE TEMPORARY TABLE `bis_lignes_a_copier` (
    `class`   TINYINT UNSIGNED NOT NULL,
    `spec`    TINYINT UNSIGNED NOT NULL,
    `slot`    TINYINT UNSIGNED NOT NULL,
    `faction` TINYINT UNSIGNED NOT NULL,
    `tier_id` SMALLINT UNSIGNED NOT NULL,
    `item_id` INT UNSIGNED NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL,
    `comment` VARCHAR(160) NOT NULL,
    PRIMARY KEY (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`)
) ENGINE=MEMORY;

INSERT INTO `bis_lignes_a_copier`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT src.`class`, c.`spec_cible`, src.`slot`, src.`faction`, src.`tier_id`,
       src.`item_id`, src.`rank`,
       LEFT(CONCAT(src.`comment`, ' [', c.`etiquette`, ']'), 160)
FROM `bis_copie_spec` c
JOIN `playerbots_bis_item` src
  ON src.`class` = c.`classe`
 AND src.`spec`  = c.`spec_source`;

-- ---------------------------------------------------------------------
-- 2. Les paliers a remplacer : uniquement ceux ou la source a une liste.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_paliers_remplaces`;
CREATE TEMPORARY TABLE `bis_paliers_remplaces` (
    `class`   TINYINT UNSIGNED NOT NULL,
    `spec`    TINYINT UNSIGNED NOT NULL,
    `tier_id` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`class`, `spec`, `tier_id`)
) ENGINE=MEMORY;

INSERT INTO `bis_paliers_remplaces` (`class`, `spec`, `tier_id`)
SELECT DISTINCT `class`, `spec`, `tier_id` FROM `bis_lignes_a_copier`;

-- ---------------------------------------------------------------------
-- 3. On retire l'ancienne liste de la cible, puis on pose la nouvelle.
-- ---------------------------------------------------------------------
DELETE i FROM `playerbots_bis_item` i
JOIN `bis_paliers_remplaces` p
  ON p.`class` = i.`class` AND p.`spec` = i.`spec` AND p.`tier_id` = i.`tier_id`;

INSERT INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT `class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`
FROM `bis_lignes_a_copier`;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - voleur et pretre, palier par palier.
-- Les trois voleurs doivent afficher le meme compte sur chaque palier, et
-- pretre 0 doit egaler pretre 1.
-- ---------------------------------------------------------------------
SELECT `tier_id`, `class`, `spec`,
       COUNT(DISTINCT `slot`) AS creneaux, COUNT(*) AS lignes
FROM `playerbots_bis_item`
WHERE (`class` = 4) OR (`class` = 5 AND `spec` IN (0, 1))
GROUP BY `tier_id`, `class`, `spec`
ORDER BY `tier_id`, `class`, `spec`;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - tout ecart restant entre une source et sa cible.
-- Aucune ligne = les listes sont bien identiques.
-- ---------------------------------------------------------------------
SELECT c.`classe`, c.`spec_source`, c.`spec_cible`, x.`tier_id`, x.`slot`,
       x.`item_id`, x.`cote` AS present_uniquement_chez
FROM `bis_copie_spec` c
JOIN (
    SELECT `class`, `spec`, `tier_id`, `slot`, `faction`, `item_id`, `rank`,
           'source' AS `cote` FROM `playerbots_bis_item`
    UNION ALL
    SELECT `class`, `spec`, `tier_id`, `slot`, `faction`, `item_id`, `rank`,
           'cible' AS `cote` FROM `playerbots_bis_item`
) x ON x.`class` = c.`classe`
   AND ((x.`cote` = 'source' AND x.`spec` = c.`spec_source`)
     OR (x.`cote` = 'cible'  AND x.`spec` = c.`spec_cible`))
WHERE x.`tier_id` IN (SELECT `tier_id` FROM `bis_paliers_remplaces`
                      WHERE `class` = c.`classe` AND `spec` = c.`spec_cible`)
  AND NOT EXISTS (
    SELECT 1 FROM `playerbots_bis_item` autre
    WHERE autre.`class` = c.`classe`
      AND autre.`spec` = IF(x.`cote` = 'source', c.`spec_cible`, c.`spec_source`)
      AND autre.`tier_id` = x.`tier_id`
      AND autre.`slot` = x.`slot`
      AND autre.`faction` = x.`faction`
      AND autre.`item_id` = x.`item_id`
      AND autre.`rank` = x.`rank`
);

DROP TEMPORARY TABLE IF EXISTS `bis_lignes_a_copier`;
DROP TEMPORARY TABLE IF EXISTS `bis_paliers_remplaces`;
DROP TEMPORARY TABLE IF EXISTS `bis_copie_spec`;
