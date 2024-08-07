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
call "%VS170COMNTOOLS%\..\..\tools\VsDevCmd.bat"
@mkdir 12bit
@mkdir 10bit
@mkdir 8bit

@cd 12bit
cmake -G "Visual Studio 17 2022" ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON
if exist x265.sln (
  MSBuild /property:Configuration="Release" x265.sln
  copy/y Release\x265-static.lib ..\8bit\x265-static-main12.lib
)

@cd ..\10bit
cmake -G "Visual Studio 17 2022" ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF
if exist x265.sln (
  MSBuild /property:Configuration="Release" x265.sln
  copy/y Release\x265-static.lib ..\8bit\x265-static-main10.lib
)

@cd ..\8bit
if not exist x265-static-main10.lib (
  msg "%username%" "10bit build failed"
  exit 1
)
if not exist x265-static-main12.lib (
  msg "%username%" "12bit build failed"
  exit 1
)
cmake -G "Visual Studio 17 2022" ../../../source -DEXTRA_LIB="x265-static-main10.lib;x265-static-main12.lib" -DLINKED_10BIT=ON -DLINKED_12BIT=ON
if exist x265.sln (
  MSBuild /property:Configuration="Release" x265.sln
  :: combine static libraries (ignore warnings caused by winxp.cpp hacks)
  move Release\x265-static.lib x265-static-main.lib
  LIB.EXE /ignore:4006 /ignore:4221 /OUT:Release\x265-static.lib x265-static-main.lib x265-static-main10.lib x265-static-main12.lib
)

pause