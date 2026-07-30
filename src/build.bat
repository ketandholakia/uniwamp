@echo off
setlocal
del /q Core\*.dcu Ui\*.dcu 2>nul

if defined BDS if exist "%BDS%\bin\rsvars.bat" call "%BDS%\bin\rsvars.bat"
if not defined DCC32EXE if exist "%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\rsvars.bat" call "%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\rsvars.bat"
if not defined DCC32EXE if exist "%ProgramFiles%\Embarcadero\Studio\23.0\bin\rsvars.bat" call "%ProgramFiles%\Embarcadero\Studio\23.0\bin\rsvars.bat"

if not exist "UniWampAssets.res" (
  if defined BDS if exist "%BDS%\bin\brcc32.exe" (
    "%BDS%\bin\brcc32.exe" UniWampAssets.rc -foUniWampAssets.res
  ) else if exist "%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\brcc32.exe" (
    "%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\brcc32.exe" UniWampAssets.rc -foUniWampAssets.res
  ) else if exist "%ProgramFiles%\Embarcadero\Studio\23.0\bin\brcc32.exe" (
    "%ProgramFiles%\Embarcadero\Studio\23.0\bin\brcc32.exe" UniWampAssets.rc -foUniWampAssets.res
  ) else (
    echo Delphi resource compiler was not found.
    exit /b 1
  )
  if errorlevel 1 exit /b 1
)

where msbuild.exe >nul 2>&1
if errorlevel 1 (
  echo MSBuild was not found.
  echo Open a Delphi command prompt or install the Windows SDK/MSBuild tools.
  exit /b 1
)

msbuild UniWamp.dproj /t:Build /p:Config=Release /p:Platform=Win32 /p:DCC_ExeOutput=tmpbuild\bin /p:DCC_DcuOutput=tmpbuild\dcu
exit /b %errorlevel%
