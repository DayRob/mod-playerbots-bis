-- Pourquoi le jeu refuse une action de guilde, alors qu'on se croit chef.
--
--   Get-Content tools\pourquoi_pas_de_droits_guilde.sql -Raw |
--     & $m -uacore -padmin acore_characters --table --force --default-character-set=utf8mb4
--
-- ATTENTION : base acore_CHARACTERS, pas acore_world.
--
-- CE QUE DIT LA SOURCE D'AZEROTHCORE
-- ----------------------------------
-- Guild.cpp, _MemberHasTabRights, lignes 2655-2662 :
--
--     if (member->IsRank(GR_GUILDMASTER) || m_leaderGuid == guid)
--         return true;                  // "Leader always has full rights"
--
-- et GR_GUILDMASTER vaut 0 (Guild.h ligne 65).
--
-- Autrement dit : un VRAI chef n'est JAMAIS bloque par les droits d'onglet.
-- Ni ceux du rang, ni ceux de l'onglet. Si le jeu refuse, c'est que le serveur
-- ne te considere pas comme chef - pas que tes droits sont mal regles.
--
-- Trois facons d'etre "chef sans l'etre" :
--
--   1. guild_member.rank n'est pas 0 pour ton personnage ;
--   2. guild.leaderguid designe quelqu'un d'autre ;
--   3. la base a ete modifiee a la main SANS redemarrer le worldserver.
--      L'objet Guild vit en memoire : il garde les rangs lus au chargement,
--      et une correction SQL ne l'atteint pas avant un redemarrage.
--
-- Remplace Betu si besoin.
SET @perso := 'Betu';

-- ---------------------------------------------------------------------
-- 1. Ton rang reel, et qui est chef pour le serveur.
-- ---------------------------------------------------------------------
SELECT 'Ton rang, et le chef officiel' AS section;
SELECT g.`guildid`, g.`name` AS guilde, c.`name` AS personnage,
       gm.`rank` AS rang_id, gr.`rname` AS rang_nom,
       CASE WHEN gm.`rank` = 0 THEN 'oui' ELSE 'NON' END AS rang_zero,
       CASE WHEN g.`leaderguid` = gm.`guid` THEN 'oui' ELSE 'NON' END AS est_leaderguid,
       (SELECT c2.`name` FROM `characters` c2 WHERE c2.`guid` = g.`leaderguid`) AS chef_declare
FROM `guild` g
JOIN `guild_member` gm ON gm.`guildid` = g.`guildid`
JOIN `characters` c    ON c.`guid` = gm.`guid`
LEFT JOIN `guild_rank` gr ON gr.`guildid` = g.`guildid` AND gr.`rid` = gm.`rank`
WHERE c.`name` = @perso;

-- ---------------------------------------------------------------------
-- 2. Les rangs de ta guilde. Le rang 0 doit exister et etre le tien.
-- ---------------------------------------------------------------------
SELECT 'Les rangs de la guilde' AS section;
SELECT gr.`rid`, gr.`rname`, gr.`rights`, gr.`BankMoneyPerDay`,
       (SELECT COUNT(*) FROM `guild_member` m
         WHERE m.`guildid` = gr.`guildid` AND m.`rank` = gr.`rid`) AS membres
FROM `guild_rank` gr
WHERE gr.`guildid` = (SELECT gm.`guildid` FROM `guild_member` gm
                      JOIN `characters` c ON c.`guid` = gm.`guid`
                      WHERE c.`name` = @perso
                      LIMIT 1)
ORDER BY gr.`rid`;

-- ---------------------------------------------------------------------
-- 3. Les onglets achetes. Zero onglet = rien a deposer, et le message
--    du client n'est alors pas tres parlant.
-- ---------------------------------------------------------------------
SELECT 'Onglets de banque achetes' AS section;
SELECT gbt.`TabId`, gbt.`TabName`, gbt.`TabIcon`
FROM `guild_bank_tab` gbt
WHERE gbt.`guildid` = (SELECT gm.`guildid` FROM `guild_member` gm
                       JOIN `characters` c ON c.`guid` = gm.`guid`
                       WHERE c.`name` = @perso
                       LIMIT 1)
ORDER BY gbt.`TabId`;

-- ---------------------------------------------------------------------
-- 4. Les droits par onglet et par rang.
--    gbright : 1 voir, 2 deposer, 3 voir+deposer, 255 tout.
--    Pour le rang 0 ces valeurs ne changent RIEN - le code passe outre -
--    mais elles expliquent le blocage de n'importe quel autre rang.
-- ---------------------------------------------------------------------
SELECT 'Droits par onglet et par rang' AS section;
SELECT gbr.`TabId`, gbr.`rid`, gr.`rname`, gbr.`gbright`, gbr.`SlotPerDay`
FROM `guild_bank_right` gbr
LEFT JOIN `guild_rank` gr ON gr.`guildid` = gbr.`guildid` AND gr.`rid` = gbr.`rid`
WHERE gbr.`guildid` = (SELECT gm.`guildid` FROM `guild_member` gm
                       JOIN `characters` c ON c.`guid` = gm.`guid`
                       WHERE c.`name` = @perso
                       LIMIT 1)
ORDER BY gbr.`TabId`, gbr.`rid`;
