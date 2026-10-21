<#
    Exporte les SOURCES des pieces rang 1 vers le ButinData.lua de l'addon
    PlayerbotsBisButin.

    POURQUOI CE FICHIER EXISTE. Le client 3.3.5 ne sait pas d'ou tombe un objet :
    ni le boss, ni le donjon. Wowhead compose cela a partir d'une base separee,
    et le module, lui, ne stocke que class/spec/slot/tier/item_id/rank. Ta base
    MONDE, elle, sait tout - c'est elle qu'on lit ici.

    Sans ce fichier, l'addon se charge quand meme : il range simplement tout
    sous "source inconnue" et le dit en clair.

    Le plus simple : donner -WowPath, le dossier qui contient Wow.exe.

      .\export_bis_butin.ps1 -WowPath "C:\Wow335"

    Si PowerShell refuse de lancer le script ("execution de scripts desactivee") :
      powershell -ExecutionPolicy Bypass -File .\tools\export_bis_butin.ps1 -WowPath "C:\Wow335"
#>

param(
    [string] $MySql    = "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe",
    [string] $User     = "acore",
    [string] $Password = "admin",
    [string] $Database = "acore_world",
    [string] $WowPath  = "",
    [switch] $SansCopie,
    [string] $Out      = (Join-Path $PSScriptRoot "..\addon\PlayerbotsBisButin\ButinData.lua")
)

$ErrorActionPreference = 'Stop'

# -WowPath l'emporte, sauf si -Out a ete donne explicitement : taper les deux
# veut dire qu'on sait ce qu'on fait.
if ($WowPath -and -not $PSBoundParameters.ContainsKey('Out')) {
    $addons = Join-Path $WowPath 'Interface\AddOns'
    if (-not (Test-Path $addons)) {
        throw "Dossier AddOns introuvable : $addons`n-WowPath doit pointer sur le dossier contenant Wow.exe."
    }

    # La copie des .lua passe AVANT l'ecriture des donnees : elle cree le
    # dossier s'il manque, et elle ne peut pas ecraser le ButinData.lua qu'on
    # vient d'ecrire, ce qu'un ordre inverse ferait.
    if (-not $SansCopie) {
        & (Join-Path $PSScriptRoot 'install_addon.ps1') -WowPath $WowPath -Addon 'PlayerbotsBisButin'
        Write-Host ""
    }

    $Out = Join-Path $addons 'PlayerbotsBisButin\ButinData.lua'
}

# MYSQL_PWD plutot que -p : evite l'avertissement sur stderr, qui devient fatal
# quand le script est appele depuis un autre ayant pose ErrorActionPreference.
$env:MYSQL_PWD = $Password

function Invoke-Sql([string] $query) {
    $ErrorActionPreference = 'Continue'
    $raw = & $MySql -u $User -N -B $Database -e $query 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "mysql a echoue : $raw"
    }
    return $raw | Where-Object { $_ -notmatch '^mysql: \[Warning\]' }
}

