@echo off
:: ================================================================
:: Black Ops 6 Geofencing Script
:: ================================================================
:: This script blocks specific game server IPs by region to
:: control matchmaking and server connections for Call of Duty.
::
:: Usage: Run as Administrator
:: ================================================================

set Cod=C:\Program Files (x86)\Call of Duty

:: UK Block
netsh advfirewall firewall add rule name="Bo6 Block UK" program="%Cod%\_retail_\cod.exe" dir=out protocol=udp action=block enable=yes remoteip=45.77.230.226,82.163.76.0/24,104.238.185.20,108.61.176.176,108.61.197.57,136.244.77.155,192.248.165.136
:: France
netsh advfirewall firewall add rule name="Bo6 Block France" program="%Cod%\_retail_\cod.exe" dir=out protocol=udp action=block enable=yes remoteip=78.138.107.0/24,95.179.208.205,95.179.209.45,95.179.211.94,95.179.217.175,92.204.171.249,107.191.47.125,108.61.176.0/24,108.61.208.220,136.244.113.145,136.244.115.128,136.244.116.63,199.247.11.0/24,217.69.2.42,217.69.9.243,217.69.14.30,217.69.13.167
:: Netherlands
netsh advfirewall firewall add rule name="Bo6 Block Netherlands" program="%Cod%\_retail_\cod.exe" dir=out protocol=udp action=block enable=no remoteip=23.109.68.36,23.109.163.4,23.109.254.244,46.23.78.91,78.141.209.67,78.141.215.99,95.179.146.133,95.179.154.240,95.179.184.89,136.244.96.14,136.244.97.236,136.244.108.228,172.255.106.100,188.42.241.20,188.42.243.236,199.247.25.77
:: Poland
::netsh advfirewall firewall add rule name="Bo6 Block Poland" program="%Cod%\_retail_\cod.exe" dir=out protocol=udp action=block enable=yes remoteip=64.176.67.115,64.176.65.32,64.176.64.244
:: Switzerland
::netsh advfirewall firewall add rule name="Bo6 Block Switzerland" program="%Cod%\_retail_\cod.exe" dir=out protocol=udp action=block enable=yes remoteip=35.216.207.127
:: Luxembourg
netsh advfirewall firewall add rule name="Bo6 Block Luxembourg" program="%Cod%\_retail_\cod.exe" dir=out protocol=udp action=block enable=yes remoteip=188.42.190.196

echo Geofencing rules applied successfully!
exit