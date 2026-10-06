-- Ou se trouve le coffre de guilde, et existe-t-il seulement.
--
--   Get-Content tools\ou_est_la_banque_de_guilde.sql -Raw |
--     & $m -uacore -padmin acore_world --table --force --default-character-set=utf8mb4
--
-- CE QUE DIT LA SOURCE
-- --------------------
-- On n'achete pas un onglet aupres d'un PNJ. GuildHandler.cpp,
-- HandleGuildBankBuyTab :
--
--     if (GetPlayer()->GetGameObjectIfCanInteractWith(packet.Banker,
--                                                     GAMEOBJECT_TYPE_GUILD_BANK))
--
-- C'est un OBJET DU DECOR - le coffre de guilde - et non une creature. Les
-- memes lignes gouvernent l'ouverture de la banque (HandleGuildBankerActivate)
-- et la consultation d'un onglet. Sans un objet de ce type a portee, le client
-- n'a personne a qui demander, et ne propose donc aucun achat.
--
-- GAMEOBJECT_TYPE_GUILDBANK vaut 34 (GameObjectData.h).
--
-- Les coffres de guilde sont arrives avec le patch 2.3. Sur un serveur cale
-- sur du contenu Vanilla, il est tout a fait possible qu'aucun ne soit pose.

-- ---------------------------------------------------------------------
-- 1. Les modeles de coffre de guilde connus de la base.
-- ---------------------------------------------------------------------
SELECT 'Modeles de coffre de guilde (type 34)' AS section;
SELECT gt.`entry`, gt.`name`,
       (SELECT COUNT(*) FROM `gameobject` g WHERE g.`id` = gt.`entry`) AS exemplaires_poses
FROM `gameobject_template` gt
WHERE gt.`type` = 34
ORDER BY exemplaires_poses DESC, gt.`name`;

-- ---------------------------------------------------------------------
-- 2. Ceux reellement POSES dans le monde, avec leur carte et leur
--    position. Carte 0 = Royaumes de l'Est, 1 = Kalimdor,
--    530 = Outreterre, 571 = Norfendre.
--
--    Aucune ligne ici = personne ne peut ouvrir de banque de guilde sur
--    ce serveur, quels que soient les droits.
-- ---------------------------------------------------------------------
SELECT 'Coffres poses dans le monde' AS section;
SELECT g.`guid`, g.`id`, gt.`name`, g.`map`,
       ROUND(g.`position_x`) AS x, ROUND(g.`position_y`) AS y, ROUND(g.`position_z`) AS z
FROM `gameobject` g
JOIN `gameobject_template` gt ON gt.`entry` = g.`id`
WHERE gt.`type` = 34
ORDER BY g.`map`, gt.`name`;

-- ---------------------------------------------------------------------
-- 3. Si rien n'est pose : la commande pour en faire apparaitre un.
--    A taper EN JEU, pres du banquier de ta capitale, avec un compte
--    de maitre de jeu :
--
--      .gobject add <entry>
--
--    L'entry est celle de la premiere requete. L'objet apparait a tes
--    pieds et est enregistre en base - il survivra au redemarrage.
--    Pour l'enlever ensuite : .gobject delete <guid>
-- ---------------------------------------------------------------------
SELECT 'Rappel : .gobject add <entry> pose un coffre a tes pieds' AS section;
