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

# Rien n'est supposé d'une table de traduction : ni son nom, ni sa clé, ni sa
# colonne de texte. Une base dont creature_template_locale est clé sur entry
# plutot que sur ID faisait echouer toute la requete sur un ERROR 1054, pour un
# simple confort d'affichage. On regarde, et a defaut on se passe du francais.
function Premiere-Colonne([string] $table, [string[]] $candidats) {
    foreach ($c in $candidats) {
        if (Colonne-Existe $table $c) { return $c }
    }
    return $null
}

function Table-Locale([string] $moderne, [string] $ancienne) {
    # Les deux dispositions rencontrees : la moderne (une ligne par langue,
    # colonne locale) et l'ancienne (une colonne par langue, name_loc3 pour le
    # francais). Ni le nom de la table, ni sa cle, ni sa colonne de texte ne
    # sont supposes - une base dont creature_template_locale est clee sur entry
    # plutot que sur ID faisait echouer tout l'export sur un ERROR 1054.
    $pistes = @(
        @{ table = $moderne;  cles = @('ID', 'entry'); noms = @('Name', 'name') },
        @{ table = $ancienne; cles = @('entry', 'ID'); noms = @('name_loc3') }
    )

    foreach ($piste in $pistes) {
        if (-not $piste.table) { continue }
        if (-not (Table-Existe $piste.table)) { continue }

        $cle = Premiere-Colonne $piste.table $piste.cles
        $nom = Premiere-Colonne $piste.table $piste.noms
        if (-not $cle -or -not $nom) { continue }

        $filtre = ''
        if (Colonne-Existe $piste.table 'locale') { $filtre = " WHERE locale = 'frFR'" }

        return @{ table = $piste.table; cle = $cle; nom = $nom; filtre = $filtre
                  dit = "$($piste.table) ($cle / $nom)" }
    }

    return @{ table = $null; dit = 'aucune - noms en anglais' }
}

$locCrea = Table-Locale 'creature_template_locale' 'locales_creature'
$locItem = Table-Locale 'item_template_locale' 'locales_item'

Write-Host "Traductions des creatures : $($locCrea.dit)"
Write-Host "Traductions des objets    : $($locItem.dit)"
Write-Host "Colonne de spawn          : creature.$colSpawn"
Write-Host ""

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
# POURQUOI LA COLLECTE EST DECOUPEE, ET NON FAITE EN UNE REQUETE
#
# La version evidente - un UNION de jointures entre playerbots_bis_item,
# creature_loot_template, reference_loot_template et creature_template - ne
# revient jamais. La raison tient en une ligne de schema :
#
#     creature_loot_template : PRIMARY KEY (Entry, Item)
#
# Reference n'est PAS indexee. La jointure "clt.Reference = rlt.Entry" repart
# donc en balayage complet de la table de butin pour CHAQUE ligne de reference,
# et le cout devient quadratique. Sur une base complete, c'est des heures.
#
# On fait donc l'inverse de ce qu'on demanderait a un SGBD bien indexe : chaque
# table est lue UNE fois, en bloc ou par paquets d'identifiants, et les
# rapprochements se font ici, dans des tables de hachage. Chaque requete
# ci-dessous est un seul balayage, et l'ensemble tient en quelques secondes.
# ---------------------------------------------------------------------------

# Un IN (...) ne peut pas grossir indefiniment : la ligne de commande Windows
# s'arrete vers 8 000 caracteres. Les identifiants partent donc par paquets.
function Invoke-SqlEnPaquets([string] $avant, [object[]] $ids, [string] $apres, [int] $taille = 400) {
    $sortie = New-Object System.Collections.Generic.List[string]
    if ($null -eq $ids -or $ids.Count -eq 0) { return $sortie }

    for ($i = 0; $i -lt $ids.Count; $i += $taille) {
        $fin = [math]::Min($i + $taille, $ids.Count) - 1
        $paquet = ($ids[$i..$fin]) -join ','
        foreach ($l in (Invoke-Sql "$avant ($paquet) $apres")) { [void]$sortie.Add([string]$l) }
    }
    return $sortie
}

function Colonne-Entiere([object[]] $lignes, [int] $index) {
    $vus = @{}
    foreach ($l in $lignes) {
        $f = ([string]$l) -split "`t"
        if ($f.Count -le $index) { continue }
        $v = 0
        if ([int]::TryParse($f[$index], [ref]$v)) { $vus[$v] = $true }
    }
    return @($vus.Keys)
}

Write-Host "Objets rang 1..."
$rang1 = @(Colonne-Entiere (Invoke-Sql "SELECT DISTINCT i.item_id FROM playerbots_bis_item i WHERE i.rank = 1;") 0)
Write-Host "  $($rang1.Count) objets"

