<#
.SYNOPSIS
    Dit pourquoi des bots niveau 1 se connectent encore malgre le filtre.

.DESCRIPTION
    Trois causes possibles, et elles demandent des reponses opposees :

      1. le module n'a pas ete recompile - BisBotGate.cpp est du C++, un
         git pull ne suffit pas ;
      2. il l'a ete, mais PlayerbotsBis.MinBotLevel manque au fichier de
         configuration, donc le filtre reste a 0 (desactive) ;
      3. tout est en place et le filtre travaille - les bots vus etaient deja
         connectes avant, ou le serveur n'a pas redemarre depuis.

    Elles se distinguent a un detail que le journal donne gratuitement.
    AzerothCore se plaint d'un reglage qu'un module LUI DEMANDE et qu'il ne
    trouve pas :

        Config: Missing property PlayerbotsBis.MinBotLevel ...

    Ce message ne peut sortir que d'un binaire qui connait le reglage. Sa
    presence prouve donc la recompilation, et son absence - combinee a celle du
    reglage dans le fichier - prouve le contraire. On lit une cause dans ce que
    le serveur dit de lui-meme, au lieu de la supposer.

    Le script ne modifie rien.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\diagnostic_filtre_bots.ps1
#>

[CmdletBinding()]
param(
    [string]   $Mysql,
    [string]   $Utilisateur = 'acore',
    [string]   $MotDePasse  = 'admin',
    [string]   $Conf,
    [string]   $Logs = 'C:\Azerothcore\logs',
    [string[]] $Racine = @('C:\Azerothcore', 'C:\AzerothCore', 'C:\azerothcore')
)

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '=== Pourquoi des bots niveau 1 passent encore ===' -ForegroundColor Cyan
Write-Host ''

# --- 1. Le fichier de configuration du module ------------------------------
if (-not $Conf) {
    foreach ($r in $Racine) {
        if (-not (Test-Path $r)) { continue }
        $f = Get-ChildItem -Path $r -File -Recurse -Filter 'playerbots_bis.conf' -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -notlike '*.dist' } | Select-Object -First 1
        if ($f) { $Conf = $f.FullName; break }
    }
}

$reglagePose = $false
$valeur = '(fichier introuvable)'
if ($Conf -and (Test-Path $Conf)) {
    Write-Host ("Configuration : {0}" -f $Conf) -ForegroundColor DarkGray
    $valeur = '(absent)'
    foreach ($l in (Get-Content -LiteralPath $Conf)) {
        if ($l -match '^\s*PlayerbotsBis\.MinBotLevel\s*=\s*(.*?)\s*$') { $valeur = $Matches[1]; break }
    }
    $reglagePose = ($valeur -match '^\d+$' -and [int]$valeur -gt 0)
}
else {
    Write-Host 'playerbots_bis.conf INTROUVABLE' -ForegroundColor Red
}
Write-Host ("  PlayerbotsBis.MinBotLevel = {0}" -f $valeur) `
    -ForegroundColor $(if ($reglagePose) { 'Green' } else { 'Red' })
Write-Host ''

# --- 2. Ce que le serveur dit de lui-meme ----------------------------------
$journaux = @()
if (Test-Path $Logs) {
    $journaux = @(Get-ChildItem -Path $Logs -File -Filter '*.log' -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 5)
}
if (-not $journaux.Count) {
    Write-Host ("Aucun journal sous {0} - relance avec -Logs <dossier>" -f $Logs) -ForegroundColor Red
    Write-Host ''
    exit 1
}
Write-Host ("Journaux lus : {0}" -f ($journaux.Name -join ', ')) -ForegroundColor DarkGray

function Chercher {
    param([string] $Motif)
    return @(Select-String -Path $journaux.FullName -Pattern $Motif -ErrorAction SilentlyContinue)
}

# Ce message ne peut venir que d'un binaire qui connait le reglage : c'est la
# preuve de recompilation, et elle ne coute rien a obtenir.
$seReclame  = (Chercher 'Missing property PlayerbotsBis\.MinBotLevel').Count -gt 0
$aDemarre   = (Chercher '\[mod-playerbots-bis\] Active').Count -gt 0
$aExpulse   = (Chercher '\[mod-playerbots-bis\].*deconnecte')

Write-Host ''
Write-Host ("  module charge au demarrage      : {0}" -f $(if ($aDemarre) { 'oui' } else { 'NON' })) `
    -ForegroundColor $(if ($aDemarre) { 'Green' } else { 'Red' })
Write-Host ("  binaire connait MinBotLevel     : {0}" -f $(if ($seReclame -or $reglagePose) { 'probable' } else { 'NON - pas recompile' })) `
    -ForegroundColor $(if ($seReclame -or $reglagePose) { 'Green' } else { 'Red' })
Write-Host ("  expulsions enregistrees         : {0}" -f $aExpulse.Count) `
    -ForegroundColor $(if ($aExpulse.Count) { 'Green' } else { 'Yellow' })
Write-Host ''

