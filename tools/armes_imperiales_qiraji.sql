-- Les Armes et Parures imperiales qiraji : que donnent-elles, d'apres TA base ?
--
-- Elles apparaissent dans les listes BiS (l'infobulle de l'addon les annonce
-- pour guerrier Fureur/Prot, paladin Prot et chasseur), mais le module laisse
-- le vote a playerbots parce qu'elles ne sont ni arme ni armure :
--
--     if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR)
--         continue;   // BisLootRollAction.cpp
--
-- Resultat : tout le raid cupidite et c'est le hasard qui tranche. Pour le
-- corriger comme les jetons d'AQ, il faut d'abord savoir par quel mecanisme
-- elles deviennent une piece : une quete, ou une recette.

-- 1. Les objets eux-memes. Class 7 = marchandise, 12 = quete.
SELECT `entry`, `name`, `class`, `subclass`, `Quality` AS qualite,
       `BuyPrice`, `SellPrice`, `maxcount`, `stackable`,
       `spellid_1`, `spellid_2`
FROM `item_template`
WHERE `name` LIKE 'Imperial Qiraji%'
ORDER BY `entry`;

-- 2. Sont-elles demandees par une quete ? C'est le mecanisme des jetons d'AQ,
--    celui que le module sait deja convertir.
SELECT j.`entry` AS jeton, j.`name` AS nom_jeton,
       q.`ID` AS quete, q.`LogTitle` AS titre,
       p.`entry` AS recompense_entry, p.`name` AS recompense,
       p.`class` AS classe_objet, p.`InventoryType` AS creneau,
       p.`AllowableClass` AS classes_autorisees
FROM `item_template` j
JOIN `quest_template` q
  ON j.`entry` IN (q.`RequiredItemId1`, q.`RequiredItemId2`, q.`RequiredItemId3`,
                   q.`RequiredItemId4`, q.`RequiredItemId5`, q.`RequiredItemId6`)
JOIN (
    SELECT `ID` AS quete, NULLIF(`RewardItem1`, 0)         AS piece FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardItem2`, 0)         FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID1`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID2`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID3`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID4`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID5`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID6`, 0) FROM `quest_template`
) r ON r.`quete` = q.`ID` AND r.`piece` IS NOT NULL
JOIN `item_template` p ON p.`entry` = r.`piece`
WHERE j.`name` LIKE 'Imperial Qiraji%'
ORDER BY j.`entry`, p.`name`;

-- 3. Et dans MES listes : sous quel entry, quel palier, quel rang ?
--    Si c'est bien la marchandise qui y figure et non l'objet fabrique,
--    c'est la liste qu'il faut corriger, pas le code.
SELECT b.`class` AS classe, b.`spec`, b.`tier_id` AS palier, b.`slot` AS creneau,
       b.`rank` AS rang, b.`item_id`, i.`name`, i.`class` AS classe_objet
FROM `playerbots_bis_item` b
JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE i.`name` LIKE 'Imperial Qiraji%'
ORDER BY b.`class`, b.`spec`, b.`tier_id`, b.`rank`;
