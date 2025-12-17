#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Call of Duty Geofencing Script - Unified Regional Blocking
.DESCRIPTION
    Blocks game server connections by geographic region using IP ranges.
    Supports multiple blocking profiles: Germany, France, Netherlands, Europe
.PARAMETER Profile
    The blocking profile to apply: Germany, GermanyFrance, GermanyNetherlands, Europe, Custom
.PARAMETER GamePath
    Path to cod.exe. Defaults to standard installation paths.
.PARAMETER Remove
    Remove existing geofencing rules instead of adding them
.EXAMPLE
    .\geofencing.ps1 -Profile Germany
.EXAMPLE
    .\geofencing.ps1 -Profile Europe -GamePath "D:\Call of Duty\_retail_\cod.exe"
.EXAMPLE
    .\geofencing.ps1 -Remove
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Germany', 'GermanyFrance', 'GermanyNetherlands', 'Europe', 'Custom')]
    [string]$Profile = 'Germany',

    [Parameter(Mandatory=$false)]
    [string]$GamePath,

    [Parameter(Mandatory=$false)]
    [switch]$Remove
)

# Error handling
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Common IP ranges blocked across all European profiles
$script:CommonEuropeanRanges = @(
    '5.0.0.0-5.255.255.255',
    '11.0.0.0-13.47.27.255',
    '13.48.28.0-13.48.255.255',
    '13.244.0.0-13.255.255.255',
    '14.0.0.0-15.255.255.255',
    '16.0.0.0-23.109.5.0',
    '23.109.5.0-24.105.29.75',
    '24.105.29.77-24.105.55.0',
    '24.105.55.1-37.244.0.0',
    '37.244.255.255-52.0.0.0',
    '53.0.0.0-67.27.0.0',
    '67.28.0.0-78.129.138.0',
    '78.129.138.1-82.145.63.254',
    '82.145.63.255-87.117.231.0',
    '87.117.231.0-94.0.0.0',
    '94.0.0.1-137.221.0.0',
    '137.223.0.0-139.255.255.255',
    '140.0.0.0-149.255.255.255',
    '150.0.0.0-185.19.216.0',
    '185.19.216.255-185.34.0.0',
    '185.80.0.0-192.168.0.0',
    '192.170.0.0-212.78.0.0',
    '212.78.0.255-255.255.255.255'
)

# Additional ranges for specific profiles
$script:ProfileRanges = @{
    Germany = @(
        '146.0.200.0',
        '173.244.0.0',
        '173.245.213.255-173.244.0.0',
        '212.39.68.0',
        '212.39.68.255-212.39.68.0'
    )

    GermanyFrance = @(
        '45.63.102.0',
        '45.63.114.255-45.63.118.0',
        '45.63.118.255-45.63.118.0',
        '92.42.110.0',
        '92.42.111.255-92.204.186.0',
        '92.204.187.255-92.204.186.0',
        '108.61.237.0',
        '108.61.237.255-134.119.100.0',
        '134.119.255.255-146.0.200.0',
        '151.106.16.0',
        '151.106.16.255-173.244.0.0',
        '173.245.213.255-185.136.0.0',
        '185.136.168.255-212.39.68.0',
        '212.39.68.255-212.39.68.0'
    )

    GermanyNetherlands = @(
        '13.49.70.0-13.49.100.255',
        '13.49.138.0-13.49.138.255',
        '13.49.140.255-13.49.255.255',
        '13.50.0.0-13.51.35.255',
        '13.51.36.0-13.100.100.100',
        '24.105.53.0',
        '24.105.53.255-24.105.55.0',
        '31.186.229.0',
        '31.186.229.255-34.120.203.0',
        '34.120.203.255-34.125.9.0',
        '34.125.9.255-37.244.0.0',
        '41.0.0.0-45.63.118.0',
        '45.63.118.255-46.23.78.0',
        '46.23.78.255-52.0.0.0',
        '64.95.100.0',
        '64.95.100.255-67.27.0.0',
        '72.26.219.0',
        '72.26.219.255-72.251.246.22',
        '72.251.246.255-78.129.138.0',
        '85.195.79.0',
        '85.195.120.255-107.6.136.0',
        '107.6.255.255-142.91.15.0',
        '142.91.15.255-146.0.200.0',
        '148.0.0.0',
        '172.255.15.0',
        '172.255.15.255-173.244.0.0',
        '173.245.213.255-198.20.103.0',
        '198.20.103.255-206.191.156.0',
        '206.191.156.255-212.39.68.0',
        '212.39.68.255-212.39.68.0'
    )

    Europe = @(
        '24.105.53.0',
        '24.105.54.255-24.105.55.0',
        '34.120.203.0',
        '34.120.203.255-34.125.9.0',
        '34.125.9.255-37.244.28.0',
        '37.244.54.255-64.95.100.0',
        '64.95.100.255-85.195.79.0',
        '92.204.187.0',
        '92.204.187.255-108.61.97.0',
        '108.61.97.255-109.169.66.0',
        '109.169.66.255-147.255.255.255',
        '148.0.0.0',
        '172.255.9.0',
        '172.255.9.255-185.19.218.255',
        '198.20.103.0',
        '198.20.103.255-198.20.114.0',
        '198.20.114.255-212.39.68.0'
    )
}

