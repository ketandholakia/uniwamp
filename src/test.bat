@echo off
setlocal
del /q tests\*.dcu 2>nul

if defined BDS if exist "%BDS%\bin\rsvars.bat" call "%BDS%\bin\rsvars.bat"
if not defined DCC32EXE if exist "%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\rsvars.bat" call "%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\rsvars.bat"
if not defined DCC32EXE if exist "%ProgramFiles%\Embarcadero\Studio\23.0\bin\rsvars.bat" call "%ProgramFiles%\Embarcadero\Studio\23.0\bin\rsvars.bat"

where dcc32.exe >nul 2>&1
if errorlevel 1 (
  echo Delphi dcc32.exe was not found.
  echo Open a Delphi command prompt or set BDS to the Delphi installation directory.
  exit /b 1
)

set DUNITX_PATH=%ProgramFiles(x86)%\Embarcadero\Studio\23.0\source\DUnitX
if not exist "%DUNITX_PATH%\DUnitX.TestFramework.pas" (
  set DUNITX_PATH=%ProgramFiles%\Embarcadero\Studio\23.0\source\DUnitX
)

echo Compiling UniWampTests...
dcc32.exe -E.\tests -I"%DUNITX_PATH%" -U"%DUNITX_PATH%";.\Core;.\Ui -R"%DUNITX_PATH%" .\tests\UniWampTests.dpr
if errorlevel 1 (
  echo Compilation failed.
  exit /b 1
)

echo.
echo Running Tests...
.\tests\UniWampTests.exe
exit /b %errorlevel%
