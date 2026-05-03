#Requires -RunAsAdministrator
<#
.SYNOPSIS
    DEPRECATED - Use geofencing.ps1 instead
.DESCRIPTION
    This script has been merged into geofencing.ps1.
    Please use geofencing.ps1 with the -Profile or -BlockRegions parameters.
    
    Old usage:
        .\ip-blocking.ps1 -Action Add -EnabledRegions @('UK', 'France')
    
    New usage:
        .\geofencing.ps1 -Profile Custom -BlockRegions @('UK', 'France')
        .\geofencing.ps1 -Profile Europe  # Whitelist Europe (default)
        .\geofencing.ps1 -Profile Germany # Whitelist Germany
#>

[CmdletBinding()]
param()

Write-Host @"

=============================================================
  DEPRECATED: ip-blocking.ps1 has been merged into geofencing.ps1
=============================================================

Please use geofencing.ps1 instead:

  # Whitelist Europe (default - blocks non-European servers)
  .\geofencing.ps1 -Profile Europe

  # Whitelist Germany
  .\geofencing.ps1 -Profile Germany

  # Custom blocking
  .\geofencing.ps1 -Profile Custom -BlockRegions @('UK', 'France')

  # Remove rules
  .\geofencing.ps1 -Remove

For more information, see README.md

"@ -ForegroundColor Yellow

exit 0