# Les jetons : la piece achetee ne tombe nulle part, c'est le jeton qui tombe.
# Sans ce chemin, les sept jetons du tier 2.5 d'Ahn'Qiraj et les jetons hakkari
# laisseraient leurs pieces sans source, donc invisibles au choix d'un raid.
$pieceDuJeton = @{}   # token_id -> liste de pieces rang 1
if (Table-Existe 'playerbots_bis_quest_token') {
    $voulu = @{}
    foreach ($id in $rang1) { $voulu[$id] = $true }

    foreach ($l in (Invoke-Sql "SELECT DISTINCT token_id, piece_id FROM playerbots_bis_quest_token;")) {
        $f = ([string]$l) -split "`t"
        if ($f.Count -lt 2) { continue }
        $tok = [int]$f[0]; $piece = [int]$f[1]
        if (-not $voulu[$piece]) { continue }
        if (-not $pieceDuJeton.ContainsKey($tok)) { $pieceDuJeton[$tok] = New-Object System.Collections.Generic.List[int] }
        [void]$pieceDuJeton[$tok].Add($piece)
    }
    Write-Host "  $($pieceDuJeton.Count) jeton(s) donnant une piece rang 1"
}

$aChercher = @($rang1 + @($pieceDuJeton.Keys)) | Select-Object -Unique

Write-Host "Butin direct des creatures..."
$lignesDirect = Invoke-SqlEnPaquets "SELECT Entry, Item, Chance FROM creature_loot_template WHERE Item IN" $aChercher ";"
Write-Host "  $($lignesDirect.Count) ligne(s)"

Write-Host "Tables de reference..."
$lignesRef = Invoke-SqlEnPaquets "SELECT Entry, Item, Chance FROM reference_loot_template WHERE Item IN" $aChercher ";"
$refEntries = @(Colonne-Entiere $lignesRef 0)
Write-Host "  $($lignesRef.Count) ligne(s), $($refEntries.Count) reference(s)"

# Qui utilise ces references. C'est la jointure qui mettait la base a genoux ;
# faite dans ce sens, sur une poignee d'identifiants, elle est immediate.
$lignesQuiRef = Invoke-SqlEnPaquets "SELECT Entry, Reference FROM creature_loot_template WHERE Reference IN" $refEntries ";"
Write-Host "  $($lignesQuiRef.Count) creature(s) tirant d'une reference"

# ---------------------------------------------------------------------------
# Les trois tables lues en bloc. Chacune est un seul balayage, et une table de
# hachage cote PowerShell remplace la jointure.
# ---------------------------------------------------------------------------
Write-Host "Creatures (noms, grade, carte)..."

$nomCreature = @{}
$gradeCreature = @{}
foreach ($l in (Invoke-Sql "SELECT ct.entry, ct.name, ct.rank FROM creature_template ct;")) {
    $f = ([string]$l) -split "`t"
    if ($f.Count -lt 3) { continue }
    $e = [int]$f[0]
    $nomCreature[$e] = $f[1]
    $gradeCreature[$e] = [int]$f[2]
}

if ($locCrea.table) {
    foreach ($l in (Invoke-Sql "SELECT $($locCrea.cle), $($locCrea.nom) FROM $($locCrea.table)$($locCrea.filtre);")) {
        $f = ([string]$l) -split "`t"
        if ($f.Count -lt 2) { continue }
        if ($f[1] -and $f[1] -ne 'NULL' -and $f[1].Trim() -ne '') { $nomCreature[[int]$f[0]] = $f[1] }
    }
}

# MIN(map) et non une ligne par spawn : un trash commun a des milliers de
# spawns, et seule sa carte nous interesse.
$carteCreature = @{}
foreach ($l in (Invoke-Sql "SELECT $colSpawn, MIN(map) FROM creature GROUP BY $colSpawn;")) {
    $f = ([string]$l) -split "`t"
    if ($f.Count -lt 2) { continue }
    $carteCreature[[int]$f[0]] = [int]$f[1]
}
Write-Host "  $($nomCreature.Count) creatures, $($carteCreature.Count) avec une carte"

Write-Host "Noms des objets..."
$noms = @{}
foreach ($l in (Invoke-SqlEnPaquets "SELECT entry, name FROM item_template WHERE entry IN" $rang1 ";")) {
    $f = ([string]$l) -split "`t"
    if ($f.Count -lt 2) { continue }
    $noms[[int]$f[0]] = $f[1]
}
if ($locItem.table) {
    $sep = if ($locItem.filtre) { " AND" } else { " WHERE" }
    foreach ($l in (Invoke-SqlEnPaquets "SELECT $($locItem.cle), $($locItem.nom) FROM $($locItem.table)$($locItem.filtre)$sep $($locItem.cle) IN" $rang1 ";")) {
        $f = ([string]$l) -split "`t"
        if ($f.Count -lt 2) { continue }
        if ($f[1] -and $f[1] -ne 'NULL' -and $f[1].Trim() -ne '') { $noms[[int]$f[0]] = $f[1] }
    }
}
Write-Host "  $($noms.Count) noms"

