-- Cree le PREMIER onglet de banque de guilde, exactement comme le ferait
-- l'achat en jeu.
--
--   Get-Content tools\creer_onglet_banque_guilde.sql -Raw |
--     & $m -uacore -padmin acore_characters --table --default-character-set=utf8mb4
--
-- ATTENTION : base acore_CHARACTERS.
--
-- A FAIRE AVANT : ARRETE LE WORLDSERVER.
-- A FAIRE APRES : REDEMARRE-LE.
--
-- Ce n'est pas une precaution de style. L'objet Guild vit en memoire : il
-- charge ses onglets au demarrage et n'en relit jamais. Ecrire ces lignes
-- pendant que le serveur tourne ne donnerait rien tant qu'il n'a pas
-- redemarre - et pire, il pourrait les ecraser en quittant.
--
-- POURQUOI PASSER PAR LA
-- ----------------------
-- Le coffre s'ouvre, l'interface montre six onglets, et rien ne s'y depose :
-- ces six cases sont les emplacements VIDES du cadre, pas des onglets
-- achetes. guild_bank_tab est vide pour cette guilde. Si l'interface du
-- client ne propose pas l'achat - c'est le cas sur certains clients
-- remanies - l'achat ne peut pas se faire en jeu, et il faut ecrire ce que
-- l'achat aurait ecrit.
--
-- CE QUE L'ACHAT ECRIT, D'APRES LA SOURCE
-- ---------------------------------------
-- Guild.cpp, _CreateNewBankTab (ligne 2442) :
--   1. une ligne dans guild_bank_tab (guildid, TabId) ;
--   2. puis, pour CHAQUE rang, CreateMissingTabsIfNeeded (ligne 287) pose une
--      ligne guild_bank_right.
--
-- Les valeurs par rang viennent de Guild.h :
--   - rang 0 (chef) : SetGuildMasterValues() -> rights = GUILD_BANK_RIGHT_FULL
--     (0xFF = 255) et slots = GUILD_WITHDRAW_SLOT_UNLIMITED ;
--   - tous les autres : le constructeur laisse rights = 0 et slots = 0.
--
-- Les droits des autres rangs se reglent ensuite tranquillement en jeu, dans
-- l'onglet Guilde. Et de toute facon le chef passe outre : _MemberHasTabRights
-- renvoie true pour le rang 0 sans meme lire ces lignes.

SET @guilde := (SELECT gm.`guildid` FROM `guild_member` gm
                JOIN `characters` c ON c.`guid` = gm.`guid`
                WHERE c.`name` = 'Betu' LIMIT 1);

SELECT 'Guilde visee' AS section;
SELECT @guilde AS guildid,
       (SELECT `name` FROM `guild` WHERE `guildid` = @guilde) AS nom,
       (SELECT COUNT(*) FROM `guild_bank_tab` WHERE `guildid` = @guilde) AS onglets_avant;

-- 1. L'onglet. TabId 0 : c'est le premier, et le code exige qu'on les cree
--    dans l'ordre (HandleBuyBankTab refuse tabId != _GetPurchasedTabsSize()).
INSERT IGNORE INTO `guild_bank_tab` (`guildid`, `TabId`, `TabName`, `TabIcon`)
VALUES (@guilde, 0, 'Onglet 1', 'Interface\\Icons\\INV_Box_01');

-- 2. Les droits, un par rang. Le chef recoit 255 et un retrait illimite,
--    les autres zero - a toi de les ouvrir ensuite en jeu.
INSERT IGNORE INTO `guild_bank_right` (`guildid`, `TabId`, `rid`, `gbright`, `SlotPerDay`)
SELECT @guilde, 0, gr.`rid`,
       CASE WHEN gr.`rid` = 0 THEN 255 ELSE 0 END,
       CASE WHEN gr.`rid` = 0 THEN 4294967295 ELSE 0 END
FROM `guild_rank` gr
WHERE gr.`guildid` = @guilde;

SELECT 'Apres : les onglets' AS section;
SELECT `TabId`, `TabName`, `TabIcon` FROM `guild_bank_tab`
WHERE `guildid` = @guilde ORDER BY `TabId`;

SELECT 'Apres : les droits par rang' AS section;
SELECT gbr.`TabId`, gbr.`rid`, gr.`rname`, gbr.`gbright`, gbr.`SlotPerDay`
FROM `guild_bank_right` gbr
LEFT JOIN `guild_rank` gr ON gr.`guildid` = gbr.`guildid` AND gr.`rid` = gbr.`rid`
WHERE gbr.`guildid` = @guilde ORDER BY gbr.`TabId`, gbr.`rid`;
