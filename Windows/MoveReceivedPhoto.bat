:: SETTINGS AND PATHS 
:: Note: Do not put spaces before the equal signs or variables will fail

:: Where to find png files
set sourcefldr="C:\Users\Public\Pictures"

:: Where to move png files
set destinationfldr="C:\Users\Public\"

:: Move file in destination and change the extension
FOR %%A in (%sourcefldr%\*.png) do (
   COPY "%%A"  %destinationfldr%\
   copy NUL "%%A".accepted
   DEL "%%A"
)

:: Work done
echo "done"

::return to the main script dir on end
popd