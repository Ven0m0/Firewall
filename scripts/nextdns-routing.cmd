@echo off
setlocal enabledelayedexpansion

:: ================================================================
:: NextDNS Routing Control Script
:: ================================================================
:: Blocks specific NextDNS servers to control routing
:: Useful for controlling which DNS endpoints are used
::
:: Usage: Run as Administrator
::        nextdns-routing.cmd [add|remove] [profile]
::
:: Profiles:
::   block-eu      - Block European servers (Frankfurt, Berlin)
::   block-us      - Block US routing
::   block-all     - Block both European and US servers
:: ================================================================

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Error: This script requires administrator privileges.
    echo Please run as Administrator.
    pause
    exit /b 1
)

:: Set defaults
set "ACTION=%~1"
set "PROFILE=%~2"
if "%ACTION%"=="" set "ACTION=add"
if "%PROFILE%"=="" set "PROFILE=block-eu"

:: Validate action parameter
if /i not "%ACTION%"=="add" if /i not "%ACTION%"=="remove" (
    echo Error: Invalid action '%ACTION%'. Use 'add' or 'remove'.
    exit /b 1
)

:: Validate profile parameter
if /i not "%PROFILE%"=="block-eu" if /i not "%PROFILE%"=="block-us" if /i not "%PROFILE%"=="block-all" (
    echo Error: Invalid profile '%PROFILE%'. Use 'block-eu', 'block-us', or 'block-all'.
    exit /b 1
)

:: Detect NextDNS installation path
set "NEXTDNS_PATH="
for %%p in (
    "C:\Program Files (x86)\NextDNS\NextDNSService.exe"
    "C:\Program Files\NextDNS\NextDNSService.exe"
    "%ProgramFiles(x86)%\NextDNS\NextDNSService.exe"
    "%ProgramFiles%\NextDNS\NextDNSService.exe"
) do (
    if exist %%p (
        set "NEXTDNS_PATH=%%~p"
        goto :path_found
    )
)

:: Path not found, use default
set "NEXTDNS_PATH=C:\Program Files (x86)\NextDNS\NextDNSService.exe"
echo Warning: Could not auto-detect NextDNS installation.
echo Using default path: %NEXTDNS_PATH%
echo.

:path_found
echo Using NextDNS executable: %NEXTDNS_PATH%
echo Profile: %PROFILE%
echo.

if /i "%ACTION%"=="remove" goto :remove_rules

:: ================================================================
:: Add firewall rules based on profile
:: ================================================================
echo Adding NextDNS routing rules...
echo.

:: European servers (always included in block-eu and block-all)
if /i "%PROFILE%"=="block-eu" goto :add_eu
if /i "%PROFILE%"=="block-all" goto :add_eu
goto :skip_eu

:add_eu
call :add_rule "NextDNS Block anexia-fra" "Block anexia-fra (anycast2, ultralow1)" "217.146.22.163,2a00:11c0:e:ffff:1::d"
call :add_rule "NextDNS Block zepto-fra" "Block zepto-fra (ultralow2)" "194.45.101.249,2a0b:4341:704:24:5054:ff:fe91:8a6c"
call :add_rule "NextDNS Block zepto-ber" "Block zepto-ber (anycast1)" "45.90.28.0,2a07:a8c0::"
call :add_rule "NextDNS Block vultr-fra" "Block vultr-fra (ultralow1)" "199.247.16.158,2a05:f480:1800:8ed:5400:2ff:fec8:7e46"

:skip_eu

:: US servers (only in block-us and block-all)
if /i "%PROFILE%"=="block-us" goto :add_us
if /i "%PROFILE%"=="block-all" goto :add_us
goto :skip_us

:add_us
call :add_rule "NextDNS Block US Routing" "Block US routing range" "45.90.0.0-45.90.255.255"

:skip_us

echo.
echo NextDNS routing rules applied successfully!
goto :end

:: ================================================================
:: Remove firewall rules
:: ================================================================
:remove_rules
echo Removing NextDNS routing rules...
echo.

call :remove_rule "NextDNS Block anexia-fra"
call :remove_rule "NextDNS Block zepto-fra"
call :remove_rule "NextDNS Block zepto-ber"
call :remove_rule "NextDNS Block vultr-fra"
call :remove_rule "NextDNS Block US Routing"

echo.
echo NextDNS routing rules removed successfully!
goto :end

:: ================================================================
:: Helper function to add a firewall rule
:: Parameters: %1=rule name, %2=description, %3=remote IPs
:: ================================================================
:add_rule
set "RULE_NAME=%~1"
set "DESC=%~2"
set "IPS=%~3"

echo Adding rule: %RULE_NAME%
netsh advfirewall firewall add rule name=%RULE_NAME% program="%NEXTDNS_PATH%" dir=out description="%DESC%" action=block enable=yes protocol=tcp remoteport=443 remoteip=%IPS% >nul 2>&1

if %errorLevel% neq 0 (
    echo   ERROR: Failed to add rule %RULE_NAME%
) else (
    echo   SUCCESS: %DESC%
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
echo Available profiles:
echo   - block-eu   : Blocks European DNS servers (Frankfurt, Berlin)
echo   - block-us   : Blocks US routing
echo   - block-all  : Blocks both European and US servers
echo.
echo Usage: %~nx0 [add^|remove] [profile]
echo Example: %~nx0 add block-eu
echo.
pause
exit /b 0
