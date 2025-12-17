@echo off
setlocal enabledelayedexpansion

:: ================================================================
:: Black Ops 6 Firewall Port Configuration
:: ================================================================
:: Allows required ports for Call of Duty Black Ops 6
:: Refactored from Bo6 Firewall.cmd with improvements
::
:: TCP Ports: 3074, 3075, 27015-27030, 27036-27037
:: UDP Ports: 3074, 4380, 27000-27036
::
:: Usage: Run as Administrator
::        firewall-ports.cmd [add|remove]
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

:: Port configuration
set "TCP_PORTS=3074,3075,27015-27030,27036-27037"
set "UDP_PORTS=3074,4380,27000-27036"

if /i "%ACTION%"=="remove" goto :remove_rules

:: ================================================================
:: Add firewall rules
:: ================================================================
echo Adding Black Ops 6 firewall port rules...
echo.

echo Adding TCP rule for ports: %TCP_PORTS%
netsh advfirewall firewall add rule name="Bo6 TCP Outbound" dir=out protocol=tcp remoteport=%TCP_PORTS% action=allow >nul 2>&1
if %errorLevel% neq 0 (
    echo   ERROR: Failed to add TCP outbound rule
) else (
    echo   SUCCESS: TCP outbound rule added
)

echo Adding TCP inbound rule for ports: %TCP_PORTS%
netsh advfirewall firewall add rule name="Bo6 TCP Inbound" dir=in protocol=tcp localport=%TCP_PORTS% action=allow >nul 2>&1
if %errorLevel% neq 0 (
    echo   ERROR: Failed to add TCP inbound rule
) else (
    echo   SUCCESS: TCP inbound rule added
)

echo Adding UDP rule for ports: %UDP_PORTS%
netsh advfirewall firewall add rule name="Bo6 UDP Outbound" dir=out protocol=udp remoteport=%UDP_PORTS% action=allow >nul 2>&1
if %errorLevel% neq 0 (
    echo   ERROR: Failed to add UDP outbound rule
) else (
    echo   SUCCESS: UDP outbound rule added
)

echo Adding UDP inbound rule for ports: %UDP_PORTS%
netsh advfirewall firewall add rule name="Bo6 UDP Inbound" dir=in protocol=udp localport=%UDP_PORTS% action=allow >nul 2>&1
if %errorLevel% neq 0 (
    echo   ERROR: Failed to add UDP inbound rule
) else (
    echo   SUCCESS: UDP inbound rule added
)

echo.
echo Firewall port rules added successfully!
goto :end

:: ================================================================
:: Remove firewall rules
:: ================================================================
:remove_rules
echo Removing Black Ops 6 firewall port rules...
echo.

for %%r in (
    "Bo6 TCP Outbound"
    "Bo6 TCP Inbound"
    "Bo6 UDP Outbound"
    "Bo6 UDP Inbound"
) do (
    echo Removing rule: %%r
    netsh advfirewall firewall delete rule name=%%r >nul 2>&1
    if %errorLevel% neq 0 (
        echo   WARNING: Rule may not exist or already removed
    ) else (
        echo   SUCCESS
    )
)

echo.
echo Firewall port rules removed successfully!
goto :end

:end
echo.
pause
exit /b 0
