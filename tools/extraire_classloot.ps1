<#
    Extrait les donnees de l'addon ClassLoot vers un fichier SQL de depart.

    ClassLoot_Data.lua donne, par objet, une note de 3 a 5 etoiles par couple
    classe/spe. PT3-RaidLoot.lua donne, par boss, la liste des objets qui y
    tombent - et donc l'instance, dont se deduit le palier.

    Ce script ne decide rien : il recopie ces deux fichiers dans deux tables,
    telles quelles. La traduction vers l'echelle BiS (classe, spe, creneau,
    palier, rang) est faite ensuite en SQL, ou elle peut s'appuyer sur
    item_template.

    Usage :
      .\tools\extraire_classloot.ps1
      .\tools\extraire_classloot.ps1 -AddonDir "D:\autre\chemin\ClassLoot"
#>
param(
    [string]$AddonDir = "C:\test\world of warcraft 3.3.5a hd\interface\addons\ClassLoot",
    [string]$Sortie   = "$PSScriptRoot\..\data\sql\db-world\base\21_classloot_seed.sql"
)

$ErrorActionPreference = "Stop"

$fData = Join-Path $AddonDir "ClassLoot_Data.lua"
$fPT3  = Join-Path $AddonDir "PT3-RaidLoot.lua"

foreach ($f in @($fData, $fPT3)) {
    if (-not (Test-Path $f)) { throw "Fichier introuvable : $f" }
}

# --- 1. Les notes -------------------------------------------------------
# La forme est  [16795] = { ["Mage"] = 5, }  : l'identifiant ouvre un bloc,
# les lignes suivantes portent les couples cle/note jusqu'au bloc suivant.
$notes = New-Object System.Collections.Generic.List[object]
$idCourant = 0

foreach ($ligne in [System.IO.File]::ReadLines($fData)) {
    if ($ligne -match '^\s*\[(\d+)\]\s*=\s*\{') { $idCourant = [int]$Matches[1]; continue }
    if ($idCourant -and $ligne -match '\["([A-Za-z]+)"\]\s*=\s*(\d+)') {
        $notes.Add([pscustomobject]@{ Id = $idCourant; Cle = $Matches[1]; Etoiles = [int]$Matches[2] })
    }
}

# --- 2. Les sources -----------------------------------------------------
# ["RaidLoot.<Instance>.<Difficulte>.<Boss>"]="id,id,id"
#
# LA DIFFICULTE EST INDISPENSABLE, pas decorative. Naxxramas et Onyxia's Lair
# existent en deux versions qui portent le MEME nom : celle d'origine a 40
# joueurs et celle de WotLK a 10 et 25. Le code de l'addon les separe sur ce
# seul champ - 0 pour la version d'origine, 1 et 2 pour les modes de WotLK :
#
#     if difficulty ~= "0" then
#         l_instance = l_instance..": ".._G["RAID_DIFFICULTY"..difficulty]
#
# La jeter rangerait des objets de niveau 213 dans le palier Naxxramas 40.
#
# Une valeur commencant par "m," est une redirection de LibPeriodicTable vers
# un autre ensemble : elle ne porte aucun identifiant. L'ensemble vise est
# lui-meme declare ailleurs, donc l'ignorer ne perd rien.
$sources = New-Object System.Collections.Generic.List[object]
$redirections = 0

foreach ($ligne in [System.IO.File]::ReadLines($fPT3)) {
    if ($ligne -notmatch '\["RaidLoot\.([^.]+)\.(\d+)\.([^"]*)"\]\s*=\s*"([^"]*)"') { continue }
    $instance   = $Matches[1]
    $difficulte = [int]$Matches[2]
    $charge     = $Matches[4]
    if ($charge.StartsWith("m,")) { $redirections++; continue }
    foreach ($m in [regex]::Matches($charge, '\d+')) {
        $sources.Add([pscustomobject]@{ Id = [int]$m.Value; Instance = $instance; Difficulte = $difficulte })
    }
}

# --- 3. Le fichier SQL --------------------------------------------------
# Converties en tableaux : le decoupage en lots indexe par une plage
# ($liste[0..499]), ce qu'un tableau accepte sans discussion.
$notes   = $notes.ToArray()
$sources = $sources.ToArray()

