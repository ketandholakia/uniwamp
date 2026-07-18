@echo off
setlocal

set "ROOT=%~dp0.."
set "RSVARS="
set "ISCC="

if defined BDS if exist "%BDS%\bin\rsvars.bat" set "RSVARS=%BDS%\bin\rsvars.bat"
if not defined RSVARS if exist "%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\rsvars.bat" set "RSVARS=%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\rsvars.bat"
if not defined RSVARS if exist "%ProgramFiles%\Embarcadero\Studio\23.0\bin\rsvars.bat" set "RSVARS=%ProgramFiles%\Embarcadero\Studio\23.0\bin\rsvars.bat"

if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not defined ISCC if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
if not defined ISCC for /f "delims=" %%I in ('where ISCC.exe 2^>nul') do if not defined ISCC set "ISCC=%%I"

if not exist "%RSVARS%" goto missing_delphi
if not exist "%ISCC%" goto missing_iscc

pushd "%ROOT%\src"
call "%RSVARS%"
if errorlevel 1 exit /b 1
if not exist "UniWampAssets.res" (
  "%BDS%\bin\brcc32.exe" UniWampAssets.rc -foUniWampAssets.res
  if errorlevel 1 exit /b 1
)
msbuild UniWamp.dproj /t:Build /p:Config=Release /p:Platform=Win32 /p:DCC_ExeOutput=tmpbuild\bin /p:DCC_DcuOutput=tmpbuild\dcu
if errorlevel 1 exit /b 1
popd

pushd "%~dp0"
"%ISCC%" UniWamp.Php82.iss
if errorlevel 1 goto build_failed
"%ISCC%" UniWamp.Php83.iss
if errorlevel 1 goto build_failed
"%ISCC%" UniWamp.Php84.iss
if errorlevel 1 goto build_failed
"%ISCC%" UniWamp.Php85.iss
if errorlevel 1 goto build_failed
"%ISCC%" UniWamp.Full.iss
if errorlevel 1 goto build_failed
popd
exit /b 0

:build_failed
set "EXITCODE=%ERRORLEVEL%"
popd
exit /b %EXITCODE%

:missing_delphi
echo Delphi environment setup not found: %RSVARS%
exit /b 1

:missing_iscc
echo Inno Setup compiler not found: %ISCC%
exit /b 1
