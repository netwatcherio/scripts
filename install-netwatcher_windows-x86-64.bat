@echo off
setlocal

echo Determining system architecture...
:: Determine the system architecture
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do (
    set "arch=%%b"
)
echo System architecture is %arch%.

echo Setting download URL based on architecture...
:: Set the download URL based on architecture
:: Set the download URL for the main .exe and libraries based on architecture
if "%arch%"=="AMD64" (
    set "mainExeUrl=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/netwatcher-agent.exe"
    set "lib1Url=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/rperf_windows-x86_64.exe"
    set "lib2Url=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/trip_windows-x86_64.exe"
) else (
    set "mainExeUrl=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/netwatcher-agent.exe"
    set "lib1Url=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/rperf_windows-x86_64.exe"
    set "lib2Url=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/trip_windows-x86_64.exe"
)

echo Creating installation directory...
:: Create the installation directory if it doesn't exist
set "installDir=C:\netwatcher-agent"
if not exist "%installDir%" (
    mkdir "%installDir%"
)

:: Create the installation and lib directories if they don't exist
echo Creating library directory...
set "libDir=%installDir%\lib"
if not exist "%libDir%" (
    mkdir "%libDir%"
)

echo Downloading NetWatcher Agent...
:: Download the main .exe with error checking and retries
:download_main_exe
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%mainExeUrl%', '%installDir%\netwatcher-agent.exe')"
if %errorlevel% neq 0 (
    echo Download failed. Retrying...
    timeout /t 5
    goto download_main_exe
)

echo Downloading NetWatcher Agent Libraries...
:: Download the required libraries with error checking and retries
:download_libraries
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%lib1Url%', '%libDir%\rperf_windows-x86_64.exe')"
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%lib2Url%', '%libDir%\trip_windows-x86_64.exe')"
if %errorlevel% neq 0 (
    echo Download failed. Retrying...
    timeout /t 5
    goto download_libraries
)

echo Setting up configuration...
:: Set default options for configuration
set "HOST=https://api.netwatcher.io"
set "HOST_WS=wss://api.netwatcher.io/agent_ws"

:: Prompt the user for configuration input
set /p "HOST=Enter HOST (default: %HOST%): " || set "HOST=%HOST%"
set /p "HOST_WS=Enter HOST_WS (default: %HOST_WS%): " || set "HOST_WS=%HOST_WS%"
set /p "ID=Enter ID: "
set /p "PIN=Enter PIN: "

:: Create the config.conf file
(
    echo HOST=%HOST%
    echo HOST_WS=%HOST_WS%
    echo ID=%ID%
    echo PIN=%PIN%
) > "%installDir%\config.conf"

:: Add firewall rules for ICMP in and out for netwatcher
echo Creating the firewall rules for ICMP...
netsh advfirewall firewall add rule name="NetWatcher ICMP In" protocol=icmpv4:8,any dir=in action=allow
netsh advfirewall firewall add rule name="NetWatcher ICMP Out" protocol=icmpv4:any,any dir=out action=allow

echo Creating startsvc_nw.bat file...
echo @echo off > %installDir%\startsvc_nw.bat
echo set "installDir=C:\netwatcher-agent" >> %installDir%\startsvc_nw.bat
echo echo Starting NetWatcher Agent... >> %installDir%\startsvc_nw.bat
echo net start netwatcher-agent >> %installDir%\startsvc_nw.bat
echo pause >> %installDir%\startsvc_nw.bat

echo Creating start_nw.bat file...
echo @echo off > %installDir%\start_nw.bat
echo title NetWatcher Agent - Network Performance Monitoring >> %installDir%\start_nw.bat
echo set "installDir=C:\netwatcher-agent" >> %installDir%\start_nw.bat
echo echo Starting NetWatcher Agent... >> %installDir%\start_nw.bat
echo cd %installDir% >> %installDir%\start_nw.bat
echo %installDir%\netwatcher-agent.exe >> %installDir%\start_nw.bat
echo pause >> %installDir%\start_nw.bat

echo Creating stop_nw.bat file...
echo @echo off > %installDir%\stop_nw.bat
echo set "installDir=C:\netwatcher-agent" >> %installDir%\stop_nw.bat
echo echo Stopping NetWatcher Agent... >> %installDir%\stop_nw.bat
echo net stop netwatcher-agent >> %installDir%\stop_nw.bat
echo pause >> %installDir%\stop_nw.bat

echo Creating uninstall_nw.bat file...
echo @echo off > %installDir%\uninstall_nw.bat
echo set "installDir=C:\netwatcher-agent" >> %installDir%\uninstall_nw.bat
echo echo Uninstalling NetWatcher Agent... >> %installDir%\uninstall_nw.bat
echo net stop netwatcher-agent >> %installDir%\uninstall_nw.bat
echo sc stop netwatcher-agent >> %installDir%\uninstall_nw.bat
echo sc delete netwatcher-agent >> %installDir%\uninstall_nw.bat
echo del "%installDir%\netwatcher-agent.exe" >> %installDir%\uninstall_nw.bat
echo del "%installDir%\config.conf" >> %installDir%\uninstall_nw.bat
echo del "%installDir%\start_nw.bat" >> %installDir%\uninstall_nw.bat
echo del "%installDir%\stop_nw.bat" >> %installDir%\uninstall_nw.bat
echo rmdir "%installDir%\lib" /s /q >> %installDir%\uninstall_nw.bat
echo rmdir "%installDir%" /s /q >> %installDir%\uninstall_nw.bat
echo echo Removing firewall rules for ICMP... >> %installDir%\uninstall_nw.bat
echo netsh advfirewall firewall delete rule name="NetWatcher ICMP In" protocol=icmpv4:8,any dir=in >> %installDir%\uninstall_nw.bat
echo netsh advfirewall firewall delete rule name="NetWatcher ICMP Out" protocol=icmpv4:any,any dir=out >> %installDir%\uninstall_nw.bat
echo echo Uninstallation completed. >> %installDir%\uninstall_nw.bat
echo pause >> %installDir%\uninstall_nw.bat

echo Creating the NetWatcher Agent service...
:: Add the program as a service that starts automatically and runs start.bat
sc create netwatcher-agent binPath= "cmd /c %installDir%\start_nw.bat" start= auto

echo Installation and configuration completed.
pause
