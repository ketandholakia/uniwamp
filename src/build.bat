@echo off
del Core\*.dcu
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
dcc32 UniWamp.dpr
