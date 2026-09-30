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

## 3. Importer les listes du nouveau palier

Depuis PowerShell, pas depuis un client MySQL deja ouvert :

```powershell
$mysql = "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe"
$base  = "C:/Azerothcore/modules/mod-playerbots-bis/data/sql/db-world/base"
& $mysql -u acore -padmin --table acore_world -e "source $base/18_bwl_wowsims.sql"
& $mysql -u acore -padmin --table acore_world -e "source $base/19_mc_wowsims.sql"
```

`USE` et `source` sont des commandes du CLIENT MySQL : collees telles quelles
dans PowerShell, elles donnent `Le terme USE n'est pas reconnu`. La forme
ci-dessus les fait executer par le client, depuis le shell.

Les barres obliques NORMALES dans `$base` ne sont pas un detail : `source` est
lu par le client MySQL, qui prend mal les antislashs.

Ces deux fichiers sont **generes** depuis les sets du simulateur WoWSims Classic
par `tools/convert_wowsims_gear.py`. Ils remplacent, pour les spes qu'ils
couvrent, les listes issues de la conversion d'origine.

Le palier 30 y gagne quatre spes curees la ou il n'en avait aucune - guerrier
Armes et Fureur, chaman Elementaire et Amelioration, druide Equilibre. Le palier
20 en gagne neuf : chasseur x3, chaman x2, demoniste x3, druide Equilibre.

Ce qu'ils ne font PAS :

- ils n'ecrasent jamais une liste ecrite a la main depuis un guide Wowhead
  (guerrier Armes/Fureur et mage au palier 20, par exemple) : un set de
  simulateur ne donne qu'un objet par emplacement, un guide classe des
  alternatives ;
- ils refusent de remplacer une spe quand le set tombe sous douze creneaux -
  c'est alors le set de raid de la classe, pas une liste d'equipement ;
- ils ne couvrent aucun soigneur : WoWSims Classic ne simule pas le soin, et
  ses repertoires correspondants sont vides.

## 4. Nettoyer les listes du nouveau palier

```powershell
& $mysql -u acore -padmin --table acore_world -e "source $base/17_purge_pvp_reputation.sql"
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

## 5. Regenerer les donnees de l'addon

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

## 6. Au redemarrage

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

## 7. Avant le premier raid BWL

```
.playerbotsbis libere moi
```

Tout le monde repart sans verrou, donc la premiere entree cree une copie neuve
et les 40 y vont ensemble. Puis les macros d'invitation, tu entres le premier,
et `summon` en tchat de raid. Le detail est dans `macros_raid.md`.
