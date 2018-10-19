set sourceDirGIT="C:\LOCALDIR\git"
set targetDirGIT="C:\REMOTEDIR\backups\git"

:: If path are local this part can be commented out
net use %targetDirGIT% /user:USER PASSWORD 

:: backup repository GIT
FOR /F %%F IN ('dir /b /a:D %sourceDirGIT%\*') DO (
  rmdir /S /Q %targetDirGIT%\%%F
  git clone --mirror %sourceDirGIT%\%%F %targetDirGIT%\%%F
)

exit 0