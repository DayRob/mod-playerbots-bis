<#
.SYNOPSIS
    Importe toutes les listes BiS dans acore_world, puis remet l'addon a jour.

.DESCRIPTION
    Un import a la main se fait dans un ordre precis, et deux pieges attendent
    celui qui le tape ligne par ligne :

      1. "source fichier.sql" n'est PAS du SQL. C'est une commande du client
         interactif mysql, et la passer par -e donne sept ERROR 1064 de suite.
         Le seul moyen fiable depuis PowerShell est de pousser le CONTENU du
         fichier dans l'entree standard de mysql.exe.

      2. L'ORDRE compte. Les fichiers generes effacent d'abord les lignes de
         leur couple classe/spe/palier, donc ils sont rejouables dans n'importe
         quel ordre entre eux. Mais 20_specs_partagees.sql recopie une spe vers
         une autre : il doit passer APRES les listes qu'il recopie, sinon il
         recopie du vide. Et 17_purge_pvp_reputation.sql passe en DERNIER,
         parce que les lignes que 20 vient de recopier peuvent contenir du PvP
         ou de la reputation, que seul 17 sait reconnaitre dans la base monde.

    Le script applique cet ordre, et surtout il SIGNALE les noms non resolus :
    chaque fichier genere porte sa propre requete de verification, dont une
    ligne veut dire "ta base ne connait pas cet objet sous ce nom". C'est la
    seule sortie qui demande une action, donc elle est isolee du reste.

    -WowPath enchaine le reexport de BisData.lua et la copie de l'addon. Sans
    lui, la base est a jour mais l'infobulle de l'addon reste sur ses anciennes
    donnees - c'est exactement l'ecart qui a fait croire une fois que le module
    se trompait alors qu'il avait raison.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\importer_tout.ps1 -WowPath "C:\Wow335"

.EXAMPLE
    Base seulement, sans toucher au client :
    powershell -ExecutionPolicy Bypass -File .\tools\importer_tout.ps1

.PARAMETER Depuis
    Numero du premier fichier a passer. Par defaut 24 : les fichiers 01 a 23
    ne changent plus, et les repasser ne ferait que du travail inutile.

    Sur une base VIERGE, mets -Depuis 1. Les fichiers 17 et 20 passent alors
    deux fois - a leur place alphabetique, puis a la fin - et c'est voulu :
    au premier passage 20 recopie des listes encore absentes, donc il faut
    bien qu'il repasse apres. Les deux sont rejouables.
#>

