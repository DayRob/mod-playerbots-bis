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
            $trouves += [pscustomobject]@{
                Date    = $stamp
                Objets  = $objets
                Version = (Get-Content (Join-Path $_.FullName 'PlayerbotsBisTooltip.toc') -ErrorAction SilentlyContinue |
                           Where-Object { $_ -match '^##\s*Version\s*:\s*(.+)$' } |
                           ForEach-Object { $Matches[1].Trim() } | Select-Object -First 1)
                Chemin  = $_.FullName
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
