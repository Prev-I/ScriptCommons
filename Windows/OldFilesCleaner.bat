:: SETTINGS AND PATHS 
:: Note: Do not put spaces before the equal signs or variables will fail
:: Ref: https://www.saotn.org/delete-files-recursively-forfiles-on-windows-server/

:: Disable command echo
@echo off

:: Example launch from CMD
:: OldFilesCleaner.bat "C:\Users\Public\Documents" "*.*" TRUE FALSE 30

:: Example set parameters
:: set destfldr="C:\Users\Public\Documents"
:: set searchfltr="*.*"
:: set searchsubdir=TRUE
:: set deleteempty=FALSE
:: set retaindays=30

:: Script search parameters
set destfldr=%1
set searchfltr=%2
set searchsubdir=%3
set deleteempty=%4
set retaindays=%5

:: Prepare parameters for search command (semove double quote, correctly set subdirsearch, ecc...)
set destfldr=%destfldr:"=%
set searchfltr=%searchfltr:"=%
set retaindays=-%retaindays% 
if %searchsubdir%==TRUE (set subdirpar="-s") else (set subdirpar="")  
set subdirpar= %subdirpar:"=%

:: Execute the deletion command on files that match the search parameters
forfiles -p %destfldr% %subdirpar% -m %searchfltr% -d %retaindays% -c "cmd /c if @isdir==FALSE (del /F /Q @file)"

:: If deleteempty is true remove the empty subfolders
if %deleteempty%==TRUE (Forfiles -p %destfldr% %subdirpar% -c "cmd /c if @isdir==TRUE (rmdir /q @file)")
 
:: work done
echo "done"

::return to the main script dir on end
popd