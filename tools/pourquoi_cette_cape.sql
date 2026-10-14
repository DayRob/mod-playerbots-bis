-- Pourquoi ce bot porte CETTE piece sur un creneau, et pas une autre.
--
--   Get-Content tools\pourquoi_cette_cape.sql -Raw |
--     & $m -uacore -padmin acore_characters --table --default-character-set=utf8mb4
--
-- ATTENTION : base acore_CHARACTERS. La requete va chercher les listes dans
-- acore_world au passage, les deux bases vivant sur le meme serveur MySQL.
--
-- CE QUE LA REPONSE DOIT TRANCHER
-- -------------------------------
-- Le module ne retire JAMAIS a playerbots le droit d'equiper, il ne fait que
-- s'ajouter. Une seule regle l'en empeche (BisItemUsageValue, branche 3) : une
-- piece qu'AUCUNE liste ne nomme ne peut pas chasser une piece qui est, elle,
-- sur la liste du bot.
--
-- Donc une piece hors liste qui arrive sur le dos d'un bot veut dire une seule
-- chose : le creneau ne portait RIEN QUI SOIT SUR SA LISTE, et le score de
-- stats de playerbots etait libre de trancher. Les trois sections ci-dessous le
-- verifient au lieu de le supposer.
--
-- Creneaux : 0 tete, 1 cou, 2 epaules, 4 torse, 5 ceinture, 6 jambes,
--            7 pieds, 8 poignets, 9 mains, 10 et 11 doigts, 12 et 13 bijoux,
--            14 DOS, 15 main droite, 16 main gauche, 17 a distance, 18 tabard.

SET @bot  := 'NOM_DU_BOT';
SET @slot := 14;

-- 1. Ce que le bot porte sur ce creneau, et si une liste le nomme.
SELECT '1. La piece portee' AS section;
SELECT ii.`itemEntry` AS entree, itpl.`name` AS nom,
       COALESCE((SELECT GROUP_CONCAT(DISTINCT CONCAT('palier ', b.`tier_id`, ' rang ', b.`rank`)
                                     ORDER BY b.`tier_id` SEPARATOR ', ')
                 FROM `acore_world`.`playerbots_bis_item` b
                 WHERE b.`item_id` = ii.`itemEntry` AND b.`class` = c.`class`),
                'HORS LISTE pour cette classe') AS sur_la_liste
FROM `character_inventory` ci
JOIN `characters` c       ON c.`guid` = ci.`guid`
JOIN `item_instance` ii   ON ii.`guid` = ci.`item`
LEFT JOIN `acore_world`.`item_template` itpl ON itpl.`entry` = ii.`itemEntry`
WHERE c.`name` = @bot AND ci.`bag` = 0 AND ci.`slot` = @slot;

-- 2. L'echelle du bot sur ce creneau, du haut vers le bas, et ce qu'il DETIENT.
--    La spe n'est stockee nulle part - le serveur la recalcule depuis les
--    talents - donc toutes les spes de la classe sont montrees.
SELECT '2. L echelle de la classe sur ce creneau' AS section;
SELECT b.`spec` AS spe, b.`tier_id` AS palier, t.`name` AS nom_du_palier,
       b.`rank` AS rang, b.`item_id` AS entree, itpl.`name` AS nom,
       b.`tier_id` * 1000 + (255 - b.`rank`) AS priorite,
       CASE
           WHEN EXISTS (SELECT 1 FROM `character_inventory` ci2
                        JOIN `characters` c2 ON c2.`guid` = ci2.`guid`
                        JOIN `item_instance` ii2 ON ii2.`guid` = ci2.`item`
                        WHERE c2.`name` = @bot AND ii2.`itemEntry` = b.`item_id`
                          AND ci2.`bag` = 0 AND ci2.`slot` <= 18) THEN 'PORTE'
           WHEN EXISTS (SELECT 1 FROM `character_inventory` ci2
                        JOIN `characters` c2 ON c2.`guid` = ci2.`guid`
                        JOIN `item_instance` ii2 ON ii2.`guid` = ci2.`item`
                        WHERE c2.`name` = @bot AND ii2.`itemEntry` = b.`item_id`) THEN 'dans ses sacs'
           ELSE 'absent'
       END AS detention
FROM `acore_world`.`playerbots_bis_item` b
JOIN `acore_world`.`playerbots_bis_tier` t ON t.`tier_id` = b.`tier_id`
LEFT JOIN `acore_world`.`item_template` itpl ON itpl.`entry` = b.`item_id`
WHERE b.`slot` = @slot
  AND b.`class` = (SELECT c3.`class` FROM `characters` c3 WHERE c3.`name` = @bot)
ORDER BY b.`spec`, priorite DESC;

-- 3. La piece en cause est-elle sur UNE SEULE liste, toutes classes confondues ?
--    Zero ligne = aucune table ne la nomme, et le score de stats de playerbots
--    a donc decide seul.
SELECT '3. Qui, dans toutes les listes, nomme la piece portee' AS section;
SELECT b.`class` AS classe, b.`spec` AS spe, b.`tier_id` AS palier, b.`rank` AS rang, b.`comment`
FROM `acore_world`.`playerbots_bis_item` b
WHERE b.`item_id` = (SELECT ii.`itemEntry`
                     FROM `character_inventory` ci
                     JOIN `characters` c     ON c.`guid` = ci.`guid`
                     JOIN `item_instance` ii ON ii.`guid` = ci.`item`
                     WHERE c.`name` = @bot AND ci.`bag` = 0 AND ci.`slot` = @slot)
ORDER BY b.`class`, b.`spec`, b.`tier_id`;
