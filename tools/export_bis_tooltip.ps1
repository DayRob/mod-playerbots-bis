<#
    Exporte playerbots_bis_item et playerbots_bis_tier vers le BisData.lua de
    l'addon PlayerbotsBisTooltip.

    L'addon ne tient donc aucune liste a lui : il lit ce que le serveur utilise
    reellement, et une correction des tables se propage a l'infobulle par un
    simple reexport suivi d'un /reload.

    Le plus simple : donner -WowPath, le dossier qui contient Wow.exe. Le script
    en deduit le chemin du BisData.lua de l'addon.

      .\export_bis_tooltip.ps1 -WowPath "C:\Wow335"

    Sans -WowPath ni -Out, le fichier du DEPOT est mis a jour ; install_addon.ps1
    le recopiera ensuite vers le client.

    Si PowerShell refuse de lancer le script ("execution de scripts desactivee") :
      powershell -ExecutionPolicy Bypass -File .\tools\export_bis_tooltip.ps1 -WowPath "C:\Wow335"
#>

param(
    [string] $MySql    = "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe",
    [string] $User     = "acore",
    [string] $Password = "admin",
    [string] $Database = "acore_world",
    [string] $WowPath  = "",
    [string] $Out      = (Join-Path $PSScriptRoot "..\addon\PlayerbotsBisTooltip\BisData.lua")
)

# -WowPath l'emporte, sauf si -Out a ete donne explicitement : taper les deux
# veut dire qu'on sait ce qu'on fait.
if ($WowPath -and -not $PSBoundParameters.ContainsKey('Out')) {
    $addons = Join-Path $WowPath 'Interface\AddOns'
    if (-not (Test-Path $addons)) {
        throw "Dossier AddOns introuvable : $addons`n-WowPath doit pointer sur le dossier contenant Wow.exe."
    }
    $folder = Join-Path $addons 'PlayerbotsBisTooltip'
    if (-not (Test-Path $folder)) {
        throw "L'addon n'est pas installe : $folder`nLance d'abord .\tools\install_addon.ps1 -WowPath ""$WowPath""."
    }
    $Out = Join-Path $folder 'BisData.lua'
}

if (-not (Test-Path $MySql)) {
    throw "mysql.exe introuvable : $MySql - passe le bon chemin avec -MySql."
}

# -N retire la ligne d'en-tete, -B produit du tabule sans bordures.
function Invoke-Sql([string] $query) {
    $raw = & $MySql -u $User "-p$Password" -N -B $Database -e $query 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "mysql a echoue : $raw"
    }
    # L'avertissement sur le mot de passe en clair arrive sur stderr et se
    # retrouve melange a la sortie ; on le jette.
    return $raw | Where-Object { $_ -notmatch '^mysql: \[Warning\]' }
}

function Escape-Lua([string] $text) {
    return $text.Replace('\', '\\').Replace('"', '\"')
}

Write-Host "Lecture des paliers..."
$tierRows = Invoke-Sql "SELECT tier_id, name FROM playerbots_bis_tier ORDER BY tier_id;"

Write-Host "Lecture des objets..."
$itemRows = Invoke-Sql "SELECT i.item_id, i.class, i.spec, i.tier_id, i.rank FROM playerbots_bis_item i ORDER BY i.item_id, i.tier_id, i.rank;"

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("-- Genere par tools/export_bis_tooltip.ps1 - ne pas editer a la main.")
[void]$sb.AppendLine("-- Source : $Database.playerbots_bis_item, $(Get-Date -Format 'yyyy-MM-dd HH:mm').")
[void]$sb.AppendLine()
[void]$sb.AppendLine("PlayerbotsBisTooltipTiers = {")
foreach ($row in $tierRows) {
    $f = $row -split "`t"
    if ($f.Count -lt 2) { continue }
    [void]$sb.AppendLine("  [$($f[0])] = `"$(Escape-Lua $f[1])`",")
}
[void]$sb.AppendLine("}")
[void]$sb.AppendLine()

# Quadruplets a plat (classe, spe, palier, rang) : une table imbriquee par ligne
# ferait exploser la taille du fichier et le temps d'analyse a la connexion.
[void]$sb.AppendLine("PlayerbotsBisTooltipItems = {")

$current = $null
$values  = New-Object System.Collections.Generic.List[string]
$items   = 0

function Flush-Item {
    if ($null -ne $script:current) {
        [void]$script:sb.AppendLine("  [$script:current] = {$($script:values -join ',')},")
        $script:items++
    }
}

foreach ($row in $itemRows) {
    $f = $row -split "`t"
    if ($f.Count -lt 5) { continue }
    if ($f[0] -ne $current) {
        Flush-Item
        $current = $f[0]
        $values.Clear()
    }
    $values.Add($f[1]); $values.Add($f[2]); $values.Add($f[3]); $values.Add($f[4])
}
Flush-Item

[void]$sb.AppendLine("}")

$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# UTF-8 sans BOM : le client 3.3.5 avale mal la marque d'ordre des octets.
[System.IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))

Write-Host "Ecrit : $Out"
Write-Host "$items objets, $($itemRows.Count) lignes, $($tierRows.Count) paliers."
