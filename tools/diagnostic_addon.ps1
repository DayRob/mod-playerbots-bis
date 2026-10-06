<#
.SYNOPSIS
    Dit POURQUOI l'infobulle de l'addon n'est pas a jour.

.DESCRIPTION
    Entre la base et l'infobulle il y a quatre maillons, et chacun peut casser
    sans rien dire :

      1. la base contient les lignes          (import SQL)
      2. le BisData.lua du DEPOT les porte    (export_bis_tooltip.ps1)
      3. le BisData.lua du CLIENT est copie   (install_addon.ps1)
      4. le client a relu le fichier          (quitter et relancer le jeu)

    Un maillon casse donne toujours le meme symptome vu du jeu : "l'infobulle
    n'est pas a jour". Ce script lit les quatre et nomme celui qui manque, au
    lieu de laisser deviner.

    Il ne modifie rien.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\diagnostic_addon.ps1 -WowPath "C:\Wow335"
#>

[CmdletBinding()]
param(
    [string] $MySql    = "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe",
    [string] $User     = "acore",
    [string] $Password = "admin",
    [string] $Database = "acore_world",
    [string] $WowPath  = ""
)

$ErrorActionPreference = 'Stop'

$source = (Resolve-Path (Join-Path $PSScriptRoot '..\addon\PlayerbotsBisTooltip')).Path

# ---------------------------------------------------------------------------
# Appeler mysql.exe sans se faire arreter par son propre avertissement.
#
# Deux pieges se combinent, et ensemble ils tuent le script a la premiere
# requete :
#
#   - "-pMOTDEPASSE" sur la ligne de commande fait ecrire au client
#     "Using a password on the command line interface can be insecure."
#     sur sa sortie d'ERREUR, a chaque appel.
#
#   - PowerShell transforme toute ligne de stderr d'un programme externe en
#     enregistrement d'erreur. Avec ErrorActionPreference a Stop, cet
#     avertissement devient donc une erreur FATALE - alors que la requete,
#     elle, a parfaitement reussi.
#
# Le mot de passe passe donc par MYSQL_PWD, que le client lit sans rien dire,
# et qui a l'avantage de ne plus l'exposer dans la ligne de commande du
# processus. Et par precaution la preference revient a Continue dans la
# fonction - sa portee est locale, donc elle se restaure a la sortie - pour
# qu'une autre ligne de stderr ne fasse pas tomber le script non plus.
# ---------------------------------------------------------------------------
$env:MYSQL_PWD = $Password
$script:MySqlCode = 0

function Invoke-MySql([string[]] $arguments) {
    $ErrorActionPreference = 'Continue'
    $sortie = & $MySql @arguments 2>&1
    $script:MySqlCode = $LASTEXITCODE
    return @($sortie | Where-Object { $_ -notmatch '^mysql: \[Warning\]' })
}

function Titre([string] $t) {
    Write-Host ""
    Write-Host $t -ForegroundColor Cyan
    Write-Host ('-' * $t.Length) -ForegroundColor Cyan
}

# Lit un BisData.lua et en rend l'horodatage, le nombre d'objets et les paliers.
#
# Le format est plat par choix : une ligne par objet, et des quadruplets
# (classe, spe, palier, rang) a la suite. Le palier est donc la TROISIEME valeur
# de chaque groupe de quatre - compter autrement melangerait les rangs et les
# paliers, qui vivent dans le meme intervalle de nombres.
function Lire-BisData([string] $chemin) {
    if (-not (Test-Path $chemin)) {
        return [pscustomobject]@{ Existe = $false }
    }

    $lignes = Get-Content $chemin
    $substitut = -not ($lignes | Where-Object { $_ -match 'PlayerbotsBisTooltipItems' })

    # Ligne par ligne, et non sur le texte entier : l'horodatage est en DEUXIEME
    # ligne du fichier genere, et une ancre ^ posee sur une chaine entiere ne
    # vaut que pour son tout debut. C'est le piege qu'install_addon.ps1 evite
    # deja de la meme facon.
    $stamp = $null
    foreach ($l in $lignes) {
        if ($l -match '^--\s*Source\s*:.*?(\d{4}-\d{2}-\d{2} \d{2}:\d{2})') {
            $stamp = $Matches[1]
            break
        }
    }

    $objets = 0
    $paliers = @{}
    foreach ($ligne in $lignes) {
        if ($ligne -notmatch '^\s*\[(\d+)\]\s*=\s*\{([\d,]*)\}') { continue }
        $objets++
        $valeurs = $Matches[2].TrimEnd(',') -split ','
        for ($i = 0; $i + 3 -lt $valeurs.Count; $i += 4) {
            $t = [int]$valeurs[$i + 2]
            $paliers[$t] = ($paliers[$t] + 1)
        }
    }

    return [pscustomobject]@{
        Existe    = $true
        Substitut = $substitut
        Stamp     = $stamp
        Objets    = $objets
        Paliers   = $paliers
        Chemin    = $chemin
    }
}

