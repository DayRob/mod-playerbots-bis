<#
.SYNOPSIS
    Renomme les reglages de playerbots.conf apres la refonte de mod-playerbots
    (prefixe AiPlayerbot. devenu Playerbots.), et dit ce qui change.

.DESCRIPTION
    Symptome qui justifie ce script : le worldserver demarre, tout fonctionne,
    mais il crache des centaines de lignes

        Config: Missing property Playerbots.XXX in file playerbots.conf,
        add "Playerbots.XXX = ..." to this file

    Ce message n'est pas un avertissement decoratif. Il veut dire que le module
    N'A PAS TROUVE le reglage et qu'il utilise sa valeur d'usine. Si le fichier
    entier est reste en AiPlayerbot., alors AUCUN reglage ne s'applique : le
    serveur tourne sur les 888 valeurs par defaut, et le playerbots.conf qu'on
    croit editer ne sert plus a rien.

    Ce que ca donne concretement, avec les defauts de mod-playerbots :

        Playerbots.MaxRandomBots        = 500   -> 500 bots d'un coup
        Playerbots.RandomBotMinLevel    = 1
        Playerbots.RandomBotMaxLevel    = 80    -> des bots 65-74 en Norfendre
        Playerbots.DisableDeathKnightLogin = 0  -> des chevaliers de la mort

    Le script compare le fichier vivant au playerbots.conf.dist livre avec le
    module. Il ne devine rien : un reglage n'est renomme que si le nouveau nom
    existe vraiment dans le .dist. Ce qui ne correspond a rien est signale, pas
    efface.

    Sans -Appliquer il ne modifie RIEN : il lit et il rapporte.
    Avec -Appliquer il sauvegarde l'original avant d'ecrire.

.PARAMETER Conf
    Le playerbots.conf utilise par le serveur. Trouve tout seul s'il est omis.

.PARAMETER Dist
    Le playerbots.conf.dist du module A JOUR. Trouve tout seul s'il est omis.

.PARAMETER Racine
    Ou chercher les deux fichiers. Par defaut C:\Azerothcore.

.PARAMETER Appliquer
    Ecrit le fichier renomme. Sans ce commutateur, rapport seul.

.EXAMPLE
    Voir ce qui se passerait, sans rien toucher :
    powershell -ExecutionPolicy Bypass -File .\tools\migrer_playerbots_conf.ps1

.EXAMPLE
    Renommer pour de bon (une sauvegarde est faite) :
    powershell -ExecutionPolicy Bypass -File .\tools\migrer_playerbots_conf.ps1 -Appliquer

.NOTES
    Apres -Appliquer il faut REDEMARRER le worldserver. Un .reload config ne
    relit pas un fichier dont les noms de cles ont change sous lui.
#>

[CmdletBinding()]
param(
    [string]   $Conf,
    [string]   $Dist,
    [string[]] $Racine = @('C:\Azerothcore', 'C:\AzerothCore', 'C:\azerothcore'),
    [switch]   $Appliquer
)

$ErrorActionPreference = 'Stop'

$ANCIEN = 'AiPlayerbot.'
$NOUVEAU = 'Playerbots.'

function Trouver-Fichier {
    param([string[]] $Racines, [string] $Motif, [bool] $Dist)

    foreach ($r in $Racines) {
        if (-not (Test-Path $r)) { continue }
        $trouves = Get-ChildItem -Path $r -File -Recurse -Filter $Motif -ErrorAction SilentlyContinue
        foreach ($f in $trouves) {
            $estDist = $f.Name -like '*.dist'
            if ($estDist -eq $Dist) { return $f.FullName }
        }
    }
    return $null
}

Write-Host ''
Write-Host '=== Migration playerbots.conf : AiPlayerbot. -> Playerbots. ===' -ForegroundColor Cyan
Write-Host ''

if (-not $Conf) { $Conf = Trouver-Fichier -Racines $Racine -Motif 'playerbots.conf'      -Dist $false }
if (-not $Dist) { $Dist = Trouver-Fichier -Racines $Racine -Motif 'playerbots.conf.dist' -Dist $true  }

if (-not $Conf) {
    Write-Host "playerbots.conf introuvable sous : $($Racine -join ', ')" -ForegroundColor Red
    Write-Host 'Relance avec -Conf "C:\chemin\vers\playerbots.conf"' -ForegroundColor Yellow
    exit 1
}
if (-not $Dist) {
    Write-Host "playerbots.conf.dist introuvable sous : $($Racine -join ', ')" -ForegroundColor Red
    Write-Host 'Relance avec -Dist "C:\chemin\vers\playerbots.conf.dist"' -ForegroundColor Yellow
    exit 1
}

