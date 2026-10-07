# DESIGN BRIEF — mod-playerbots-bis

> Le module n'a pas d'interface graphique propre côté serveur : son « design » est la **voix des bots** dans le chat et les **addons client**.

## 1. Principes

1. **Dire ce qui part, pas seulement ce qui arrive.** Une annonce nomme toujours la pièce remplacée, ou précise « créneau vide ».
2. **Ne jamais mentir** : une main gauche n'est annoncée comme rangée que si elle a réellement quitté le créneau.
3. **Économie de messages** : un seul chuchotement par bot et par cadavre ; un raid de 40 ne doit pas inonder le chat.
4. **Lisible d'un coup d'œil** : palier entre parenthèses, nom d'objet en lien cliquable.
5. **Français** pour les annonces et la documentation.

## 2. Messages des bots

| Moment | Format |
|---|---|
| Revendication | `[Objet] - c'est mon BiS (Vanilla Phase 2 - Blackwing Lair), a la place de [Ancien]` |
| Revendication, créneau libre | `[Objet] - c'est mon BiS (Vanilla Pre-Raid), creneau vide` |
| Pièce de classe | `[Objet] - je le prends a la place de [Ancien] : reserve a ma classe…` |
| Butin de maître | `Je need cet objet : [Objet] a la place de [Ancien] (phase)` |
| Équipement | `J'equipe [Objet] a la place de [Ancien] (palier)` |
| Arme à deux mains | `J'equipe [Baton] a la place de [Epee], et je range [Grimoire] (…)` |

## 3. Addon PlayerbotsBisTooltip

- **Infobulle** : une ligne **par palier** (pas une par combinaison) listant les classes/spés qui veulent l'objet.
- **Code couleur du rang** : vert = 1, jaune = 2, gris = 3, **toujours accompagné du chiffre** (la couleur sert à balayer, le chiffre à trancher).
- Nom de classe toujours écrit, dans sa **couleur de classe**.
- `/pbbis detail` : affichage détaillé, une ligne par classe, spé et palier.
- **Navigateur** `/pbbis` : liste complète créneau par créneau ; `/pbbisraids` ; bouton de minimap masquable.
- **Compositions** `/pbbis compo save | apply | invite | clear` ; **jets** `/pbbis jets`.

## 4. Addon PlayerbotsCensus

Recensement de la population en ligne (classe, race, niveau, zone, guilde) avec l'API 3.3.5a native, sans dépendance.

## 5. Commandes MJ

`.playerbotsbis reload | report | missing | libere | equipe` : sorties textuelles structurées, avec numéro de créneau et raison exacte des refus.
