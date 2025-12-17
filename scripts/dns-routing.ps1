#Requires -RunAsAdministrator
<#
.SYNOPSIS
    NextDNS Routing Control Script
.DESCRIPTION
    Blocks specific NextDNS servers to control DNS routing.
    Modernized PowerShell version replacing nextdns-routing.cmd
.PARAMETER Action
    Action to perform: Add or Remove firewall rules
.PARAMETER Profile
    Blocking profile: BlockEU, BlockUS, BlockAll
.PARAMETER NextDNSPath
    Path to NextDNSService.exe. Auto-detected if not specified.
.EXAMPLE
    .\dns-routing.ps1 -Action Add -Profile BlockEU
.EXAMPLE
    .\dns-routing.ps1 -Action Remove
.EXAMPLE
    .\dns-routing.ps1 -Action Add -Profile BlockAll
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Add', 'Remove')]
    [string]$Action = 'Add',

    [Parameter(Mandatory=$false)]
    [ValidateSet('BlockEU', 'BlockUS', 'BlockAll')]
    [string]$Profile = 'BlockEU',

    [Parameter(Mandatory=$false)]
    [string]$NextDNSPath
)

# Import common utilities
$modulePath = Join-Path $PSScriptRoot 'FirewallUtils.psm1'
Import-Module $modulePath -Force

# Error handling
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# NextDNS server definitions
$script:EuropeanServers = @(
    @{
        Name = 'NextDNS Block anexia-fra'
        Description = 'Block anexia-fra (anycast2, ultralow1)'
        IPv4 = '217.146.22.163'
        IPv6 = '2a00:11c0:e:ffff:1::d'
    },
    @{
        Name = 'NextDNS Block zepto-fra'
        Description = 'Block zepto-fra (ultralow2)'
        IPv4 = '194.45.101.249'
        IPv6 = '2a0b:4341:704:24:5054:ff:fe91:8a6c'
    },
    @{
        Name = 'NextDNS Block zepto-ber'
        Description = 'Block zepto-ber (anycast1)'
        IPv4 = '45.90.28.0'
        IPv6 = '2a07:a8c0::'
    },
    @{
        Name = 'NextDNS Block vultr-fra'
        Description = 'Block vultr-fra (ultralow1)'
        IPv4 = '199.247.16.158'
        IPv6 = '2a05:f480:1800:8ed:5400:2ff:fec8:7e46'
    }
)

$script:USServers = @(
    @{
        Name = 'NextDNS Block US Routing'
        Description = 'Block US routing range'
        IPv4 = '45.90.0.0-45.90.255.255'
        IPv6 = $null
    }
)

function Add-DNSBlockingRules {
    <#
    .SYNOPSIS
        Adds DNS blocking rules based on profile
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExecutablePath,

        [Parameter(Mandatory=$true)]
        [string]$BlockProfile
    )

    Write-Host "`nAdding NextDNS routing rules..." -ForegroundColor Cyan
    Write-Host "Profile: $BlockProfile" -ForegroundColor Gray
    Write-Host ""

    $successCount = 0
    $failCount = 0
    $serversToBlock = @()

    # Determine which servers to block based on profile
    switch ($BlockProfile) {
        'BlockEU' {
            $serversToBlock = $script:EuropeanServers
        }
        'BlockUS' {
            $serversToBlock = $script:USServers
        }
        'BlockAll' {
            $serversToBlock = $script:EuropeanServers + $script:USServers
        }
    }

    foreach ($server in $serversToBlock) {
        Write-Host "Processing: $($server.Name)" -ForegroundColor Yellow

        # Combine IPv4 and IPv6 addresses
        $addresses = @()
        if ($server.IPv4) { $addresses += $server.IPv4 }
        if ($server.IPv6) { $addresses += $server.IPv6 }

        $remoteAddresses = $addresses -join ','

        $result = Add-FirewallRule `
            -RuleName $server.Name `
            -Direction Outbound `
            -Protocol TCP `
            -Action Block `
            -Program $ExecutablePath `
            -RemoteAddress $remoteAddresses `
            -RemotePort '443' `
            -Description $server.Description

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

function Remove-DNSBlockingRules {
    <#
    .SYNOPSIS
        Removes all NextDNS blocking rules
    #>
    [CmdletBinding()]
    param()

    Write-Host "`nRemoving NextDNS routing rules..." -ForegroundColor Cyan
    Write-Host ""

    $totalRemoved = Remove-FirewallRulesByPattern -Pattern "NextDNS Block*"

    if ($totalRemoved -gt 0) {
        Write-Host "`nSuccessfully removed $totalRemoved rule(s)" -ForegroundColor Green
    } else {
        Write-Host "`nNo rules to remove" -ForegroundColor Gray
    }
}

function Show-ProfileInfo {
    <#
    .SYNOPSIS
        Displays available profile information
    #>
    [CmdletBinding()]
    param()

    Write-Host "`nAvailable Profiles:" -ForegroundColor Cyan
    Write-Host "  BlockEU   - Blocks European DNS servers (Frankfurt, Berlin)" -ForegroundColor Gray
    Write-Host "  BlockUS   - Blocks US routing" -ForegroundColor Gray
    Write-Host "  BlockAll  - Blocks both European and US servers" -ForegroundColor Gray
    Write-Host "`nUsage: .\dns-routing.ps1 -Action [Add|Remove] -Profile [BlockEU|BlockUS|BlockAll]" -ForegroundColor Gray
}

# Main execution
try {
    Write-Host "`n=== NextDNS Routing Control ===" -ForegroundColor Cyan

    # Verify administrator privileges
    Assert-AdministratorRole

    if ($Action -eq 'Remove') {
        Remove-DNSBlockingRules
    }
    else {
        # Validate and locate NextDNS executable
        if (-not $NextDNSPath) {
            Write-Host "`nSearching for NextDNS executable..." -ForegroundColor Yellow
            $NextDNSPath = Find-NextDNSExecutable

            if (-not $NextDNSPath) {
                throw @"
Could not locate NextDNSService.exe automatically. Please specify the path using -NextDNSPath parameter.
Example: .\dns-routing.ps1 -Action Add -Profile BlockEU -NextDNSPath "C:\Program Files\NextDNS\NextDNSService.exe"
"@
            }
        }

        if (-not (Test-Path $NextDNSPath)) {
            throw "NextDNS executable not found at: $NextDNSPath"
        }

        Write-Host "Using executable: $NextDNSPath" -ForegroundColor Gray

        Add-DNSBlockingRules -ExecutablePath $NextDNSPath -BlockProfile $Profile
    }

    Show-ProfileInfo

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
