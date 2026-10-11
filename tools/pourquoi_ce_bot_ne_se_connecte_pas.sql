-- Pourquoi tel bot de la guilde reste hors ligne, alors que ses voisins non.
--
--   Get-Content tools\pourquoi_ce_bot_ne_se_connecte_pas.sql -Raw |
--     & $m -uacore -padmin acore_characters --table --default-character-set=utf8mb4
--
-- ATTENTION : base acore_CHARACTERS. La requete trouve toute seule le nom de
-- la base playerbots (acore_playerbots chez la plupart, mais pas chez tous) en
-- interrogeant information_schema.
--
-- POURQUOI
-- --------
-- qui_manque_a_la_guilde.sql montre QUI manque. Celui-ci montre POURQUOI, et la
-- difference tient a une chose : le vivier de personnages rndbot est plus grand
-- que Playerbots.MaxRandomBots.
--
-- mod-playerbots cree deux reserves de comptes rndbot :
--
--   - les premiers comptes alimentent les RANDOMBOTS, tires pour atteindre
--     MaxRandomBots et maintenus en ligne ;
--   - les derniers (Playerbots.AddClassAccountPoolSize) sont RESERVES a la
--     commande addclass. Ces bots-la ne se connectent JAMAIS d'eux-memes.
--
-- Les deux portent le meme prefixe de compte et se ressemblent en tout point
-- dans la table characters. Seule leur presence dans playerbots_random_bots
-- les distingue : le gestionnaire n'y inscrit que ce qu'il pilote.
--
-- Colonnes de sortie :
--   en_ligne       1 si le bot est connecte maintenant
--   rang_compte    place du compte parmi les comptes rndbot, du plus ancien au
--                  plus recent. Les rangs eleves sont la reserve addclass.
--   suivi_par      nombre de lignes dans playerbots_random_bots pour ce bot.
--                  0 = le gestionnaire de randombots ne le connait pas, donc il
--                  ne le connectera jamais.
--   dernier_event  le dernier evenement enregistre, et quand.

SET @guilde := 5;   -- Reborn

SELECT TABLE_SCHEMA INTO @pb
FROM   information_schema.TABLES
WHERE  TABLE_NAME = 'playerbots_random_bots'
LIMIT  1;

SELECT IFNULL(@pb, '!! table playerbots_random_bots introuvable !!') AS base_playerbots;

SET @q := CONCAT('
SELECT  c.name                               AS nom,
        c.level                              AS niveau,
        c.online                             AS en_ligne,
        a.username                           AS compte,
        r.rang                               AS rang_compte,
        (SELECT COUNT(*) FROM ', @pb, '.playerbots_random_bots p
          WHERE p.bot = c.guid)              AS suivi_par,
        (SELECT CONCAT(p.event, " le ", FROM_UNIXTIME(p.time))
           FROM ', @pb, '.playerbots_random_bots p
          WHERE p.bot = c.guid
          ORDER BY p.time DESC, p.id DESC LIMIT 1) AS dernier_event
FROM    characters c
JOIN    guild_member gm ON gm.guid = c.guid
LEFT JOIN acore_auth.account a ON a.id = c.account
LEFT JOIN (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rang
        FROM   acore_auth.account
        WHERE  username LIKE "RNDBOT%"
     ) r ON r.id = c.account
WHERE   gm.guildid = ', @guilde, '
ORDER BY c.online, r.rang, c.name');

PREPARE s FROM @q;
EXECUTE s;
DEALLOCATE PREPARE s;
