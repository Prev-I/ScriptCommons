:: Path to data folder which may differ from install dir
::set datafldr="C:\WebServer\htdocs\localadhd.marionegri.it"

:: Switch to the data directory to enumerate the folders
::pushd %datafldr%

@echo off
setlocal
SET AREYOUSURE=N
:PROMPT
SET /P AREYOUSURE=Are you in a JOOMLA ROOT DIRECTORY (Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END

icacls . /remove:d SYSTEM /t

:END
endlocal