if ($aExpulse.Count) {
    Write-Host 'Dernieres expulsions :' -ForegroundColor Cyan
    $aExpulse | Select-Object -Last 5 | ForEach-Object { Write-Host ("  " + $_.Line.Trim()) -ForegroundColor DarkGray }
    Write-Host ''
}

# --- 2 bis. Ce que la file d'attente a REELLEMENT ecrit --------------------
#
# C'est la seule preuve directe. Les lignes "logout" et "add" posees au
# demarrage sont dans la base : si elles y sont, le code a tourne et la cause
# est ailleurs ; si elles n'y sont pas, inutile de chercher plus loin.
function Essayer-Client {
    param([string] $chemin)
    if (-not (Test-Path $chemin)) { return $false }
    $sauve = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $v = (& $chemin --version 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $v -match 'Ver\s') { return $true }
    } catch { }
    finally { $ErrorActionPreference = $sauve }
    return $false
}

if (-not $Mysql) {
    $candidats = @()
    foreach ($svc in (Get-CimInstance Win32_Service -ErrorAction SilentlyContinue |
                      Where-Object { $_.Name -match 'mysql|mariadb' })) {
        if ($svc.PathName -match '"?([A-Za-z]:\\[^"]*?\\bin)\\[^\\"]*\.exe') {
            $candidats += (Join-Path $Matches[1] 'mysql.exe')
            $candidats += (Join-Path $Matches[1] 'mariadb.exe')
        }
    }
    $candidats += Get-ChildItem 'C:\Program Files','C:\Program Files (x86)' `
                    -Directory -Recurse -Filter 'bin' -ErrorAction SilentlyContinue |
                  ForEach-Object { Join-Path $_.FullName 'mysql.exe'; Join-Path $_.FullName 'mariadb.exe' }
    foreach ($c in ($candidats | Select-Object -Unique)) {
        if (Essayer-Client $c) { $Mysql = $c; break }
    }
}

$lignesPosees = $null
if ($Mysql) {
    $sql = @'
SELECT CONCAT(
  'logout_poses=',   SUM(p.event = 'logout'),
  ' add_poses=',     SUM(p.event = 'add'),
  ' add_de_la_guilde=', SUM(p.event = 'add' AND gm.guildid IS NOT NULL),
  ' lvl1_encore_en_ligne=', (SELECT COUNT(*) FROM acore_characters.characters c2
                             WHERE c2.online = 1 AND c2.level < 3)
) AS etat
FROM playerbots_random_bots p
LEFT JOIN acore_characters.guild_member gm ON gm.guid = p.bot;
'@
    $lignesPosees = ($sql | & $Mysql "-u$Utilisateur" "-p$MotDePasse" acore_playerbots --skip-column-names 2>$null) -join ''
    Write-Host ''
    Write-Host 'Etat de la base :' -ForegroundColor Cyan
    Write-Host ("  " + $lignesPosees) -ForegroundColor DarkGray
}
else {
    Write-Host ''
    Write-Host 'Client mysql introuvable : etat de la base non verifie.' -ForegroundColor Yellow
}

$aEcrit = ($lignesPosees -match 'logout_poses=([1-9]\d*)')

# --- 3. Le verdict ---------------------------------------------------------
Write-Host 'VERDICT' -ForegroundColor Cyan
if (-not $aDemarre) {
    Write-Host '  Le module ne se charge pas. Rien d autre ne peut marcher.' -ForegroundColor Red
}
elseif (-not $reglagePose -and -not $seReclame) {
    Write-Host '  Le binaire ignore PlayerbotsBis.MinBotLevel : IL FAUT RECOMPILER.' -ForegroundColor Red
    Write-Host '  BisBotGate.cpp est du C++ ; un git pull ne suffit pas.' -ForegroundColor Red
}
elseif (-not $reglagePose) {
    Write-Host '  Recompile, mais le reglage est absent ou a 0 : le filtre dort.' -ForegroundColor Red
    Write-Host '  .\tools\population_des_bots.ps1 -Bots 500 -Appliquer' -ForegroundColor Yellow
}
elseif ($null -ne $lignesPosees -and -not $aEcrit) {
    Write-Host '  Le reglage est pose mais AUCUNE ligne logout en base :' -ForegroundColor Red
    Write-Host '  la file d attente n a pas tourne. Soit le binaire est ancien' -ForegroundColor Red
    Write-Host '  (recompiler), soit OnStartup ne se declenche pas chez toi.' -ForegroundColor Red
}
elseif (-not $aExpulse.Count) {
    Write-Host '  Tout est en place, mais aucune expulsion enregistree.' -ForegroundColor Yellow
    Write-Host '  Soit le serveur n a pas redemarre depuis, soit aucun bot sous le' -ForegroundColor Yellow
    Write-Host '  plancher ne s est presente - les niveau 1 vus etaient deja la.' -ForegroundColor Yellow
}
else {
    Write-Host '  Le filtre travaille. Les bots niveau 1 encore visibles etaient' -ForegroundColor Green
    Write-Host '  connectes avant lui : ils partiront a leur prochaine deconnexion.' -ForegroundColor Green
}
Write-Host ''
