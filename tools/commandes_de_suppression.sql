-- Fabriquer la liste des .account delete pour les comptes de bots jamais joues.
--
-- Cette requete NE SUPPRIME RIEN. Elle ecrit des commandes, a relire et a
-- passer soi-meme dans la console du serveur.
--
--   Get-Content tools\commandes_de_suppression.sql -Raw |
--     & $m -uacore -padmin acore_playerbots --skip-column-names --default-character-set=utf8mb4
--
-- ATTENTION : base acore_PLAYERBOTS.
--
-- POURQUOI PASSER PAR UNE COMMANDE EN JEU
-- ---------------------------------------
-- Supprimer un personnage touche une trentaine de tables : inventaire,
-- courrier, reputations, sorts, talents, succes, instances, groupe, amis,
-- guilde, enchères... Un DELETE sur characters en laisse partout, et ces
-- restes ressortent plus tard sous forme d'objets orphelins ou de plantages.
--
-- .account delete appelle le code du coeur qui fait le menage complet. C'est
-- plus lent et plus bavard, et c'est la seule facon propre.
--
-- La requete n'inclut QUE les comptes dont aucun personnage n'a depasse le
-- niveau 1 et qui ne portent aucun membre de guilde - les memes garde-fous
-- que pas_de_bots_niveau_1.sql, pour la meme raison.
--
-- SI TU HESITES, NE SUPPRIME PAS. pas_de_bots_niveau_1.ps1 les rend deja
-- invisibles en les sortant du vivier, ce qui suffit a retrouver un serveur
-- normal. La suppression ne gagne que de la place disque.

SET @seuil := 1;

SELECT '-- Comptes concernes, et ce qu ils contiennent :' AS '';

SELECT  CONCAT('--   ', a.username, ' : ', COUNT(c.guid), ' personnages, niveau max ', MAX(c.level)) AS ''
FROM    playerbots_account_type t
JOIN    acore_auth.account a ON a.id = t.account_id
JOIN    acore_characters.characters c ON c.account = t.account_id
WHERE   t.account_type = 0
GROUP BY t.account_id, a.username
HAVING  MAX(c.level) <= @seuil
   AND  SUM(EXISTS (SELECT 1 FROM acore_characters.guild_member gm WHERE gm.guid = c.guid)) = 0
ORDER BY a.username;

SELECT '' AS '';
SELECT '-- A passer dans la console du worldserver, serveur ALLUME :' AS '';

SELECT  CONCAT('.account delete ', a.username) AS ''
FROM    playerbots_account_type t
JOIN    acore_auth.account a ON a.id = t.account_id
JOIN    acore_characters.characters c ON c.account = t.account_id
WHERE   t.account_type = 0
GROUP BY t.account_id, a.username
HAVING  MAX(c.level) <= @seuil
   AND  SUM(EXISTS (SELECT 1 FROM acore_characters.guild_member gm WHERE gm.guid = c.guid)) = 0
ORDER BY a.username;
