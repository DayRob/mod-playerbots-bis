-- ---------------------------------------------------------------------------
-- Ou tombe cet objet ?
--
-- Le tooltip du client 3.3.5 ne contient AUCUNE information de provenance : ni
-- le boss, ni le donjon, ni la quete. Wowhead compose cela a partir d'une base
-- separee. Le module, de son cote, ne stocke que class/spec/slot/faction/
-- tier/item_id/rank : pas de colonne source non plus. L'addon n'a donc rien a
-- afficher.
--
-- Ta base MONDE, elle, sait tout. Ce script y repond.
--
-- UTILISATION : remplace le nom ci-dessous, puis lance le script sur la base
-- monde (acore_world par defaut) :
--     mysql -u acore -p acore_world < tools/ou_tombe_cet_objet.sql
--
-- LIMITE CONNUE : le nom de la ZONE n'est pas dans la base monde - il vit dans
-- les DBC du client. Tu obtiens le nom de la creature, du coffre, du vendeur ou
-- de la quete, ce qui suffit largement pour retrouver l'endroit.
--
-- SET NAMES utf8mb4 est indispensable : sans lui, la variable herite du jeu de
-- caracteres de ta session et la comparaison COLLATE echoue (erreur 1253).
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
SET @objet := _utf8mb4'Cap of the Scarlet Savant';

SELECT 'creature'       AS origine, ct.`name` AS source, clt.`Chance` AS chance
FROM `creature_loot_template` clt
JOIN `creature_template` ct ON ct.`entry` = clt.`Entry`
JOIN `item_template` it ON it.`entry` = clt.`Item`
 AND it.`name` COLLATE utf8mb4_general_ci = @objet COLLATE utf8mb4_general_ci

UNION ALL
SELECT 'creature (table de reference)', ct.`name`, rlt.`Chance`
FROM `reference_loot_template` rlt
JOIN `item_template` it ON it.`entry` = rlt.`Item`
 AND it.`name` COLLATE utf8mb4_general_ci = @objet COLLATE utf8mb4_general_ci
JOIN `creature_loot_template` clt ON clt.`Reference` = rlt.`Entry`
JOIN `creature_template` ct ON ct.`entry` = clt.`Entry`

UNION ALL
SELECT 'objet du decor', gt.`name`, glt.`Chance`
FROM `gameobject_loot_template` glt
JOIN `gameobject_template` gt ON gt.`entry` = glt.`Entry`
JOIN `item_template` it ON it.`entry` = glt.`Item`
 AND it.`name` COLLATE utf8mb4_general_ci = @objet COLLATE utf8mb4_general_ci

UNION ALL
SELECT 'vendeur', ct.`name`, 100
FROM `npc_vendor` nv
JOIN `creature_template` ct ON ct.`entry` = nv.`entry`
JOIN `item_template` it ON it.`entry` = nv.`item`
 AND it.`name` COLLATE utf8mb4_general_ci = @objet COLLATE utf8mb4_general_ci

UNION ALL
SELECT 'quete', qt.`LogTitle`, 100
FROM `quest_template` qt
JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = @objet COLLATE utf8mb4_general_ci
 AND it.`entry` IN (qt.`RewardItem1`, qt.`RewardItem2`, qt.`RewardItem3`, qt.`RewardItem4`,
                    qt.`RewardChoiceItemID1`, qt.`RewardChoiceItemID2`, qt.`RewardChoiceItemID3`,
                    qt.`RewardChoiceItemID4`, qt.`RewardChoiceItemID5`, qt.`RewardChoiceItemID6`)
ORDER BY 1;
