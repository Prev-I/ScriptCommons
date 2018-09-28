:: SETTINGS AND PATHS 
:: Note: Do not put spaces before the equal signs or variables will fail
:: Ref: https://www.saotn.org/delete-files-recursively-forfiles-on-windows-server/

:: Disable command echo
@echo off

:: Search parameters
set destfldr="C:\Users\Public\Documents"
set searchsubdir=TRUE
set deleteempty=FALSE
set filter="*.*"
set retaindays=30

:: Prepare parameters for search command (semove double quote, correctly set subdirsearch, ecc...)
set destfldr=%destfldr:"=%
set filter=%filter:"=%
set retaindays=-%retaindays% 
if %searchsubdir%==TRUE (set subdirpar="-s") else (set subdirpar="")  
set subdirpar= %subdirpar:"=%

:: Execute the deletion command on files that match the search parameters
forfiles -p %destfldr% %subdirpar% -m %filter% -d %retaindays% -c "cmd /c if @isdir==FALSE (del /F /Q @file)"

:: If deleteempty is true remove the empty folders matching the same search parameters
if %deleteempty%==TRUE (Forfiles -p %destfldr% %subdirpar% -d %retaindays% -c "cmd /c if @isdir==TRUE (rmdir /q @file)")
 
:: work done
echo "done"

::return to the main script dir on end
popd