. "$(Split-Path $PSScriptRoot -Parent)\common_ps1\mod_utils.ps1"

# More mods here: https://github.com/knah/VRCMods/releases
# Add/remove comma-separated DLL names below.
$DesiredMods = @(
    "IKTweaks.dll",
    #"MirrorResolutionUnlimiter.dll",
    "TrueShaderAntiCrash.dll"
)

$TempDir = "$(Get-Temp-Dir-Path)\install_knah_mods"

Install-Mods-From-Release `
    -DesiredMods $DesiredMods `
    -TempDir $TempDir `
    -ModReleaseUri "https://api.github.com/repos/knah/VRCMods/releases/latest"


Write-Output "`nSuccess!`n"