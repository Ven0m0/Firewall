@echo off
setlocal enabledelayedexpansion

:: ================================================================
:: Black Ops 6 Specific IP Blocking Script
:: ================================================================
:: Blocks specific game server IPs by country/region
:: Refactored from Bo6 GeoFencing.cmd with improvements
::
:: Usage: Run as Administrator
::        specific-ip-blocking.cmd [add|remove]
:: ================================================================

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Error: This script requires administrator privileges.
    echo Please run as Administrator.
    pause
    exit /b 1
)

:: Set default action
set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=add"

:: Validate action parameter
if /i not "%ACTION%"=="add" if /i not "%ACTION%"=="remove" (
    echo Error: Invalid action '%ACTION%'. Use 'add' or 'remove'.
    exit /b 1
)

:: Detect Call of Duty installation path
set "COD_PATH="
for %%p in (
    "C:\Program Files (x86)\Call of Duty"
    "C:\Program Files\Call of Duty"
    "D:\Call of Duty"
    "E:\Call of Duty"
) do (
    if exist "%%~p\_retail_\cod.exe" (
        set "COD_PATH=%%~p"
        goto :path_found
    )
)

:: Path not found, use default
set "COD_PATH=C:\Program Files (x86)\Call of Duty"
echo Warning: Could not auto-detect Call of Duty installation.
echo Using default path: %COD_PATH%
echo.

:path_found
set "COD_EXE=%COD_PATH%\_retail_\cod.exe"
echo Using executable: %COD_EXE%
echo.

:: Configuration - IP addresses by region
set "UK_IPS=45.77.230.226,82.163.76.0/24,104.238.185.20,108.61.176.176,108.61.197.57,136.244.77.155,192.248.165.136"
set "FRANCE_IPS=78.138.107.0/24,95.179.208.205,95.179.209.45,95.179.211.94,95.179.217.175,92.204.171.249,107.191.47.125,108.61.176.0/24,108.61.208.220,136.244.113.145,136.244.115.128,136.244.116.63,199.247.11.0/24,217.69.2.42,217.69.9.243,217.69.14.30,217.69.13.167"
set "NETHERLANDS_IPS=23.109.68.36,23.109.163.4,23.109.254.244,46.23.78.91,78.141.209.67,78.141.215.99,95.179.146.133,95.179.154.240,95.179.184.89,136.244.96.14,136.244.97.236,136.244.108.228,172.255.106.100,188.42.241.20,188.42.243.236,199.247.25.77"
set "POLAND_IPS=64.176.67.115,64.176.65.32,64.176.64.244"
set "SWITZERLAND_IPS=35.216.207.127"
set "LUXEMBOURG_IPS=188.42.190.196"

if /i "%ACTION%"=="remove" goto :remove_rules

:: ================================================================
:: Add firewall rules
:: ================================================================
echo Adding geofencing rules...
echo.

call :add_rule "Bo6 Block UK" "%UK_IPS%" yes
call :add_rule "Bo6 Block France" "%FRANCE_IPS%" yes
call :add_rule "Bo6 Block Netherlands" "%NETHERLANDS_IPS%" no
call :add_rule "Bo6 Block Poland" "%POLAND_IPS%" no
call :add_rule "Bo6 Block Switzerland" "%SWITZERLAND_IPS%" no
call :add_rule "Bo6 Block Luxembourg" "%LUXEMBOURG_IPS%" yes

echo.
echo Geofencing rules applied successfully!
goto :end

:: ================================================================
:: Remove firewall rules
:: ================================================================
:remove_rules
echo Removing geofencing rules...
echo.

call :remove_rule "Bo6 Block UK"
call :remove_rule "Bo6 Block France"
call :remove_rule "Bo6 Block Netherlands"
call :remove_rule "Bo6 Block Poland"
call :remove_rule "Bo6 Block Switzerland"
call :remove_rule "Bo6 Block Luxembourg"

echo.
echo Geofencing rules removed successfully!
goto :end

:: ================================================================
:: Helper function to add a firewall rule
:: Parameters: %1=rule name, %2=IPs, %3=enabled (yes/no)
:: ================================================================
:add_rule
set "RULE_NAME=%~1"
set "IPS=%~2"
set "ENABLED=%~3"

echo Adding rule: %RULE_NAME% [enabled=%ENABLED%]
netsh advfirewall firewall add rule name=%RULE_NAME% program="%COD_EXE%" dir=out protocol=udp action=block enable=%ENABLED% remoteip=%IPS% >nul 2>&1

if %errorLevel% neq 0 (
    echo   ERROR: Failed to add rule %RULE_NAME%
) else (
    echo   SUCCESS
)
goto :eof

:: ================================================================
:: Helper function to remove a firewall rule
:: Parameters: %1=rule name
:: ================================================================
:remove_rule
set "RULE_NAME=%~1"

echo Removing rule: %RULE_NAME%
netsh advfirewall firewall delete rule name=%RULE_NAME% >nul 2>&1

if %errorLevel% neq 0 (
    echo   WARNING: Rule may not exist or already removed
) else (
    echo   SUCCESS
)
goto :eof

:end
echo.
pause
exit /b 0
