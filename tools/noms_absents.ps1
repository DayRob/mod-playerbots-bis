<#
.SYNOPSIS
    Liste tous les noms d'objets que ta base monde ne connait pas, fichier par
    fichier, en une seule requete.

.DESCRIPTION
    Les fichiers SQL generes portent chacun leur propre verification, mais elle
    ne parle que de son fichier et defile avec le reste de l'import. Pour voir
    l'ensemble il fallait remonter trente-quatre blocs de sortie.

    Ce script relit les noms directement dans les fichiers - la meme liste que
    l'import pose dans sa table temporaire - et les confronte tous a
    item_template en un passage.

    Un nom absent n'est pas une erreur de l'import : la ligne est simplement
    perdue, le creneau garde ses autres rangs. Mais c'est un rang en moins, et
    quand c'est le rang 1 d'un creneau, le bot vise la piece du dessous sans
    que rien ne le dise.

    Trois causes, et le script les distingue :

      - SUFFIXE ALEATOIRE : "Eternal Crown of Healing" n'existe sous aucun nom
        dans item_template, la base ne connait que "Eternal Crown". Le
        convertisseur en ecarte deja la plupart ; ceux qui passent sont des
        formes que son dictionnaire ne couvre pas.
      - NOM DE LA BASE DIFFERENT : ponctuation, article, orthographe anglaise
        d'une autre version du jeu.
      - OBJET ABSENT de ta base monde, tout simplement.

    Il ne modifie rien.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\noms_absents.ps1
#>

[CmdletBinding()]
param(
    [string] $MySql    = "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe",
    [string] $User     = "acore",
    [string] $Password = "admin",
    [string] $Database = "acore_world",
    [int]    $Depuis   = 1
)

$ErrorActionPreference = 'Stop'

# Comme partout ailleurs : -p ferait ecrire un avertissement sur stderr, que
# Windows PowerShell transforme en erreur fatale sous ErrorActionPreference Stop.
$env:MYSQL_PWD = $Password

if (-not (Test-Path $MySql)) {
    throw "mysql.exe introuvable : $MySql - passe le bon chemin avec -MySql."
}

$base = (Resolve-Path (Join-Path $PSScriptRoot '..\data\sql\db-world\base')).Path

# ---------------------------------------------------------------------------
# Les noms, lus dans les fichiers.
#
# C'est l'EN-TETE de chaque INSERT qui decide, pas la forme des lignes. Deux
# raisons, et les deux ont mordu :
#
#   - 01_playerbots_bis_tier.sql insere des PALIERS, pas des objets. Un motif
#     qui se contente de reconnaitre "(nombre, nombre, 'texte')" y voit dix-huit
#     noms d'objets introuvables - "Vanilla Pre-Raid", "WotLK Phase 2 - Ulduar".
#     Faux positifs purs.
#
#   - Les fichiers cures 03 a 16 ecrivent "(1, 1, 0, 0, 1, 'Nom')", avec CINQ
#     nombres. Le meme motif ne les voyait pas du tout : les listes ecrites a la
#     main, celles qui risquent le plus une faute de frappe, echappaient
#     entierement au controle.
#
# On lit donc la liste de colonnes de l'INSERT en cours. S'il n'y a pas de
# colonne item_name, les lignes qui suivent ne sont pas des objets et on les
# saute. Le nom lui-meme est la seule chaine entre apostrophes de la ligne, ce
# qui evite d'avoir a decouper sur des virgules dont certaines sont DANS le nom
# ("Mish'undare, Circlet of the Mind Flayer").
# ---------------------------------------------------------------------------
$paires = New-Object System.Collections.Generic.List[string]
$total = 0
$ignores = 0