Write-Host ("Fichier vivant : {0}" -f $Conf)
Write-Host ("Reference      : {0}" -f $Dist)
Write-Host ''

# --- Les cles que le module d'aujourd'hui connait -------------------------
#
# Le .dist est la seule autorite ici. Une cle absente du .dist n'existe pas,
# quel que soit son prefixe.
$clesDist = @{}
$defautsDist = @{}
foreach ($l in (Get-Content -LiteralPath $Dist)) {
    if ($l -match '^\s*([A-Za-z0-9_.]+)\s*=\s*(.*?)\s*$') {
        $clesDist[$Matches[1]] = $true
        $defautsDist[$Matches[1]] = $Matches[2]
    }
}
Write-Host ("Le module connait {0} reglages." -f $clesDist.Count) -ForegroundColor DarkGray
Write-Host ''

# --- Lecture du fichier vivant --------------------------------------------
$lignes = Get-Content -LiteralPath $Conf
$sortie = New-Object System.Collections.Generic.List[string]

$renommees = New-Object System.Collections.Generic.List[string]
$orphelines = New-Object System.Collections.Generic.List[string]
$dejaBonnes = 0

# Deux ensembles, et la distinction est tout le propos du script :
#   $actives : les cles que le serveur lit AUJOURD'HUI (bon prefixe deja)
#   $apres   : ce qu'il lira une fois le renommage applique
$actives = @{}
$apres = @{}

foreach ($l in $lignes) {
    # Les lignes commentees sont recopiees telles quelles : un commentaire qui
    # cite un ancien nom reste un commentaire, et le renommer embrouillerait
    # plus qu'autre chose.
    if ($l -match '^\s*#' -or $l -notmatch '^\s*([A-Za-z0-9_.]+)\s*=') {
        $sortie.Add($l)
        continue
    }

    $cle = $Matches[1]

    if ($cle.StartsWith($NOUVEAU)) {
        $dejaBonnes++
        $actives[$cle] = $true
        $apres[$cle] = $true
        $sortie.Add($l)
        continue
    }

    if (-not $cle.StartsWith($ANCIEN)) {
        # Un reglage d'un autre module pose dans le meme fichier. On n'y touche pas.
        $sortie.Add($l)
        continue
    }

    $nouvelle = $NOUVEAU + $cle.Substring($ANCIEN.Length)

    if ($clesDist.ContainsKey($nouvelle)) {
        $sortie.Add(($l -replace [regex]::Escape($cle), $nouvelle))
        $renommees.Add("$cle -> $nouvelle")
        $apres[$nouvelle] = $true
    }
    else {
        # Le nom n'existe plus, meme renomme : la cle a ete supprimee ou
        # rebaptisee autrement. On la laisse intacte et on la signale, parce
        # qu'une suppression silencieuse perdrait un reglage voulu.
        $sortie.Add($l)
        $orphelines.Add($cle)
    }
}

Write-Host ("Reglages deja au bon prefixe : {0}" -f $dejaBonnes)
Write-Host ("Reglages a renommer          : {0}" -f $renommees.Count) -ForegroundColor Yellow
Write-Host ("Reglages sans equivalent     : {0}" -f $orphelines.Count) -ForegroundColor $(if ($orphelines.Count) { 'Red' } else { 'DarkGray' })
Write-Host ''

if ($orphelines.Count) {
    Write-Host 'Sans equivalent dans le module actuel (laisses tels quels, inactifs) :' -ForegroundColor Red
    foreach ($o in $orphelines) {
        # Un dernier espoir : la meme fin de nom ailleurs dans le .dist.
        $queue = $o.Substring($ANCIEN.Length)
        $piste = $clesDist.Keys | Where-Object { $_ -like "*$queue" } | Select-Object -First 1
        if ($piste) { Write-Host ("  {0}   (peut-etre : {1})" -f $o, $piste) }
        else        { Write-Host ("  {0}" -f $o) }
    }
    Write-Host ''
}

# --- Les reglages qui expliquent ce qu'on voit en jeu ----------------------
#
# Pas un echantillon au hasard : ce sont ceux dont le defaut se VOIT, parce
# qu'il peuple le serveur de bots d'un autre niveau et d'une autre extension.
$aSurveiller = @(
    'Playerbots.MinRandomBots',
    'Playerbots.MaxRandomBots',
    'Playerbots.RandomBotMinLevel',
    'Playerbots.RandomBotMaxLevel',
    'Playerbots.DisableDeathKnightLogin',
    'Playerbots.RandomBotAccountCount',
    'Playerbots.AddClassAccountPoolSize',
    'Playerbots.EnablePeriodicOnlineOffline',
    'Playerbots.PeriodicOnlineOfflineRatio',
    'Playerbots.RandomBotAutologin',
    'Playerbots.DeleteRandomBotAccounts'
)

