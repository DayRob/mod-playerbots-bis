-- Ecarter du vivier les comptes de bots fraichement crees (personnages lvl 1).
--
-- A LANCER SERVEUR ARRETE. L'assignation des comptes se fait au demarrage ;
-- passe par tools\pas_de_bots_niveau_1.ps1, qui le verifie avant.
--
--   Get-Content tools\pas_de_bots_niveau_1.sql -Raw |
--     & $m -uacore -padmin acore_playerbots --table --default-character-set=utf8mb4
--
-- ATTENTION : base acore_PLAYERBOTS.
--
-- POURQUOI
-- --------
-- Monter Playerbots.MaxRandomBots fait creer des comptes supplementaires :
-- le module calcule ce qu'il lui faut et comble la difference.
--
--     neededRndBotAccounts = (maxBots + divisor - 1) / divisor;   // divisor = 10
--     if (existingRndBotAccounts < neededRndBotAccounts) { ... assigner ... }
--
-- Redescendre le plafond ne les reprend PAS : il n'existe aucune branche qui
-- desassigne quand on repasse en dessous. Les personnages neufs restent donc
-- candidats, et comme ils naissent au niveau 1, ils peuplent le monde de bots
-- niveau 1 qu'on n'a jamais demandes.
--
-- Rien n'oblige a les supprimer. Le module range ses comptes dans
-- playerbots_account_type :
--
--     account_type = 1  vivier des randombots, connexion automatique
--     account_type = 2  reserve addclass, jamais connectee seule
--     account_type = 0  non assigne - ignore des deux listes
--
-- rndBotTypeAccounts n'est rempli qu'avec les comptes de type 1. Remettre les
-- comptes neufs a 0 les met hors circuit sans toucher a un personnage, et se
-- defait en remettant 1.
--
-- DEUX GARDE-FOUS, tous deux en dur :
--   - un compte qui porte un membre de guilde n'est JAMAIS ecarte, quel que
--     soit le niveau de ses autres personnages ;
--   - les comptes addclass (type 2) ne sont pas touches.
--
-- APRES COUP, il faut que le plafond redescende. Si MaxRandomBots reste haut,
-- le prochain demarrage constatera qu'il manque des comptes et reassignera
-- ceux qu'on vient d'ecarter - ou en creera de nouveaux. Le tableau 4 le dit.

-- Niveau maximum qu'un compte peut avoir pour etre considere comme neuf.
-- 1 = seulement les comptes dont AUCUN personnage n'a jamais joue. Monter ce
-- seuil elargit le menage, et le rend moins sur.
SET @seuil := 1;

-- Le plafond vise, pour le controle final. 10 personnages par compte.
SET @plafond := 500;

-- ------------------------------------------------------------------
-- 1. Etat du vivier, par niveau du meilleur personnage du compte.
-- ------------------------------------------------------------------
SELECT '--- 1. vivier actuel ---' AS '';

SELECT  CASE WHEN x.niveau_max <= @seuil THEN CONCAT('neuf (lvl <= ', @seuil, ')')
             ELSE 'joue' END                             AS etat,
        COUNT(*)                                         AS comptes,
        SUM(x.persos)                                    AS personnages,
        SUM(x.membres_guilde)                            AS dont_membres_de_guilde
FROM (
    SELECT  t.account_id,
            MAX(c.level)                                 AS niveau_max,
            COUNT(c.guid)                                AS persos,
            SUM(CASE WHEN gm.guid IS NOT NULL THEN 1 ELSE 0 END) AS membres_guilde
    FROM    playerbots_account_type t
    JOIN    acore_characters.characters c ON c.account = t.account_id
    LEFT JOIN acore_characters.guild_member gm ON gm.guid = c.guid
    WHERE   t.account_type = 1
    GROUP BY t.account_id
) x
GROUP BY etat;

-- ------------------------------------------------------------------
-- 2. Les comptes qui vont etre ecartes.
-- ------------------------------------------------------------------
SELECT '--- 2. seront ecartes ---' AS '';

SELECT  a.username AS compte, COUNT(c.guid) AS personnages, MAX(c.level) AS niveau_max
FROM    playerbots_account_type t
JOIN    acore_auth.account a ON a.id = t.account_id
JOIN    acore_characters.characters c ON c.account = t.account_id
WHERE   t.account_type = 1
GROUP BY t.account_id, a.username
HAVING  MAX(c.level) <= @seuil
   AND  SUM(CASE WHEN EXISTS (SELECT 1 FROM acore_characters.guild_member gm
                              WHERE gm.guid = c.guid) THEN 1 ELSE 0 END) = 0
ORDER BY a.username;

-- ------------------------------------------------------------------
-- 3. La mise hors circuit.
-- ------------------------------------------------------------------
START TRANSACTION;

UPDATE  playerbots_account_type t
JOIN (
    SELECT  c.account AS id
    FROM    acore_characters.characters c
    LEFT JOIN acore_characters.guild_member gm ON gm.guid = c.guid
    GROUP BY c.account
    HAVING  MAX(c.level) <= @seuil
       AND  COUNT(gm.guid) = 0
) neufs ON neufs.id = t.account_id
SET     t.account_type = 0
WHERE   t.account_type = 1;

COMMIT;

-- ------------------------------------------------------------------
-- 4. Controle : reste-t-il assez de comptes pour le plafond vise ?
-- ------------------------------------------------------------------
SELECT '--- 4. controle ---' AS '';

SELECT  SUM(account_type = 1)                            AS comptes_vivier,
        SUM(account_type = 2)                            AS comptes_addclass,
        SUM(account_type = 0)                            AS comptes_ecartes,
        CEIL(@plafond / 10)                              AS comptes_exiges,
        CASE WHEN SUM(account_type = 1) >= CEIL(@plafond / 10)
             THEN CONCAT('ok - garde MaxRandomBots a ', @plafond, ' au plus')
             ELSE CONCAT('!! BAISSE MaxRandomBots a ', SUM(account_type = 1) * 10,
                         ' ou moins, sinon ils seront reassignes !!')
        END                                              AS verdict
FROM    playerbots_account_type;