[CmdletBinding()]
param(
    [string] $MySql    = "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe",
    [string] $User     = "acore",
    [string] $Password = "admin",
    [string] $Database = "acore_world",
    [string] $WowPath  = "",
    [int]    $Depuis   = 24,
    [switch] $SansPurge
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Le mot de passe passe par MYSQL_PWD, pas par -p.
#
# Avec "-pMOTDEPASSE", le client ecrit "Using a password on the command line
# interface can be insecure." sur sa sortie d'ERREUR a chaque appel. PowerShell
# transforme toute ligne de stderr d'un programme externe en enregistrement
# d'erreur, et avec ErrorActionPreference a Stop cet avertissement devient
# FATAL - alors que la requete a reussi. Ce script mourait donc sur son premier
# fichier, sans rien importer.
#
# MYSQL_PWD est lu en silence, et ne laisse plus le mot de passe dans la ligne
# de commande du processus.
# ---------------------------------------------------------------------------
$env:MYSQL_PWD = $Password

if (-not (Test-Path $MySql)) {
    throw "mysql.exe introuvable : $MySql`nPasse le bon chemin avec -MySql."
}

$base = Join-Path $PSScriptRoot '..\data\sql\db-world\base'
if (-not (Test-Path $base)) {
    throw "Dossier SQL introuvable : $base"
}
$base = (Resolve-Path $base).Path

# Une base sans les tables de base ne peut rien recevoir : les fichiers generes
# ecrivent dans playerbots_bis_item, et la recapitulation lit
# playerbots_bis_tier. Mieux vaut le dire ici que laisser defiler trente-deux
# echecs identiques.
# ErrorActionPreference revient a Continue le temps de l'appel : sa portee est
# la fonction, donc la valeur Stop se retablit d'elle-meme ensuite.
function Invoke-MySql([string[]] $arguments) {
    $ErrorActionPreference = 'Continue'
    $sortie = & $MySql @arguments 2>&1
    $script:MySqlCode = $LASTEXITCODE
    return @($sortie | Where-Object { $_ -notmatch '^mysql: \[Warning\]' })
}

$compte = Invoke-MySql @('-u', $User, '-N', '-B', $Database,
                         '-e', 'SELECT COUNT(*) FROM playerbots_bis_tier;')
if ($script:MySqlCode -ne 0) {
    throw "Les tables du module sont absentes de $Database ($compte).`nPasse d'abord 01 et 02 : relance avec -Depuis 1."
}
if ([int]($compte | Select-Object -First 1) -eq 0) {
    Write-Host "playerbots_bis_tier est vide - relance avec -Depuis 1 pour un import a froid." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Un passage de mysql.exe, par l'entree standard.
# ---------------------------------------------------------------------------
function Invoke-SqlFile([System.IO.FileInfo] $fichier) {
    $ErrorActionPreference = 'Continue'
    $sortie = Get-Content $fichier.FullName -Raw |
              & $MySql -u $User --default-character-set=utf8mb4 $Database 2>&1
    $code = $LASTEXITCODE
    $lignes = @($sortie | Where-Object { $_ -notmatch '^mysql: \[Warning\]' })
    return [pscustomobject]@{ Code = $code; Lignes = $lignes }
}

# Les noms non resolus, isoles du reste de la sortie.
#
# VERIFICATION 1 renvoie trois colonnes (slot, rank, nom_non_resolu),
# VERIFICATION 2 en renvoie quatre. Le nombre de colonnes suffit donc a savoir
# ou s'arrete le premier resultat, sans deviner sur le contenu.
function Get-ColonneSignalee([string[]] $lignes, [string] $entete, [int] $colonne) {
    $trouves = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $lignes.Count; $i++) {
        if ($lignes[$i] -notmatch $entete) { continue }
        for ($j = $i + 1; $j -lt $lignes.Count; $j++) {
            $champs = $lignes[$j] -split "`t"
            if ($champs.Count -ne 3) { break }
            $trouves.Add($champs[$colonne])
        }
    }
    return $trouves
}

function Get-NomsNonResolus([string[]] $lignes) {
    return Get-ColonneSignalee $lignes 'nom_non_resolu' 2
}

# Un jeton que les listes reclament mais que le fichier 56 ne sait pas
# convertir : le bot le gagnerait et ne pourrait rien en faire. Detecte ici
# pour la meme raison que les noms non resolus - une VERIFICATION qui defile
# sans que rien ne la lise ne verifie rien. C'est exactement l'erreur commise
# avec l'alias "nom_introuvable", qui a laisse passer deux noms de piece faux.
function Get-JetonsSansConversion([string[]] $lignes) {
    return Get-ColonneSignalee $lignes 'jeton_sans_conversion' 0
}

# ---------------------------------------------------------------------------
# La liste des fichiers, dans l'ordre.
# ---------------------------------------------------------------------------
$listes = Get-ChildItem (Join-Path $base '*.sql') | Where-Object {
    $_.Name -match '^(\d+)_' -and [int]$Matches[1] -ge $Depuis
} | Sort-Object Name

$ordre = @($listes)
$ordre += Get-Item (Join-Path $base '20_specs_partagees.sql')
if (-not $SansPurge) {
    $ordre += Get-Item (Join-Path $base '17_purge_pvp_reputation.sql')
}

Write-Host ""
Write-Host "Import de $($ordre.Count) fichier(s) dans $Database." -ForegroundColor Cyan
Write-Host ""

$echecs    = New-Object System.Collections.Generic.List[string]
$nonResolus = @{}
$jetonsOrphelins = @{}

# Au-dela, un fichier merite qu'on dise combien de temps il a pris : sans ca,
# un fichier lent et un fichier BLOQUE se ressemblent exactement - le nom
# s'affiche, et plus rien ne bouge.
$SECONDES_LENTES = 10

foreach ($f in $ordre) {
    Write-Host ("  {0,-40}" -f $f.Name) -NoNewline
    $chrono = [System.Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-SqlFile $f
    $chrono.Stop()
    $duree = [math]::Round($chrono.Elapsed.TotalSeconds, 1)

    if ($r.Code -ne 0) {
        Write-Host " ECHEC" -ForegroundColor Red
        $echecs.Add($f.Name)
        $r.Lignes | Where-Object { $_ -match 'ERROR' } | ForEach-Object {
            Write-Host "      $_" -ForegroundColor Red
        }
        continue
    }

    # @() force le tableau : PowerShell deroule une liste d'un seul element
    # en une simple chaine, qui n'a pas le .Count attendu plus bas.
    $manquants = @(Get-NomsNonResolus $r.Lignes)
    $sansConv  = @(Get-JetonsSansConversion $r.Lignes)
    $temps = if ($duree -ge $SECONDES_LENTES) { "  [$duree s]" } else { "" }

    $alertes = New-Object System.Collections.Generic.List[string]
    if ($manquants.Count -gt 0) {
        $alertes.Add("$($manquants.Count) nom(s) non resolu(s)")
        $nonResolus[$f.Name] = $manquants
    }
    if ($sansConv.Count -gt 0) {
        $alertes.Add("$($sansConv.Count) jeton(s) sans conversion")
        $jetonsOrphelins[$f.Name] = $sansConv
    }

    if ($alertes.Count -gt 0) {
        Write-Host " ok, $($alertes -join ', ')$temps" -ForegroundColor Yellow
    } else {
        Write-Host " ok$temps" -ForegroundColor Green
    }
}

# ---------------------------------------------------------------------------
# Ce qui demande une action.
# ---------------------------------------------------------------------------
if ($echecs.Count -gt 0) {
    Write-Host ""
    Write-Host "FICHIERS EN ECHEC :" -ForegroundColor Red
    $echecs | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

if ($nonResolus.Count -gt 0) {
    Write-Host ""
    Write-Host "NOMS QUE TA BASE NE CONNAIT PAS" -ForegroundColor Yellow
    Write-Host "Chaque ligne est un objet absent de la liste finale : le creneau" -ForegroundColor Yellow
    Write-Host "garde ses autres rangs, mais celui-la est perdu." -ForegroundColor Yellow
    foreach ($fichier in ($nonResolus.Keys | Sort-Object)) {
        Write-Host ""
        Write-Host "  $fichier" -ForegroundColor Yellow
        $nonResolus[$fichier] | ForEach-Object { Write-Host "    - $_" }
    }
}

if ($jetonsOrphelins.Count -gt 0) {
    Write-Host ""
    Write-Host "JETONS SANS CONVERSION" -ForegroundColor Yellow
    Write-Host "Un bot peut reclamer ces jetons mais rien ne les echange contre" -ForegroundColor Yellow
    Write-Host "une piece : il les gagnerait pour rien." -ForegroundColor Yellow
    foreach ($fichier in ($jetonsOrphelins.Keys | Sort-Object)) {
        Write-Host ""
        Write-Host "  $fichier" -ForegroundColor Yellow
        $jetonsOrphelins[$fichier] | ForEach-Object { Write-Host "    - objet $_" }
    }
}

# ---------------------------------------------------------------------------
# Couverture finale, lue dans la base et non deduite des fichiers.
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Couverture par palier :" -ForegroundColor Cyan
$q = @"
SELECT t.name AS palier, COUNT(DISTINCT i.class, i.spec) AS couples,
       COUNT(*) AS lignes
FROM playerbots_bis_item i
JOIN playerbots_bis_tier t ON t.tier_id = i.tier_id
GROUP BY i.tier_id, t.name ORDER BY i.tier_id;
"@
Invoke-MySql @('-u', $User, '--default-character-set=utf8mb4', '--table', $Database, '-e', $q) |
    ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "Spes vanilla sans aucune arme (le bot n'a pas de cible au creneau 15) :" -ForegroundColor Cyan
# Limite aux paliers vanilla : les paliers TBC et WotLK sont volontairement
# incomplets - ils viennent de la conversion d'origine, pas d'une liste curee -
# et les faire remonter ici noierait la seule ligne qui demande une action.
$q = @"
SELECT t.name AS palier,
       CASE i.class WHEN 1 THEN 'Guerrier' WHEN 2 THEN 'Paladin' WHEN 3 THEN 'Chasseur'
            WHEN 4 THEN 'Voleur' WHEN 5 THEN 'Pretre' WHEN 7 THEN 'Chaman'
            WHEN 8 THEN 'Mage' WHEN 9 THEN 'Demoniste' WHEN 11 THEN 'Druide'
            ELSE CONCAT('classe ', i.class) END AS classe,
       i.spec AS spe
FROM playerbots_bis_item i
JOIN playerbots_bis_tier t ON t.tier_id = i.tier_id
WHERE i.tier_id <= 70
GROUP BY i.tier_id, t.name, i.class, i.spec
HAVING SUM(i.slot = 15) = 0
ORDER BY i.tier_id, i.class, i.spec;
"@
Invoke-MySql @('-u', $User, '--default-character-set=utf8mb4', '--table', $Database, '-e', $q) |
    ForEach-Object { Write-Host "  $_" }

# ---------------------------------------------------------------------------
# L'addon. Une base a jour et un BisData.lua perime se contredisent en silence.
# ---------------------------------------------------------------------------
if ($WowPath) {
    Write-Host ""
    Write-Host "Reexport de BisData.lua et copie de l'addon..." -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'export_bis_tooltip.ps1') -MySql $MySql -User $User `
        -Password $Password -Database $Database
    & (Join-Path $PSScriptRoot 'install_addon.ps1') -WowPath $WowPath
    Write-Host ""
    Write-Host "Dans le jeu : /reload, puis /pbbis info pour verifier la date d'export." -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Base a jour. L'addon, lui, lit encore son ancien BisData.lua :" -ForegroundColor Yellow
    Write-Host "  relance avec -WowPath ""C:\chemin\vers\Wow"" pour le remettre a jour aussi." -ForegroundColor Yellow
}

if ($echecs.Count -gt 0) { exit 1 }
