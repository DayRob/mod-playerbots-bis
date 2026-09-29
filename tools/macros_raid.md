# Monter un raid de 40 bots, et les emmener tous dans la meme instance

Procedure complete, dans l'ordre. Les macros sont sous la barre des 255
caracteres de la boite a macros et ont ete testees sous Lua 5.1 avec un faux
client : 40 invitations envoyees, `ConvertToRaid()` appele une seule fois.

## 0. Liberer les verrous d'instance - serveur ARRETE

`.instance unbind all` ne libere que **toi**, ou ta cible si tu en as une
selectionnee (`cs_instance.cpp` : `getSelectedPlayer()` puis, a defaut, toi).
Elle ne touche jamais ton raid. Elle saute aussi la carte ou le joueur se
trouve, donc lancee depuis l'interieur de l'instance elle ne libere pas cette
instance-la.

Tant qu'un bot garde un verrou vers une autre copie, le summon l'y depose : vous
serez sur la meme carte, aux memes coordonnees, dans deux copies paralleles.

Worldserver **arrete** - sinon il reecrit les verrous depuis sa memoire a la
sauvegarde suivante :

```powershell
& "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe" -u acore -padmin acore_characters -e "DELETE FROM character_instance;"
```

Pour ne liberer que le Coeur du Magma (carte 409) et garder le reste :

```powershell
& "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe" -u acore -padmin acore_characters -e "DELETE ci FROM character_instance ci JOIN instance i ON i.id = ci.instance WHERE i.map = 409;"
```

Controle apres redemarrage - zero ligne attendue :

```powershell
& "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe" -u acore -padmin --table acore_characters -e "SELECT c.name, ci.instance FROM character_instance ci JOIN instance i ON i.id = ci.instance JOIN characters c ON c.guid = ci.guid WHERE i.map = 409;"
```

Pour un seul bot egare, pas besoin de tout ca : clique-le dans le cadre de raid
pour le selectionner, sors de l'instance, et lance `.instance unbind all`. La
commande s'applique a ta cible.

## 1. Connecter les 40 bots de guilde

Ouvre la fenetre de guilde (`J`) et **coche "Voir membres deconnectes"** :
sans ca `GetNumGuildMembers()` ne liste que les connectes, c'est-a-dire
exactement ceux dont tu n'as pas besoin.

Macro 1 - construit la liste (133 caracteres) :

```
/run GuildRoster() G={} for i=1,GetNumGuildMembers() do local n=GetGuildRosterInfo(i) if n~=UnitName("player") then G[#G+1]=n end end
```

Macro 2 - les connecte un par un, 0,6 s d'ecart (212 caracteres) :

```
/run H=CreateFrame("Frame") A=0 J=0 H:SetScript("OnUpdate",function(s,d) A=A+d if A>.6 then A=0 J=J+1 if G[J] then SendChatMessage(".playerbots bot add "..G[J],"SAY") else s:SetScript("OnUpdate",nil) end end end)
```

Ceux deja en ligne repondent "player already logged in", sans effet. Les absents
se connectent et te prennent pour maitre.

## 2. Les inviter et passer en raid

Macro 3 - invite espacee, conversion en raid a la cinquieme (210 caracteres) :

```
/run K=CreateFrame("Frame") B=0 L=0 K:SetScript("OnUpdate",function(s,d) B=B+d if B>.5 then B=0 L=L+1 if L==5 then ConvertToRaid() end if G[L] then InviteUnit(G[L]) else s:SetScript("OnUpdate",nil) end end end)
```

C'est **toi** qui invites, donc c'est toi le chef, et chaque bot te prend pour
maitre en acceptant (`AcceptInvitationAction.cpp` : `SetMaster(inviter)` pour un
randombot). Les deux conditions du summon sont remplies par ce seul geste.

Controle (81 caracteres) :

```
/run print(GetNumRaidMembers().." dans le raid, chef="..tostring(IsRaidLeader()))
```

Attendu : `40 dans le raid, chef=1`.

## 3. Les faire venir

En tchat de **raid**, sans point :

```
summon
```

C'est l'action de mod-playerbots : elle ne verifie ni la carte, ni le groupe, ni
le commandement. Son seul prerequis est que le bot t'ait pour maitre.

`.summon <nom>` est la commande MJ du coeur, et elle, dans une instance, exige
`Instance.GMSummonPlayer = 1` dans `worldserver.conf` **et** que tu sois chef du
raid. Garde-la pour rapatrier un bot isole.

## 4. Entrer

Rentre le premier. Comme plus personne n'a de verrou, la copie que tu crees
devient celle du groupe, et les bots la prennent. Relance `summon` une fois
dedans si certains sont restes dehors.

## Pieges

- `AiPlayerbot.MaxAddedBots = 40` : tu es au caractere pres. Passe-le a 45 avant
  de recruter un 41e bot, sinon il sera refuse sans explication.
- `GuildRoster()` est asynchrone : juste apres connexion la liste peut etre vide
  et la macro 1 n'invite personne. Ouvre l'onglet guilde une fois avant.
- Se deconnecter transfere le commandement a un bot. Si tu reviens et que le
  summon echoue, c'est ca : `.group leader <ton nom>`, ou refais l'etape 2.