# Le tableau est mis en forme a la main plutot qu'avec Format-Table : celui-ci
# ne rend rien quand la sortie est redirigee (fichier, pipe, tache planifiee),
# et c'est precisement la qu'on relit un diagnostic.
Write-Host 'Reglages dont le defaut se voit en jeu :' -ForegroundColor Cyan
Write-Host ''

$tableau = foreach ($c in $aSurveiller) {
    $ancienNom = $ANCIEN + $c.Substring($NOUVEAU.Length)
    $tienne = $null
    foreach ($l in $lignes) {
        if ($l -match "^\s*$([regex]::Escape($ancienNom))\s*=\s*(.*?)\s*$" -or
            $l -match "^\s*$([regex]::Escape($c))\s*=\s*(.*?)\s*$") {
            $tienne = $Matches[1]
            break
        }
    }
    $defaut = if ($defautsDist.ContainsKey($c)) { $defautsDist[$c] } else { '?' }

    # Deux colonnes, et leur ecart est le diagnostic : "Aujourd'hui" est ce que
    # le serveur applique en ce moment, "Apres" ce qu'il appliquera une fois le
    # renommage fait. Tant que la cle porte l'ancien prefixe, "Aujourd'hui" vaut
    # le defaut, quoi qu'on ait ecrit en face.
    $lue = $actives.ContainsKey($c)
    $sera = $apres.ContainsKey($c)
    [pscustomobject]@{
        Reglage    = $c.Substring($NOUVEAU.Length)
        TaValeur   = if ($null -eq $tienne) { '(absent)' } else { $tienne }
        Aujourdhui = if ($lue)  { $tienne } else { $defaut }
        Apres      = if ($sera) { $tienne } else { $defaut }
        Perdu      = (-not $lue) -and ($null -ne $tienne) -and ($tienne -ne $defaut)
    }
}

$lReglage = 7; $lTienne = 9; $lAuj = 11
foreach ($r in $tableau) {
    if ($r.Reglage.Length    -gt $lReglage) { $lReglage = $r.Reglage.Length }
    if ($r.TaValeur.Length   -gt $lTienne)  { $lTienne  = $r.TaValeur.Length }
    if ($r.Aujourdhui.Length -gt $lAuj)     { $lAuj     = $r.Aujourdhui.Length }
}
$ligne = "  {0,-$lReglage}   {1,-$lTienne}   {2,-$lAuj}   {3}"
Write-Host ($ligne -f 'Reglage', 'Ta valeur', "Aujourd'hui", 'Apres migration') -ForegroundColor DarkGray
Write-Host ($ligne -f ('-' * $lReglage), ('-' * $lTienne), ('-' * $lAuj), ('-' * 15)) -ForegroundColor DarkGray
foreach ($r in $tableau) {
    $couleur = if ($r.Perdu) { 'Red' } else { 'Gray' }
    $suffixe = if ($r.Perdu) { '   <== ta valeur est ignoree' } else { '' }
    Write-Host (($ligne -f $r.Reglage, $r.TaValeur, $r.Aujourdhui, $r.Apres) + $suffixe) -ForegroundColor $couleur
}
Write-Host ''

if (-not $Appliquer) {
    Write-Host 'RAPPORT SEUL - rien n a ete modifie.' -ForegroundColor Yellow
    Write-Host 'Relance avec -Appliquer pour ecrire le fichier renomme.' -ForegroundColor Yellow
    Write-Host ''
    exit 0
}

if ($renommees.Count -eq 0) {
    Write-Host 'Rien a renommer : le fichier est deja au bon prefixe.' -ForegroundColor Green
    Write-Host ''
    exit 0
}

$sauvegarde = "$Conf.avant-renommage-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -LiteralPath $Conf -Destination $sauvegarde
Write-Host ("Sauvegarde : {0}" -f $sauvegarde) -ForegroundColor DarkGray

[System.IO.File]::WriteAllLines($Conf, $sortie, (New-Object System.Text.UTF8Encoding $false))

Write-Host ("{0} reglages renommes dans {1}" -f $renommees.Count, $Conf) -ForegroundColor Green
Write-Host ''
Write-Host 'Il faut maintenant REDEMARRER le worldserver.' -ForegroundColor Yellow
Write-Host 'Un .reload config ne suffit pas : les noms de cles ont change.' -ForegroundColor Yellow
Write-Host ''
