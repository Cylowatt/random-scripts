echo off

powershell -command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; .\install_open_vr_fsr\InstallOpenVrFsr.ps1; .\install_knah_mods\InstallKnahMods.ps1; .\install_network_sanity_mod\InstallNetworkSanityMod.ps1 exit"

echo.
set /p asd="Press enter to exit"

echo on