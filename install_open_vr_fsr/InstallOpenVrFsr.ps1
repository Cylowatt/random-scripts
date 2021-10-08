$TempDir = [System.Environment]::ExpandEnvironmentVariables("%LocalAppData%") + "\Temp\openvr_fsr_downloader"

Write-Output ""

function Pre-Run-Init {
    if (Test-Path -Path $TempDir) {
        Write-Output("Removing everything in $($TempDir)`n")
        Remove-Item "$($TempDir)\*" -Recurse
    } else {
        Write-Output("Creating $($TempDir)`n")
        New-Item -ItemType "directory" -Path $TempDir
    }
}

function Get-Fsr-Release {
    Invoke-RestMethod `
        -Uri "https://api.github.com/repos/fholger/openvr_fsr/releases/latest"
}

function Get-Steam-Lib-Vdf-Dir {
    $SteamPath = (Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\Valve\Steam -Name "SteamPath").SteamPath

    "$($SteamPath)/steamapps/libraryfolders.vdf"
}

function Get-Vrc-Dir {
    $SteamLibVdfDir = Get-Steam-Lib-Vdf-Dir

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

    $VrcSteamLibDirQuoted = $MatchingDirs[$MatchingDirs.Count - 1].Line.Trim().Substring(6).Trim()
    $VrcSteamLibDir = $VrcSteamLibDirQuoted.Substring(1, $VrcSteamLibDirQuoted.Length - 2).Replace("\\", "\")

    "$($VrcSteamLibDir)\steamapps\common\VRChat"
}

function Process-Asset {
    param (
        [PSCustomObject]$Asset
    )

    # Download.
    Write-Output "Downloading $($Asset.name)`n"

    Invoke-WebRequest `
        -Uri $Asset.browser_download_url `
        -OutFile "$($TempDir)\$($Asset.name)"

    # Unzip.
    $UnzipDirectoryName = $Asset.name.Substring(0, $Asset.name.Length - 4)
    Write-Output "Unzipping $($Asset.name) to $($UnzipDirectoryName)`n"

    Expand-Archive `
        -Path "$($TempDir)\$($Asset.name)" `
        -DestinationPath "$($TempDir)\$($UnzipDirectoryName)"

    # Copy the OVR FSR files.
    $VrcPluginsDir = "$(Get-Vrc-Dir)\VRChat_Data\Plugins\x86_64"
    Write-Output("VRC plugins directory: $($VrcPluginsDir)`n")

    $OvrApiFileName = "openvr_api.dll"
    $OriginalOvrApiFileName = "openvr_api.orig.dll"

    $OvrApiPath = "$($VrcPluginsDir)\$($OvrApiFileName)"
    $OrigOvrApiPath = "$($VrcPluginsDir)\$($OriginalOvrApiFileName)"

    # If original OVR DLL, copy it over.
    $OvrApiFileProductName = (Get-ItemProperty -Path $OvrApiPath).VersionInfo.ProductName
    if ($OvrApiFileProductName -eq "OpenVR") {
        Write-Output("Copying $($OvrApiFileName) as $($OriginalOvrApiFileName)`n")
        Copy-Item -Path $OvrApiPath -Destination $OrigOvrApiPath
    }

    Write-Output("Copying $($OvrApiFileName) to VRC plugins directory`n")
    Copy-Item `
        -Path "$($TempDir)\$($UnzipDirectoryName)\openvr_api.dll" `
        -Destination $VrcPluginsDir

    if (-Not (Test-Path -Path "$($VrcPluginsDir)\openvr_mod.cfg")) {
        Write-Output("Writing default configuration file to VRC plugins directory`n")
        Copy-Item `
            -Path "$($TempDir)\$($UnzipDirectoryName)\openvr_mod.cfg" `
            -Destination $VrcPluginsDir
    }
}

Pre-Run-Init

$Response = Get-Fsr-Release

foreach ($Asset in $Response.assets) {
    if ($Asset.name -like "openvr_fsr_*.zip") {
        Process-Asset -Asset $Asset
        break
    }
}

Write-Output "Done"