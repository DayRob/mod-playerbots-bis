# Playerbots BiS Tooltip

Addon 3.3.5a en deux morceaux, lus **directement depuis les tables du serveur** :

- une **infobulle** qui ajoute sous un objet les classes et spés qui le listent
  en BiS ;
- un **navigateur** (`/pbbis`) qui affiche une liste complète, créneau par
  créneau, sans passer par un site externe.

```
BiS - Guerrier Fureur - Vanilla Pre-Raid (rang 1)
BiS - Voleur Combat - Vanilla Pre-Raid (rang 1)
Aussi BiS pour : Chasseur - Précision ; Druide - Farouche, Restauration
```

L'addon ne tient aucune liste à lui. `BisData.lua` est généré depuis
`playerbots_bis_item`, donc l'infobulle dit exactement ce que les bots pensent :
pas de seconde copie qui dérive.

## Installation

1. Copier le dossier `PlayerbotsBisTooltip` dans `Interface\AddOns\`
2. Générer les données :

```powershell
.\tools\export_bis_tooltip.ps1 -Out "C:\chemin\vers\wow\interface\addons\PlayerbotsBisTooltip\BisData.lua"
```

3. Relancer le client et cocher **« Charger les addons obsolètes »**

Le script prend aussi `-MySql`, `-User`, `-Password` et `-Database` si ta
configuration diffère des valeurs par défaut d'AzerothCore.

## Le navigateur

`/pbbis` (ou `/pbbislist`) ouvre une fenêtre : trois sélecteurs **Classe / Spé /
Phase**, et en dessous la liste groupée par créneau d'équipement, triée par rang.

- **Clic gauche / clic droit** sur un sélecteur : valeur suivante / précédente.
  Seules les combinaisons qui existent réellement dans tes tables sont proposées.
- **Survol** d'une ligne : la vraie infobulle de l'objet — avec, dessous, les
  lignes BiS de l'autre moitié de l'addon.
- **Maj+clic** : insère le lien dans le chat. **Ctrl+clic** : cabine d'essayage.
- Le bouton **Tous les rangs / Rang 1 seul** réduit la liste au choix principal.

Certains objets apparaissent d'abord en `Chargement...` sous une section
**En attente du serveur**. C'est normal : `GetItemInfo` ne répond que pour les
objets déjà en cache côté client, et un objet jamais croisé n'y est pas. Le
navigateur les demande au serveur et remplit les lignes dès que les noms
arrivent — quelques secondes la première fois, instantané ensuite.

## Commandes

| Commande | Effet |
|---|---|
| `/pbbis` | ouvre le navigateur des listes (aussi `/pbbislist`) |
| `/pbbis info` | nombre d'objets chargés et réglages courants |
| `/pbbis all` | bascule entre ta seule classe et toutes les classes |
| `/pbbis maxtier <n>` | masque les paliers au-dessus de `n` (`0` = aucun plafond) |

Par défaut seules les lignes de **ta** classe sont détaillées, les autres
apparaissant en résumé — sinon une pièce partagée par huit spés produit huit
lignes d'infobulle. Le résumé **nomme les spés** : `Druide` tout seul ne répond
pas à la seule question qui se pose devant une pièce d'une autre classe.
`/pbbis all` donne en plus le palier et le rang de chacune.

Règle `maxtier` sur la même valeur que `PlayerbotsBis.MaxTier` pour voir ce que
tes bots voient : au-delà de leur plafond, un objet leur est invisible.

## Régénérer

Après toute modification des tables — nouveau palier, correction d'une liste —
relance le script puis `/reload` en jeu. Le rang et le palier affichés suivent.
