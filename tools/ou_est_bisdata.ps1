<#
.SYNOPSIS
    Trouve TOUTES les copies de l'addon sur le disque, avec la date de chacune.

.DESCRIPTION
    Symptome qui justifie ce script : le diagnostic dit que le BisData.lua du
    client est a jour, et le jeu, lui, affiche une date plus ancienne dans
    /pbbis info.

    Deux causes possibles, et une seule se voit a l'oeil :

      - le client n'a pas ete QUITTE. Un /reload ne relit pas un fichier
        nouveau, et pas toujours un fichier change.

      - il y a PLUSIEURS installations de WoW sur la machine, et celle qu'on
        lance n'est pas celle qu'on met a jour. Rien dans le jeu ne le dit :
        l'addon se charge, affiche une date coherente, et c'est la date de
        l'autre dossier.

    Ce script liste chaque PlayerbotsBisTooltip trouve, avec la date inscrite
    dans son BisData.lua et le nombre d'objets. Deux lignes de dates
    differentes, et la reponse est sous les yeux.

    Il ne modifie rien.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\ou_est_bisdata.ps1

.EXAMPLE
    Limite a un disque, beaucoup plus rapide :
    powershell -ExecutionPolicy Bypass -File .\tools\ou_est_bisdata.ps1 -Racine "C:\"
#>

[CmdletBinding()]
param(
    [string[]] $Racine = @()
)

if ($Racine.Count -eq 0) {
    $Racine = Get-PSDrive -PSProvider FileSystem |
              Where-Object { $_.Free -ne $null } |
              ForEach-Object { $_.Root }
}

Write-Host ""
Write-Host "Recherche des dossiers PlayerbotsBisTooltip dans : $($Racine -join ', ')" -ForegroundColor Cyan
Write-Host "(ca peut prendre une minute)" -ForegroundColor DarkGray
Write-Host ""

$trouves = @()

foreach ($r in $Racine) {
    Get-ChildItem -Path $r -Directory -Recurse -Filter 'PlayerbotsBisTooltip' -ErrorAction SilentlyContinue |
        ForEach-Object {
            $lua = Join-Path $_.FullName 'BisData.lua'
            $stamp, $objets = '-', 0
            if (Test-Path $lua) {
                foreach ($l in (Get-Content $lua -TotalCount 10)) {
                    if ($l -match '^--\s*Source\s*:.*?(\d{4}-\d{2}-\d{2} \d{2}:\d{2})') { $stamp = $Matches[1]; break }
                }
                $objets = (Select-String -Path $lua -Pattern '^\s*\[\d+\]\s*=\s*\{' -AllMatches).Count
            } else {
                $stamp = 'BisData.lua ABSENT'
            }
            # La date de BisData.lua ne dit RIEN des autres fichiers : l'export
            # la reecrit a chaque passage, meme quand la copie des .lua a
            # echoue ou que le depot n'etait pas a jour. On regarde donc aussi
            # ce que le code CONTIENT - la presence d'une commande recente est
            # une preuve directe, une date ne l'est pas.
            $principal = Join-Path $_.FullName 'PlayerbotsBisTooltip.lua'
            $commandes = @()
            if (Test-Path $principal) {
                $corps = Get-Content $principal -Raw
                foreach ($c in 'jets', 'bilan', 'inspect') {
                    if ($corps -match ('Print\("/pbbis ' + $c)) { $commandes += $c }
                }
            } else {
                $commandes += 'FICHIER ABSENT'
            }

            $trouves += [pscustomobject]@{
                Date      = $stamp
                Objets    = $objets
                Version   = (Get-Content (Join-Path $_.FullName 'PlayerbotsBisTooltip.toc') -ErrorAction SilentlyContinue |
                             Where-Object { $_ -match '^##\s*Version\s*:\s*(.+)$' } |
                             ForEach-Object { $Matches[1].Trim() } | Select-Object -First 1)
                Commandes = ($commandes -join ',')
                Inspect   = (Test-Path (Join-Path $_.FullName 'PlayerbotsBisInspect.lua'))
                Chemin    = $_.FullName
            }
        }
}

if ($trouves.Count -eq 0) {
    Write-Host "Aucune copie de l'addon trouvee." -ForegroundColor Red
    return
}

# Out-String -Width fige la largeur : sans console - sortie redirigee vers un
# fichier, fenetre etroite - Format-Table rend un tableau VIDE, ce qui ressemble
# a "rien trouve" alors que la collection est pleine.
$trouves | Sort-Object Date -Descending | Format-Table -AutoSize | Out-String -Width 200

if (($trouves | Select-Object -ExpandProperty Date -Unique).Count -gt 1) {
    Write-Host "PLUSIEURS DATES DIFFERENTES." -ForegroundColor Yellow
    Write-Host "Le jeu que tu lances utilise l'une de ces copies, pas forcement celle" -ForegroundColor Yellow
    Write-Host "que tu mets a jour. Compare la date de /pbbis info a celles ci-dessus :" -ForegroundColor Yellow
    Write-Host "celle qui correspond te dit quel dossier le client lit vraiment." -ForegroundColor Yellow
} else {
    Write-Host "Une seule date : il n'y a pas de doublon. Si le jeu en affiche une autre," -ForegroundColor Green
    Write-Host "c'est qu'il n'a pas ete quitte depuis la copie." -ForegroundColor Green
}

# La colonne Commandes tranche ce que la date ne peut pas trancher.
Write-Host ""
$vieux = @($trouves | Where-Object { $_.Commandes -notmatch 'inspect' })
if ($vieux.Count -gt 0) {
    Write-Host "CODE EN RETARD" -ForegroundColor Yellow
    Write-Host "Ces copies n'ont pas la commande /pbbis inspect, donc leur" -ForegroundColor Yellow
    Write-Host "PlayerbotsBisTooltip.lua est anterieur a la version qui l'ajoute :" -ForegroundColor Yellow
    $vieux | ForEach-Object { Write-Host ("  {0}  [{1}]" -f $_.Chemin, $_.Commandes) }
    Write-Host ""
    Write-Host "Une date de BisData.lua recente ne prouve rien la-dessus : l'export la" -ForegroundColor Yellow
    Write-Host "reecrit meme quand le depot n'etait pas a jour. Fais, dans cet ordre :" -ForegroundColor Yellow
    Write-Host "  1. git pull        dans C:\Azerothcore\modules\mod-playerbots-bis" -ForegroundColor Yellow
    Write-Host "  2. l'export avec -WowPath" -ForegroundColor Yellow
    Write-Host "  3. QUITTER le client et le relancer (PlayerbotsBisInspect.lua est neuf)" -ForegroundColor Yellow
} else {
    Write-Host "Toutes les copies ont /pbbis inspect : le code est a jour sur le disque." -ForegroundColor Green
    Write-Host "Si le jeu ne la propose pas, c'est que le client n'a pas ete quitte." -ForegroundColor Green
}

$sansFichier = @($trouves | Where-Object { -not $_.Inspect })
if ($sansFichier.Count -gt 0) {
    Write-Host ""
    Write-Host "PlayerbotsBisInspect.lua manque dans :" -ForegroundColor Red
    $sansFichier | ForEach-Object { Write-Host "  $($_.Chemin)" -ForegroundColor Red }
}
