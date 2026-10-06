#!/usr/bin/env python3
"""Convertit une liste BiS copiee depuis wowtbc.gg en fichier SQL.

La page ne peut pas etre lue d'ici - le domaine est bloque par le proxy - donc
l'entree est le TEXTE BRUT copie depuis le navigateur, tel quel. Le format est
regulier et se laisse analyser :

    Lionheart Helm            <- le nom, deux fois
    Lionheart Helm
    enchantLesser Arcanum...  <- l'enchantement, ignore
    head                      <- le creneau : c'est l'ancre
    Blacksmithing             <- la provenance
    BoE Pattern (300)
    Dropdown Arrow            <- separateur, ignore
    Mask of the Unforgiven
    ...

LES RANGS viennent de l'ORDRE D'APPARITION dans un creneau : le premier objet
est le rang 1, le deuxieme le rang 2, les suivants le rang 3. C'est ce que la
page exprime par son menu deroulant, et ca correspond au classement deja
utilise par les listes curees a la main.

ANNEAUX ET BIJOUX : seuls "finger 1" et "trinket 1" sont retenus. Les groupes
"2" rejouent les memes objets dans un autre ordre, et le module apparie
lui-meme le second emplacement - les reprendre creerait deux rangs 1.

PVP ET REPUTATION sont ecartes a la generation, d'apres la provenance : c'est
la regle du projet, et la page nomme sa source pour chaque objet.

Usage :
  python3 tools/convert_wowtbc_bis.py --classe 1 --spec 2 --palier 10 \
      --entree page.txt --sortie data/sql/db-world/base/30_ma_liste.sql
  (--sans-arme-main-gauche pour une spe tank : le creneau 16 est le bouclier)
"""
import argparse
import re
import sys

# Les libelles de creneau de la page -> l'enumeration EquipmentSlots.
#
# Les armes raciales - "orc weapon", "human weapon" - existent parce que la
# specialisation d'arme d'un Orc ou d'un Humain decide du type a porter. La
# table n'a pas de dimension race, donc tout est aplati dans le meme creneau et
# le module choisit selon ce que le bot sait manier.
CRENEAUX = {
    "head": 0, "neck": 1, "shoulder": 2, "shoulders": 2, "back": 14, "cloak": 14,
    "chest": 4, "wrist": 8, "wrists": 8, "hands": 9, "gloves": 9,
    "waist": 5, "belt": 5, "legs": 6, "feet": 7, "boots": 7,
    "finger 1": 10, "ring 1": 10,
    "trinket 1": 12,
    "main hand": 15, "weapon": 15, "two hand": 15, "2h weapon": 15,
    "orc weapon": 15, "human weapon": 15, "dwarf weapon": 15, "troll weapon": 15,
    "off hand": 16, "offhand": 16, "shield": 16,
    "orc off hand": 16, "human off hand": 16,
    "ranged": 17, "relic": 17, "wand": 17, "libram": 17, "idol": 17, "totem": 17,
}

# Les groupes "2" rejouent les memes objets : on les reconnait pour les ignorer
# sans les signaler comme libelles inconnus.
IGNORES = {"finger 2", "ring 2", "trinket 2"}

# Lignes de decor de la page.
DECOR = {"gear", "slot", "source", "dropdown arrow", "alternative", "enchant"}

# Provenances qui disqualifient : la regle du projet ecarte le PvP et la
# reputation, qu'un bot n'ira jamais chercher.
# "arena" tout court est volontairement absent : le Cercle de la Loi de
# Blackrock Depths donne un coffre appele "Arena Spoils", qui est du PvE pur et
# que le mot seul faisait tomber. Il n'y avait pas d'arene en Vanilla ; pour les
# pages TBC et WotLK, ce sont "arena season" et "arena points" qui comptent.
EXCLUS = re.compile(
    r"\b(exalted|revered|honored|friendly|reputation|rank \d|pvp|honor system|"
    r"battleground|alterac valley|warsong gulch|arathi basin|"
    r"arena season|arena points)\b", re.I)

# Suffixes aleatoires de Vanilla. Un objet "Eternal Crown of Healing" n'existe
# pas sous ce nom dans item_template : la base ne connait que "Eternal Crown",
# et le "of Healing" vient d'ItemRandomSuffix, applique a l'exemplaire au
# moment ou il tombe. Le nom complet ne se resout donc JAMAIS.
#
# Et le rabattre sur l'objet de base serait pire que de l'ecarter :
# playerbots_bis_item est indexee par item_id, et toutes les variantes
# partagent le meme. Le bot reclamerait alors "Eternal Crown of the Tiger"
# aussi volontiers que celle de soin.
#
# Le test exige AUSSI l'hotel des ventes, parce que le suffixe seul ne suffit
# pas : "Hands of Power" est un vrai objet, qui tombe sur Quartermaster Zigris.
SUFFIXES_ALEATOIRES = re.compile(
    r"\s+of (?:the (?:Bear|Boar|Eagle|Falcon|Gorilla|Monkey|Owl|Tiger|Whale|Wolf)|"
    r"Agility|Arcane Wrath|Defense|Fiery Wrath|Frozen Wrath|Healing|Intellect|"
    r"Nature's Wrath|Power|Shadow Wrath|Spirit|Stamina|Strength|Marksmanship|"
    r"Concentration|Restoration|Sorcery)$", re.I)