function Afficher-BisData($d, [string] $quoi) {
    if (-not $d.Existe) {
        Write-Host "  $quoi : ABSENT" -ForegroundColor Red
        return
    }
    if ($d.Substitut) {
        Write-Host "  $quoi : SUBSTITUT - aucune donnee, l'export n'a jamais tourne ici." -ForegroundColor Red
        return
    }
    Write-Host "  $quoi : exporte le $($d.Stamp), $($d.Objets) objets" -ForegroundColor Green
    $cles = $d.Paliers.Keys | Sort-Object
    $resume = ($cles | ForEach-Object { "$_ ($($d.Paliers[$_]))" }) -join '  '
    Write-Host "    paliers : $resume"
}

# ---------------------------------------------------------------------------
# 1. La base
# ---------------------------------------------------------------------------
Titre "1. La base ($Database)"

if (-not (Test-Path $MySql)) {
    Write-Host "  mysql.exe introuvable : $MySql" -ForegroundColor Red
    Write-Host "  Passe le bon chemin avec -MySql ; les maillons 2 a 4 restent lisibles." -ForegroundColor Yellow
    $baseLue = $false
} else {
    $requete = @"
SELECT i.tier_id AS palier, t.name AS nom,
       COUNT(DISTINCT i.class, i.spec) AS couples, COUNT(*) AS lignes
FROM playerbots_bis_item i
LEFT JOIN playerbots_bis_tier t ON t.tier_id = i.tier_id
WHERE i.tier_id <= 70
GROUP BY i.tier_id, t.name ORDER BY i.tier_id;
"@
    $lignesSql = Invoke-MySql @('-u', $User, '--default-character-set=utf8mb4',
                                '--table', $Database, '-e', $requete)
    if ($script:MySqlCode -ne 0) {
        Write-Host "  La requete a echoue :" -ForegroundColor Red
        $lignesSql | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        $baseLue = $false
    } else {
        $lignesSql | ForEach-Object { Write-Host "  $_" }
        $baseLue = $true
    }
}

# ---------------------------------------------------------------------------
# 2. Le depot
# ---------------------------------------------------------------------------
Titre "2. Le BisData.lua du depot"
$depot = Lire-BisData (Join-Path $source 'BisData.lua')
Afficher-BisData $depot 'depot'

# ---------------------------------------------------------------------------
# 3. Le client
# ---------------------------------------------------------------------------
Titre "3. Le dossier de l'addon dans le client"

