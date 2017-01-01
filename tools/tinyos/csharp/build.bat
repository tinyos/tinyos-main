@echo OFF
echo    NET FRAMEWORK TO COMPILE
echo    ========================
echo.
echo    1 - Microsoft .NET 3.5
echo    2 - Microsoft .NET 4.0
echo.
echo    E - EXIT
echo.
choice /c:12E>nul
if errorlevel 3 goto end
if errorlevel 2 goto 4-0
if errorlevel 1 goto 3-5
echo CHOICE missing
goto end

:3-5
setlocal ENABLEEXTENSIONS
set VALUE_NAME=MSBuildToolsPath
set KEY_NAME=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions\3.5
FOR /F "tokens=3" %%A IN ('REG QUERY %KEY_NAME% /v %VALUE_NAME% 2^>nul') DO (
    set MSBUILD_3_5=%%AMSbuild.exe
)

if not defined MSBUILD_3_5 (
	@echo MSBuild.exe PATH not found.
  goto end)

%MSBUILD_3_5% tinyos-sdk.sln /p:Configuration=Release
goto copy

:4-0
set VALUE_NAME=MSBuildToolsPath
set KEY_NAME=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions\4.0
FOR /F "tokens=3" %%A IN ('REG QUERY %KEY_NAME% /v %VALUE_NAME% 2^>nul') DO (
    set MSBUILD_4_0=%%AMSbuild.exe
)

if not defined MSBUILD_4_0 (
	@echo MSBuild.exe PATH not found.
    goto end)

%MSBUILD_4_0% tinyos-sdk.sln /p:Configuration=Release

:copy
copy sfsharp\bin\Release\sfsharp.exe .
copy tinyos-sdk\bin\Release\tinyos-sdk.dll .

:end
pause