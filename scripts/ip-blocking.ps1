#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Black Ops 6 Specific IP Blocking Script
.DESCRIPTION
    Blocks specific game server IPs by country/region using Windows Firewall.
    Modernized PowerShell version replacing specific-ip-blocking.cmd
.PARAMETER Action
    Action to perform: Add or Remove firewall rules
.PARAMETER GamePath
    Path to cod.exe. Auto-detected if not specified.
.PARAMETER EnabledRegions
    Array of regions to enable. Default: UK, France, Luxembourg
.EXAMPLE
    .\ip-blocking.ps1 -Action Add
.EXAMPLE
    .\ip-blocking.ps1 -Action Remove
.EXAMPLE
    .\ip-blocking.ps1 -Action Add -EnabledRegions @('UK', 'France')
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Add', 'Remove')]
    [string]$Action = 'Add',

    [Parameter(Mandatory=$false)]
    [string]$GamePath,

    [Parameter(Mandatory=$false)]
    [ValidateSet('UK', 'France', 'Netherlands', 'Poland', 'Switzerland', 'Luxembourg')]
    [string[]]$EnabledRegions = @('UK', 'France', 'Luxembourg')
)

# Import common utilities
$modulePath = Join-Path $PSScriptRoot 'FirewallUtils.psm1'
Import-Module $modulePath -Force

# Error handling
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# IP address definitions by region
$script:RegionIPs = @{
    UK = @(
        '45.77.230.226',
        '82.163.76.0/24',
        '104.238.185.20',
        '108.61.176.176',
        '108.61.197.57',
        '136.244.77.155',
        '192.248.165.136'
    )

    France = @(
        '78.138.107.0/24',
        '95.179.208.205',
        '95.179.209.45',
        '95.179.211.94',
        '95.179.217.175',
        '92.204.171.249',
        '107.191.47.125',
        '108.61.176.0/24',
        '108.61.208.220',
        '136.244.113.145',
        '136.244.115.128',
        '136.244.116.63',
        '199.247.11.0/24',
        '217.69.2.42',
        '217.69.9.243',
        '217.69.14.30',
        '217.69.13.167'
    )

    Netherlands = @(
        '23.109.68.36',
        '23.109.163.4',
        '23.109.254.244',
        '46.23.78.91',
        '78.141.209.67',
        '78.141.215.99',
        '95.179.146.133',
        '95.179.154.240',
        '95.179.184.89',
        '136.244.96.14',
        '136.244.97.236',
        '136.244.108.228',
        '172.255.106.100',
        '188.42.241.20',
        '188.42.243.236',
        '199.247.25.77'
    )

    Poland = @(
        '64.176.67.115',
        '64.176.65.32',
        '64.176.64.244'
    )

    Switzerland = @(
        '35.216.207.127'
    )

    Luxembourg = @(
        '188.42.190.196'
    )
}

function Add-RegionBlockingRules {
    <#
    .SYNOPSIS
        Adds blocking rules for enabled regions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExecutablePath,

        [Parameter(Mandatory=$true)]
        [string[]]$Regions
    )

    Write-Host "`nAdding geofencing rules..." -ForegroundColor Cyan

    $successCount = 0
    $failCount = 0

    foreach ($region in $script:RegionIPs.Keys) {
        $enabled = $Regions -contains $region
        $ruleName = "Bo6 Block $region"
        $ips = $script:RegionIPs[$region] -join ','

        $statusText = if ($enabled) { "ENABLED" } else { "DISABLED" }
        Write-Host "`n[$statusText] $region" -ForegroundColor $(if ($enabled) { 'Yellow' } else { 'Gray' })

        $result = Add-FirewallRule `
            -RuleName $ruleName `
            -Direction Outbound `
            -Protocol UDP `
            -Action Block `
            -Program $ExecutablePath `
            -RemoteAddress $ips `
            -Description "Block $region game servers for Call of Duty" `
            -Enabled $enabled

        if ($result) {
            $successCount++
        } else {
            $failCount++
        }
    }

    Write-Host "`n" -NoNewline
    Write-Host "Summary: " -ForegroundColor Cyan -NoNewline
    Write-Host "$successCount succeeded, $failCount failed" -ForegroundColor $(if ($failCount -eq 0) { 'Green' } else { 'Yellow' })
}

function Remove-RegionBlockingRules {
    <#
    .SYNOPSIS
        Removes all region blocking rules
    #>
    [CmdletBinding()]
    param()

    Write-Host "`nRemoving geofencing rules..." -ForegroundColor Cyan

    $totalRemoved = Remove-FirewallRulesByPattern -Pattern "Bo6 Block*"

    if ($totalRemoved -gt 0) {
        Write-Host "`nSuccessfully removed $totalRemoved rule(s)" -ForegroundColor Green
    } else {
        Write-Host "`nNo rules to remove" -ForegroundColor Gray
    }
}

# Main execution
try {
    Write-Host "`n=== Black Ops 6 IP Blocking Configuration ===" -ForegroundColor Cyan

    # Verify administrator privileges
    Assert-AdministratorRole

    if ($Action -eq 'Remove') {
        Remove-RegionBlockingRules
    }
    else {
        # Validate and locate game executable
        if (-not $GamePath) {
            Write-Host "`nSearching for Call of Duty executable..." -ForegroundColor Yellow
            $GamePath = Find-CodExecutable

            if (-not $GamePath) {
                throw @"
Could not locate cod.exe automatically. Please specify the path using -GamePath parameter.
Example: .\ip-blocking.ps1 -Action Add -GamePath "D:\Call of Duty\_retail_\cod.exe"
"@
            }
        }

        if (-not (Test-Path $GamePath)) {
            throw "Game executable not found at: $GamePath"
        }

        Write-Host "Using executable: $GamePath" -ForegroundColor Gray
        Write-Host "Enabled regions: $($EnabledRegions -join ', ')" -ForegroundColor Gray

        Add-RegionBlockingRules -ExecutablePath $GamePath -Regions $EnabledRegions
    }

    Write-Host "`n✓ Operation completed successfully!`n" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "`n✗ Error: $_`n" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Verbose "Stack trace: $($_.ScriptStackTrace)"
    }
    exit 1
}