foreach ($f in (Get-ChildItem (Join-Path $base '*.sql') | Sort-Object Name)) {
    if ($f.Name -notmatch '^(\d+)_') { continue }
    if ([int]$Matches[1] -lt $Depuis) { continue }

    $vus = @{}
    $dansObjets = $false
    $attendColonnes = $false

    foreach ($ligne in (Get-Content $f.FullName)) {
        # La liste de colonnes est tantot sur la ligne de l'INSERT, tantot sur
        # la suivante. Sans ce second cas, onze en-tetes etaient pris pour des
        # lignes d'objet illisibles.
        if ($ligne -match '^\s*INSERT\s+(?:IGNORE\s+)?INTO\s+`?\w+`?\s*(.*)$') {
            $reste = $Matches[1]
            if ($reste -match '^\(([^)]*)\)') {
                $dansObjets = $Matches[1] -match 'item_name'
                $attendColonnes = $false
            } else {
                $dansObjets = $false
                $attendColonnes = $true
            }
            continue
        }
        if ($attendColonnes) {
            if ($ligne -match '^\s*\(([^)]*)\)') {
                $dansObjets = $Matches[1] -match 'item_name'
                $attendColonnes = $false
                continue
            }
        }
        if ($ligne -match '^\s*(SELECT|DELETE|UPDATE|CREATE|DROP)\b') {
            $dansObjets = $false; $attendColonnes = $false; continue
        }
        if (-not $dansObjets) { continue }
        if ($ligne -notmatch "^\s*\(") { continue }

        $chaines = [regex]::Matches($ligne, "'((?:[^']|'')*)'")
        if ($chaines.Count -ne 1) { $ignores++; continue }

        $nom = $chaines[0].Groups[1].Value
        if ($vus.ContainsKey($nom)) { continue }
        $vus[$nom] = $true
        $paires.Add("('$($f.Name)','$nom')")
        $total++
    }
}

if ($ignores -gt 0) {
    Write-Host "$ignores ligne(s) d'objet non analysee(s) - signale-le, le motif est a revoir." -ForegroundColor Yellow
}

if ($total -eq 0) {
    Write-Host "Aucun nom trouve dans $base - rien a verifier." -ForegroundColor Yellow
    return
}

Write-Host "$total nom(s) distinct(s) a confronter a item_template." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Une table temporaire, un LEFT JOIN, et seules les lignes sans correspondance.
#
# Le regroupement par MIN(entry) est celui des fichiers generes : deux objets
# peuvent partager un nom - les deux Warblade of the Hakkari, main droite et
# main gauche - et la liste n'en retient qu'un.
# ---------------------------------------------------------------------------
$requete = @"
DROP TEMPORARY TABLE IF EXISTS ``bis_noms_a_verifier``;
CREATE TEMPORARY TABLE ``bis_noms_a_verifier`` (
    ``fichier`` VARCHAR(80) NOT NULL,
    ``nom``     VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO ``bis_noms_a_verifier`` (``fichier``, ``nom``) VALUES
$($paires -join ",`n");

SELECT v.``fichier``, v.``nom`` AS nom_absent
FROM ``bis_noms_a_verifier`` v
LEFT JOIN (SELECT ``name``, MIN(``entry``) AS entry FROM ``item_template`` GROUP BY ``name``) r
  ON r.``name`` COLLATE utf8mb4_general_ci = v.``nom`` COLLATE utf8mb4_general_ci
WHERE r.entry IS NULL
ORDER BY v.``fichier``, v.``nom``;
"@

$ErrorActionPreference = 'Continue'
$sortie = $requete | & $MySql -u $User --default-character-set=utf8mb4 --table $Database 2>&1
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'

$lignes = @($sortie | Where-Object { $_ -notmatch '^mysql: \[Warning\]' })

if ($code -ne 0) {
    Write-Host "La requete a echoue :" -ForegroundColor Red
    $lignes | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

if ($lignes.Count -eq 0) {
    Write-Host ""
    Write-Host "Aucun nom absent : ta base connait les $total objets." -ForegroundColor Green
    return
}

Write-Host ""
$lignes | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "Chaque ligne est un rang perdu dans son creneau. Colle ce tableau et" -ForegroundColor Yellow
Write-Host "je corrige les noms, ou j'ecarte ceux qui n'existent pas." -ForegroundColor Yellow
