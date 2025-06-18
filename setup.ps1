sudo choco install visualstudio2019buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.MSBuildTools;includeRecommended --add Microsoft.VisualStudio.Workload.VCTools;includeRecommended --quiet" -y
winget install "Microsoft .NET Framework 4.6.2 Developer Pack"
Invoke-WebRequest -Uri "https://download.microsoft.com/download/cb9de490-6e67-4ac6-8c2c-6dfabb824e8a/windowssdk/winsdksetup.exe" -OutFile "winsdksetup.exe"
Start-Process winsdksetup.exe -ArgumentList "/q" -Wait
winget install Microsoft.NuGet
& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\Common7\Tools\Launch-VsDevShell.ps1"
$env:PATH = "C:\Windows\System32\WindowsPowerShell\v1.0;$env:PATH"
nuget restore CentennialFixups.sln
cd tests
nuget restore tests.sln
cd ..