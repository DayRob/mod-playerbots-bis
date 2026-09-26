-- Couverture BiS par bot, produite par .playerbotsbis report.
--
-- La commande cree cette table si elle manque, donc importer ce fichier n'est
-- pas obligatoire : il est ici pour documenter le schema et pour pouvoir la
-- recreer a la main.
--
-- Une ligne par (bot, objet) de la liste BiS que le bot peut atteindre a son
-- palier. `rank` = 1 designe la piece que la liste retient pour le creneau ;
-- les rangs superieurs sont des replis. Regenerer la table est toujours sans
-- risque : elle ne contient rien qui ne puisse etre recalcule.
--
-- La spe n'est stockee nulle part ailleurs dans la base : AiFactory la
-- recalcule depuis les talents a chaque fois. C'est le module qui la fige ici,
-- et c'est ce qui rend un rapport par spe possible hors du serveur.

DROP TABLE IF EXISTS `playerbots_bis_report`;
CREATE TABLE `playerbots_bis_report` (
  `guid` INT UNSIGNED NOT NULL,
  `name` VARCHAR(12) NOT NULL,
  `guild_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `class` TINYINT UNSIGNED NOT NULL,
  `spec` TINYINT UNSIGNED NOT NULL COMMENT '10 = druide farouche ours (sentinelle du module)',
  `level` TINYINT UNSIGNED NOT NULL,
  `slot` TINYINT UNSIGNED NOT NULL,
  `item_id` INT UNSIGNED NOT NULL,
  `tier_id` SMALLINT UNSIGNED NOT NULL,
  `rank` TINYINT UNSIGNED NOT NULL COMMENT '1 = la piece retenue pour le creneau',
  `state` TINYINT UNSIGNED NOT NULL COMMENT '0 manquant, 1 en sac, 2 equipe',
  `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`,`item_id`),
  KEY `guild_id` (`guild_id`),
  KEY `state` (`state`),
  KEY `item_id` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='mod-playerbots-bis : couverture BiS par bot';
