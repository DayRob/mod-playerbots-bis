# Playerbots BiS Tooltip

Addon 3.3.5a en quatre morceaux, lus **directement depuis les tables du serveur** :

- une **infobulle** qui ajoute sous un objet les classes et spés qui le listent
  en BiS ;
- un **navigateur** (`/pbbis`) qui affiche une liste complète, créneau par
  créneau, sans passer par un site externe ;
- un **relevé des bots** (`.playerbotsbis report`) qui montre, bot par bot, ce
  qui manque à chacun ;
- un **plan de donjons** (`/pbisplan`, `.playerbotsbis donjons`) qui dit quelle
  instance faire et avec lesquels y aller.

```
BiS P2 BWL     Guerrier Fureur (2)/Prot (2)   Voleur Combat (1)
BiS P1 MC/Ony  Guerrier Prot (1)/Fureur (3)   Voleur Assass (1)/Combat (2)
BiS Pre-Raid   Guerrier Armes (1)/Prot (1)    Voleur Combat (1)/Assass (3)
```

**Une ligne par palier**, pas une par combinaison : une pièce que seize
classe/spé/palier revendiquent tenait seize lignes, elle en tient trois.

Le rang suit la spé entre parenthèses **et** la colore — vert 1, jaune 2, gris
3. La couleur sert à balayer, le chiffre à trancher : une ligne dont toutes les
spés partagent un rang est une ligne d'une seule couleur, sans rien à quoi la
comparer. Le nom de classe est toujours écrit, dans sa couleur de classe, même
quand la ligne ne porte que la tienne : `Prot` tout seul ne dit pas Prot de
quoi.

`/pbbis detail` rend l'ancien affichage, une ligne par classe, spé et palier.

L'addon ne tient aucune liste à lui. `BisData.lua` est généré depuis
`playerbots_bis_item`, donc l'infobulle dit exactement ce que les bots pensent.

**Mais c'est un instantané, pas un flux.** Après chaque import de nouvelles
données BiS, il faut relancer `export_bis_tooltip.ps1` — sinon l'infobulle
continue d'annoncer l'ancienne liste pendant que les bots, eux, suivent déjà la
nouvelle. La fenêtre du relevé (`.playerbotsbis report`), elle, vient en direct
du serveur : **en cas de désaccord entre les deux, c'est elle qui a raison.**

La date de génération est en tête de `BisData.lua` ; si elle est antérieure à
ton dernier import, l'infobulle est périmée.

## Installation

