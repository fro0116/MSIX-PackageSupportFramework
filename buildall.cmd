
echo "==================== PSF x86  DEBUG  ================================="
msbuild CentennialFixups.sln /p:platform=x86;configuration=debug
echo "==================== PSF x86 RELEASE ================================="
msbuild CentennialFixups.sln /p:platform=x86;configuration=release
echo "==================== PSF x64  DEBUG  ================================="
msbuild CentennialFixups.sln /p:platform=x64;configuration=debug
echo "==================== PSF x64 RELEASE ================================="
msbuild CentennialFixups.sln /p:platform=x64;configuration=release
@REM pushd tests
@REM echo "==================== TEST x86  DEBUG  ================================="
@REM msbuild tests.sln /p:platform=x86;configuration=debug
@REM echo "==================== TEST x86 RELEASE ================================="
@REM msbuild tests.sln /p:platform=x86;configuration=release
@REM echo "==================== TEST x64  DEBUG  ================================="
@REM msbuild tests.sln /p:platform=x64;configuration=debug
@REM echo "==================== TEST x64 RELEASE ================================="
@REM msbuild tests.sln /p:platform=x64;configuration=release
@REM popd