function Lots($liste, $taille) {
    for ($i = 0; $i -lt $liste.Count; $i += $taille) {
        , $liste[$i..([Math]::Min($i + $taille - 1, $liste.Count - 1))]
    }
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("-- GENERE par tools/extraire_classloot.ps1 - ne pas editer a la main.")
[void]$sb.AppendLine("-- Source : addon ClassLoot (Pneumatus), donnees de Kaliban's Class Loot List.")
[void]$sb.AppendLine("-- Deux tables brutes ; la traduction vers l'echelle BiS est dans 22_classloot.sql.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("DROP TABLE IF EXISTS ``cl_note``;")
[void]$sb.AppendLine("CREATE TABLE ``cl_note`` (")
[void]$sb.AppendLine("    ``item_id`` INT UNSIGNED NOT NULL,")
[void]$sb.AppendLine("    ``cle``     VARCHAR(32) NOT NULL,")
[void]$sb.AppendLine("    ``etoiles`` TINYINT UNSIGNED NOT NULL,")
[void]$sb.AppendLine("    PRIMARY KEY (``item_id``, ``cle``)")
[void]$sb.AppendLine(") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("DROP TABLE IF EXISTS ``cl_source``;")
[void]$sb.AppendLine("CREATE TABLE ``cl_source`` (")
[void]$sb.AppendLine("    ``item_id``    INT UNSIGNED NOT NULL,")
[void]$sb.AppendLine("    ``instance``   VARCHAR(64) NOT NULL,")
[void]$sb.AppendLine("    ``difficulte`` TINYINT UNSIGNED NOT NULL,")
[void]$sb.AppendLine("    PRIMARY KEY (``item_id``, ``instance``, ``difficulte``)")
[void]$sb.AppendLine(") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;")
[void]$sb.AppendLine("")

foreach ($lot in Lots $notes 500) {
    $valeurs = ($lot | ForEach-Object { "($($_.Id),'$($_.Cle)',$($_.Etoiles))" }) -join ","
    [void]$sb.AppendLine("INSERT IGNORE INTO ``cl_note`` (``item_id``,``cle``,``etoiles``) VALUES $valeurs;")
}

# Les noms d'instance portent des apostrophes - Zul'Gurub, Ruins of Ahn'Qiraj -
# qui doivent etre doublees pour SQL.
foreach ($lot in Lots $sources 500) {
    $valeurs = ($lot | ForEach-Object {
        "($($_.Id),'" + $_.Instance.Replace("'", "''") + "',$($_.Difficulte))"
    }) -join ","
    [void]$sb.AppendLine("INSERT IGNORE INTO ``cl_source`` (``item_id``,``instance``,``difficulte``) VALUES $valeurs;")
}

$dossier = Split-Path -Parent $Sortie
if (-not (Test-Path $dossier)) { New-Item -ItemType Directory -Force -Path $dossier | Out-Null }
[System.IO.File]::WriteAllText($Sortie, $sb.ToString(), [System.Text.Encoding]::ASCII)

# --- 4. Le compte rendu -------------------------------------------------
# Les deux premiers chiffres doivent valoir 3369 et 15664 : ce sont ceux
# qu'un comptage direct du fichier a donnes. S'ils different, l'extraction a
# rate quelque chose et le SQL ne vaut rien.
""
"objets notes          : " + ($notes.Id | Sort-Object -Unique).Count + "   (attendu 3369)"
"entrees de note       : " + $notes.Count + "   (attendu 15664)"
"redirections ignorees : $redirections"
"paires objet/instance : " + $sources.Count
"fichier ecrit         : " + (Resolve-Path $Sortie).Path
""
"--- INSTANCES TROUVEES (difficulte 0 = version d'origine) ---"
$sources | Group-Object Instance, Difficulte | Sort-Object Name |
    Select-Object @{n='Instance';e={($_.Group[0]).Instance}},
                  @{n='Diff';e={($_.Group[0]).Difficulte}},
                  @{n='Objets';e={$_.Count}} |
    Sort-Object Instance, Diff | Format-Table -AutoSize
