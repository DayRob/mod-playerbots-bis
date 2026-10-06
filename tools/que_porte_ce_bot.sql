-- Ce qu'un bot porte, creneau par creneau.
--
--   Get-Content tools\que_porte_ce_bot.sql -Raw |
--     & $m -uacore -padmin acore_characters --table --default-character-set=utf8mb4
--
-- ATTENTION : base acore_CHARACTERS. La requete va chercher les noms dans
-- acore_world au passage, les deux bases vivant sur le meme serveur MySQL.
--
-- POURQUOI
-- --------
-- "le coeur a refuse l'equipement au creneau 11 (sacs pleins ?)" etait une
-- SUPPOSITION de mon code : HandleAutoEquipItemSlotOpcode ne rend rien et
-- decline en silence, donc la seule chose lisible apres coup est que le creneau
-- n'a pas change.
--
-- Les sacs ne sont pas pleins. Reste le refus qui ressemble le plus a
-- celui-la : un anneau UNIQUE - EQUIPE deja porte a l'AUTRE doigt.
--
-- GetWornPriorityPaired rend le plus FAIBLE des deux doigts, pour que le
-- nouvel anneau remplace le moins bon. Mais elle ne regarde pas ce que porte le
-- doigt le plus fort : si c'est deja le meme anneau, la comparaison de
-- priorites ne le voit pas, le module annonce une amelioration, et le coeur
-- refuse pour cause d'unicite. A chaque tick.
--
-- Creneaux : 0 tete, 1 cou, 2 epaules, 3 chemise, 4 torse, 5 ceinture,
--            6 jambes, 7 pieds, 8 poignets, 9 mains, 10 et 11 DOIGTS,
--            12 et 13 bijoux, 14 dos, 15 main droite, 16 main gauche,
--            17 a distance, 18 tabard.

SET @bot := 'Thegvetukk';

SELECT 'Equipement porte' AS section;
SELECT ci.`slot` AS creneau,
       CASE ci.`slot`
           WHEN 0 THEN 'tete'     WHEN 1 THEN 'cou'      WHEN 2 THEN 'epaules'
           WHEN 4 THEN 'torse'    WHEN 5 THEN 'ceinture' WHEN 6 THEN 'jambes'
           WHEN 7 THEN 'pieds'    WHEN 8 THEN 'poignets' WHEN 9 THEN 'mains'
           WHEN 10 THEN 'DOIGT 1' WHEN 11 THEN 'DOIGT 2'
           WHEN 12 THEN 'bijou 1' WHEN 13 THEN 'bijou 2' WHEN 14 THEN 'dos'
           WHEN 15 THEN 'main droite' WHEN 16 THEN 'main gauche'
           WHEN 17 THEN 'a distance'  WHEN 18 THEN 'tabard'
           ELSE '' END AS emplacement,
       ii.`itemEntry`, itpl.`name`,
       CASE WHEN (itpl.`flags` & 0x00080000) <> 0 THEN 'UNIQUE-EQUIPE' ELSE '' END AS unicite
FROM `character_inventory` ci
JOIN `characters` c  ON c.`guid` = ci.`guid`
JOIN `item_instance` ii ON ii.`guid` = ci.`item`
LEFT JOIN `acore_world`.`item_template` itpl ON itpl.`entry` = ii.`itemEntry`
WHERE c.`name` = @bot AND ci.`bag` = 0 AND ci.`slot` <= 18
ORDER BY ci.`slot`;

-- Combien d'exemplaires de l'anneau en cause, portes OU en sac.
SELECT 'Exemplaires de Band of Dark Dominion detenus' AS section;
SELECT ci.`bag`, ci.`slot`, ii.`itemEntry`, itpl.`name`
FROM `character_inventory` ci
JOIN `characters` c  ON c.`guid` = ci.`guid`
JOIN `item_instance` ii ON ii.`guid` = ci.`item`
JOIN `acore_world`.`item_template` itpl ON itpl.`entry` = ii.`itemEntry`
WHERE c.`name` = @bot AND itpl.`name` = 'Band of Dark Dominion'
ORDER BY ci.`bag`, ci.`slot`;