function Escape-Lua([string] $text) {
    return $text.Replace('\', '\\').Replace('"', '\"')
}

function Table-Existe([string] $table) {
    $n = Invoke-Sql "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '$table';"
    return ([int]($n | Select-Object -First 1)) -gt 0
}

function Colonne-Existe([string] $table, [string] $colonne) {
    $n = Invoke-Sql "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '$table' AND COLUMN_NAME = '$colonne';"
    return ([int]($n | Select-Object -First 1)) -gt 0
}

if (-not (Table-Existe 'playerbots_bis_item')) {
    throw "playerbots_bis_item est absente de $Database - importe d'abord les tables du module."
}

# ---------------------------------------------------------------------------
# Les differences de schema qu'on rencontre reellement.
#
# creature.id1 est devenu id1/id2/id3 (plusieurs entrees par spawn) sur les
# revisions recentes d'AzerothCore ; les anciennes ont une simple colonne id.
# Les traductions, elles, vivent soit dans creature_template_locale (ID, locale,
# Name), soit dans l'ancienne locales_creature (entry, name_loc3).
# ---------------------------------------------------------------------------
$colSpawn = if (Colonne-Existe 'creature' 'id1') { 'id1' } else { 'id' }

$joinLocCrea = ''
$nomBoss     = 'ct.name'
if (Table-Existe 'creature_template_locale') {
    $joinLocCrea = "LEFT JOIN creature_template_locale cl ON cl.ID = ct.entry AND cl.locale = 'frFR'"
    $nomBoss     = "COALESCE(NULLIF(cl.Name, ''), ct.name)"
} elseif (Table-Existe 'locales_creature') {
    $joinLocCrea = "LEFT JOIN locales_creature cl ON cl.entry = ct.entry"
    $nomBoss     = "COALESCE(NULLIF(cl.name_loc3, ''), ct.name)"
}

$joinLocItem = ''
$nomItem     = 'it.name'
if (Table-Existe 'item_template_locale') {
    $joinLocItem = "LEFT JOIN item_template_locale il ON il.ID = it.entry AND il.locale = 'frFR'"
    $nomItem     = "COALESCE(NULLIF(il.Name, ''), it.name)"
} elseif (Table-Existe 'locales_item') {
    $joinLocItem = "LEFT JOIN locales_item il ON il.entry = it.entry"
    $nomItem     = "COALESCE(NULLIF(il.name_loc3, ''), it.name)"
}

$tete = "SELECT DISTINCT i.item_id, $nomBoss, IFNULL(c.map, -1), ct.rank, clt.Chance"

# 1. Le butin direct de la creature.
$direct = @"
$tete, 0
FROM playerbots_bis_item i
JOIN creature_loot_template clt ON clt.Item = i.item_id
JOIN creature_template ct ON ct.entry = clt.Entry
$joinLocCrea
LEFT JOIN creature c ON c.$colSpawn = ct.entry
WHERE i.rank = 1
"@

# 2. Le butin passant par une table de reference - c'est le cas de beaucoup de
#    pieces de raid, dont les jetons de tier.
$reference = @"
SELECT DISTINCT i.item_id, $nomBoss, IFNULL(c.map, -1), ct.rank, rlt.Chance, 0
FROM playerbots_bis_item i
JOIN reference_loot_template rlt ON rlt.Item = i.item_id
JOIN creature_loot_template clt ON clt.Reference = rlt.Entry
JOIN creature_template ct ON ct.entry = clt.Entry
$joinLocCrea
LEFT JOIN creature c ON c.$colSpawn = ct.entry
WHERE i.rank = 1
"@

$morceaux = @($direct, $reference)

# 3. Les pieces qu'on ACHETE avec un jeton. La piece elle-meme ne tombe nulle
#    part : c'est le jeton qui tombe. Sans ce morceau, les sept jetons du tier
#    2.5 d'Ahn'Qiraj et les jetons hakkari laisseraient leurs pieces sans
#    source, c'est-a-dire invisibles au moment de choisir un raid.
if (Table-Existe 'playerbots_bis_quest_token') {
    $morceaux += @"
SELECT DISTINCT i.item_id, $nomBoss, IFNULL(c.map, -1), ct.rank, clt.Chance, 1
FROM playerbots_bis_item i
JOIN playerbots_bis_quest_token t ON t.piece_id = i.item_id
JOIN creature_loot_template clt ON clt.Item = t.token_id
JOIN creature_template ct ON ct.entry = clt.Entry
$joinLocCrea
LEFT JOIN creature c ON c.$colSpawn = ct.entry
WHERE i.rank = 1
"@
    $morceaux += @"
SELECT DISTINCT i.item_id, $nomBoss, IFNULL(c.map, -1), ct.rank, rlt.Chance, 1
FROM playerbots_bis_item i
JOIN playerbots_bis_quest_token t ON t.piece_id = i.item_id
JOIN reference_loot_template rlt ON rlt.Item = t.token_id
JOIN creature_loot_template clt ON clt.Reference = rlt.Entry
JOIN creature_template ct ON ct.entry = clt.Entry
$joinLocCrea
LEFT JOIN creature c ON c.$colSpawn = ct.entry
WHERE i.rank = 1
"@
}

Write-Host "Lecture des sources (butin direct, tables de reference, jetons)..."
$sourceRows = Invoke-Sql (($morceaux -join "`nUNION ALL`n") + ";")

Write-Host "Lecture des noms d'objets..."
$nomRows = Invoke-Sql @"
SELECT DISTINCT i.item_id, $nomItem
FROM playerbots_bis_item i
JOIN item_template it ON it.entry = i.item_id
$joinLocItem
WHERE i.rank = 1;
"@

# ---------------------------------------------------------------------------
# Les cartes. Le nom d'une carte n'est PAS dans la base monde - il vit dans les
# DBC du client - donc cette table est ecrite ici. L'ordre est celui de la
# progression : c'est dans cet ordre qu'on choisit un raid, pas dans l'ordre
# alphabetique.
#
# Sans accents, comme le reste du depot : le client 3.3.5 lit du UTF-8 sans
# marque d'ordre des octets, et un fichier ASCII ne peut pas se tromper.
# ---------------------------------------------------------------------------
$cartes = [ordered]@{
    389 = @{ nom = "Gouffre de Ragefeu";        ordre = 10 }
     43 = @{ nom = "Grottes des Lamentations";  ordre = 11 }
     36 = @{ nom = "Les Mortemines";            ordre = 12 }
     33 = @{ nom = "Donjon d'Ombrecroc";        ordre = 13 }
     34 = @{ nom = "Les Carceres";              ordre = 14 }
     48 = @{ nom = "Profondeurs de Brassenoire"; ordre = 15 }
     47 = @{ nom = "Souilles de Tranchebauge";  ordre = 16 }
     90 = @{ nom = "Gnomeregan";                ordre = 17 }
    129 = @{ nom = "Tranchebauge";              ordre = 18 }
    189 = @{ nom = "Monastere ecarlate";        ordre = 19 }
     70 = @{ nom = "Uldaman";                   ordre = 20 }
    209 = @{ nom = "Zul'Farrak";                ordre = 21 }
    349 = @{ nom = "Maraudon";                  ordre = 22 }
    109 = @{ nom = "Temple englouti";           ordre = 23 }
    230 = @{ nom = "Profondeurs de Rochenoire"; ordre = 24 }
    429 = @{ nom = "Hache-tripes";              ordre = 25 }
    289 = @{ nom = "Scholomance";               ordre = 26 }
    329 = @{ nom = "Stratholme";                ordre = 27 }
    229 = @{ nom = "Pic Rochenoire";            ordre = 28 }
    309 = @{ nom = "Zul'Gurub";                 ordre = 40 }
    509 = @{ nom = "Ruines d'Ahn'Qiraj";        ordre = 41 }
    409 = @{ nom = "Coeur du Magma";            ordre = 42 }
    249 = @{ nom = "Repaire d'Onyxia";          ordre = 43 }
    469 = @{ nom = "Repaire de l'Aile noire";   ordre = 44 }
    531 = @{ nom = "Temple d'Ahn'Qiraj";        ordre = 45 }
    533 = @{ nom = "Naxxramas";                 ordre = 46 }
      0 = @{ nom = "Royaumes de l'Est";         ordre = 80 }
      1 = @{ nom = "Kalimdor";                  ordre = 81 }
     -1 = @{ nom = "Sans lieu connu";           ordre = 90 }
}

# ---------------------------------------------------------------------------
# Un objet tombe souvent de plusieurs creatures : le boss, son trash, un rare
# du meme donjon. On n'en garde qu'une - celle qui repond a "ou vais-je le
# chercher" - et l'ordre de preference est explicite plutot que laisse au
# hasard du tri de MySQL.
# ---------------------------------------------------------------------------
$meilleur = @{}

foreach ($row in $sourceRows) {
    $f = $row -split "`t"
    if ($f.Count -lt 6) { continue }

    $id     = [int]$f[0]
    $boss   = $f[1]
    $carte  = [int]$f[2]
    $grade  = [int]$f[3]
    $chance = [double]$f[4]
    $jeton  = [int]$f[5]

    $score = 0
    # Une source directe l'emporte toujours sur un jeton : si la piece tombe
    # elle-meme quelque part, c'est la qu'on l'attend.
    if ($jeton -eq 0)            { $score += 4000 }
    if ($cartes.Contains($carte)) { $score += 1000 }
    if ($grade -eq 3)            { $score += 500 }
    elseif ($grade -ge 1)        { $score += 100 }
    $score += [math]::Min([int]$chance, 99)

    $ancien = $meilleur[$id]
    if ($null -eq $ancien -or $score -gt $ancien.score) {
        $meilleur[$id] = @{ score = $score; boss = $boss; carte = $carte; jeton = $jeton }
    }
}

$noms = @{}
foreach ($row in $nomRows) {
    $f = $row -split "`t"
    if ($f.Count -lt 2) { continue }
    $noms[[int]$f[0]] = $f[1]
}

$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("-- Genere par tools/export_bis_butin.ps1 - ne pas editer a la main.")
[void]$sb.AppendLine("-- Source : $Database (butin des creatures, tables de reference, jetons), $stamp.")
[void]$sb.AppendLine()
[void]$sb.AppendLine("PlayerbotsBisButinStamp = `"$stamp`"")
[void]$sb.AppendLine()

[void]$sb.AppendLine("PlayerbotsBisButinMaps = {")
foreach ($cle in $cartes.Keys) {
    $c = $cartes[$cle]
    [void]$sb.AppendLine("  [$cle] = { nom = `"$(Escape-Lua $c.nom)`", ordre = $($c.ordre) },")
}
[void]$sb.AppendLine("}")
[void]$sb.AppendLine()

