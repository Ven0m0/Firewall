@echo off
:: ================================================================
:: NextDNS Routing Control Script
:: ================================================================
:: This script blocks specific NextDNS servers to control routing
:: Blocks European DNS servers (Frankfurt, Berlin regions)
::
:: Usage: Run as Administrator
:: ================================================================

netsh advfirewall firewall add rule name="Nextdns Block anexia-fra" program="C:\Program Files (x86)\NextDNS\NextDNSService.exe" dir=out description="Block anexia-fra ipv6" action=block enable=yes protocol=tcp remoteport=443 remoteip=2a00:11c0:e:ffff:1::d
netsh advfirewall firewall add rule name="Nextdns Block zepto-fra" program="C:\Program Files (x86)\NextDNS\NextDNSService.exe" dir=out description="Block zepto-fra (ultralow2)" action=block enable=yes protocol=tcp remoteport=443 remoteip=194.45.101.249,2a0b:4341:704:24:5054:ff:fe91:8a6c

echo NextDNS routing rules applied successfully!
exit
