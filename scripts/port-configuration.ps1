#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Black Ops 6 Firewall Port Configuration
.DESCRIPTION
    Configures Windows Firewall to allow required ports for Call of Duty Black Ops 6.
    Modernized PowerShell version replacing firewall-ports.cmd
.PARAMETER Action
    Action to perform: Add or Remove firewall rules
.PARAMETER TCPPorts
    Custom TCP ports (comma-separated). Default: 3074,3075,27015-27030,27036-27037
.PARAMETER UDPPorts
    Custom UDP ports (comma-separated). Default: 3074,4380,27000-27036
.EXAMPLE
    .\port-configuration.ps1 -Action Add
.EXAMPLE
    .\port-configuration.ps1 -Action Remove
.EXAMPLE
    .\port-configuration.ps1 -Action Add -TCPPorts "3074,3075" -UDPPorts "3074"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Add', 'Remove')]
    [string]$Action = 'Add',

    [Parameter(Mandatory=$false)]
    [string]$TCPPorts = '3074,3075,27015-27030,27036-27037',

    [Parameter(Mandatory=$false)]
    [string]$UDPPorts = '3074,4380,27000-27036'
)

# Import common utilities
$modulePath = Join-Path $PSScriptRoot 'FirewallUtils.psm1'
Import-Module $modulePath -Force

# Error handling
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Port rule definitions
$script:PortRules = @(
    @{
        Name = 'Bo6 TCP Outbound'
        Direction = 'Outbound'
        Protocol = 'TCP'
        PortType = 'RemotePort'
        Ports = $TCPPorts
    },
    @{
        Name = 'Bo6 TCP Inbound'
        Direction = 'Inbound'
        Protocol = 'TCP'
        PortType = 'LocalPort'
        Ports = $TCPPorts
    },
    @{
        Name = 'Bo6 UDP Outbound'
        Direction = 'Outbound'
        Protocol = 'UDP'
        PortType = 'RemotePort'
        Ports = $UDPPorts
    },
    @{
        Name = 'Bo6 UDP Inbound'
        Direction = 'Inbound'
        Protocol = 'UDP'
        PortType = 'LocalPort'
        Ports = $UDPPorts
    }
)

function Add-PortRules {
    <#
    .SYNOPSIS
        Adds all port-based firewall rules
    #>
    [CmdletBinding()]
    param()

    Write-Host "`nAdding Black Ops 6 firewall port rules..." -ForegroundColor Cyan
    Write-Host "TCP Ports: $TCPPorts" -ForegroundColor Gray
    Write-Host "UDP Ports: $UDPPorts" -ForegroundColor Gray
    Write-Host ""

    $successCount = 0
    $failCount = 0

    foreach ($rule in $script:PortRules) {
        $params = @{
            RuleName = $rule.Name
            Direction = $rule.Direction
            Protocol = $rule.Protocol
            Action = 'Allow'
            Description = "Allow $($rule.Protocol) ports for Call of Duty Black Ops 6"
        }

        # Add port parameter based on type
        if ($rule.PortType -eq 'RemotePort') {
            $params['RemotePort'] = $rule.Ports
        } else {
            $params['LocalPort'] = $rule.Ports
        }

        $result = Add-FirewallRule @params

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

function Remove-PortRules {
    <#
    .SYNOPSIS
        Removes all port-based firewall rules
    #>
    [CmdletBinding()]
    param()

    Write-Host "`nRemoving Black Ops 6 firewall port rules..." -ForegroundColor Cyan
    Write-Host ""

    $totalRemoved = 0

    foreach ($rule in $script:PortRules) {
        if (Remove-FirewallRuleByName -RuleName $rule.Name) {
            $totalRemoved++
        }
    }

    if ($totalRemoved -gt 0) {
        Write-Host "`nSuccessfully removed $totalRemoved rule(s)" -ForegroundColor Green
    } else {
        Write-Host "`nNo rules to remove" -ForegroundColor Gray
    }
}

# Main execution
try {
    Write-Host "`n=== Black Ops 6 Port Configuration ===" -ForegroundColor Cyan

    # Verify administrator privileges
    Assert-AdministratorRole

    if ($Action -eq 'Remove') {
        Remove-PortRules
    }
    else {
        Add-PortRules
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
