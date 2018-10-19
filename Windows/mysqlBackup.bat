:: Auto MySQL Backup For Windows Servers By Matt Moeller  v.1.5
:: RED OLIVE INC.  - www.redolive.com

:: Follow us on twitter for updates to this script  twitter.com/redolivedesign
:: coming soon:  email admin a synopsis of the backup with total file size(s) and time it took to execute

:: FILE HISTORY ----------------------------------------------
:: UPDATE 11.7.2012  Added setup all folder paths into variables at the top of the script to ease deployment
:: UPDATE 7.16.2012  Added --routines, fix for dashes in filename, and fix for regional time settings
:: UPDATE 3.30.2012  Added error logging to help troubleshoot databases backup errors.   --log-error="c:\MySQLBackups\backupfiles\dumperrors.txt"
:: UPDATE 12.29.2011 Added time bug fix and remote FTP options - Thanks to Kamil Tomas 
:: UPDATE 5.09.2011  v 1.0 


:: If the time is less than two digits insert a zero so there is no space to break the filename

:: If you have any regional date/time issues call this include: getdate.cmd  credit: Simon Sheppard for this cmd - untested
:: call getdate.cmd

IF "%time:~0,1%" LSS "1" (
SET BACKUPTIME=%date:~6,4%-%date:~3,2%-%date:~0,2%-0%time:~1,1%-%time:~3,2%-%time:~6,2%
) ELSE (
SET BACKUPTIME=%date:~6,4%-%date:~3,2%-%date:~0,2%-%time:~0,2%-%time:~3,2%-%time:~6,2%
)

:: SETTINGS AND PATHS 
:: Note: Do not put spaces before the equal signs or variables will fail

:: Name of the database user with rights to all tables
set dbuser=root

:: Password for the database user
set dbpass=Desmo16

:: Error log path - Important in debugging your issues
set errorLogPath="C:\Backups\mysqlErrors.txt"

:: MySQL EXE Path
set mysqldumpexe="C:\Program Files\MySQL\MySQL Server 5.5\bin\mysqldump.exe"

:: where to put backups
set backupfldr="C:\Backups\DataBase\MySql"

:: Path to data folder which may differ from install dir
set datafldr="C:\DataBase\Mysql\data"

:: Path to zip executable
set zipper="C:\Program Files\7-Zip\7z.exe"

:: Number of days to retain .zip backup files 
set retaindays=30

:: DONE WITH SETTINGS



:: GO FORTH AND BACKUP EVERYTHING!

:: Switch to the data directory to enumerate the folders
pushd %datafldr%

echo "Pass each name to mysqldump.exe and output an individual .sql file for each"

:: Thanks to Radek Dolezel for adding the support for dashes in the db name
:: Added --routines thanks for the suggestion Angel

:: turn on if you are debugging
@echo off

FOR /D %%F IN (*) DO (
  IF NOT [%%F]==[performance_schema] (
    SET %%F=!%%F:@002d=-!
    %mysqldumpexe% --user=%dbuser% --password=%dbpass% --databases --routines --log-error=%errorLogPath% %%F > "%backupfldr%\%%F.%backuptime%.sql"
    %zipper% a -tzip "%backupfldr%\%%F.%backuptime%.zip" "%backupfldr%\%%F.%backuptime%.sql"
  ) ELSE (
    echo Skipping DB backup for performance_schema
  )
)

echo "Deleting all the files ending in .sql only"
 
del "%backupfldr%\*.sql"

echo "Deleting old zip files now"
::remove "" from folderpath
set backupfldr=%backupfldr:"=%
Forfiles -p %backupfldr% -s -m *.* -d -%retaindays% -c "cmd /c del /q @path"


::FOR THOSE WHO WISH TO FTP YOUR FILE UNCOMMENT THESE LINES AND UPDATE - Thanks Kamil for this addition!

::cd\[path to directory where your file is saved]
::@echo off
::echo user [here comes your ftp username]>ftpup.dat
::echo [here comes ftp password]>>ftpup.dat
::echo [optional line; you can put "cd" command to navigate through the folders on the ftp server; eg. cd\folder1\folder2]>>ftpup.dat
::echo binary>>ftpup.dat
::echo put [file name comes here; eg. FullBackup.%backuptime%.zip]>>ftpup.dat
::echo quit>>ftpup.dat
::ftp -n -s:ftpup.dat [insert ftp server here; eg. myserver.com]
::del ftpup.dat

echo "done"

::return to the main script dir on end
popd