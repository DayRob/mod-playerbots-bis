-- D'ou vient la ligne « Imperial Qiraji Armaments » dans les listes ?
--
-- Le convertisseur sort bien « Blessed Qiraji War Axe » aux creneaux 15 rang 2
-- et 16 rang 1 pour guerrier Fureur, et le SQL genere resout les noms par
-- appariement EXACT sur item_template. Ce nom ne peut donc pas donner l'entry
-- du jeton. Pourtant ta base porte le jeton a ces coordonnees exactes.
--
-- La colonne `comment` garde le nom qui a produit chaque ligne : c'est elle
-- qui dit si la ligne vient de la generation AQ ou d'un import plus ancien.

-- 1. Tout ce que porte guerrier Fureur aux deux creneaux d'arme, au palier 60.
SELECT b.`slot` AS creneau, b.`rank` AS rang, b.`item_id`,
       i.`name`, i.`class` AS classe_objet, b.`comment`
FROM `playerbots_bis_item` b
LEFT JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE b.`class` = 1 AND b.`spec` = 1 AND b.`tier_id` = 60
  AND b.`slot` IN (15, 16)
ORDER BY b.`slot`, b.`rank`;

-- 2. La hache existe-t-elle sous ce nom exact, et sous quel entry ?
SELECT `entry`, `name`, `class`, `subclass`, `InventoryType` AS creneau_objet
FROM `item_template`
WHERE `name` IN ('Blessed Qiraji War Axe', 'Blessed Qiraji Pugio',
                 'Blessed Qiraji Bulwark', 'Blessed Qiraji Musket',
                 'Blessed Qiraji War Hammer', 'Blessed Qiraji Acolyte Staff',
                 'Blessed Qiraji Augur Staff')
ORDER BY `entry`;

-- 3. Combien de lignes de listes portent un jeton plutot qu'une piece, toutes
--    classes confondues ? Si le probleme depasse les deux objets qiraji, il
--    est systemique et se corrige en amont, pas cas par cas.
SELECT i.`class` AS classe_objet, COUNT(*) AS lignes,
       COUNT(DISTINCT b.`item_id`) AS objets_distincts
FROM `playerbots_bis_item` b
JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE i.`class` NOT IN (2, 4)
GROUP BY i.`class`
ORDER BY lignes DESC;

-- 4. Et lesquels, nommement.
SELECT i.`class` AS classe_objet, b.`item_id`, i.`name`,
       COUNT(*) AS lignes, MIN(b.`comment`) AS premier_commentaire
FROM `playerbots_bis_item` b
JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE i.`class` NOT IN (2, 4)
GROUP BY i.`class`, b.`item_id`, i.`name`
ORDER BY lignes DESC
LIMIT 30;