RANG_MAX = 3

# Certaines pages suffixent un objet par la classe a qui il revient :
# "Royal Seal of Eldre'Thalas (Warlock)". item_template ne connait que le nom
# nu, donc le suffixe est retire - sinon la ligne finit en "nom non resolu".
# Qualificatifs que la page accole au nom et que la base ne connait pas : la
# classe (la table est deja indexee par classe), la faction, et la main a
# laquelle l'objet se porte - "(OH)" chez Zul'Gurub.
QUALIFICATIF = re.compile(
    r"\s*\((?:warlock|mage|priest|druid|hunter|rogue|paladin|shaman|warrior|"
    r"death knight|alliance|horde|oh|mh|a|h)\)\s*$", re.I)


def nettoyer(nom):
    return QUALIFICATIF.sub("", nom).strip()


def lire_blocs(lignes):
    """Decoupe le texte en (nom, creneau, provenance)."""
    # Le nom apparait deux fois de suite : c'est l'ancre la plus fiable, parce
    # qu'un nom d'objet peut par ailleurs ressembler a n'importe quoi.
    #
    # Les deux occurrences ne sont pas toujours identiques au caractere pres :
    # la premiere porte parfois un qualificatif que la seconde n'a pas, comme
    # "Warblade of the Hakkari (OH)" a Zul'Gurub. Comparer les noms NETTOYES
    # plutot que bruts rattrape ces blocs, qui disparaissaient en silence.
    def ancre(a, b):
        return bool(a) and nettoyer(a) == nettoyer(b)

    blocs = []
    i = 0
    n = len(lignes)
    while i < n - 1:
        if ancre(lignes[i], lignes[i + 1]):
            nom = lignes[i]
            j = i + 2
            creneau, source = None, []
            while j < n and not (j + 1 < n and ancre(lignes[j], lignes[j + 1])):
                bas = lignes[j].lower()
                if creneau is None and (bas in CRENEAUX or bas in IGNORES):
                    creneau = bas
                elif creneau is not None:
                    source.append(lignes[j])
                j += 1
            blocs.append((nettoyer(nom), creneau, " ".join(source)))
            i = j
        else:
            i += 1
    return blocs


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--classe", type=int, required=True)
    p.add_argument("--spec", required=True,
                   help="une spe, ou plusieurs separees par des virgules quand "
                        "la meme liste les couvre toutes (ex: 0,2)")
    p.add_argument("--palier", type=int, required=True)
    p.add_argument("--entree", required=True)
    p.add_argument("--sortie", required=True)
    p.add_argument("--etiquette", default="", help="texte mis dans le commentaire SQL")
    p.add_argument("--sans-arme-main-gauche", action="store_true",
                   help="spe tank : le creneau 16 reste au bouclier")
    p.add_argument("--garde", default="",
                   help="noms d'objets a conserver malgre la regle PvP/reputation, "
                        "separes par des virgules. Pour les objets ARTISANAUX liables "
                        "dont seul le PATRON demande une reputation : le porteur, lui, "
                        "n'a rien a gagner, donc un bot peut les recevoir.")
    p.add_argument("--exclut", default="",
                   help="noms d'objets a ecarter nommement, separes par des "
                        "virgules. Pour ce que la provenance ne trahit pas : une "
                        "recompense de quete d'Alterac Valley s'affiche comme "
                        "n'importe quelle quete.")
    p.add_argument("--remplace", action="store_true",
                   help="efface d'abord les lignes existantes de ce couple "
                        "classe/spe/palier (sinon elles coexistent, et deux "
                        "rangs 1 se retrouvent dans le meme creneau)")
    args = p.parse_args()

    specs = [int(x) for x in str(args.spec).split(",") if x.strip() != ""]
    if not specs:
        print("--spec est vide", file=sys.stderr)
        return 1

    brut = open(args.entree, encoding="utf-8").read()
    lignes = []
    for l in brut.splitlines():
        l = l.strip()
        bas = l.lower()
        if not l or bas in DECOR or bas.startswith("enchant"):
            continue
        lignes.append(l)

    blocs = lire_blocs(lignes)

    gardes = set(x.strip().lower() for x in args.garde.split(",") if x.strip())
    exclus_nommes = set(x.strip().lower() for x in args.exclut.split(",") if x.strip())

    retenus, ecartes, inconnus = [], [], []
    par_creneau = {}

    for nom, creneau, source in blocs:
        if creneau is None:
            inconnus.append(nom)
            continue
        if creneau in IGNORES:
            continue
        if nom.lower() in exclus_nommes:
            ecartes.append((nom, "ecarte nommement (--exclut)"))
            continue

        if EXCLUS.search(source) and nom.lower() not in gardes:
            ecartes.append((nom, source.strip()))
            continue

        if "Auction House" in source and SUFFIXES_ALEATOIRES.search(nom):
            ecartes.append((nom, "suffixe aleatoire - absent d'item_template"))
            continue

        slot = CRENEAUX[creneau]

        # Une arme de main gauche pour un tank ferait lacher le bouclier. Les
        # boucliers, eux, restent : ils arrivent par "off hand" ou "shield".
        if args.sans_arme_main_gauche and slot == 16 and "off hand" in creneau and creneau != "off hand":
            ecartes.append((nom, "arme de main gauche, spe tank"))
            continue

        rang = min(par_creneau.get(slot, 0) + 1, RANG_MAX)
        par_creneau[slot] = par_creneau.get(slot, 0) + 1

        # Un objet deja vu dans ce creneau - les groupes raciaux en produisent -
        # ne compte qu'une fois.
        if any(r[0] == nom and r[1] == slot for r in retenus):
            par_creneau[slot] -= 1
            continue

        retenus.append((nom, slot, rang))

    etiquette = args.etiquette or "wowtbc.gg"
    out = []
    out.append("-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py")
    out.append("-- Source : %s. Classe %d, spe %s, palier %d."
               % (etiquette, args.classe, ",".join(str(x) for x in specs), args.palier))
    out.append("-- Les rangs viennent de l'ordre d'apparition dans la page.")
    out.append("-- PvP et reputation ecartes a la generation.")
    out.append("")
    out.append("DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;")
    out.append("CREATE TEMPORARY TABLE `bis_seed_wowtbc` (")
    out.append("    `slot`      TINYINT UNSIGNED NOT NULL,")
    out.append("    `rank`      TINYINT UNSIGNED NOT NULL,")
    out.append("    `item_name` VARCHAR(100) NOT NULL")
    out.append(") ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;")
    out.append("")
    out.append("INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES")
    lignes_sql = ["(%2d, %d, '%s')" % (s, r, n.replace("'", "''")) for n, s, r in retenus]
    out.append(",\n".join(lignes_sql) + ";")
    out.append("")
    # Une seule table de depart, posee autant de fois qu'il y a de spes : quand
    # la page couvre plusieurs arbres - c'est le cas du demoniste, du chasseur
    # et du mage - recopier le fichier n'apporterait que des divergences.
    for spec in specs:
        if args.remplace:
            out.append("-- REMPLACE : la liste existante de ce couple classe/spe/palier part")
            out.append("-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau")
            out.append("-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne")
            out.append("-- sait pas departager.")
            out.append("DELETE FROM `playerbots_bis_item`")
            out.append("WHERE `class` = %d AND `spec` = %d AND `tier_id` = %d;"
                       % (args.classe, spec, args.palier))
            out.append("")

        out.append("INSERT IGNORE INTO `playerbots_bis_item`")
        out.append("    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)")
        out.append("SELECT %d, %d, s.`slot`, 0, %d, r.entry, s.`rank`,"
                   % (args.classe, spec, args.palier))
        out.append("       CONCAT('%s - ', s.`item_name`)" % etiquette.replace("'", "''"))
        out.append("FROM `bis_seed_wowtbc` s")
        out.append("JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r")
        out.append("  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;")
        out.append("")

    out.append("-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).")
    out.append("SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu")
    out.append("FROM `bis_seed_wowtbc` s")
    out.append("LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r")
    out.append("  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci")
    out.append("WHERE r.entry IS NULL;")
    out.append("")
    out.append("-- VERIFICATION 2 - couverture obtenue.")
    out.append("SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`")
    out.append("WHERE `class` = %d AND `spec` IN (%s) AND `tier_id` = %d"
               % (args.classe, ",".join(str(x) for x in specs), args.palier))
    out.append("GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;")
    out.append("")
    out.append("DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;")

    open(args.sortie, "w", encoding="ascii", errors="strict").write("\n".join(out) + "\n")

    print("objets retenus : %d sur %d creneaux, poses sur la/les spe(s) %s"
          % (len(retenus), len(par_creneau), ",".join(str(x) for x in specs)))
    print("fichier ecrit  : %s" % args.sortie)
    if ecartes:
        print("\nECARTES (%d) :" % len(ecartes))
        for nom, pourquoi in ecartes:
            print("  - %-38s %s" % (nom, pourquoi[:60]))
    if exclus_nommes:
        vus = set(n.lower() for n, _ in ((x[0], x[1]) for x in ecartes))
        for e in sorted(exclus_nommes):
            if e not in vus:
                print("\nATTENTION : --exclut \"%s\" ne correspond a aucun objet de la page." % e)

    if gardes:
        poses = set(n.lower() for n, _, _ in retenus)
        for g in sorted(gardes):
            if g not in poses:
                print("\nATTENTION : --garde \"%s\" ne correspond a aucun objet de la page." % g)

    if inconnus:
        print("\nSANS CRENEAU RECONNU (%d) - a verifier :" % len(inconnus))
        for nom in inconnus:
            print("  - %s" % nom)
    return 0


if __name__ == "__main__":
    sys.exit(main())
