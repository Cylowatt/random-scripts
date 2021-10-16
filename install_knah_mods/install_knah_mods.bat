echo off

powershell -command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; .\InstallKnahMods.ps1; exit"

echo.
set /p asd="Press enter to exit"

echo on