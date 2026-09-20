# Playerbots BiS Tooltip

Addon 3.3.5a qui ajoute sous l'infobulle d'un objet les classes et spés qui le
listent en BiS, lues **directement depuis les tables du serveur**.

```
BiS - Guerrier Fureur - Vanilla Pre-Raid (rang 1)
BiS - Voleur Combat - Vanilla Pre-Raid (rang 1)
Aussi BiS pour : Chasseur
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

## Commandes

| Commande | Effet |
|---|---|
| `/pbbis` | nombre d'objets chargés et réglages courants |
| `/pbbis all` | bascule entre ta seule classe et toutes les classes |
| `/pbbis maxtier <n>` | masque les paliers au-dessus de `n` (`0` = aucun plafond) |

Par défaut seules les lignes de **ta** classe sont détaillées, les autres
apparaissant en résumé — sinon une pièce partagée par huit spés produit huit
lignes d'infobulle.

Règle `maxtier` sur la même valeur que `PlayerbotsBis.MaxTier` pour voir ce que
tes bots voient : au-delà de leur plafond, un objet leur est invisible.

## Régénérer

Après toute modification des tables — nouveau palier, correction d'une liste —
relance le script puis `/reload` en jeu. Le rang et le palier affichés suivent.
