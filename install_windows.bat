@echo off
setlocal

:: Determine the system architecture
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do (
    set "arch=%%b"
)

:: Set the download URL for the main .exe and libraries based on architecture
if "%arch%"=="AMD64" (
    set "mainExeUrl=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/netwatcher-agent_x64.exe"
    set "lib1Url=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/trip_windows-x86_64.exe"
    set "lib2Url=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/rperf_windows-x86_64.exe"
) else (
    set "mainExeUrl=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/netwatcher-agent_x64.exe"
    set "lib1Url=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/trip_windows-x86_64.exe"
    set "lib2Url=https://github.com/netwatcherio/netwatcher-agent/releases/download/v1.0.5/rperf_windows-x86_64.exe"
)

:: Create the installation and lib directories if they don't exist
set "installDir=C:\netwatcher-agent"
set "libDir=%installDir%\lib"
if not exist "%installDir%" (
    mkdir "%installDir%"
)
if not exist "%libDir%" (
    mkdir "%libDir%"
)

:: Download the main .exe
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%mainExeUrl%', '%installDir%\netwatcher-agent.exe')"

:: Download the required libraries
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%lib1Url%', '%libDir%\trip_windows-x86_64.exe')"
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%lib2Url%', '%libDir%\rperf_windows-x86_64.exe')"

:: Continue with the rest of your script for configuration and service setup...

:: Create an uninstaller batch script
(
echo @echo off
echo setlocal
echo sc stop netwatcher-agent
echo sc delete netwatcher-agent
echo netsh advfirewall firewall delete rule name="NetWatcher ICMP In"
echo netsh advfirewall firewall delete rule name="NetWatcher ICMP Out"
echo del "%installDir%\netwatcher-agent.exe"
echo del "%libDir%\rperf_windows-x86_64.exe"
echo del "%libDir%\trip_windows-x86_64.exe"
echo rmdir "%libDir%"
echo del "%installDir%\uninstaller.bat"
echo echo Uninstallation complete.
) > "%installDir%\uninstaller.bat"

echo Installation and configuration completed.
