echo off

powershell -command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; .\InstallSleepyVrcMods.ps1; exit"

echo.
set /p asd="Press enter to exit"

echo on