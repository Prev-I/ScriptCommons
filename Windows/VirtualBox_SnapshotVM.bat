:: Check missing parameters
IF %1.==. (
  echo "Missing VM Name!"
  exit -1
)

echo "Renaming old snapshot..."
VBoxManage.exe snapshot %1 edit previous --name discard  
echo "Renaming current snapshot..."
VBoxManage.exe snapshot %1 edit current --name previous 
echo "Taking new snapshot..."
VBoxManage.exe snapshot %1 take current  
echo "Deleting old snapshot..."
VBoxManage.exe snapshot %1 delete discard     

::pause 
exit 0