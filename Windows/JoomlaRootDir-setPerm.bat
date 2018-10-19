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

:: first level folder to set read only
icacls . /deny SYSTEM:(WDAC,WO,WD,WEA,WA,AD) /t

:: folder to be set writable
icacls cache /remove:d SYSTEM /t
icacls logs /remove:d SYSTEM /t
icacls media /remove:d SYSTEM /t
icacls tmp /remove:d SYSTEM /t
icacls administrator/cache /remove:d SYSTEM /t
icacls administrator/manifests /remove:d SYSTEM /t
icacls administrator/php_errors.log /remove:d SYSTEM 
icacls php_errors.log /remove:d SYSTEM

:END
endlocal