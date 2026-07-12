@echo off
setlocal

set "ROOT=%~dp0.."
set "RSVARS=C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
set "ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

if not exist "%RSVARS%" goto missing_delphi
if not exist "%ISCC%" goto missing_iscc

pushd "%ROOT%\src"
call "%RSVARS%"
if errorlevel 1 exit /b 1
msbuild UniWamp.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /p:DCC_ExeOutput=tmpbuild\bin /p:DCC_DcuOutput=tmpbuild\dcu
if errorlevel 1 exit /b 1
popd

pushd "%~dp0"
"%ISCC%" UniWamp.iss
set "EXITCODE=%ERRORLEVEL%"
popd
exit /b %EXITCODE%

:missing_delphi
echo Delphi environment setup not found: %RSVARS%
exit /b 1

:missing_iscc
echo Inno Setup compiler not found: %ISCC%
exit /b 1
