
:: If the time is less than two digits insert a zero so there is no space to break the filename
IF "%time:~0,1%" LSS "1" (
SET BACKUPTIME=%date:~6,4%-%date:~3,2%-%date:~0,2%-0%time:~1,1%-%time:~3,2%-%time:~6,2%
) ELSE (
SET BACKUPTIME=%date:~6,4%-%date:~3,2%-%date:~0,2%-%time:~0,2%-%time:~3,2%-%time:~6,2%
)

:: SETTINGS AND PATHS 
:: Note: Do not put spaces before the equal signs or variables will fail

:: Error log path - Important in debugging your issues
set errorLogPath="C:\Backups\htdocsErrors.txt"

:: Where to save backups
set backupfldr="C:\Backups\htdocs"

:: Path to data folder which may differ from install dir
set datafldr="C:\WebServer\htdocs"

:: Path to zip executable
set zipper="C:\Program Files\7-Zip\7z.exe"

:: Number of days to retain .zip backup files 
set retaindays=30

:: System directory to be excluded from backup
set sysdir="SYSTEM"


:: BACKUP EVERYTHING!

:: Switch to the data directory to enumerate the folders
pushd %datafldr%

:: turn on if you are debugging
@echo off

FOR /D %%F IN (*) DO (
  IF NOT [%%F]==[%sysdir%] (
    %zipper% a -tzip "%backupfldr%\%%F-%backuptime%.zip" "%%F\"
  ) ELSE (
    echo Skipping backup for %%F
  )
)

echo "Deleting old zip files now"
set backupfldr=%backupfldr:"=%
Forfiles -p %backupfldr% -s -m *.* -d -%retaindays% -c "cmd /c del /q @path"

echo "done"

::return to the main script dir on end
popd