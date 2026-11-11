# Sabre Windfury

Un bruit de sabre laser à chaque proc de **Furie-des-vents**.

```
/sabre test              joue le son maintenant
/sabre on | off          allume ou éteint
/sabre chemin <chemin>   change le fichier
```

## Le fichier son — à fournir toi-même

L'addon ne contient aucun son : je ne peux pas t'en livrer un, et un sabre
laser n'est pas libre de droits. Dépose le tien ici :

```
Interface\AddOns\SabreWindfury\sabre.ogg
```

**Format.** Le client 3.3.5 lit l'**OGG Vorbis** de façon fiable ; le MP3 passe
parfois, le WAV souvent, mais l'OGG est le seul sur lequel je parierais. Si
`/sabre test` reste muet alors que le chemin est bon, c'est presque toujours le
format.

**Durée.** Vise moins d'une seconde. Furie-des-vents proque souvent : un son de
deux secondes se chevauche avec le suivant et devient un grognement continu.

Un autre chemin fonctionne aussi, du moment qu'il part de `Interface\` :

```
/sabre chemin Interface\AddOns\MonDossier\monson.ogg
```

## Ce que l'addon écoute, et pourquoi

Un proc de Furie-des-vents n'est pas un sort lancé : c'est une **attaque
supplémentaire** accordée par l'enchantement d'arme. Dans le journal de combat
elle apparaît comme `SPELL_EXTRA_ATTACKS`, et c'est le seul événement qui
marque le proc lui-même — les dégâts qui suivent sont deux lignes séparées, qui
feraient sonner deux fois.

Le sort est reconnu **par son nom**, pas par son identifiant : Furie-des-vents a
sept rangs et son attaque plusieurs aussi. `GetSpellInfo(25504)` donne le nom
traduit par ton client, donc la comparaison marche en français sans table de
correspondance. Si ce sort manque sur le serveur, un filtre par motif prend le
relais (`windfury`, `furie-des-vents`).

Deux garde-fous :

- **Toi seulement.** Sans le test `sourceGUID == UnitGUID("player")`, chaque
  chaman du raid ferait sonner ton casque. En Naxxramas ce serait continu.
- **0,35 seconde entre deux sons.** Deux procs peuvent tomber à quelques
  centièmes l'un de l'autre.

## Si tu préfères vraiment une WeakAura

C'est faisable, mais je ne peux pas te livrer la chaîne d'import : elle est
sérialisée puis compressée puis encodée, et une chaîne écrite sans pouvoir
l'essayer donne presque toujours « chaîne d'import invalide », sans dire où.

À la main, c'est trois minutes :

1. Nouvelle aura, type **Modèle → vide**, affichage **Texte** (il restera vide).
2. Déclencheur : **Événement personnalisé** → `COMBAT_LOG_EVENT_UNFILTERED`,
   et dans la fonction de déclenchement :

```lua
function(event, _, sousEvenement, sourceGUID, _, _, _, _, _, _, nomDuSort)
    return sousEvenement == "SPELL_EXTRA_ATTACKS"
       and sourceGUID == UnitGUID("player")
       and nomDuSort == GetSpellInfo(25504)
end
```

3. Actions → **Au démarrage** → *Jouer un son* → *Son personnalisé* →
   `Interface\AddOns\SabreWindfury\sabre.ogg`.

L'addon fait déjà tout ça, avec en plus le verrou de 0,35 seconde que la
WeakAura n'a pas.
