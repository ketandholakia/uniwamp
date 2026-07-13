@echo off
setlocal
if defined BDS if exist "%BDS%\bin\rsvars.bat" call "%BDS%\bin\rsvars.bat"
if not defined DCC32EXE if exist "%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\rsvars.bat" call "%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\rsvars.bat"
if not defined DCC32EXE if exist "%ProgramFiles%\Embarcadero\Studio\23.0\bin\rsvars.bat" call "%ProgramFiles%\Embarcadero\Studio\23.0\bin\rsvars.bat"
where dcc32.exe >nul 2>&1
if errorlevel 1 (
  echo Delphi dcc32.exe was not found.
  exit /b 1
)
cd /d "%~dp0"
dcc32.exe -U"..\src;..\src\Core;..\src\Ui" ConfigHarness.dpr
exit /b %errorlevel%
