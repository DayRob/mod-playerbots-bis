# Monter un raid de 40 bots, et les emmener tous dans la meme instance

Procedure complete, dans l'ordre. Les macros sont sous la barre des 255
caracteres de la boite a macros et ont ete testees sous Lua 5.1 avec un faux
client : 40 invitations envoyees, `ConvertToRaid()` appele une seule fois.

## 0. Comprendre qui decide de la copie

Le `summon` de mod-playerbots ne transporte que vers une **carte** :

```cpp
player->TeleportTo(mapId, x, y, z, 0);   // UseMeetingStoneAction.cpp
```

C'est donc le coeur qui choisit la copie, dans cet ordre (`InstanceSaveMgr.cpp`,
`PlayerGetDestinationInstanceId`) :

```cpp
if (ipb && ipb->perm)                        // 1. verrou PERMANENT du bot
    return ipb->save->GetInstanceId();
if (Group* g = player->GetGroup())
{
    if (InstancePlayerBind* ilb = PlayerGetBoundInstance(g->GetLeaderGUID(), ...))
        return ilb->save->GetInstanceId();    // 2. verrou du CHEF
    return 0;                                 // 3. chef sans verrou -> NOUVELLE copie
}
return ipb ? ipb->save->GetInstanceId() : 0;  // 4. verrou temporaire du bot
```

Ce qu'il faut en retenir :

- Le verrou **temporaire** d'un bot ne compte pas. Chef + verrou du chef =
  tout le monde chez toi, quels que soient leurs verrous temporaires.
- Un verrou **permanent** bat tout le reste. Il apparait des qu'un boss meurt
  dans la copie. Un bot qui a tue Lucifron dans la copie 1 y retournera
  toujours.
- Si le chef n'a **pas** de verrou, chaque bot se cree sa propre copie. Summoner
  avant d'entrer, ou laisser un bot recuperer le commandement, fabrique 40
  instances.
- Entrer cree le verrou tout de suite (`InstanceMap::AddPlayerToMap` appelle
  `PlayerBindToInstance`), et lie aussi le chef s'il ne l'etait pas encore.
  D'ou la regle : **tu entres le premier, tu summons ensuite.**

`.instance unbind all` ne libere que **toi**, ou ta cible si tu en as une
selectionnee (`cs_instance.cpp` : `getSelectedPlayer()` puis, a defaut, toi).
Elle saute aussi la carte ou le joueur vise se trouve
(`itr->first != player->GetMapId()`), donc lancee depuis l'interieur de
l'instance elle ne libere pas cette instance-la.

## 0 bis. Diagnostic : qui est ou

```powershell
& "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe" -u acore -padmin --table acore_characters -e "SELECT ci.instance, ci.permanent, COUNT(*) n, GROUP_CONCAT(c.name ORDER BY c.name SEPARATOR ', ') noms FROM character_instance ci JOIN instance i ON i.id = ci.instance JOIN characters c ON c.guid = ci.guid WHERE i.map = 409 GROUP BY ci.instance, ci.permanent;"
```

En jeu, sans SQL : clique le bot dans le cadre de raid, puis

```
.instance listbinds
```

Elle s'applique a ta cible et affiche `map: 409, inst: N, perm: yes/no`.

## 0 ter. Liberer les verrous des bots

Une commande du module, a chaud, sans SQL et sans redemarrage :

```
.playerbotsbis libere
```

Elle libere les verrous d'instance de tous les bots de **ton groupe ou de ton
raid**, et ne touche jamais le tien - ton verrou, c'est ta progression.

Avant d'avoir forme le raid, quand personne n'est encore groupe :

```
.playerbotsbis libere guilde
```

Ajoute `moi` pour te liberer toi aussi - c'est le "ID illimite" en une seule
commande, puisque plus personne n'a de verrou et que la prochaine entree cree
une copie neuve :

```
.playerbotsbis libere moi
.playerbotsbis libere guilde moi 409
```

