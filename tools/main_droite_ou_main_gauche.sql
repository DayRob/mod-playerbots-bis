-- mod-playerbots-bis : "deux mains, ou une main + main gauche ?"
--
-- La reponse est deja dans les listes, mais elle ne se lit pas a l'oeil :
-- c'est le RANG 1 DU CRENEAU 15 qui tranche. Les guides classent l'arme dans
-- une seule echelle ou les deux mains et les une main se melangent, donc poser
-- une arme a deux mains en tete, c'est dire qu'elle bat la meilleure arme a une
-- main ACCOMPAGNEE de la meilleure main gauche. Le site n'ecrit jamais cette
-- phrase ; il la dit en placant le baton en premier.
--
-- Quand le rang 1 du creneau 15 est a deux mains, toutes les lignes du creneau
-- 16 de ce couple sont mortes : le bot qui atteint son BiS ne pourra jamais les
-- porter. Elles ne sont pas fausses, elles sont inatteignables - et c'est le
-- module qui doit les ignorer, pas la table qui doit les perdre : un bot qui
-- n'a pas encore son baton porte tres bien une main gauche en attendant.
--
-- InventoryType 17 = INVTYPE_2HWEAPON. 14 / 22 / 23 = bouclier, arme de main
-- gauche, tenu en main gauche.

SELECT
    mh.`class`                                   AS classe,
    mh.`spec`                                    AS spe,
    t.`name`                                     AS palier,
    it.`name`                                    AS main_droite_rang_1,
    CASE it.`InventoryType` WHEN 17 THEN 'DEUX MAINS' ELSE 'une main' END AS prise,
    COUNT(DISTINCT oh.`item_id`)                 AS lignes_main_gauche,
    CASE
        WHEN it.`InventoryType` = 17 AND COUNT(oh.`item_id`) > 0
            THEN 'le baton gagne -> lignes main gauche inatteignables'
        WHEN it.`InventoryType` = 17
            THEN 'le baton gagne'
        WHEN COUNT(oh.`item_id`) = 0
            THEN 'une main, mais AUCUNE main gauche listee -> creneau vide'
        ELSE 'une main + main gauche'
    END                                          AS verdict
FROM `playerbots_bis_item` mh
JOIN `item_template` it
  ON it.`entry` = mh.`item_id`
JOIN `playerbots_bis_tier` t
  ON t.`tier_id` = mh.`tier_id`
LEFT JOIN `playerbots_bis_item` oh
  ON  oh.`class`   = mh.`class`
  AND oh.`spec`    = mh.`spec`
  AND oh.`tier_id` = mh.`tier_id`
  AND oh.`slot`    = 16
WHERE mh.`slot` = 15
  AND mh.`rank` = 1
GROUP BY mh.`class`, mh.`spec`, mh.`tier_id`, t.`name`, it.`name`, it.`InventoryType`
ORDER BY mh.`tier_id`, mh.`class`, mh.`spec`;
