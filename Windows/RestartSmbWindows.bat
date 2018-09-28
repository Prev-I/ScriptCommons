::Restart all the services responsible of network sharing
::May be usefull for pc that have very long user session
net stop Workstation
net start Netlogon
net start Browser
net start SessionEnv
net start Workstation
exit 0
