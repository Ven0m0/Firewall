---
name: pwsh-syntax
description: Run PowerShell syntax check and linting on scripts
pattern: "lint|syntax|pwsh|powershell"
---

```bash
pwsh -NoLogo -NoProfile -Command '
Set-PSRepository PSGallery -InstallationPolicy Trusted; 
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck;
Invoke-ScriptAnalyzer -Path ./scripts/*.ps1
'
```