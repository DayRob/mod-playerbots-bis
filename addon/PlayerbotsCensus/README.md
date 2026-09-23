# Playerbots Census

Recense la population en ligne d'un serveur 3.3.5a et la ventile par **classe,
race, niveau, zone et guilde**. Concu pour un realm peuple de randombots, mais
il compte les vrais joueurs de la meme facon.

## Pourquoi pas CensusPlus

`CensusPlusWotlk` (CurseForge, WoWInterface) cible **WotLK Classic**, la
reedition Blizzard : son `.toc` annonce `## Interface: 30400` et son code appelle
`C_FriendList.SendWho()`, `C_FriendList.GetNumWhoResults()`,
`C_FriendList.GetWhoInfo()`. Le namespace `C_FriendList` a ete introduit dans
Battle for Azeroth (8.0) et **n'existe pas en 3.3.5a**, ou ces fonctions sont des
globales. L'addon se charge donc mais echoue des le premier scan, silencieusement
tant que `/console scriptErrors 1` n'est pas actif. Il depend en plus de
`LibRealmID`, qui ne connait que les royaumes officiels.

Cet addon utilise l'API 3.3.5 correcte et n'a aucune dependance.

## Comment il obtient les chiffres

Un client n'a qu'un seul canal pour connaitre la population : la requete `/who`.
L'addon en envoie **une par niveau**, de 1 a `maxLevel`.

Chaque reponse porte deux nombres, et c'est la tout l'interet :

| | |
|---|---|
| lignes envoyees | plafonnees par `MaxWhoListReturns` de `worldserver.conf` (**49** par defaut) |
| total des correspondances | **non plafonne** |

Dans AzerothCore (`MiscHandler.cpp`, `HandleWhoOpcode`) ce sont `displaycount` et
`matchCount`, ecrits separement dans le paquet. Consequence directe :

- le **total en ligne** et l'**histogramme par niveau** sont **exacts**, meme
  au-dela de 49 ;
- le detail **classe / race / zone / guilde** se limite aux lignes recues.

Quand le plafond retient des lignes, l'addon l'affiche au lieu de faire semblant.
Pour un detail complet, monte `MaxWhoListReturns` dans `worldserver.conf` - le
commentaire amont le signale comme instable au-dela de 49, alors augmente par
paliers et teste.

Deux limites qui ne viennent pas de l'addon :

- Un `/who` ne renvoie que **ta propre faction**, sauf si ton compte porte la
  permission RBAC `two-side who list`.
- Un `/who` ne renvoie **pas la spe** : nom, guilde, niveau, race, classe, genre,
  zone. La couverture BiS par spe reste hors de portee d'un addon.

La liste cote serveur est un cache rafraichi **toutes les 5 secondes**, donc un
releve est une photo a 5 secondes pres.

## Installation

Copier le dossier `PlayerbotsCensus` dans
`<WoW>\Interface\AddOns\`, puis `/reload` ou relancer le client.

## Commandes

| Commande | Effet |
|---|---|
| `/pbcensus` | ouvre ou ferme la fenetre (alias `/pbc`) |
| `/pbcensus scan` | lance un balayage |
| `/pbcensus stop` | l'interrompt |
| `/pbcensus max <n>` | dernier niveau balaye (defaut 80) |
| `/pbcensus delay <s>` | intervalle entre requetes (defaut 1.5) |
| `/pbcensus keep <n>` | releves conserves (defaut 8) |
| `/pbcensus raw` | stocke ou non le detail par personnage |
| `/pbcensus clear` | vide l'archive |

Un balayage dure environ `maxLevel x delay` secondes : ~2 minutes en 1..80,
~1 min 30 en 1..60. Cale `max` sur le niveau maximum de ton realm, c'est autant
de requetes en moins.

## Export

Chaque balayage est archive dans
`<WoW>\WTF\Account\<COMPTE>\SavedVariables\PlayerbotsCensus.lua`.

**Le fichier n'est ecrit qu'a la deconnexion ou au `/reload`** - c'est le
fonctionnement des SavedVariables, pas un oubli. Fais un `/reload` apres un
balayage si tu veux l'exporter sans quitter.

Conversion en CSV :

```powershell
.\tools\export_census_csv.ps1 `
  -Sv "C:\test\world of warcraft 3.3.5a hd\WTF\Account\MONCOMPTE\SavedVariables\PlayerbotsCensus.lua" `
  -Out "C:\Azerothcore\reporting\census.csv"
```

Colonnes : `Horodatage, Royaume, Faction, Nom, Guilde, Niveau, Race, Classe, Zone`.

Une ligne par personnage et par releve, l'horodatage repete sur chaque ligne :
c'est une table de faits a plat, sans jointure a faire. `-Append` accumule
plusieurs exports dans le meme fichier pour constituer un historique.
