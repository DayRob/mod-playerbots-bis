-- mod-playerbots-bis : comble les spes sans liste au palier 30 (Blackwing Lair).
--
-- Apres 18_bwl_wowsims.sql il reste trois combinaisons sans aucune ligne au
-- palier 30 : WoWSims ne publie pas de set pour elles, et la conversion
-- d'origine ne les couvrait pas non plus a ce palier.
--
--   Voleur Assassinat (4/0) et Subtilite (4/2) -> Voleur Combat (4/1)
--   Pretre Discipline (5/0)                    -> Pretre Sacre (5/1)
--
-- Ce n'est pas un raccourci : en Vanilla les trois arbres de voleur visent le
-- meme equipement DPS (WoWSims lui-meme ne publie qu'un set de voleur par
-- phase, comme pour le chasseur et le mage), et Discipline soigne avec le
-- stuff de Sacre. Un guide propre a la spe, s'il arrive un jour, remplacera
-- ces lignes.
--
-- GARDE-FOU : on ne copie QUE vers une spe totalement vide a ce palier. Si tu
-- ajoutes plus tard une liste a la main pour 4/0, ce fichier ne la touchera
-- plus. Il est donc rejouable sans risque.
--
-- A rejouer apres 18, et AVANT 17 : les lignes copiees peuvent contenir du
-- PvP ou de la reputation, que seul le fichier 17 sait reconnaitre.

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
-- La copie, en deux temps.
--
-- On ne peut pas lire et ecrire playerbots_bis_item dans une seule
-- instruction en s'appuyant sur NOT EXISTS : des la premiere ligne
-- inseree la condition deviendrait fausse et la spe n'aurait qu'un
-- seul objet. On fige donc d'abord ce qu'il y a a copier, puis on
-- insere depuis cette photo.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_lignes_a_copier`;
CREATE TEMPORARY TABLE `bis_lignes_a_copier` (
    `class`   TINYINT UNSIGNED NOT NULL,
    `spec`    TINYINT UNSIGNED NOT NULL,
    `slot`    TINYINT UNSIGNED NOT NULL,
    `faction` TINYINT UNSIGNED NOT NULL,
    `item_id` INT UNSIGNED NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL,
    `comment` VARCHAR(160) NOT NULL,
    PRIMARY KEY (`class`, `spec`, `slot`, `faction`, `item_id`)
) ENGINE=MEMORY;

INSERT INTO `bis_lignes_a_copier`
    (`class`, `spec`, `slot`, `faction`, `item_id`, `rank`, `comment`)
SELECT src.`class`, c.`spec_cible`, src.`slot`, src.`faction`,
       src.`item_id`, src.`rank`,
       LEFT(CONCAT(src.`comment`, ' [', c.`etiquette`, ']'), 160)
FROM `bis_copie_spec` c
JOIN `playerbots_bis_item` src
  ON src.`class` = c.`classe`
 AND src.`spec`  = c.`spec_source`
 AND src.`tier_id` = 30
WHERE NOT EXISTS (
    SELECT 1 FROM `playerbots_bis_item` deja
    WHERE deja.`class` = c.`classe`
      AND deja.`spec`  = c.`spec_cible`
      AND deja.`tier_id` = 30
);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT `class`, `spec`, `slot`, `faction`, 30, `item_id`, `rank`, `comment`
FROM `bis_lignes_a_copier`;

DROP TEMPORARY TABLE IF EXISTS `bis_lignes_a_copier`;

-- ---------------------------------------------------------------------
-- VERIFICATION - creneaux couverts par spe au palier 30.
-- Attendu : 28 lignes (9 classes x 3 spes + l'ours druide 11/10).
-- ---------------------------------------------------------------------
SELECT `class`, `spec`, COUNT(DISTINCT `slot`) AS creneaux, COUNT(*) AS lignes
FROM `playerbots_bis_item` WHERE `tier_id` = 30
GROUP BY `class`, `spec` ORDER BY `class`, `spec`;

DROP TEMPORARY TABLE IF EXISTS `bis_copie_spec`;
