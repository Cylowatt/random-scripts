. "$(Split-Path $PSScriptRoot -Parent)\common_ps1\mod_utils.ps1"

$TempDir = "$(Get-Temp-Dir-Path)\openvr_fsr_downloader"

Write-Output ""

function Get-Fsr-Release {
    Invoke-RestMethod `
        -Uri "https://api.github.com/repos/fholger/openvr_fsr/releases/latest"
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
    Write-Output "Unzipping $($Asset.name) to $($UnzipDirectoryName) in $($TempDir)`n"

    Expand-Archive `
        -Path "$($TempDir)\$($Asset.name)" `
        -DestinationPath "$($TempDir)\$($UnzipDirectoryName)"

    $VrcDir = Get-Vrc-Dir
    Write-Output("VRC directory: $($VrcDir)`n")
    if (-Not (Test-Path -Path $VrcDir)) {
        Fail-With "Could not find VRC under $($VrcDir). Do you have VRC installed?"
    }
    

    # Copy the OVR FSR files.
    $VrcPluginsDir = "$($VrcDir)\VRChat_Data\Plugins\x86_64"
    Write-Output("VRC plugins directory: $($VrcPluginsDir)`n")
    if (-Not (Test-Path -Path $VrcPluginsDir)) {
        Fail-With "Directory $($VrcPluginsDir) does not exist! Exiting..."
    }

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

Init-Temp-Dir($TempDir)

$Response = Get-Fsr-Release

foreach ($Asset in $Response.assets) {
    if ($Asset.name -like "openvr_fsr_*.zip") {
        Process-Asset -Asset $Asset
        break
    }
}

Write-Output "Success!"