$client = $null
$cible  = $null
if (-not $WowPath) {
    Write-Host "  -WowPath n'a pas ete donne : impossible de regarder le client." -ForegroundColor Yellow
} else {
    $addons = Join-Path $WowPath 'Interface\AddOns'
    if (-not (Test-Path $addons)) {
        Write-Host "  Dossier AddOns introuvable : $addons" -ForegroundColor Red
        Write-Host "  -WowPath doit pointer sur le dossier qui contient Wow.exe." -ForegroundColor Yellow
    } else {
        $cible = Join-Path $addons 'PlayerbotsBisTooltip'
        if (-not (Test-Path $cible)) {
            Write-Host "  L'addon n'est pas installe : $cible" -ForegroundColor Red
        } else {
            Write-Host "  $cible"
            $client = Lire-BisData (Join-Path $cible 'BisData.lua')
            Afficher-BisData $client 'client'

            # Un fichier .lua absent du dossier du client n'existe pas pour le
            # jeu, meme s'il est liste dans le .toc : le chargement saute la
            # ligne en silence. C'est ce qui fait disparaitre une fenetre
            # entiere sans aucun message.
            $manquants = @()
            foreach ($f in Get-ChildItem -Path $source -File) {
                if (-not (Test-Path (Join-Path $cible $f.Name))) { $manquants += $f.Name }
            }
            if ($manquants.Count -gt 0) {
                Write-Host "  FICHIERS ABSENTS du client : $($manquants -join ', ')" -ForegroundColor Red
            } else {
                Write-Host "  tous les fichiers du depot sont presents." -ForegroundColor Green
            }

            function Version([string] $toc) {
                if (-not (Test-Path $toc)) { return '?' }
                foreach ($l in Get-Content $toc) {
                    if ($l -match '^##\s*Version\s*:\s*(.+)$') { return $Matches[1].Trim() }
                }
                return '?'
            }
            $vd = Version (Join-Path $source 'PlayerbotsBisTooltip.toc')
            $vc = Version (Join-Path $cible  'PlayerbotsBisTooltip.toc')
            if ($vd -eq $vc) {
                Write-Host "  version du .toc : $vc des deux cotes." -ForegroundColor Green
            } else {
                Write-Host "  version du .toc : depot $vd, client $vc - la copie n'a pas eu lieu." -ForegroundColor Red
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Verdict
# ---------------------------------------------------------------------------
Titre "Verdict"

if ($depot.Existe -and $depot.Substitut) {
    Write-Host "  Maillon 2 casse : le depot porte encore le substitut." -ForegroundColor Red
    Write-Host "  L'export n'a jamais tourne, ou il a echoue sans que tu le voies." -ForegroundColor Red
    Write-Host ""
    Write-Host "  A faire :" -ForegroundColor Yellow
    Write-Host "    powershell -ExecutionPolicy Bypass -File .\tools\export_bis_tooltip.ps1"
    if ($WowPath) {
        Write-Host "    powershell -ExecutionPolicy Bypass -File .\tools\install_addon.ps1 -WowPath ""$WowPath"""
    }
} elseif ($client -and $client.Existe -and $client.Substitut) {
    Write-Host "  Maillon 3 casse : le depot a un vrai export, le client garde le substitut." -ForegroundColor Red
    Write-Host "  A faire : .\tools\install_addon.ps1 -WowPath ""$WowPath""" -ForegroundColor Yellow
} elseif ($client -and $client.Existe -and $depot.Stamp -and $client.Stamp -ne $depot.Stamp) {
    Write-Host "  Maillon 3 en retard : depot $($depot.Stamp), client $($client.Stamp)." -ForegroundColor Yellow
    Write-Host "  A faire : .\tools\install_addon.ps1 -WowPath ""$WowPath""" -ForegroundColor Yellow
} elseif ($client -and $client.Existe -and -not $client.Substitut) {
    Write-Host "  Les trois maillons hors du jeu sont bons." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Reste le quatrieme, dans le jeu :" -ForegroundColor Yellow
    Write-Host "    - QUITTE le client entierement et relance-le. Un /reload ne suffit"
    Write-Host "      pas pour un fichier .lua nouveau, et pas toujours pour un fichier"
    Write-Host "      change."
    Write-Host "    - puis /pbbis info : la date affichee doit etre $($client.Stamp)."
    Write-Host "    - si la date est bonne mais qu'un palier manque a l'infobulle,"
    Write-Host "      regarde la ligne 'maxtier' de /pbbis info. Un plafond pose un"
    Write-Host "      jour par /pbbis maxtier reste enregistre et masque tout"
    Write-Host "      au-dessus. /pbbis maxtier 0 l'enleve."
} elseif (-not $WowPath) {
    Write-Host "  Relance avec -WowPath pour que le client soit regarde aussi." -ForegroundColor Yellow
}
