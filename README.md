# Call of Duty: Black Ops 6 - Firewall & Geoblocking Scripts

![GitHub Downloads](https://img.shields.io/github/downloads/Ven0m0/Firewall/total?logo=github&label=GitHub%20Downloads)
![Commit activity](https://img.shields.io/github/last-commit/Ven0m0/Firewall?logo=github)

## Overview

This repository contains Windows firewall scripts for implementing geoblocking and network routing control for Call of Duty: Black Ops 6. These scripts allow you to control which game server regions you connect to by blocking or allowing specific IP ranges.

**Note:** These scripts replicate the functionality of GeoFilter features found in gaming routers or paid applications, but are completely free and open-source.

## Features

- **Geofencing by Region**: Block game servers from specific countries/regions
- **Firewall Port Configuration**: Allow required game ports through Windows Firewall
- **NextDNS Routing Control**: Block specific DNS servers to control routing
- **Organized IP Lists**: Easy-to-read IP lists organized by region

## Repository Structure

```
Firewall/
├── Bo6 GeoFencing.cmd          # Main geofencing script
├── Geofencing/
│   ├── Bo6 Firewall.cmd        # Port configuration script
│   ├── Cod Geoblock Europe.txt # Europe-wide blocking (PowerShell)
│   ├── Cod Geoblock Germany.txt
│   ├── Cod Geoblock Germany & Netherlands.txt
│   └── Cod Geoblock Germany & France.txt
├── IPs/
│   ├── Game server.txt         # Server IPs by region
│   └── Germany.txt             # German server IPs
└── Nextdns/
    ├── NextDNS Routing.cmd     # DNS routing control
    └── Nextdns.txt             # DNS server information
```

## Usage

### Prerequisites

- Windows 10/11
- Administrator privileges
- Call of Duty: Black Ops 6 installed

### Running the Scripts

1. **Right-click** on any `.cmd` file
2. Select **"Run as Administrator"**
3. Wait for the success message

### Main Scripts

#### Bo6 GeoFencing.cmd
Blocks game servers from specific regions:
- UK
- France
- Netherlands
- Luxembourg
- Poland (commented out)
- Switzerland (commented out)

#### Bo6 Firewall.cmd
Allows required game ports:
- **TCP**: 3074, 3075, 27015-27030, 27036-27037
- **UDP**: 3074, 4380, 27000-27036

#### NextDNS Routing.cmd
Controls NextDNS routing by blocking specific European DNS servers.

## Configuration

### Customizing Regions

Edit `Bo6 GeoFencing.cmd` to enable/disable specific regions:
- To **enable** a rule: Remove the `::` comment prefix
- To **disable** a rule: Add `::` before the netsh command or set `enable=no`

### Custom Game Path

If your game is installed in a different location, edit the path in line 11:
```batch
set Cod=C:\Program Files (x86)\Call of Duty
```

## How It Works

These scripts use Windows Firewall (`netsh advfirewall`) to create outbound blocking rules that prevent your game from connecting to specific IP addresses. This effectively controls which regional servers you can connect to.

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
