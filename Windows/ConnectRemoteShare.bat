@echo off

:: Remove network share
net use /delete /y "X:"
:: Add network share 
net use L: \\[SERVER]\[FOLDER] /u:[DOMAIN]\[USERNAME] [PASSWORD]

exit 0