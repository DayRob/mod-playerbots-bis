-- Ce que les idoles et scarabees d'Ahn'Qiraj donnent, d'apres TA base.
SELECT j.`name` AS objet, q.`ID` AS quete, q.`LogTitle` AS titre,
       p.`name` AS recompense, p.`entry` AS recompense_entry,
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
) r ON r.`quete` = q.`ID` AND r.`piece` IS NOT NULL
JOIN `item_template` p ON p.`entry` = r.`piece`
WHERE j.`name` LIKE 'Idol of %' OR j.`name` LIKE '%Scarab'
ORDER BY j.`name`, p.`name`;
