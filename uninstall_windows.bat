@echo off
setlocal

:: Stop the service (replace 'YourServiceName' with the actual service name)
sc stop netwatcher-agent

:: Delete the service (replace 'YourServiceName' with the actual service name)
sc delete netwatcher-agent

:: Delete the firewall rules
netsh advfirewall firewall delete rule name="NW-ICMPv4-In" protocol=icmpv4:any,any dir=in
netsh advfirewall firewall delete rule name="NW-ICMPv4-Out" protocol=icmpv4:any,any dir=out

:: Determine the installation directory
set "installDir=C:\netwatcher-agent"

:: Delete the installation directory and its contents
if exist "%installDir%" (
    rmdir /s /q "%installDir%"
)

echo Uninstallation completed.