[void]$sb.AppendLine("PlayerbotsBisButinSources = {")
foreach ($id in ($meilleur.Keys | Sort-Object)) {
    $m = $meilleur[$id]
    $j = if ($m.jeton -eq 1) { ", jeton = true" } else { "" }
    [void]$sb.AppendLine("  [$id] = { map = $($m.carte), boss = `"$(Escape-Lua $m.boss)`"$j },")
}
[void]$sb.AppendLine("}")
[void]$sb.AppendLine()

[void]$sb.AppendLine("PlayerbotsBisButinNoms = {")
foreach ($id in ($noms.Keys | Sort-Object)) {
    [void]$sb.AppendLine("  [$id] = `"$(Escape-Lua $noms[$id])`",")
}
[void]$sb.AppendLine("}")

$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# UTF-8 sans BOM : le client 3.3.5 avale mal la marque d'ordre des octets.
[System.IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))

$sansSource = 0
foreach ($id in $noms.Keys) {
    if (-not $meilleur.ContainsKey([int]$id)) { $sansSource++ }
}

Write-Host "Ecrit : $Out"
Write-Host "$($meilleur.Count) objets rang 1 avec une source, $($noms.Count) objets rang 1 au total."
if ($sansSource -gt 0) {
    Write-Host "$sansSource objet(s) sans source connue - ils seront groupes sous \"Source inconnue\"." -ForegroundColor Yellow
    Write-Host "  C'est normal pour une piece de quete, de reputation ou d'artisanat." -ForegroundColor Yellow
}
Write-Host "Relance le client (pas un simple /reload) si l'addon vient d'etre installe."
