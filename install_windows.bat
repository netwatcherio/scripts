@echo off
setlocal

:: Determine the system architecture
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do (
    set "arch=%%b"
)

:: Set the download URL based on architecture
if "%arch%"=="AMD64" (
    set "downloadUrl=https://github.com/netwatcherio/netwatcher-agent/releases/latest/download/netwatcher-agent_windows-amd64.zip"
) else (
    set "downloadUrl=https://github.com/netwatcherio/netwatcher-agent/releases/latest/download/netwatcher-agent_windows-386.zip"
)

:: Create the installation directory if it doesn't exist
set "installDir=C:\netwatcher-agent"
if not exist "%installDir%" (
    mkdir "%installDir%"
)

:: Download the latest release .zip
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%downloadUrl%', '%installDir%\netwatcher-agent.zip')"

:: Unzip and copy the 'lib' folder from the downloaded .zip file
powershell -command "Expand-Archive -Path '%installDir%\netwatcher-agent.zip' -DestinationPath '%installDir%' -Force"

:: Remove the downloaded .zip file
del "%installDir%\netwatcher-agent.zip"

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

:: Add the program as a service that starts automatically
sc create netwatcher-agent binPath= "cmd /K %installDir%\lib\netwatcher-agent.exe" start= auto

echo Installation and configuration completed.
