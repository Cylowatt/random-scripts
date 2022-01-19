. "$(Split-Path $PSScriptRoot -Parent)\common_ps1\mod_utils.ps1"

# More mods here: https://github.com/SDraw/ml_mods/releases
# Add/remove comma-separated DLL names below.
$DesiredMods = @(
    "ml_alg.dll"
)

$TempDir = "$(Get-Temp-Dir-Path)\install_ml_mods"

Install-Mods-From-Release `
    -DesiredMods $DesiredMods `
    -TempDir $TempDir `
    -ModReleaseUri "https://api.github.com/repos/SDraw/ml_mods/releases/latest"

Write-Output "`nSuccess!`n"