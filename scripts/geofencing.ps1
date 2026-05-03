#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Call of Duty Geofencing Script - Unified Regional Blocking
.DESCRIPTION
    Blocks game server connections by geographic region using IP ranges.
    Supports multiple blocking profiles: Europe (whitelisted), Germany, Custom.
    Reads IP addresses from game-servers.txt configuration file.
    Auto-detects Battle.net and Steam installations.
.PARAMETER Profile
    The blocking profile to apply:
    - Europe: Whitelist (blocks non-European servers, allows Europe) - DEFAULT
    - Germany: Block non-German servers
    - Custom: Block specific regions using -BlockRegions parameter
.PARAMETER GamePath
    Path to cod24-cod.exe. Auto-detected if not specified.
.PARAMETER BlockRegions
    Array of regions to block (for Custom profile): UK, France, Netherlands, Poland, Switzerland, Luxembourg, Germany
    Note: Europe is whitelisted by default (user is in Germany)
.PARAMETER Remove
    Remove existing geofencing rules instead of adding them
.EXAMPLE
    .\geofencing.ps1 -Profile Europe
.EXAMPLE
    .\geofencing.ps1 -Profile Germany
.EXAMPLE
    .\geofencing.ps1 -Profile Custom -BlockRegions @('UK', 'France')
.EXAMPLE
    .\geofencing.ps1 -Remove
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Europe', 'Germany', 'Custom')]
    [string]$Profile = 'Europe',

    [Parameter(Mandatory=$false)]
    [string]$GamePath,

    [Parameter(Mandatory=$false)]
    [ValidateSet('UK', 'France', 'Netherlands', 'Poland', 'Switzerland', 'Luxembourg', 'Germany')]
    [string[]]$BlockRegions = @(),

    [Parameter(Mandatory=$false)]
    [switch]$Remove
)

# Import common utilities
$modulePath = Join-Path $PSScriptRoot 'FirewallUtils.psm1'
Import-Module $modulePath -Force

# Error handling
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

#region IP Data Loading

function Import-GameServerIPs {
    <#
    .SYNOPSIS
        Loads IP addresses from game-servers.txt configuration file
    .OUTPUTS
        Hashtable mapping region names to IP address arrays
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $configPath = Join-Path $PSScriptRoot 'game-servers.txt'
    
    if (-not (Test-Path $configPath)) {
        throw "Configuration file not found: $configPath"
    }

    $regionIPs = @{}
    $currentRegion = $null

    $lines = Get-Content $configPath -ErrorAction Stop
    
    foreach ($line in $lines) {
        # Skip comments and empty lines
        $trimmedLine = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmedLine) -or $trimmedLine.StartsWith('#')) {
            continue
        }

        # Check for region header [region_name]
        if ($trimmedLine -match '^\[(\w+)\]$') {
            $currentRegion = $matches[1].ToLower()
            $regionIPs[$currentRegion] = @()
            continue
        }

        # Add IP/range to current region
        if ($currentRegion -and -not [string]::IsNullOrWhiteSpace($trimmedLine)) {
            $regionIPs[$currentRegion] += $trimmedLine
        }
    }

    return $regionIPs
}

#endregion

#region Firewall Rules

function Add-RegionalBlockingRules {
    <#
    .SYNOPSIS
        Adds blocking rules for specified regions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExecutablePath,

        [Parameter(Mandatory=$true)]
        [string[]]$RegionsToBlock,

        [Parameter(Mandatory=$true)]
        [hashtable]$RegionIPs
    )

    Write-Host "`nAdding geofencing rules..." -ForegroundColor Cyan

    $successCount = 0
    $failCount = 0

    # Get all available regions
    $availableRegions = $RegionIPs.Keys | Where-Object { $_ -ne 'europe' }

    foreach ($region in $availableRegions) {
        # Determine if this region should be blocked
        $shouldBlock = $false
        foreach ($blockedRegion in $RegionsToBlock) {
            if ($blockedRegion.ToLower() -eq $region.ToLower()) {
                $shouldBlock = $true
                break
            }
        }
        
        $ruleName = "Cod GeoFilter $region"
        $ips = $RegionIPs[$region] -join ','
        
        $statusText = if ($shouldBlock) { "BLOCKED" } else { "ALLOWED (Europe)" }
        $color = if ($shouldBlock) { 'Yellow' } else { 'Gray' }
        
        Write-Host "`n[$statusText] $region" -ForegroundColor $color

        # Skip if no IPs defined for this region
        if ([string]::IsNullOrWhiteSpace($ips)) {
            Write-Host "  ℹ No IPs defined for $region, skipping" -ForegroundColor Gray
            continue
        }

        $result = Add-FirewallRule `
            -RuleName $ruleName `
            -Direction Outbound `
            -Protocol UDP `
            -Action Block `
            -Program $ExecutablePath `
            -RemoteAddress $ips `
            -Description "Block $region game servers for Call of Duty" `
            -Enabled $shouldBlock

        if ($result) {
            $successCount++
        } else {
            $failCount++
        }
    }

    Write-Host "`n" -NoNewline
    Write-Host "Summary: " -ForegroundColor Cyan -NoNewline
    Write-Host "$successCount regions processed, $failCount failed" -ForegroundColor $(if ($failCount -eq 0) { 'Green' } else { 'Yellow' })
}