# ---------------------------------------------------------------------------
# Les candidatures : (objet, creature, chance, est-ce un jeton).
# ---------------------------------------------------------------------------
$meilleur = @{}

# Un objet tombe souvent de plusieurs creatures : le boss, son trash, un rare du
# meme donjon. On n'en garde qu'une - celle qui repond a "ou vais-je le chercher"
# - et l'ordre de preference est explicite plutot que laisse au hasard.
#
# Note au fil de l'eau plutot qu'apres coup : une piece vendue en butin de monde
# peut tomber de plusieurs milliers de creatures, et garder toutes ces
# candidatures en memoire avant de les departager coute bien plus cher que de
# comparer chacune au passage.
function Retenir([int] $objet, [int] $creature, [double] $chance, [int] $jeton) {
    $carte = if ($script:carteCreature.ContainsKey($creature)) { $script:carteCreature[$creature] } else { -1 }
    $grade = if ($script:gradeCreature.ContainsKey($creature)) { $script:gradeCreature[$creature] } else { 0 }

    $score = 0
    # Une source directe l'emporte toujours sur un jeton : si la piece tombe
    # elle-meme quelque part, c'est la qu'on l'attend.
    if ($jeton -eq 0)                    { $score += 4000 }
    if ($script:cartes.Contains($carte)) { $score += 1000 }
    if ($grade -eq 3)                    { $score += 500 }
    elseif ($grade -ge 1)                { $score += 100 }
    $score += [math]::Min([int]$chance, 99)

    $ancien = $script:meilleur[$objet]
    if ($null -ne $ancien -and $score -le $ancien.score) { return }

    $boss = if ($script:nomCreature.ContainsKey($creature)) { $script:nomCreature[$creature] } else { "Creature $creature" }
    $script:meilleur[$objet] = @{ score = $score; boss = $boss; carte = $carte; jeton = $jeton }
}

function Ajouter-Candidats([object[]] $lignes, [int] $colEntry, [int] $colItem, [int] $colChance) {
    foreach ($l in $lignes) {
        $f = ([string]$l) -split "`t"
        if ($f.Count -le [math]::Max($colEntry, [math]::Max($colItem, $colChance))) { continue }

        $creature = [int]$f[$colEntry]
        $objet    = [int]$f[$colItem]
        $chance   = [double]$f[$colChance]

        # Une piece rang 1 qui tombe directement.
        if ($script:voulus[$objet]) { Retenir $objet $creature $chance 0 }

        # Un jeton : la source compte pour chaque piece qu'il donne.
        if ($script:pieceDuJeton.ContainsKey($objet)) {
            foreach ($piece in $script:pieceDuJeton[$objet]) {
                Retenir $piece $creature $chance 1
            }
        }
    }
}

$voulus = @{}
foreach ($id in $rang1) { $voulus[$id] = $true }

Ajouter-Candidats $lignesDirect 0 1 2

# Le butin de reference : l'objet vient de la reference, la creature de qui s'en
# sert. On recompose le couple ici.
$creaturesParRef = @{}
foreach ($l in $lignesQuiRef) {
    $f = ([string]$l) -split "`t"
    if ($f.Count -lt 2) { continue }
    $ref = [int]$f[1]
    if (-not $creaturesParRef.ContainsKey($ref)) { $creaturesParRef[$ref] = New-Object System.Collections.Generic.List[int] }
    [void]$creaturesParRef[$ref].Add([int]$f[0])
}

foreach ($l in $lignesRef) {
    $f = ([string]$l) -split "`t"
    if ($f.Count -lt 3) { continue }
    $ref = [int]$f[0]; $objet = [int]$f[1]; $chance = [double]$f[2]
    if (-not $creaturesParRef.ContainsKey($ref)) { continue }

    foreach ($creature in $creaturesParRef[$ref]) {
        if ($voulus[$objet]) { Retenir $objet $creature $chance 0 }
        if ($pieceDuJeton.ContainsKey($objet)) {
            foreach ($piece in $pieceDuJeton[$objet]) {
                Retenir $piece $creature $chance 1
            }
        }
    }
}

Write-Host "$($meilleur.Count) objet(s) rang 1 avec une source."
Write-Host ""

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
    Write-Host "$sansSource objet(s) sans source connue - ils seront groupes sous 'Source inconnue'." -ForegroundColor Yellow
    Write-Host "  C'est normal pour une piece de quete, de reputation ou d'artisanat." -ForegroundColor Yellow
}
Write-Host "Relance le client (pas un simple /reload) si l'addon vient d'etre installe."
