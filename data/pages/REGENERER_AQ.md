# Regenerer les seize fichiers du palier 60 (Ahn'Qiraj)

Chaque ligne ci-dessous reconstruit son fichier SQL **a l'octet** depuis la page
conservee a cote. C'est verifie, pas suppose : les seize commandes ont ete
rejouees et comparees aux fichiers du depot, seize identiques, zero divergence.

Ce fichier existe pour une raison precise, que le README raconte : les fichiers
24 a 33 ont du rester tels quels alors qu'une regle du convertisseur avait
change, parce que leurs pages n'existaient plus. Une page sans sa commande est a
moitie perdue - on sait quoi relire, pas avec quels arguments.

## Les commandes

```bash
C=tools/convert_wowtbc_bis.py
P=data/pages
B=data/sql/db-world/base

python3 $C --classe 11 --spec 0     --palier 60 --remplace --entree $P/druid_balance_p5.txt     --sortie $B/58_aq_druide_equilibre.sql
python3 $C --classe 11 --spec 10    --palier 60 --remplace --entree $P/druid_feral_tank_p5.txt  --sortie $B/59_aq_druide_ours.sql
python3 $C --classe 11 --spec 1     --palier 60 --remplace --entree $P/druid_feral_dps_p5.txt   --sortie $B/60_aq_druide_chat.sql
python3 $C --classe 11 --spec 2     --palier 60 --remplace --entree $P/druid_resto_p5.txt       --sortie $B/61_aq_druide_restauration.sql
python3 $C --classe 3  --spec 0,1,2 --palier 60 --remplace --entree $P/hunter_p5.txt            --sortie $B/62_aq_chasseur.sql
python3 $C --classe 8  --spec 0,1,2 --palier 60 --remplace --entree $P/mage_p5.txt              --sortie $B/63_aq_mage.sql
python3 $C --classe 5  --spec 1     --palier 60 --remplace --entree $P/priest_holy_p5.txt       --sortie $B/64_aq_pretre_sacre.sql
python3 $C --classe 5  --spec 2     --palier 60 --remplace --entree $P/priest_shadow_p5.txt     --sortie $B/65_aq_pretre_ombre.sql
python3 $C --classe 4  --spec 1     --palier 60 --remplace --entree $P/rogue_combat_p5.txt      --sortie $B/66_aq_voleur_combat.sql
python3 $C --classe 7  --spec 0     --palier 60 --remplace --entree $P/shaman_elem_p5.txt       --sortie $B/67_aq_chaman_elementaire.sql
python3 $C --classe 7  --spec 2     --palier 60 --remplace --entree $P/shaman_resto_p5.txt      --sortie $B/68_aq_chaman_restauration.sql
python3 $C --classe 7  --spec 1     --palier 60 --remplace --entree $P/shaman_enh_p5.txt        --sortie $B/69_aq_chaman_amelioration.sql
python3 $C --classe 9  --spec 0,2   --palier 60 --remplace --entree $P/warlock_affli_p5.txt     --sortie $B/70_aq_demoniste.sql
python3 $C --classe 1  --spec 1     --palier 60 --remplace --entree $P/warrior_fury_p5.txt      --sortie $B/71_aq_guerrier_fureur.sql
python3 $C --classe 1  --spec 2     --palier 60 --remplace --sans-arme-main-gauche --entree $P/warrior_prot_p5.txt --sortie $B/72_aq_guerrier_protection.sql
python3 $C --classe 1  --spec 0     --palier 60 --remplace --entree $P/warrior_arms_p5.txt      --sortie $B/73_aq_guerrier_armes.sql
```

Puis la ligne 2 de chaque fichier, que le convertisseur ecrit `wowtbc.gg.` et
qui doit nommer la phase :

```bash
sed -i '2s|-- Source : wowtbc.gg.|-- Source : Vanilla P5 AQ (wowtbc.gg).|' $B/5[89]_aq_*.sql $B/6*_aq_*.sql $B/7[0-2]_aq_*.sql
sed -i '2s|-- Source : wowtbc.gg.|-- Source : Vanilla P5 AQ (wowtbc.gg), page Fury sans ses armes.|' $B/73_aq_guerrier_armes.sql
```

## Les choix que les commandes portent, et pourquoi

**`--remplace` partout.** Il ecrit le `DELETE` qui efface la liste du couple
classe/spe/palier avant de poser la nouvelle. Les seize fichiers ont d'abord ete
generes SANS, et les lignes du fichier 02 - la conversion d'origine, dont les
rangs ne sortent d'aucun guide - survivaient a cote, toutes au rang 1. Deux
objets de rang 1 dans un creneau, l'echelle ne peut pas les departager.

**`--spec 0,1,2` pour le chasseur et le mage.** Leurs pages ne distinguent pas
les arbres : une seule liste pour les trois. Le convertisseur pose la meme table
de depart trois fois plutot que de dupliquer le fichier.

**`--spec 0,2` pour le demoniste.** Les pages Affliction et Destruction de cette
phase sont **identiques mot pour mot** - verifie par `diff`. La spe 1
(Demonologie) est remplie par la recopie de `20_specs_partagees.sql`, qui passe
apres tous les fichiers numerotes.

**`--sans-arme-main-gauche` pour la protection seule.** Sa page separe le
bouclier (`off hand`) de l'arme de main gauche (`off hand weapon`, `orc off
hand`). Sans l'option, un bot tank equiperait une arme et lacherait son
bouclier.

**La page du guerrier Armes est la page Fury amputee.** `warrior_arms_p5.txt`
est `warrior_fury_p5.txt` dont les quatre groupes d'arme ont ete retires - Fury
se bat a deux armes a une main, son creneau 15 ne vaut rien pour Armes et son 16
lui serait nuisible. Les deux spes portent la MEME armure, et wowtbc.gg n'a pas
de page Arms pour cette phase. L'arme a deux mains arrive par le fichier 74, qui
n'est pas genere.

## Ce qui n'est PAS regenere par ces commandes

- `74_aq_guerrier_armes_deux_mains.sql` - ecrit a la main, classement issu des
  guides, a verifier avec `tools/armes_deux_mains_palier_60.sql`
- `75_aq_jetons_qiraji.sql` - ecrit a la main, mais ne nomme que dix jetons : la
  piece et la classe sortent de la base monde