function Remove-GeofencingRules {
    <#
    .SYNOPSIS
        Removes all Call of Duty geofencing firewall rules
    #>
    [CmdletBinding()]
    param()

    Write-Host "`nRemoving geofencing rules..." -ForegroundColor Cyan

    $totalRemoved = Remove-FirewallRulesByPattern -Pattern "Cod GeoFilter*"

    if ($totalRemoved -gt 0) {
        Write-Host "`nSuccessfully removed $totalRemoved rule(s)" -ForegroundColor Green
    } else {
        Write-Host "`nNo rules to remove" -ForegroundColor Gray
    }
}

#endregion

#region Profile Logic

function Get-BlockedRegionsForProfile {
    <#
    .SYNOPSIS
        Determines which regions to block based on profile
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProfileName,

        [Parameter(Mandatory=$false)]
        [string[]]$CustomRegions
    )

    # All available regions (excluding Europe which is whitelisted)
    $allRegions = @('UK', 'France', 'Netherlands', 'Poland', 'Switzerland', 'Luxembourg', 'Germany')

    switch ($ProfileName) {
        'Europe' {
            # Europe is whitelisted - block everything except Europe
            # This means allow European IPs, block non-European
            # For simplicity, we block all defined regions (non-European)
            return $allRegions
        }
        'Germany' {
            # Block everything except Germany
            return $allRegions | Where-Object { $_ -ne 'Germany' }
        }
        'Custom' {
            return $CustomRegions
        }
        default {
            return @()
        }
    }
}

#endregion

# Main execution
try {
    Write-Host "`n=== Call of Duty Geofencing Configuration ===" -ForegroundColor Cyan

    # Verify administrator privileges
    Assert-AdministratorRole

    # Handle removal mode
    if ($Remove) {
        Remove-GeofencingRules
        Write-Host "`nGeofencing rules removed successfully!`n" -ForegroundColor Green
        exit 0
    }

    # Load IP configuration
    Write-Host "Loading IP configuration from game-servers.txt..." -ForegroundColor Gray
    $regionIPs = Import-GameServerIPs

    if ($regionIPs.Count -eq 0) {
        throw "No IP configurations found in game-servers.txt"
    }

    Write-Host "Loaded $($regionIPs.Count) region(s)" -ForegroundColor Gray

    # Validate and locate game executable
    if (-not $GamePath) {
        Write-Host "`nSearching for Call of Duty executable..." -ForegroundColor Yellow
        $GamePath = Find-CodExecutable

        if (-not $GamePath) {
            throw @"
Could not locate cod24-cod.exe automatically. Please specify the path using -GamePath parameter.

Supported installation paths:
  Battle.net: C:\Program Files (x86)\Call of Duty
  Steam: C:\Program Files (x86)\Steam\steamapps\common\Call of Duty HQ

Example: .\geofencing.ps1 -Profile Europe -GamePath "C:\Program Files (x86)\Steam\steamapps\common\Call of Duty HQ\cod24\cod24-cod.exe"
"@
        }
    }

    if (-not (Test-Path $GamePath)) {
        throw "Game executable not found at: $GamePath"
    }

    Write-Host "Using executable: $GamePath" -ForegroundColor Gray

    # Determine blocked regions based on profile
    $blockedRegions = Get-BlockedRegionsForProfile -ProfileName $Profile -CustomRegions $BlockRegions

    if ($blockedRegions.Count -eq 0 -and $Profile -ne 'Europe') {
        Write-Host "No regions selected for blocking" -ForegroundColor Yellow
    }

    # Display configuration
    Write-Host "Profile: $Profile" -ForegroundColor Cyan
    
    if ($Profile -eq 'Europe') {
        Write-Host "Mode: Whitelist (Europe allowed, blocking other regions)" -ForegroundColor Gray
    } elseif ($Profile -eq 'Germany') {
        Write-Host "Mode: Whitelist (Germany allowed, blocking other regions)" -ForegroundColor Gray
    } else {
        Write-Host "Blocked regions: $($blockedRegions -join ', ')" -ForegroundColor Gray
    }

    # Remove existing rules first
    Remove-GeofencingRules

    # Add new rules
    Add-RegionalBlockingRules -ExecutablePath $GamePath -RegionsToBlock $blockedRegions -RegionIPs $regionIPs

    Write-Host "`n✓ Geofencing configured successfully!`n" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "`n✗ Error: $_`n" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    }
    exit 1
}