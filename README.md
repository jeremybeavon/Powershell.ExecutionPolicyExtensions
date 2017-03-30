# Usage

This project provides functions for running unsigned scripts when the AllSigned execution policy is enabled.

Powershell to load the module:
```powershell
New-Module -ScriptBlock ([ScriptBlock]::Create((Invoke-WebRequest -Uri https://raw.githubusercontent.com/jeremybeavon/Powershell.ExecutionPolicyExtensions/master/ExecutionPolicyExtensions.psm1))) -Name ExecutionPolicyExtensions | Out-Null
```

## Functions
Import an unsigned module:
```powershell
Import-UnsignedModule -Name .\UnsignedModule.psm1
Import-UnsignedModule -Name .\UnsignedModule.psd1
```

Run an unsigned ps1 file:
```powershell
Invoke-UnsignedPs1File .\UnsignedFile.ps1 -Parameter1 'Test'
```

## Putting it together
Batch file that can run unsigned ps1 files:
```
powershell -Command "& { New-Module -ScriptBlock ([ScriptBlock]::Create((Invoke-WebRequest -Uri https://raw.githubusercontent.com/jeremybeavon/Powershell.ExecutionPolicyExtensions/master/ExecutionPolicyExtensions.psm1))) -Name ExecutionPolicyExtensions | Out-Null;Invoke-UnsignedModule %* }"
```
