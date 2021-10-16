function Fail-With {
    param (
        [string]$message
    )

    Write-Error($message)
    exit
}

function Get-Steam-Lib-Vdf-Dir {
    $SteamPathProp = (Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\Valve\Steam -Name "SteamPath")

    if (-Not ($SteamPathProp)) {
        Fail-With("Could not find Steam. Do you have it installed?")
    }

    $SteamPath = $SteamPathProp.SteamPath;
    if (-Not $SteamPath -Or ($SteamPath.GetType().Name -ne "String") -Or [string]::IsNullOrWhiteSpace($SteamPath)) {
        Fail-With("Could not find Steam. Do you have it installed?")
    }

    "$($SteamPath)/steamapps/libraryfolders.vdf"
}

function Get-Vrc-Dir {
    $SteamLibVdfDir = Get-Steam-Lib-Vdf-Dir
    if (-Not (Test-Path -Path $SteamLibVdfDir)) {
        Fail-With "Could not find steam library folders manifest at $($SteamLibVdfDir). Do you have VRC installed?"
    }

    $VrcAppId = '"438100"'
    $VdfContent = Get-Content -Path $SteamLibVdfDir

    $SteamLibDirs = ($VdfContent | Select-String "path")
    $VrcIdLineNumber = ($VdfContent | Select-String $VrcAppId).LineNumber

    # TODO rewrite using Where-Object
    $MatchingDirs = @()
    foreach ($Dir in $SteamLibDirs) {
      if ($Dir.LineNumber -lt $VrcIdLineNumber) {
        $MatchingDirs += ,$Dir
      } else {
        break
      }
    }

    if (-Not ($MatchingDirs.Count)) {
        Fail-With "Could not find Steam libraries in $($SteamLibVdfDir)! Exiting..."
    }

    $VrcSteamLibDirQuoted = $MatchingDirs[$MatchingDirs.Count - 1].Line.Trim().Substring(6).Trim()
    $VrcSteamLibDir = $VrcSteamLibDirQuoted.Substring(1, $VrcSteamLibDirQuoted.Length - 2).Replace("\\", "\")

    "$($VrcSteamLibDir)\steamapps\common\VRChat"
}

function Get-Temp-Dir-Path {
  [System.Environment]::ExpandEnvironmentVariables("%LocalAppData%") + "\Temp"
}

function Init-Temp-Dir {
    param (
        [string]$TempDir
    )

    if (Test-Path -Path $TempDir) {
        Write-Output("Removing everything in $($TempDir)`n")
        Remove-Item "$($TempDir)\*" -Recurse
    } else {
        Write-Output("Creating $($TempDir)`n")
        New-Item -ItemType "directory" -Path $TempDir
    }
}

function Download-Desired-Assets {
    param (
        [PSCustomObject[]] $Assets,
        [string[]] $NormalisedDesiredAssetNames,
        [string] $DownloadLocation
    )

    $DownloadedAssetPaths = @()

    foreach ($CurrentAsset in $Assets) {
        $NormalisedName = $CurrentAsset.name.ToLower().Trim()

        if (-Not ($NormalisedDesiredAssetNames.Contains($NormalisedName))) {
            continue
        } 
 
        $OutFilePath = "$($DownloadLocation)\$($CurrentAsset.name)"
        
        Invoke-WebRequest `
            -Uri $CurrentAsset.browser_download_url `
            -OutFile $OutFilePath

        $DownloadedAssetPaths += ,$OutFilePath
    }

    $DownloadedAssetPaths
}

function Install-Mods-From-Release {
    param (
        [string[]] $DesiredMods,
        [string] $TempDir,
        [string] $ModReleaseUri
    )

    Write-Output "`nDesired mods: $($DesiredMods)`n"

    Init-Temp-Dir $TempDir
    Write-Output ""

    $NormalisedDesiredMods = $DesiredMods.Clone().ToLower()
    Write-Output "Downloading latest release"

    $Release = Invoke-RestMethod -Uri $ModReleaseUri

    $ModFilePaths = Download-Desired-Assets `
        -Assets $Release.assets `
        -NormalisedDesiredAssetNames $NormalisedDesiredMods `
        -DownloadLocation $TempDir

    $DestinationDir = "$(Get-Vrc-Dir)\Mods"
    if (-Not (Test-Path -Path $DestinationDir)) { 
        Fail-With "Mod directory does not exist at $($DestinationDir). Are you sure that you have Melon Loader installed?"
    }

    foreach ($File in $ModFilePaths) {
       Write-Output "Copying to $($File)"
       Copy-Item -Path $File -Destination $DestinationDir
    }
}