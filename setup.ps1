#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

# The Visual Studio Installer refuses --quiet unless it is started elevated, so
# relaunch this script elevated once if needed.
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Elevating...'
    $elevated = Start-Process -FilePath (Get-Process -Id $PID).Path `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Wait -PassThru
    exit $elevated.ExitCode
}

# Post-build events invoke Windows PowerShell, whose default policy is Restricted.
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile `
    -Command "Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force"

function Install-WingetPackage {
    param([Parameter(Mandatory)][string]$Id, [string]$Override)

    $wingetArgs = @('install', '--id', $Id, '--exact', '--accept-package-agreements', '--accept-source-agreements')
    if ($Override) {
        $wingetArgs += @('--override', $Override)
    }

    Write-Host "Installing $Id..."
    & winget @wingetArgs
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        throw "winget failed to install $Id (exit code $LASTEXITCODE)."
    }
}

function Update-ProcessPath {
    $env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('PATH', 'User') + ';' +
                $env:PATH
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required. Install "App Installer" from the Microsoft Store first.'
}

# MSBuild, the v142 C++ toolset (required by the vcxproj files), the Windows 11 SDK
# hardcoded by the projects, and the .NET desktop tools for PsfShimMonitor.
$vsComponents = @(
    'Microsoft.VisualStudio.Workload.MSBuildTools'
    'Microsoft.VisualStudio.Workload.VCTools'
    'Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools'
    'Microsoft.VisualStudio.Component.VC.14.29.16.11.x86.x64'
    'Microsoft.VisualStudio.Component.Windows11SDK.22621'
    'Microsoft.Net.Component.4.6.2.TargetingPack'
)

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vsInstall = $null
if (Test-Path $vswhere) {
    $vsInstall = & $vswhere -latest -products * -property installationPath 2>$null
}

if ($vsInstall) {
    # winget no-ops when the package is already installed, so modify the existing
    # installation to add any missing workloads/components.
    Write-Host "Updating Visual Studio Build Tools at $vsInstall..."
    $modifyArgs = @('modify', '--installPath', "`"$vsInstall`"")
    foreach ($component in $vsComponents) {
        $modifyArgs += @('--add', $component)
    }
    $modifyArgs += @('--quiet', '--norestart')

    $installer = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
    $process = Start-Process -FilePath $installer -ArgumentList $modifyArgs -Wait -PassThru
    if ($process.ExitCode -notin @(0, 3010)) {
        throw "Visual Studio Installer failed (exit code $($process.ExitCode))."
    }
}
else {
    $override = (@($vsComponents | ForEach-Object { '--add'; $_ }) -join ' ') + ' --quiet --wait --norestart'
    Install-WingetPackage -Id 'Microsoft.VisualStudio.2022.BuildTools' -Override $override
}

# The WDK supplies the km headers/libs used by MFRFixup (hardcoded to 10.0.22621.0).
Install-WingetPackage -Id 'Microsoft.WindowsWDK.10.0.22621'

# .NET Framework 4.6.2 Developer Pack, used by PsfShimMonitor.
Install-WingetPackage -Id 'Microsoft.DotNet.Framework.DeveloperPack.4.6'

Install-WingetPackage -Id 'Microsoft.NuGet'

# Installs above update the persisted PATH, not this process's copy.
Update-ProcessPath

if (-not (Test-Path $vswhere)) {
    throw 'vswhere.exe not found. The Visual Studio Build Tools installation may have failed.'
}

$vsInstall = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.14.29.16.11.x86.x64 -property installationPath
if (-not $vsInstall) {
    throw 'Could not find a Visual Studio installation with the v142 C++ toolset.'
}

Import-Module "$vsInstall\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Enter-VsDevShell -VsInstallPath $vsInstall -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'

if (-not (Get-Command nuget -ErrorAction SilentlyContinue)) {
    $nuget = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Microsoft.NuGet*\nuget.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($nuget) {
        $env:PATH = "$($nuget.DirectoryName);$env:PATH"
    }
}
if (-not (Get-Command nuget -ErrorAction SilentlyContinue)) {
    throw 'nuget.exe was not found on PATH after installation.'
}

Push-Location $PSScriptRoot
try {
    Write-Host 'Restoring NuGet packages...'
    nuget restore CentennialFixups.sln
    nuget restore tests\tests.sln
}
finally {
    Pop-Location
}

Write-Host 'Setup complete. Run buildall.cmd to build the PSF.'
