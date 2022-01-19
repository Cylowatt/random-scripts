. "$(Split-Path $PSScriptRoot -Parent)\common_ps1\mod_utils.ps1"

# More mods here: https://github.com/SleepyVRC/Mods/releases
# Add/remove comma-separated DLL names below.
$DesiredMods = @(
    "VRChatUtilityKit.dll",
    "VRChatUtilityKit.xml"
)

$TempDir = "$(Get-Temp-Dir-Path)\install_sleepy_vrc_mods"

Install-Mods-From-Release `
    -DesiredMods $DesiredMods `
    -TempDir $TempDir `
    -ModReleaseUri "https://api.github.com/repos/SleepyVRC/Mods/releases/latest"

Write-Output "`nSuccess!`n"