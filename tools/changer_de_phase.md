# Passer les bots a la phase suivante

Ecrit pour le passage en Blackwing Lair (palier 30), mais la marche a suivre
vaut pour n'importe quelle phase : seul le numero change.

| Phase | Palier |
|---|---|
| Vanilla Pre-Raid | 10 |
| Molten Core / Onyxia | 20 |
| **Blackwing Lair** | **30** |
| Zul'Gurub | 40 |
| Ahn'Qiraj 20 | 50 |
| Ahn'Qiraj 40 | 60 |
| Naxxramas 40 | 70 |

## 1. Serveur arrete : le code

```powershell
cd C:\Azerothcore\modules\mod-playerbots-bis
git pull origin claude/randombots-bis-logic-0mbx4x
```

Puis **Build** dans le gestionnaire. Si "Rebuild only" echoue, "Clean Full
Build" : des fichiers C++ ont ete ajoutes (`BisUnbind`) et d'autres retires
(`BisDungeonPlan`), donc la configuration CMake a bouge.

## 2. Les fichiers de configuration

`C:\Azerothcore\configs\modules\playerbots_bis.conf` :

```
PlayerbotsBis.MaxTier = 30
PlayerbotsBis.NeedOnlyForBis = 1
PlayerbotsBis.ForceNeedForBis = 1
PlayerbotsBis.ClaimClassRestricted = 1
```

Les trois dernieres manquaient : ton `.conf` date d'avant leur ajout, et le
build n'installe que le `.dist`. Elles tournaient donc sur leurs defauts, dont
`NeedOnlyForBis = 0` - la moitie qui RETIRE le Besoin a ce qui n'est pas BiS.

`C:\Azerothcore\configs\modules\playerbots.conf` :

```
AiPlayerbot.LootNeedRollLevel = 2
```

Sinon mod-playerbots reecrit chaque Besoin en Cupidite juste avant de voter
(`LootRollAction.cpp`). Avec `ForceNeedForBis = 1` le module emet le Besoin
lui-meme, donc ce reglage n'est plus indispensable - mais il evite une
incoherence entre les deux.

`C:\Azerothcore\configs\worldserver.conf`, si tu rejoues une instance
d'affilee :

```
AccountInstancesPerHour = 100
```

Pas 0 : la comparaison est `size() < config`, donc 0 veut dire "aucune".

## 3. Nettoyer les listes du nouveau palier

```sql
USE acore_world;
source C:/Azerothcore/modules/mod-playerbots-bis/data/sql/db-world/base/17_purge_pvp_reputation.sql
```

Le palier 30 n'a **aucun fichier curé** : ses 24 combinaisons classe/spe
viennent toutes de la conversion d'origine, dont les rangs ne sortent d'aucun
guide et qui contient du PvP en rang 1. Ce fichier retire au moins ce qui viole
la regle du projet - PvP et reputation - sur preuve et non sur supposition :
reputation requise, rang de haut fait, ou vente contre un cout etendu (honneur,
marques).

Il affiche ce qu'il va supprimer AVANT de le faire. Lis cette premiere table.

**Ca n'en fait pas des listes justes pour autant** : l'ordre des rangs reste
celui de la conversion. Pour de vraies listes BWL il faut les guides, spe par
spe.

## 4. Regenerer les donnees de l'addon

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\export_bis_tooltip.ps1 -WowPath "C:\test\world of warcraft 3.3.5a hd"
powershell -ExecutionPolicy Bypass -File .\tools\install_addon.ps1 -WowPath "C:\test\world of warcraft 3.3.5a hd"
```

Les deux passent par `-ExecutionPolicy Bypass` : la politique par defaut de
Windows refuse d'executer un script telecharge, et l'appel direct echoue sur
`UnauthorizedAccess`.

L'infobulle lit un export fige : sans ca elle continue d'annoncer les anciennes
listes pendant que les bots suivent les nouvelles. La fenetre du releve, elle,
vient en direct du serveur - en cas de desaccord, c'est elle qui a raison.

## 5. Au redemarrage

```
.playerbotsbis reload
```

Elle relit le `.conf` depuis le disque et **annonce le palier obtenu**. Verifie
qu'il dit bien 30.

```
.playerbotsbis report
```

Les lignes doivent maintenant citer `Vanilla Phase 2 - Blackwing Lair`. Si un
bot est ignore, la commande dit lequel et pourquoi.

## 6. Avant le premier raid BWL

```
.playerbotsbis libere moi
```

Tout le monde repart sans verrou, donc la premiere entree cree une copie neuve
et les 40 y vont ensemble. Puis les macros d'invitation, tu entres le premier,
et `summon` en tchat de raid. Le detail est dans `macros_raid.md`.
