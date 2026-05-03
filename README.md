# Call of Duty: Black Ops 6 - Firewall & Geoblocking Scripts

![GitHub Downloads](https://img.shields.io/github/downloads/Ven0m0/Firewall/total?logo=github&label=GitHub%20Downloads)![Commit activity](https://img.shields.io/github/last-commit/Ven0m0/Firewall?logo=github)

## Overview

This repository contains Windows firewall scripts for implementing geoblocking and network routing control for Call of Duty: Black Ops 6. These scripts allow you to control which game server regions you connect to by blocking or allowing specific IP ranges.

**Note:** These scripts replicate the functionality of GeoFilter features found in gaming routers or paid applications, but are completely free and open-source.

## Recent Updates

**Version 4.0 - Unified Geofencing**
- **Merged ip-blocking.ps1 into geofencing.ps1** - Single unified script
- **Parsable IP configuration** - IP addresses in `game-servers.txt`, not hardcoded
- **Europe whitelist by default** - User in Germany gets European servers
- **Battle.net detection** - Supports both Battle.net and Steam installations
- **System variables** - Uses `ProgramFiles(x86)` for portable paths

**Version 3.0 - Full PowerShell Modernization**
- **Eliminated ALL legacy batch scripts** - Everything is now modern PowerShell
- **Created shared utilities module** (`FirewallUtils.psm1`) - Zero code duplication
- **Unified PowerShell architecture** - Consistent error handling and validation across all scripts
- **Enhanced parameter support** - More flexible configuration options
- **Better user experience** - Colored output, improved error messages, progress feedback
- **Maintained backward compatibility** - Legacy batch scripts moved to `legacy/` folder for reference

**Version 2.0 - Refactored & Optimized**
- Consolidated duplicate code across multiple files
- Added PowerShell script with parameterized region profiles
- Improved error handling and validation
- Auto-detection of game installation path
- Added remove/cleanup functionality
- Centralized rule definitions so add/remove paths stay in sync

## Features

- **100% Modern PowerShell**: All scripts use PowerShell 5.1+ with advanced features
- **Shared Utilities Module**: Common functions eliminate code duplication
- **Unified Geofencing**: Single PowerShell script with multiple region profiles
- **IP Blocking**: Block individual server IPs by country/region
- **Port Configuration**: Allow required game ports through Windows Firewall
- **DNS Routing Control**: NextDNS server routing management
- **Auto-Detection**: Automatically locates game and service installations
- **Robust Error Handling**: Comprehensive validation and informative error messages
- **Easy Cleanup**: Simple removal of all firewall rules with `-Action Remove`
- **Flexible Configuration**: Parameter-based configuration, no manual file editing

## Repository Structure

```
Firewall/
├── scripts/                           # Modern PowerShell scripts (v4.0)
│   ├── firewall-utils.psm1           # Shared utilities module
│   ├── geofencing.ps1                # Unified regional blocking (merges ip-blocking)
│   ├── game-servers.txt              # Parsable IP configuration by region
│   ├── port-configuration.ps1        # Port allowlist configuration
│   └── dns-routing.ps1               # NextDNS routing control
├── legacy/                            # Deprecated batch scripts (reference only)
│   ├── specific-ip-blocking.cmd      # Old batch script
│   ├── firewall-ports.cmd            # Old batch script
│   ├── nextdns-routing.cmd           # Old batch script
│   ├── Bo6 GeoFencing.cmd            # Original monolithic script
│   └── Geofencing/                   # Old separate region files
└── README.md
```

> **Note**: `ip-blocking.ps1` has been merged into `geofencing.ps1`. Use `-Profile Europe` (default) to whitelist Europe.

## Quick Start

### Prerequisites

- Windows 10/11
- PowerShell 5.1 or higher (for `.ps1` scripts)
- Administrator privileges
- Call of Duty: Black Ops 6 installed

## Usage

### 1. Regional Geofencing (geofencing.ps1)

Block entire regions using IP range profiles. Reads IP addresses from `game-servers.txt`.

**Add geofencing rules:**
```powershell
# Whitelist Europe (blocks non-European servers) - DEFAULT
.\scripts\geofencing.ps1 -Profile Europe

# Whitelist Germany (allows German servers, blocks others)
.\scripts\geofencing.ps1 -Profile Germany

# Custom blocking - specify regions to block
.\scripts\geofencing.ps1 -Profile Custom -BlockRegions @('UK', 'France')

# Auto-detect game path
.\scripts\geofencing.ps1 -Profile Europe

# Specify custom game path
.\scripts\geofencing.ps1 -Profile Europe -GamePath "C:\Program Files (x86)\Steam\steamapps\common\Call of Duty HQ\cod24\cod24-cod.exe"
```

**Remove all geofencing rules:**
```powershell
.\scripts\geofencing.ps1 -Remove
```

> **Note**: Europe is whitelisted by default since the user is in Germany. The script will automatically detect Battle.net (`C:\Program Files (x86)\Call of Duty`) or Steam (`C:\Program Files (x86)\Steam\steamapps\common\Call of Duty HQ`) installations.

### 3. Port Configuration (port-configuration.ps1)

Allow required game ports through Windows Firewall.

**Add port rules:**
```powershell
.\scripts\port-configuration.ps1 -Action Add
```

**Remove port rules:**
```powershell
.\scripts\port-configuration.ps1 -Action Remove
```

**Custom ports:**
```powershell
.\scripts\port-configuration.ps1 -Action Add -TCPPorts "3074,3075" -UDPPorts "3074"
```

**Default ports configured:**
- **TCP**: 3074, 3075, 27015-27030, 27036-27037
- **UDP**: 3074, 4380, 27000-27036

### 4. NextDNS Routing Control (dns-routing.ps1)

Block specific NextDNS servers to control DNS routing.

**Block European servers:**
```powershell
.\scripts\dns-routing.ps1 -Action Add -Profile BlockEU
```

**Block US servers:**
```powershell
.\scripts\dns-routing.ps1 -Action Add -Profile BlockUS
```

**Block all servers:**
```powershell
.\scripts\dns-routing.ps1 -Action Add -Profile BlockAll
```

**Remove all DNS routing rules:**
```powershell
.\scripts\dns-routing.ps1 -Action Remove
```

## Available Blocking Profiles

| Profile | Description | Behavior |
|---------|-------------|----------|
| `Europe` | Whitelist Europe | Blocks non-European servers, allows European ones (DEFAULT) |
| `Germany` | Whitelist Germany | Blocks non-German servers, allows German ones |
| `Custom` | Custom regions | Use `-BlockRegions` to specify which to block |

### Available Regions (for Custom profile)

| Region | Description |
|--------|-------------|
| `UK` | United Kingdom |
| `France` | France |
| `Netherlands` | Netherlands |
| `Poland` | Poland |
| `Switzerland` | Switzerland |
| `Luxembourg` | Luxembourg |
| `Germany` | Germany |

> **Note**: IP addresses are loaded from `game-servers.txt` - no hardcoded IPs in scripts!

## How It Works

These scripts use Windows Firewall to create outbound blocking rules that prevent your game from connecting to specific IP addresses or ranges. This effectively controls which regional servers you can connect to.

### Modern PowerShell Features

1. **Auto-Detection**: Automatically searches common installation paths for executables
2. **Shared Utilities Module**: Eliminates code duplication across all scripts
3. **Parameterized Configuration**: All options configurable via command-line parameters
4. **Advanced Error Handling**: Comprehensive validation, permission checks, detailed error messages
5. **Clean Removal**: Remove all rules with single `-Action Remove` or `-Remove` command
6. **Colored Output**: Visual feedback with success (green), warnings (yellow), errors (red)
7. **Progress Reporting**: Summary of successful/failed operations
8. **Consistent API**: All scripts follow the same parameter patterns and conventions

## Configuration

All scripts support parameter-based configuration - IP addresses are loaded from `game-servers.txt`!

### geofencing.ps1 Parameters

```powershell
.\scripts\geofencing.ps1 [-Profile <String>] [-GamePath <String>] [-BlockRegions <String[]>] [-Remove]
```

- `-Profile`: Region profile (Europe, Germany, Custom) - default: Europe
- `-GamePath`: Custom path to cod24-cod.exe (optional, auto-detected)
- `-BlockRegions`: Array of regions to block (for Custom profile): UK, France, Netherlands, Poland, Switzerland, Luxembourg, Germany
- `-Remove`: Remove all geofencing rules

**Auto-detected Installation Paths:**
- **Battle.net**: `C:\Program Files (x86)\Call of Duty`
- **Steam**: `C:\Program Files (x86)\Steam\steamapps\common\Call of Duty HQ\cod24\cod24-cod.exe`

### port-configuration.ps1 Parameters

```powershell
.\scripts\port-configuration.ps1 [[-Action] <String>] [[-TCPPorts] <String>] [[-UDPPorts] <String>]
```

- `-Action`: Add or Remove (default: Add)
- `-TCPPorts`: Custom TCP ports (default: 3074,3075,27015-27030,27036-27037)
- `-UDPPorts`: Custom UDP ports (default: 3074,4380,27000-27036)

### dns-routing.ps1 Parameters

```powershell
.\scripts\dns-routing.ps1 [[-Action] <String>] [[-Profile] <String>] [[-NextDNSPath] <String>]
```

- `-Action`: Add or Remove (default: Add)
- `-Profile`: BlockEU, BlockUS, or BlockAll (default: BlockEU)
- `-NextDNSPath`: Custom path to NextDNSService.exe (optional, auto-detected)

## Troubleshooting

### Script won't run
- Right-click script → "Run as Administrator"
- For PowerShell scripts, you may need to allow execution:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### Game path not found
- Specify the path manually:
  ```powershell
  .\scripts\geofencing.ps1 -Profile Germany -GamePath "C:\Your\Custom\Path\_retail_\cod.exe"
  ```

### Rules not working
- Verify rules are created: `netsh advfirewall firewall show rule name=all`
- Check Windows Firewall is enabled
- Ensure no VPN/proxy is interfering

### Remove all rules
```powershell
# Regional geofencing rules
.\scripts\geofencing.ps1 -Remove

# IP blocking rules
.\scripts\ip-blocking.ps1 -Action Remove

# Port rules
.\scripts\port-configuration.ps1 -Action Remove

# DNS routing rules
.\scripts\dns-routing.ps1 -Action Remove
```

## Migration from Legacy Scripts

### v2.0 → v3.0 Migration

If you're using the old batch scripts, update to the new PowerShell versions:

**Old (v2.0 Batch):**
```batch
scripts\specific-ip-blocking.cmd add
scripts\firewall-ports.cmd add
scripts\nextdns-routing.cmd add block-eu
```

**New (v3.0 PowerShell):**
```powershell
.\scripts\ip-blocking.ps1 -Action Add
.\scripts\port-configuration.ps1 -Action Add
.\scripts\dns-routing.ps1 -Action Add -Profile BlockEU
```

### v1.0 → v3.0 Migration

If you're using the original scripts:

**Old (v1.0):**
```batch
# Multiple separate .txt files
Cod Geoblock Germany.txt
Cod Geoblock Germany & France.txt
```

**New (v3.0):**
```powershell
# Single unified script
.\scripts\geofencing.ps1 -Profile Germany
.\scripts\geofencing.ps1 -Profile GermanyFrance
```

## Changelog

### v3.0.0 - Full PowerShell Modernization (2024)
- **100% PowerShell**: Converted all batch scripts to modern PowerShell
- **Shared utilities module**: Created `FirewallUtils.psm1` for zero code duplication
- **New scripts**: Added `ip-blocking.ps1`, `port-configuration.ps1`, `dns-routing.ps1`
- **Enhanced features**: Parameter-based configuration, colored output, progress reporting
- **Improved error handling**: Consistent validation and error messages across all scripts
- **Better UX**: Visual feedback with colored output (green/yellow/red)
- **Backward compatibility**: Legacy batch scripts moved to `legacy/` folder

### v2.0.0 - Refactored Release (2024)
- **Eliminated duplicate code**: Reduced codebase by ~80%
- **Unified PowerShell script**: Single `geofencing.ps1` replaces 4 separate files
- **Auto-detection**: Finds game installation automatically
- **Better error handling**: Comprehensive validation and error messages
- **Cleanup support**: Easy removal of all firewall rules
- **Improved documentation**: Comprehensive usage examples

### v1.0.0 - Initial Release (2024)
- Basic geofencing batch scripts
- Individual PowerShell blocking files per region
- Manual path configuration required

## Resources

- [Free SBMM Disabler Tool](https://cyanlabs.net/free-multi-sbmm-disabler/)

## Warning

⚠️ **Important Notes:**
- Always run scripts as Administrator
- Backup your firewall rules before making changes
- These scripts modify Windows Firewall settings
- Use at your own discretion - may affect matchmaking times
- Some configurations may violate game Terms of Service

## Contributing

Feel free to submit issues or pull requests to improve these scripts or add support for additional regions.

## License

This project is provided as-is for educational purposes.
