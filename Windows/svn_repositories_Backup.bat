set sourceDirSVN="C:\LOCALDIR\svn"
set targetDirSVN="\\REMOTEDIR\backups\SVN"

:: If path are local this part can be commented out
net use %targetDirSVN% /user:USER PASSWORD 

:: backup repository SVN
:: dump command create a single file as backup
:: svnadmin dump %sourceDirSVN%\%%F > %targetDirSVN%\%%F.dump
FOR /F %%F IN ('dir /b /a:D %sourceDirSVN%\*.') DO (
  :: remove old repository copy and take a new hotcopy
  rmdir /S /Q %targetDirSVN%\%%F
  svnadmin hotcopy %sourceDirSVN%\%%F %targetDirSVN%\%%F
  :: dump command create a single file as backup
  :: svnadmin dump %sourceDirSVN%\%%F > %targetDirSVN%\%%F.dump
)

exit 0