function Find-CodExecutable {
    <#
    .SYNOPSIS
        Locates the Call of Duty executable
    #>
    [CmdletBinding()]
    param()

    $possiblePaths = @(
        "${env:ProgramFiles(x86)}\Call of Duty\_retail_\cod.exe",
        "${env:ProgramFiles}\Call of Duty\_retail_\cod.exe",
        "D:\Call of Duty\_retail_\cod.exe",
        "C:\Call of Duty\_retail_\cod.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Verbose "Found cod.exe at: $path"
            return $path
        }
    }

    return $null
}

function Get-IPRanges {
    <#
    .SYNOPSIS
        Gets IP ranges for the specified profile
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProfileName
    )

    $ranges = [System.Collections.ArrayList]::new($script:CommonEuropeanRanges)

    if ($script:ProfileRanges.ContainsKey($ProfileName)) {
        $ranges.AddRange($script:ProfileRanges[$ProfileName])
    }

    return ($ranges -join ',')
}

function Remove-GeofencingRules {
    <#
    .SYNOPSIS
        Removes all Call of Duty geofencing firewall rules
    #>
    [CmdletBinding()]
    param()

    Write-Host "Removing existing geofencing rules..." -ForegroundColor Yellow

    $rules = Get-NetFirewallRule -DisplayName "Cod GeoFilter*" -ErrorAction SilentlyContinue

    if ($rules) {
        $rules | Remove-NetFirewallRule
        Write-Host "Removed $($rules.Count) geofencing rule(s)" -ForegroundColor Green
    } else {
        Write-Host "No existing geofencing rules found" -ForegroundColor Gray
    }
}

function Add-GeofencingRule {
    <#
    .SYNOPSIS
        Adds a geofencing firewall rule
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RuleName,

        [Parameter(Mandatory=$true)]
        [string]$ExecutablePath,

        [Parameter(Mandatory=$true)]
        [string]$IPRanges
    )

    try {
        New-NetFirewallRule `
            -DisplayName $RuleName `
            -Direction Outbound `
            -Protocol UDP `
            -Action Block `
            -Program $ExecutablePath `
            -RemoteAddress $IPRanges `
            -ErrorAction Stop | Out-Null

        Write-Host "Created rule: $RuleName" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create rule '$RuleName': $_"
        throw
    }
}

# Main execution
try {
    Write-Host "`n=== Call of Duty Geofencing Configuration ===" -ForegroundColor Cyan

    # Handle removal mode
    if ($Remove) {
        Remove-GeofencingRules
        Write-Host "`nGeofencing rules removed successfully!`n" -ForegroundColor Green
        exit 0
    }

    # Validate and locate game executable
    if (-not $GamePath) {
        Write-Host "Searching for Call of Duty executable..." -ForegroundColor Yellow
        $GamePath = Find-CodExecutable

        if (-not $GamePath) {
            Write-Error @"
Could not locate cod.exe automatically. Please specify the path using -GamePath parameter.
Example: .\geofencing.ps1 -Profile Germany -GamePath "D:\Call of Duty\_retail_\cod.exe"
"@
            exit 1
        }
    }

    if (-not (Test-Path $GamePath)) {
        Write-Error "Game executable not found at: $GamePath"
        exit 1
    }

    Write-Host "Using executable: $GamePath" -ForegroundColor Gray
    Write-Host "Applying profile: $Profile" -ForegroundColor Gray

    # Remove existing rules first
    Remove-GeofencingRules

    # Get IP ranges for profile
    $ipRanges = Get-IPRanges -ProfileName $Profile

    if (-not $ipRanges) {
        Write-Error "No IP ranges defined for profile: $Profile"
        exit 1
    }

    # Add new rule
    $ruleName = "Cod GeoFilter $Profile"
    Add-GeofencingRule -RuleName $ruleName -ExecutablePath $GamePath -IPRanges $ipRanges

    Write-Host "`nGeofencing configured successfully!" -ForegroundColor Green
    Write-Host "Profile: $Profile" -ForegroundColor Gray
    Write-Host "Blocked IP ranges: $($ipRanges.Split(',').Count)" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "`nError: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
