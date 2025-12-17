# Call of Duty: Black Ops 6 - Firewall & Geoblocking Scripts

![GitHub Downloads](https://img.shields.io/github/downloads/Ven0m0/Firewall/total?logo=github&label=GitHub%20Downloads)
![Commit activity](https://img.shields.io/github/last-commit/Ven0m0/Firewall?logo=github)

## Overview

This repository contains Windows firewall scripts for implementing geoblocking and network routing control for Call of Duty: Black Ops 6. These scripts allow you to control which game server regions you connect to by blocking or allowing specific IP ranges.

**Note:** These scripts replicate the functionality of GeoFilter features found in gaming routers or paid applications, but are completely free and open-source.

## Recent Updates

**Version 2.0 - Refactored & Optimized**
- Consolidated duplicate code across multiple files
- Added PowerShell script with parameterized region profiles
- Improved error handling and validation
- Auto-detection of game installation path
- Added remove/cleanup functionality
- Centralized rule definitions so add/remove paths stay in sync
- Better documentation and usage examples

## Features

- **Unified Geofencing Script**: Single PowerShell script with multiple region profiles
- **Specific IP Blocking**: Batch script for blocking individual server IPs by country
- **Firewall Port Configuration**: Allow required game ports through Windows Firewall
- **Auto-Detection**: Automatically locates Call of Duty installation
- **Error Handling**: Robust validation and informative error messages
- **Easy Cleanup**: Simple removal of all firewall rules

## Repository Structure

```
Firewall/
├── scripts/                           # Refactored scripts (recommended)
│   ├── geofencing.ps1                # Unified PowerShell geofencing script
│   ├── specific-ip-blocking.cmd      # Batch script for specific IPs
│   └── firewall-ports.cmd            # Port configuration script
├── legacy/                            # Original scripts (deprecated)
│   ├── Bo6 GeoFencing.cmd
│   └── Geofencing/
└── README.md
```

## Quick Start

### Prerequisites

- Windows 10/11
- PowerShell 5.1 or higher (for `.ps1` scripts)
- Administrator privileges
- Call of Duty: Black Ops 6 installed

## Usage

### Recommended: Unified PowerShell Geofencing

The new unified script consolidates all regional blocking into a single, parameterized PowerShell script.

**Add geofencing rules:**
```powershell
# Block Germany only
.\scripts\geofencing.ps1 -Profile Germany

# Block Germany and France
.\scripts\geofencing.ps1 -Profile GermanyFrance

# Block Germany and Netherlands
.\scripts\geofencing.ps1 -Profile GermanyNetherlands

# Block all European servers
.\scripts\geofencing.ps1 -Profile Europe

# Custom game path
.\scripts\geofencing.ps1 -Profile Germany -GamePath "D:\Call of Duty\_retail_\cod.exe"
```

**Remove all geofencing rules:**
```powershell
.\scripts\geofencing.ps1 -Remove
```

### Alternative: Specific IP Blocking (Batch)

For blocking individual server IPs by country (UK, France, Netherlands, etc.).

**Add blocking rules:**
```batch
scripts\specific-ip-blocking.cmd add
```

**Remove blocking rules:**
```batch
scripts\specific-ip-blocking.cmd remove
```

### Port Configuration

Allow required game ports through Windows Firewall.

**Add port rules:**
```batch
scripts\firewall-ports.cmd add
```

**Remove port rules:**
```batch
scripts\firewall-ports.cmd remove
```

**Ports configured:**
- **TCP**: 3074, 3075, 27015-27030, 27036-27037
- **UDP**: 3074, 4380, 27000-27036

## Available Blocking Profiles

| Profile | Description | IP Ranges |
|---------|-------------|-----------|
| `Germany` | Blocks German servers only | Common EU + Germany-specific |
| `GermanyFrance` | Blocks German and French servers | Common EU + Germany + France |
| `GermanyNetherlands` | Blocks German and Dutch servers | Common EU + Germany + Netherlands |
| `Europe` | Blocks all major European servers | Comprehensive European ranges |

## How It Works

These scripts use Windows Firewall to create outbound blocking rules that prevent your game from connecting to specific IP addresses or ranges. This effectively controls which regional servers you can connect to.

### PowerShell Script Features

1. **Auto-Detection**: Searches common installation paths for `cod.exe`
2. **Parameterized Profiles**: Select blocking profile via command-line parameter
3. **IP Range Deduplication**: Common European ranges shared across profiles
4. **Error Handling**: Validates paths, checks permissions, reports failures
5. **Clean Removal**: Remove all rules with single command

### Batch Script Features

1. **Admin Check**: Validates administrator privileges before execution
2. **Path Auto-Detection**: Searches multiple common installation locations
3. **Error Reporting**: Reports success/failure for each rule
4. **Bidirectional**: Both add and remove functionality

## Configuration

### PowerShell Script

The PowerShell script accepts several parameters:

```powershell
.\scripts\geofencing.ps1 [[-Profile] <String>] [[-GamePath] <String>] [-Remove]
```

- `-Profile`: Region profile to apply (Germany, GermanyFrance, GermanyNetherlands, Europe)
- `-GamePath`: Custom path to cod.exe (optional, auto-detected by default)
- `-Remove`: Remove all geofencing rules instead of adding

### Batch Scripts

Edit variables at the top of each `.cmd` file to customize:

**specific-ip-blocking.cmd:**
```batch
set "UK_IPS=45.77.230.226,82.163.76.0/24,..."
set "FRANCE_IPS=78.138.107.0/24,95.179.208.205,..."
```

**firewall-ports.cmd:**
```batch
set "TCP_PORTS=3074,3075,27015-27030,27036-27037"
set "UDP_PORTS=3074,4380,27000-27036"
```

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
# PowerShell geofencing rules
.\scripts\geofencing.ps1 -Remove

# Batch IP blocking rules
.\scripts\specific-ip-blocking.cmd remove

# Port rules
.\scripts\firewall-ports.cmd remove
```

## Migration from Legacy Scripts

If you're using the old scripts, here's how to migrate:

**Old:**
```batch
# Multiple separate .txt files with duplicated IP ranges
Cod Geoblock Germany.txt
Cod Geoblock Germany & France.txt
Cod Geoblock Germany & Netherlands.txt
Cod Geoblock Europe.txt
```

**New:**
```powershell
# Single script with profile parameter
.\scripts\geofencing.ps1 -Profile Germany
.\scripts\geofencing.ps1 -Profile GermanyFrance
.\scripts\geofencing.ps1 -Profile GermanyNetherlands
.\scripts\geofencing.ps1 -Profile Europe
```

## Changelog

### v2.0.0 - Refactored Release
- **Eliminated duplicate code**: Reduced codebase by ~80%
- **Unified PowerShell script**: Single script replaces 4 separate files
- **Auto-detection**: Finds game installation automatically
- **Better error handling**: Comprehensive validation and error messages
- **Cleanup support**: Easy removal of all firewall rules
- **Improved documentation**: Comprehensive usage examples

### v1.0.0 - Initial Release
- Basic geofencing batch scripts
- Individual PowerShell blocking files per region

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