1. Copier le dossier `PlayerbotsBisTooltip` dans `Interface\AddOns\`
2. Générer les données :

```powershell
.\tools\export_bis_tooltip.ps1 -Out "C:\chemin\vers\wow\interface\addons\PlayerbotsBisTooltip\BisData.lua"
```

3. Relancer le client et cocher **« Charger les addons obsolètes »**

Le script prend aussi `-MySql`, `-User`, `-Password` et `-Database` si ta
configuration diffère des valeurs par défaut d'AzerothCore.

## Le bouton de minicarte

Un bouton apparaît autour de la minicarte. **Clic gauche** : ouvre le navigateur.
**Clic droit** : bascule entre ta seule classe et toutes les classes. **Glisser** :
le déplace le long du cercle, la position est retenue. `/pbbis minimap` le masque
ou le réaffiche.

C'est un `Button` nommé, enfant de `Minimap` : les collecteurs de boutons le
rangent automatiquement.

## Le navigateur

`/pbbis` (ou `/pbbislist`) ouvre une fenêtre : trois menus déroulants **Classe /
Spé / Phase**, et en dessous la liste groupée par créneau d'équipement, triée par
rang.

- **Menus déroulants** pour la classe, la spé et la phase. Seules les
  combinaisons qui existent réellement dans tes tables y figurent : pas de spé
  vide, pas de phase sans objet.
- **La phase ne bouge pas** quand tu changes de spé ou de classe. Si la nouvelle
  sélection ne la propose pas, l'addon descend à la phase immédiatement
  inférieure plutôt que de sauter à la plus récente.
- **Survol** d'une ligne : la vraie infobulle de l'objet — avec, dessous, les
  lignes BiS de l'autre moitié de l'addon.
- **Maj+clic** : insère le lien dans le chat. **Ctrl+clic** : cabine d'essayage.
- Le bouton **Tous les rangs / Rang 1 seul** réduit la liste au choix principal.

Certains objets apparaissent d'abord en `Chargement...` sous une section
**En attente du serveur**. C'est normal : `GetItemInfo` ne répond que pour les
objets déjà en cache côté client, et un objet jamais croisé n'y est pas. Le
navigateur les demande au serveur et remplit les lignes dès que les noms
arrivent — quelques secondes la première fois, instantané ensuite.

## Le relevé des bots

`.playerbotsbis report` en jeu remplit la fenêtre (`/pbbis roster`, ou le second
bouton de minicarte). Un bot par ligne, dépliable créneau par créneau.

Le bouton de gauche fait tourner trois vues, et affiche toujours celle où il
est :

| Vue | Ce qu'elle montre |
|---|---|
| **Manquants seulement** | les créneaux où le rang 1 n'est pas porté — le travail qui reste |
| **Équipés seulement** | les créneaux réglés — ce que le bot a déjà sécurisé |
| **Tout afficher** | les deux |

Un créneau compte comme réglé quand **la pièce que la liste choisit pour lui est
celle qui est portée**. Un rang 2 au dos, ou un rang 1 qui dort dans les sacs,
reste dans les manquants : le créneau a encore quelque chose à gagner.

## Les compositions de raid

Les invitations remplissent les sous-groupes dans l'ordre d'arrivée : sans rien
faire, la composition change à chaque raid. Ces trois commandes la figent.

```
/pbbis compo save mc       (une fois, le raid étant rangé comme tu veux)
/pbbis compo apply mc      (après chaque vague d'invitations)
```

`apply` répare la répartition membre par membre : un déplacement quand le groupe
visé a une place libre, un échange sinon. Sur un raid de 40 entièrement mélangé
il faut une vingtaine d'ordres, soit une dizaine de secondes.

Les membres absents de la composition sont laissés où ils sont, et ceux de la
composition qui ne sont pas dans le raid sont ignorés — tu peux donc enregistrer
une composition de 40 et l'appliquer à un raid de 25.

Il faut être **chef de raid ou assistant** : le serveur refuse les déplacements
autrement. La commande le vérifie avant de commencer plutôt que de laisser des
ordres partir dans le vide.

Un point de mécanique explique la cadence : le serveur ne renvoie la liste
mise à jour qu'après un aller-retour, donc `GetRaidRosterInfo` ment juste après
un déplacement. La commande fait **un** mouvement, attend, relit, recommence.
Enchaîner les ordres sur des données périmées produirait des échanges qui se
défont entre eux.

`/pbbis compo` seul liste ce qui est enregistré, `/pbbis compo clear <nom>`
oublie une composition, `/pbbis compo stop` interrompt une application en cours.

## Commandes

| Commande | Effet |
|---|---|
| `/pbbis` | ouvre le navigateur des listes (aussi `/pbbislist`) |
| `/pbbis info` | nombre d'objets chargés et réglages courants |
| `/pbbis minimap` | affiche ou masque le bouton de minicarte |
| `/pbbis all` | bascule entre ta seule classe et toutes les classes |
| `/pbbis detail` | bascule entre l'affichage compact et l'affichage détaillé |
| `/pbbis compo` | enregistre et réapplique une répartition de raid |
| `/pbbis maxtier <n>` | masque les paliers au-dessus de `n` (`0` = aucun plafond) |

Par défaut seules les spés de **ta** classe sont affichées par palier, les
autres classes tenant dans une ligne grise en dessous. Ce résumé **nomme les
spés** : `Druide` tout seul ne répond pas à la seule question qui se pose devant
une pièce d'une autre classe. `/pbbis all` remonte tout le monde dans les lignes
de palier, avec le rang de chacun ; en compact, cela reste une ligne par palier.

Règle `maxtier` sur la même valeur que `PlayerbotsBis.MaxTier` pour voir ce que
tes bots voient : au-delà de leur plafond, un objet leur est invisible.

## Régénérer

Après toute modification des tables — nouveau palier, correction d'une liste —
relance le script puis `/reload` en jeu. Le rang et le palier affichés suivent.
