:: Check missing parameters
IF %1.==. (
  echo "Missing VM Name!"
  exit -1
)
IF %2.==. (
  echo "Missing DISK Name!"
  exit -1
)

:: Variable declarations
IF "%time:~0,1%" LSS "1" (
SET BACKUPTIME=%date:~6,4%-%date:~3,2%-%date:~0,2%-0%time:~1,1%-%time:~3,2%-%time:~6,2%
) ELSE (
SET BACKUPTIME=%date:~6,4%-%date:~3,2%-%date:~0,2%-%time:~0,2%-%time:~3,2%-%time:~6,2%
)
set RETAINDAYS=30

echo "Cloning VM Disk..."
xcopy /s /y D:\VirtualBox\%1\%2.vbox D:\Backups\%1\
VBoxManage.exe clonemedium D:\VirtualBox\%1\%2.vdi D:\Backups\%1\%2_%BACKUPTIME%.vdi

echo "Deleting OLD Disk..."
Forfiles -p D:\Backups\%1 -s -m *.vdi -d -%RETAINDAYS% -c "cmd /c del /q @path"

::pause
exit 0