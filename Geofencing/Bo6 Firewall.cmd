@echo off
:: ================================================================
:: Black Ops 6 Firewall Port Configuration
:: ================================================================
:: This script allows required ports for Call of Duty Black Ops 6
:: TCP Ports: 3074, 3075, 27015-27030, 27036-27037
:: UDP Ports: 3074, 4380, 27000-27036
::
:: Usage: Run as Administrator
:: ================================================================

netsh advfirewall firewall add rule name="Bo6 TCP" dir=out protocol=tcp remoteport=3074,3075,27015-27030,27036-27037 action=allow
netsh advfirewall firewall add rule name="Bo6 UDP" dir=out protocol=udp remoteport=3074,4380,27000-27036 action=allow

echo Firewall rules added successfully!
exit