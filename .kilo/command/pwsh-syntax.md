---
name: pwsh-syntax
description: Run PowerShell syntax check on scripts
pattern: "lint|syntax|pwsh|powershell"
---

```bash
pwsh -NoProfile -Command "Get-Command -Syntax .\scripts\*.ps1"
```