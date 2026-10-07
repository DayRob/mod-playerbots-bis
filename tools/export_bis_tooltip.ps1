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
    # Le plafond de palier du serveur. -1 signifie "a deduire du fichier de
    # configuration", 0 "aucun plafond", et toute autre valeur s'impose.
    [int]    $MaxTier  = -1,
    # Chemin de playerbots_bis.conf. Vide : on cherche aux endroits habituels.
    [string] $Conf     = "",
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

# ---------------------------------------------------------------------------
# Le plafond de palier du SERVEUR.
#
# L'addon avait jusqu'ici un plafond purement local, a zero par defaut, qu'il
# fallait recopier a la main depuis PlayerbotsBis.MaxTier. Personne ne le fait,
# et le symptome ne designe pas sa cause : avec l'affichage "palier le plus
# haut", une piece best in slot a Zul'Gurub n'affiche que sa ligne TBC Pre-Raid,
# une phase que le serveur ne joue pas.
#
# La valeur vit dans playerbots_bis.conf, qui est sur cette machine. On la lit.
# ---------------------------------------------------------------------------
function Trouver-Conf {
    if ($Conf) {
        if (Test-Path $Conf) { return $Conf }
        throw "Fichier de configuration introuvable : $Conf"
    }
    # Les emplacements habituels d'AzerothCore, relatifs au depot du module.
    $pistes = @(
        # Disposition rencontree en vrai : AzerothCore\configs\modules\.
        # Elle ne figurait dans aucune des trois suivantes, et seule la
        # recherche recursive l'avait trouvee.
        (Join-Path $PSScriptRoot '..\..\..\configs\modules\playerbots_bis.conf'),
        (Join-Path $PSScriptRoot '..\..\..\env\dist\etc\playerbots_bis.conf'),
        (Join-Path $PSScriptRoot '..\..\..\etc\playerbots_bis.conf'),
        (Join-Path $PSScriptRoot '..\..\..\bin\etc\playerbots_bis.conf'),
        (Join-Path $PSScriptRoot '..\conf\playerbots_bis.conf')
    )
    foreach ($p in $pistes) {
        if (Test-Path $p) { return (Resolve-Path $p).Path }
    }

    # Les quatre chemins ci-dessus sont les dispositions habituelles
    # d'AzerothCore, et aucune n'est universelle : build hors arborescence,
    # installation par docker, dossier etc deplace. Plutot que d'abandonner, on
    # fouille la racine du serveur - en general deux niveaux au-dessus du module
    # - sur une profondeur bornee. Un fichier de configuration ne se cache
    # jamais bien loin, et chercher cinq secondes vaut mieux que rendre une
    # valeur fausse en silence.
    $racine = Join-Path $PSScriptRoot '..\..\..'
    if (Test-Path $racine) {
        $trouve = Get-ChildItem -Path $racine -Filter 'playerbots_bis.conf' `
                                -Recurse -Depth 5 -File -ErrorAction SilentlyContinue |
                  Select-Object -First 1
        if ($trouve) { return $trouve.FullName }
    }

    return $null
}

$plafond = $MaxTier
if ($plafond -lt 0) {
    $fichierConf = Trouver-Conf
    if ($fichierConf) {
        foreach ($ligne in (Get-Content $fichierConf)) {
            if ($ligne -match '^\s*PlayerbotsBis\.MaxTier\s*=\s*(\d+)') {
                $plafond = [int]$Matches[1]
                Write-Host "Plafond lu dans $fichierConf : $plafond"
                break
            }
        }
    }
    if ($plafond -lt 0) {
        $plafond = 0
        Write-Host "PlayerbotsBis.MaxTier introuvable - aucun plafond inscrit." -ForegroundColor Yellow
        Write-Host "  Passe -MaxTier <n> ou -Conf <chemin> pour que l'infobulle s'y cale." -ForegroundColor Yellow
    }
}

# Le mot de passe passe par MYSQL_PWD et non par -p.
#
# Avec -p, le client ecrit "Using a password on the command line interface can
# be insecure." sur sa sortie d'ERREUR a chaque appel. Tant que ce script est
# lance seul, PowerShell se contente d'en faire un enregistrement d'erreur non
# fatal et le filtre ci-dessous suffisait. Mais appele depuis un script qui a
# pose ErrorActionPreference a Stop - importer_tout.ps1 - la preference est
# HERITEE, et ce simple avertissement devient fatal alors que la requete a
# reussi. MYSQL_PWD est lu en silence et supprime le probleme a la racine.
$env:MYSQL_PWD = $Password

# -N retire la ligne d'en-tete, -B produit du tabule sans bordures.
function Invoke-Sql([string] $query) {
    # Portee de fonction : la valeur se retablit d'elle-meme a la sortie.
    $ErrorActionPreference = 'Continue'
    $raw = & $MySql -u $User -N -B $Database -e $query 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "mysql a echoue : $raw"
    }
    # Ceinture et bretelles : une autre ligne de stderr ne doit pas finir dans
    # le fichier Lua.
    return $raw | Where-Object { $_ -notmatch '^mysql: \[Warning\]' }
}

function Escape-Lua([string] $text) {
    return $text.Replace('\', '\\').Replace('"', '\"')
}

Write-Host "Lecture des paliers..."
$tierRows = Invoke-Sql "SELECT tier_id, name FROM playerbots_bis_tier ORDER BY tier_id;"

Write-Host "Lecture des objets..."
$itemRows = Invoke-Sql "SELECT i.item_id, i.class, i.spec, i.tier_id, i.rank FROM playerbots_bis_item i ORDER BY i.item_id, i.tier_id, i.rank;"

$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("-- Genere par tools/export_bis_tooltip.ps1 - ne pas editer a la main.")
[void]$sb.AppendLine("-- Source : $Database.playerbots_bis_item, $stamp.")
[void]$sb.AppendLine()
# La date est aussi une valeur Lua, pas seulement un commentaire : un export
# oublie apres un import SQL fait mentir l'infobulle sans rien signaler, et le
# bot - qui lit la base en direct - annonce alors un BiS que l'infobulle ignore.
# /pbbis info affiche cette date pour que l'ecart se voie.
[void]$sb.AppendLine("PlayerbotsBisTooltipStamp = `"$stamp`"")
[void]$sb.AppendLine()
# Le plafond du serveur, dont l'addon se sert par defaut. 0 = aucun.
[void]$sb.AppendLine("PlayerbotsBisTooltipServerMaxTier = $plafond")
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
Write-Host "Plafond de palier inscrit : $(if ($plafond -eq 0) { 'aucun' } else { $plafond })"
