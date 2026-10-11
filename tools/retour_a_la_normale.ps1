<#
.SYNOPSIS
    Remet la population de bots dans l'etat d'avant : les anciens bots, et eux
    seuls.

.DESCRIPTION
    Monter Playerbots.MaxRandomBots a fait creer des comptes et des centaines
    de personnages neufs, niveau 1. Redescendre le plafond ne les reprend pas :
    le module n'a aucune branche qui desassigne quand on repasse en dessous.

    Ce script enchaine les trois gestes du retour en arriere, dans l'ordre ou
    ils doivent avoir lieu :

      1. La configuration     population_des_bots.ps1
         Plafond ramene a sa valeur d'origine, plancher de niveau a 60,
         chevaliers de la mort exclus de la connexion.

      2. Le vivier            pas_de_bots_niveau_1.ps1
         Les comptes dont aucun personnage n'a jamais joue sortent du vivier
         (account_type = 0). Rien n'est supprime : ils deviennent invisibles
         et le restent tant que le plafond ne remonte pas.

      3. La guilde            bots_de_guilde_en_premier.ps1
         Les bots de la guilde retrouvent leur place reservee, en dernier pour
         que leurs marques soient les plus fraiches.

    L'ordre compte. Regler le plafond APRES avoir ecarte les comptes ferait
    constater un manque au demarrage suivant, et le module recreerait
    exactement ce qu'on vient d'ecarter.

    RIEN N'EST SUPPRIME. Les personnages neufs restent en base, inertes. Pour
    les effacer pour de bon, le SQL commandes_de_suppression.sql fabrique la
    liste des .account delete a passer en jeu - c'est la seule facon propre,
    une suppression de personnage touchant une trentaine de tables.

.PARAMETER Bots
    Le plafond d'origine. Defaut 500.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\retour_a_la_normale.ps1 -Bots 500

.NOTES
    SERVEUR ARRETE. Redemarrer une fois les trois etapes passees.
#>

[CmdletBinding()]
param(
    [int]    $Bots        = 500,
    [string] $Mysql,
    [string] $Utilisateur = 'acore',
    [string] $MotDePasse  = 'admin'
)

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '===========================================' -ForegroundColor Cyan
Write-Host '   Retour a la normale - population bots   ' -ForegroundColor Cyan
Write-Host '===========================================' -ForegroundColor Cyan
Write-Host ''

$vivants = @(Get-Process -Name 'worldserver' -ErrorAction SilentlyContinue)
if ($vivants.Count) {
    Write-Host 'worldserver.exe TOURNE ENCORE :' -ForegroundColor Red
    foreach ($p in $vivants) {
        Write-Host ("  PID {0}, demarre a {1}" -f $p.Id, $p.StartTime) -ForegroundColor Red
    }
    Write-Host ''
    Write-Host 'Arrete-le avant (.server shutdown 30), puis relance.' -ForegroundColor Yellow
    Write-Host ''
    exit 1
}
Write-Host 'Serveur arrete. On peut travailler.' -ForegroundColor Green
Write-Host ''

# Les trois etapes partagent le meme client MySQL, trouve une seule fois et
# passe explicitement : chacune le chercherait sinon, et une seule qui tombe
# sur un binaire inutilisable arreterait la chaine au milieu.
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

if ($Mysql -and -not (Essayer-Client $Mysql)) {
    Write-Host ("Le client donne ne s execute pas : {0}" -f $Mysql) -ForegroundColor Red
    exit 1
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
if (-not $Mysql) {
    Write-Host 'Aucun client mysql utilisable. Relance avec -Mysql "C:\...\mysql.exe"' -ForegroundColor Red
    exit 1
}
Write-Host ("Client MySQL : {0}" -f $Mysql) -ForegroundColor DarkGray
Write-Host ''

# Les arguments sont des TABLES DE HACHAGE, pas des tableaux. @tableau splatte
# positionnellement - "-Bots" devient alors la valeur du premier parametre, et
# la conversion en entier echoue. Seule une table de hachage, et seulement
# depuis une variable, passe des parametres nommes.
$etapes = @(
    @{ Nom = '1/3  Configuration : plafond, plancher de niveau, DK'
       Fichier = 'population_des_bots.ps1'
       Args = @{ Bots = $Bots; Appliquer = $true } },

    @{ Nom = '2/3  Vivier : ecarter les comptes jamais joues'
       Fichier = 'pas_de_bots_niveau_1.ps1'
       Args = @{ Plafond = $Bots; Mysql = $Mysql; Utilisateur = $Utilisateur; MotDePasse = $MotDePasse } },

    @{ Nom = '3/3  Guilde : rendre leurs places reservees'
       Fichier = 'bots_de_guilde_en_premier.ps1'
       Args = @{ Mysql = $Mysql; Utilisateur = $Utilisateur; MotDePasse = $MotDePasse } }
)

foreach ($e in $etapes) {
    Write-Host ''
    Write-Host ('--- ' + $e.Nom + ' ---') -ForegroundColor Cyan

    $script = Join-Path $PSScriptRoot $e.Fichier
    if (-not (Test-Path $script)) {
        Write-Host ("Introuvable : {0} (git pull ?)" -f $script) -ForegroundColor Red
        exit 1
    }

    $arguments = $e.Args
    $global:LASTEXITCODE = 0
    & $script @arguments

    # Une etape ratee laisse les suivantes sans leur prerequis : la 3 reserve
    # les places dans un vivier que la 2 n'aurait pas nettoye. On s'arrete.
    if ($LASTEXITCODE -ne 0) {
        Write-Host ''
        Write-Host ("Etape interrompue : {0}" -f $e.Fichier) -ForegroundColor Red
        Write-Host 'Les etapes suivantes ne sont PAS lancees.' -ForegroundColor Red
        Write-Host ''
        exit 1
    }
}

Write-Host ''
Write-Host '===========================================' -ForegroundColor Green
Write-Host '   Les trois etapes sont passees.          ' -ForegroundColor Green
Write-Host '===========================================' -ForegroundColor Green
Write-Host ''
Write-Host 'REDEMARRE le worldserver, puis compte :' -ForegroundColor Yellow
Write-Host ''
Write-Host '  Get-Content tools\recensement_des_bots.sql -Raw |' -ForegroundColor DarkGray
Write-Host '    & $m -uacore -padmin acore_characters --table --default-character-set=utf8mb4' -ForegroundColor DarkGray
Write-Host ''
Write-Host 'Les personnages neufs restent en base, inertes. Pour les effacer' -ForegroundColor DarkGray
Write-Host 'definitivement : tools\commandes_de_suppression.sql' -ForegroundColor DarkGray
Write-Host ''
