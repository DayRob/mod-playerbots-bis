-- mod-playerbots-bis : qui bloque la base, et sur quoi.
--
-- A lancer dans une SECONDE fenetre PowerShell PENDANT qu'un import semble
-- fige. Une requete lente et une requete BLOQUEE se ressemblent exactement vu
-- du terminal - le nom du fichier s'affiche et plus rien ne bouge - mais elles
-- ne se soignent pas pareil :
--
--   lente   : elle avance, le temps passe dans Time et l'etat change
--   bloquee : elle attend un VERROU que personne ne relache, souvent une
--             transaction restee ouverte par le worldserver
--
--   Get-Content tools\ou_ca_bloque.sql -Raw |
--     & $m -uacore -padmin acore_world --table --default-character-set=utf8mb4

-- ---------------------------------------------------------------------
-- 1. Les connexions en cours. La colonne Time donne l'age en secondes.
--    Une requete d'import qui attend affiche un State du genre
--    "Waiting for table metadata lock" ou "updating".
-- ---------------------------------------------------------------------
SELECT 'Connexions en cours' AS section;
SELECT `ID`, `USER`, `DB`, `COMMAND`, `TIME`, `STATE`,
       LEFT(COALESCE(`INFO`, ''), 120) AS requete
FROM `information_schema`.`PROCESSLIST`
WHERE `COMMAND` <> 'Sleep'
ORDER BY `TIME` DESC;

-- ---------------------------------------------------------------------
-- 2. Les transactions InnoDB ouvertes. Une transaction en etat RUNNING
--    depuis des minutes, qui ne vient pas de l'import, est le suspect
--    numero un : c'est elle qui tient le verrou.
-- ---------------------------------------------------------------------
SELECT 'Transactions InnoDB ouvertes' AS section;
SELECT `trx_id`, `trx_state`, `trx_started`,
       TIMESTAMPDIFF(SECOND, `trx_started`, NOW()) AS `age_secondes`,
       `trx_mysql_thread_id` AS `connexion`,
       `trx_rows_locked`, `trx_rows_modified`,
       LEFT(COALESCE(`trx_query`, ''), 120) AS requete
FROM `information_schema`.`INNODB_TRX`
ORDER BY `trx_started`;

-- ---------------------------------------------------------------------
-- 3. Combien de lignes le fichier 17 doit traiter chez toi. Si ce nombre
--    est enorme, le fichier est lent et non bloque, et la reponse n'est
--    pas la meme.
-- ---------------------------------------------------------------------
SELECT 'Volume que le fichier 17 doit parcourir' AS section;
SELECT
  (SELECT COUNT(*) FROM `playerbots_bis_item` WHERE `tier_id` BETWEEN 10 AND 70)
      AS `lignes_bis_paliers_10_70`,
  (SELECT COUNT(*) FROM `item_template`)  AS `lignes_item_template`,
  (SELECT COUNT(*) FROM `npc_vendor`)     AS `lignes_npc_vendor`,
  (SELECT COUNT(DISTINCT `item`) FROM `npc_vendor` WHERE `ExtendedCost` > 0)
      AS `objets_a_cout_etendu`;
