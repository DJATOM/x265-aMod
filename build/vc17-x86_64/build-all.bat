@echo off
setlocal enabledelayedexpansion
if "%VS170COMNTOOLS%" == "" (
for /f "usebackq tokens=1* delims=: " %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest `) do (
  if /i "%%i"=="productPath" (
        set VS170COMNTOOLS=%%j
)
)
)
setx VS170COMNTOOLS "!VS170COMNTOOLS!"
if "%VS170COMNTOOLS%" == "" (
  msg "%username%" "Visual Studio 17 not detected"
  exit 1
)
if not exist x265.sln (
  call make-solutions.bat
)
if exist x265.sln (
  call "%VS170COMNTOOLS%\..\..\tools\VsDevCmd.bat"
  MSBuild /property:Configuration="Release" x265.sln
  MSBuild /property:Configuration="Debug" x265.sln
  MSBuild /property:Configuration="RelWithDebInfo" x265.sln
)