Ce n'est jamais le defaut : ton verrou, c'est la progression du raid, et
l'effacer en plein clear remet Ragnaros debout.

Pour ne liberer qu'une instance, ajoute son numero de carte (409 = Coeur du
Magma, 469 = Repaire de l'Aile noire, 309 = Zul'Gurub) :

```
.playerbotsbis libere 409
.playerbotsbis libere guilde 409
```

Elle passe par `InstanceSaveMgr`, le gestionnaire du coeur, donc l'effet est
immediat - contrairement a un DELETE dans `character_instance`, qui ne change
rien tant que le serveur n'a pas redemarre puisqu'il garde ses verrous en
memoire.

**Un bot qui se trouve DANS l'instance ne peut pas etre libere** : le coeur s'y
refuse, et la commande le compte a part pour que tu le saches. Sors-le d'abord
(`.summon <nom>` depuis l'exterieur), puis relance.

### A la main, pour un seul bot

Clique-le dans le cadre de raid pour le selectionner, sors de l'instance, et
lance `.instance unbind all`. La commande du coeur s'applique a ta cible.

### Tout remettre a zero, y compris toi

Worldserver **arrete** - sinon il garde ses verrous en memoire et ta suppression
ne change rien jusqu'au redemarrage :

```powershell
& "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe" -u acore -padmin acore_characters -e "DELETE ci FROM character_instance ci JOIN instance i ON i.id = ci.instance WHERE i.map = 409;"
```

Et ca se repare tout seul ensuite : des que le premier boss tombe avec les 40
dedans, les 40 verrous deviennent permanents **sur la meme copie**, et l'etape 1
suffit pour le reste de la semaine.

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

L'ordre n'est pas une preference, c'est l'etape 2 du code ci-dessus : **tu
entres le premier**, ce qui te donne un verrou, et c'est ce verrou que chaque
bot summonne ensuite recopie. Summoner avant d'etre entre tombe dans l'etape 3
et fabrique une copie par bot.

Si un bot reste fantome - visible dans le raid et sur la minicarte, absent a
l'ecran - c'est qu'il a un verrou permanent ailleurs. Applique-lui la
reparation du 0 ter.

## Refaire l'instance en boucle

Liberer les verrous ne suffit pas si tu enchaines : le coeur compte aussi les
instances **differentes** entrees dans l'heure.

```cpp
// PlayerStorage.cpp:7162
bool Player::CheckInstanceCount(uint32 instanceId) const
{
    if (_instanceResetTimes.size() < sWorld->getIntConfig(CONFIG_MAX_INSTANCES_PER_HOUR))
        return true;
    return _instanceResetTimes.find(instanceId) != _instanceResetTimes.end();
}
```

Au-dela, c'est "You have entered too many instances recently". Dans
`worldserver.conf` :

```
AccountInstancesPerHour = 100
```

**Ne mets pas 0.** La comparaison est `size() < config` : a 0 elle est fausse des
la premiere instance, donc 0 ne veut pas dire "illimite", il veut dire "aucune".
Mets un grand nombre.

Le compte est par personnage et par heure glissante, donc avec 40 bots qui
entrent chacun, c'est le premier mur que tu rencontres en rejouant MC d'affilee.

## Pieges

- `AiPlayerbot.MaxAddedBots = 40` : tu es au caractere pres. Passe-le a 45 avant
  de recruter un 41e bot, sinon il sera refuse sans explication.
- `GuildRoster()` est asynchrone : juste apres connexion la liste peut etre vide
  et la macro 1 n'invite personne. Ouvre l'onglet guilde une fois avant.
- Se deconnecter transfere le commandement a un bot. C'est le pire cas : le
  nouveau chef n'a aucun verrou, donc l'etape 3 s'applique et chaque bot
  summonne se cree sa propre copie. `.group leader <ton nom>` avant tout
  summon, ou refais l'etape 2.
