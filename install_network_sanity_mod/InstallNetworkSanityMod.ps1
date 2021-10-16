. "$(Split-Path $PSScriptRoot -Parent)\common_ps1\mod_utils.ps1"

$DesiredMods = @(
    "NetworkSanity.dll"
)

$TempDir = "$(Get-Temp-Dir-Path)\install_network_sanity_mod"

Install-Mods-From-Release `
    -DesiredMods $DesiredMods `
    -TempDir $TempDir `
    -ModReleaseUri "https://api.github.com/repos/RequiDev/NetworkSanity/releases/latest"

Write-Output "`nSuccess!`n"