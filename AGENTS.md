# Call of Duty Firewall Scripts - Agent Guide

## Project Overview

PowerShell-based Windows Firewall management for Call of Duty: Black Ops 6 geofencing and network routing control. Scripts create outbound blocking rules to control which game server regions can be accessed.

## Architecture

- `scripts/FirewallUtils.psm1` - Shared utility module with common functions
- `scripts/geofencing.ps1` - Regional IP blocking with profiles
- `scripts/ip-blocking.ps1` - Specific IP blocking by country
- `scripts/port-configuration.ps1` - Game port allowlist management
- `scripts/dns-routing.ps1` - NextDNS server routing control
- `legacy/` - Deprecated batch scripts (reference only)

## Key Conventions

### PowerShell Style
- All scripts require admin privileges (`#Requires -RunAsAdministrator`)
- Use `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'`
- Import utilities via `Import-Module "$PSScriptRoot\FirewallUtils.psm1" -Force`
- Use parameter validation: `[ValidateSet(...)]`, mandatory parameters
- Follow verb-noun naming for functions (Get-, Add-, Remove-, Test-, Assert-)

### IP Ranges Format
- Single IPs: `146.0.200.0`
- Ranges: `start-end` (e.g., `5.0.0.0-5.255.255.255`)
- Multiple ranges joined by comma in `-RemoteAddress` parameter

### Rule Naming Convention
- Geofencing: `Cod GeoFilter {Profile}` (e.g., "Cod GeoFilter Germany")
- IP Blocking: `Cod IP Block {Country}` (e.g., "Cod IP Block UK")
- Ports: `Cod Port {TCP|UDP} {Port}` (e.g., "Cod Port TCP 3074")
- DNS: `Cod DNS Block {Profile}` (e.g., "Cod DNS Block EU")

## Common Commands

```powershell
# Apply geofencing profile
.\scripts\geofencing.ps1 -Profile Germany

# Remove all geofencing rules
.\scripts\geofencing.ps1 -Remove

# Add IP blocking for specific regions
.\scripts\ip-blocking.ps1 -Action Add -EnabledRegions @('UK', 'France')

# Configure game ports
.\scripts\port-configuration.ps1 -Action Add

# Remove all rules
.\scripts\geofencing.ps1 -Remove
.\scripts\ip-blocking.ps1 -Action Remove
.\scripts\port-configuration.ps1 -Action Remove
```

## Testing

```powershell
# Verify rules exist
Get-NetFirewallRule -DisplayName "Cod*" -ErrorAction SilentlyContinue

# Test execution policy
powershell -ExecutionPolicy Bypass -File .\scripts\geofencing.ps1 -Profile Germany
```

## Linting & Validation

```bash
# PowerShell syntax check
pwsh -NoProfile -Command "Get-Command -Syntax .\scripts\*.ps1"
```

## Security Notes

- Scripts must run as Administrator
- Backup firewall rules before bulk changes
- Some configurations may violate game Terms of Service
- IP ranges may become outdated and require updates

## File Discovery

Use `rg` (ripgrep) for fast file discovery:

```bash
# Find PowerShell files
rg --type ps1 "" -l

# Find IP address files
rg --type txt "" -l

# Search for specific patterns in scripts
rg "New-NetFirewallRule" -t ps1
```