#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Common utilities for Call of Duty firewall management scripts
.DESCRIPTION
    Shared functions for geofencing, port configuration, and DNS routing
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Path Detection

function Find-CodExecutable {
    <#
    .SYNOPSIS
        Locates the Call of Duty executable
    .OUTPUTS
        String path to cod.exe or $null if not found
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $possiblePaths = @(
        "${env:ProgramFiles(x86)}\Call of Duty\_retail_\cod.exe",
        "${env:ProgramFiles}\Call of Duty\_retail_\cod.exe",
        "D:\Call of Duty\_retail_\cod.exe",
        "E:\Call of Duty\_retail_\cod.exe",
        "C:\Call of Duty\_retail_\cod.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Verbose "Found cod.exe at: $path"
            return $path
        }
    }

    Write-Warning "Could not auto-detect Call of Duty installation"
    return $null
}

function Find-NextDNSExecutable {
    <#
    .SYNOPSIS
        Locates the NextDNS executable
    .OUTPUTS
        String path to NextDNSService.exe or $null if not found
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $possiblePaths = @(
        "${env:ProgramFiles(x86)}\NextDNS\NextDNSService.exe",
        "${env:ProgramFiles}\NextDNS\NextDNSService.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Verbose "Found NextDNSService.exe at: $path"
            return $path
        }
    }

    Write-Warning "Could not auto-detect NextDNS installation"
    return $null
}

#endregion

#region Firewall Rule Management

function Add-FirewallRule {
    <#
    .SYNOPSIS
        Adds a Windows Firewall rule with consistent error handling
    .PARAMETER RuleName
        Display name for the firewall rule
    .PARAMETER Direction
        Traffic direction (Inbound or Outbound)
    .PARAMETER Protocol
        Network protocol (TCP, UDP, etc.)
    .PARAMETER Action
        Firewall action (Allow or Block)
    .PARAMETER Program
        Path to the program executable
    .PARAMETER RemoteAddress
        Remote IP addresses or ranges
    .PARAMETER RemotePort
        Remote port(s)
    .PARAMETER LocalPort
        Local port(s)
    .PARAMETER Description
        Optional description for the rule
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RuleName,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Inbound', 'Outbound')]
        [string]$Direction,

        [Parameter(Mandatory=$true)]
        [ValidateSet('TCP', 'UDP', 'Any')]
        [string]$Protocol,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Allow', 'Block')]
        [string]$Action,

        [Parameter(Mandatory=$false)]
        [string]$Program,

        [Parameter(Mandatory=$false)]
        [string]$RemoteAddress,

        [Parameter(Mandatory=$false)]
        [string]$RemotePort,

        [Parameter(Mandatory=$false)]
        [string]$LocalPort,

        [Parameter(Mandatory=$false)]
        [string]$Description,

        [Parameter(Mandatory=$false)]
        [bool]$Enabled = $true
    )

    try {
        $params = @{
            DisplayName = $RuleName
            Direction = $Direction
            Protocol = $Protocol
            Action = $Action
            Enabled = if ($Enabled) { 'True' } else { 'False' }
            ErrorAction = 'Stop'
        }

        if ($Program) { $params['Program'] = $Program }
        if ($RemoteAddress) { $params['RemoteAddress'] = $RemoteAddress }
        if ($RemotePort) { $params['RemotePort'] = $RemotePort }
        if ($LocalPort) { $params['LocalPort'] = $LocalPort }
        if ($Description) { $params['Description'] = $Description }

        New-NetFirewallRule @params | Out-Null
        Write-Host "  ✓ Created rule: $RuleName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  ✗ Failed to create rule '$RuleName': $_" -ForegroundColor Red
        return $false
    }
}

function Remove-FirewallRulesByPattern {
    <#
    .SYNOPSIS
        Removes firewall rules matching a display name pattern
    .PARAMETER Pattern
        Display name pattern to match (supports wildcards)
    .OUTPUTS
        Number of rules removed
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Pattern
    )

    try {
        $rules = Get-NetFirewallRule -DisplayName $Pattern -ErrorAction SilentlyContinue

        if ($rules) {
            $count = ($rules | Measure-Object).Count
            $rules | Remove-NetFirewallRule -ErrorAction Stop
            Write-Host "  ✓ Removed $count rule(s) matching '$Pattern'" -ForegroundColor Green
            return $count
        }
        else {
            Write-Host "  ℹ No rules found matching '$Pattern'" -ForegroundColor Gray
            return 0
        }
    }
    catch {
        Write-Host "  ✗ Error removing rules: $_" -ForegroundColor Red
        return 0
    }
}

function Remove-FirewallRuleByName {
    <#
    .SYNOPSIS
        Removes a specific firewall rule by exact name
    .PARAMETER RuleName
        Exact display name of the rule to remove
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RuleName
    )

    try {
        $rule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue

        if ($rule) {
            Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction Stop
            Write-Host "  ✓ Removed rule: $RuleName" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "  ℹ Rule not found: $RuleName" -ForegroundColor Gray
            return $false
        }
    }
    catch {
        Write-Host "  ✗ Error removing rule '$RuleName': $_" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Validation

function Test-AdministratorRole {
    <#
    .SYNOPSIS
        Checks if the current session has administrator privileges
    .OUTPUTS
        Boolean indicating admin status
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-AdministratorRole {
    <#
    .SYNOPSIS
        Throws an error if not running as administrator
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-AdministratorRole)) {
        throw "This script requires administrator privileges. Please run as Administrator."
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Find-CodExecutable',
    'Find-NextDNSExecutable',
    'Add-FirewallRule',
    'Remove-FirewallRulesByPattern',
    'Remove-FirewallRuleByName',
    'Test-AdministratorRole',
    'Assert-AdministratorRole'
)
