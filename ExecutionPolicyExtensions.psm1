$ampersandOperator = [System.Management.Automation.Language.TokenKind]::Ampersand
$dotOperator = [System.Management.Automation.Language.TokenKind]::Dot

function Import-UnsignedModule
{
	[CmdletBinding()]
	param(
		[Parameter(ParameterSetName = "Name", Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[Parameter(ParameterSetName = "PSSession", Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[Parameter(ParameterSetName = "CimSession", Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[string[]]
		$Name,
		
		[ValidateNotNull]
		[string[]]
		$Alias,
		
		[Alias("Args")]
		[object[]]
		$ArgumentList,
		
		[switch]
		$AsCustomObject,
		
		[Parameter(ParameterSetName = "Assembly", Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[System.Reflection.Assembly[]]
		$Assembly,
		
		[Parameter(ParameterSetName = "CimSession", Mandatory = $false)]
		[ValidateNotNullOrEmpty]
		[string]
		$CimNamespace,
		
		[Parameter(ParameterSetName = "CimSession", Mandatory = $false)]
		[ValidateNotNull]
		[Uri]
		$CimResourceUri,
		
		[Parameter(ParameterSetName = "CimSession", Mandatory = $true)]
		[ValidateNotNull]
		[Microsoft.Management.Infrastructure.CimSession]
		$CimSession,
		
		[ValidateNotNull]
		[string[]]
		$Cmdlet,
		
		[switch]
		$DisableNameChecking,
		
		[switch]
		$Force,
		
		[Parameter(ParameterSetName = "FullyQualifiedName", Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[Microsoft.PowerShell.Commands.ModuleSpecification[]]
		$FullyQualifiedName,
		
		[ValidateNotNull]
		[string[]]
		$Function,
		
		[switch]
		$Global,
		
		[Parameter(ParameterSetName = "Name")]
		[Parameter(ParameterSetName = "PSSession")]
		[Parameter(ParameterSetName = "CimSession")]
		[string]
		$MaximumVersion,
		
		[Parameter(ParameterSetName = "Name")]
		[Parameter(ParameterSetName = "PSSession")]
		[Parameter(ParameterSetName = "CimSession")]
		[Alias("Version")]
		[Version]
		$MinimumVersion,
		
		[Parameter(ParameterSetName = "ModuleInfo", Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[System.Management.Automation.PSModuleInfo[]]
		$ModuleInfo,
		
		[Alias("NoOverwrite")]
		[switch]
		$NoClobber,
		
		[switch]
		$PassThru,
		
		[ValidateNotNull]
		[string]
		$Prefix,
		
		[Parameter(ParameterSetName = "PSSession", Mandatory = $true)]
		[Parameter(ParameterSetName = "FullyQualifiedNameAndPSSession", Mandatory = $true)]
		[ValidateNotNull]
		[System.Management.Automation.Runspaces.PSSession]
		$PSSession,
		
		[Parameter(ParameterSetName = "Name")]
		[Parameter(ParameterSetName = "PSSession")]
		[Parameter(ParameterSetName = "CimSession")]
		[Version]
		$RequiredVersion,
		
		[ValidateSet("Local", "Global")]
		[string]
		$Scope,
		
		[ValidateNotNull]
		[string[]]
		$Variable
	)
	
	$parameters = @{}
	if ($Name)
	{
		$parameters.Add("Name", $Name)
	}
	if ($Alias)
	{
		$parameters.Add("Alias", $Alias)
	}
	if ($ArgumentList)
	{
		$parameters.Add("ArgumentList", $ArgumentList)
	}
	if ($AsCustomObject)
	{
		$parameters.Add("AsCustomObject", $AsCustomObject)
	}
	if ($Assembly)
	{
		$parameters.Add("Assembly", $Assembly)
	}
	if ($CimNamespace)
	{
		$parameters.Add("CimNamespace", $CimNamespace)
	}
	if ($CimResourceUri)
	{
		$parameters.Add("CimResourceUri", $CimResourceUri)
	}
	if ($CimSession)
	{
		$parameters.Add("CimSession", $CimSession)
	}
	if ($Cmdlet)
	{
		$parameters.Add("Cmdlet", $Cmdlet)
	}
	if ($DisableNameChecking)
	{
		$parameters.Add("DisableNameChecking", $DisableNameChecking)
	}
	if ($Force)
	{
		$parameters.Add("Force", $Force)
	}
	if ($FullyQualifiedName)
	{
		$parameters.Add("FullyQualifiedName", $FullyQualifiedName)
	}
	if ($Function)
	{
		$parameters.Add("Function", $Function)
	}
	if ($Global)
	{
		$parameters.Add("Global", $Global)
	}
	if ($MaximumVersion)
	{
		$parameters.Add("MaximumVersion", $MaximumVersion)
	}
	if ($MinimumVersion)
	{
		$parameters.Add("MinimumVersion", $MinimumVersion)
	}
	if ($ModuleInfo)
	{
		$parameters.Add("ModuleInfo", $ModuleInfo)
	}
	if ($NoClobber)
	{
		$parameters.Add("NoClobber", $NoClobber)
	}
	if ($PassThru)
	{
		$parameters.Add("PassThru", $PassThru)
	}
	if ($Prefix)
	{
		$parameters.Add("Prefix", $Prefix)
	}
	if ($PSSession)
	{
		$parameters.Add("PSSession", $PSSession)
	}
	if ($RequiredVersion)
	{
		$parameters.Add("RequiredVersion", $RequiredVersion)
	}
	if ($Scope)
	{
		$parameters.Add("Scope", $Scope)
	}
	if ($Variable)
	{
		$parameters.Add("Variable", $Variable)
	}

	$useName = $false
	if (!$Assembly -and !$CimSession -and !$FullyQualifiedName -and !$ModuleInfo -and !$PSSession)
	{
        $useName = $true
		$newModuleNames = @()
		foreach ($moduleName in $Name)
		{
			$moduleFile = ''
			$moduleSearchFiles = @(
				$moduleName
				"$moduleName.psd1"
				"$moduleName.psm1"
				(Join-Path (Get-Location) $moduleName)
				(Join-Path (Get-Location) "$moduleName.psd1")
				(Join-Path (Get-Location) "$moduleName.psm1")
			)
			foreach ($potentialModuleFile in $moduleSearchFiles)
			{
				if (Test-Path $potentialModuleFile)
				{
					$moduleFile = $potentialModuleFile
					break
				}
			}
			
			if ($moduleFile -and (Test-Path $moduleFile))
			{
				$moduleExtension = [System.IO.Path]::GetExtension($moduleFile)
				$signedModulePath = [System.IO.Path]::ChangeExtension($moduleFile, "signed$moduleExtension")
				if ($moduleExtension -eq ".psm1")
				{
					New-Module -Name $moduleName -ScriptBlock (Get-UnsignedScript $moduleFile) | Out-Null
				}
				elseif ($moduleExtension -eq ".psd1")
				{
					Import-UnsignedPsd1File $moduleFile
				}
				else
				{
					$newModuleNames += $moduleName
				}
			}
			else
			{
				$newModuleNames += $moduleName
			}
		}
		
		$parameters.Name = $newModuleNames
	}
    if (!$useName -or $parameters.Name)
    {
	    Import-Module @parameters
    }
}

function Import-UnsignedPsd1File
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path
	)
	
	$directory = Split-Path $Path -Parent
	$fileName = Split-Path $Path -Leaf
	$psd1Data = Import-LocalizedData -BaseDirectory $directory -FileName $fileName
	$rootModule = $psd1Data.RootModule
	if ($psd1Data.ModuleToProcess)
	{
		$rootModule = $psd1Data.ModuleToProcess
	}
	if ($rootModule)
	{
		$rootModulePath = Join-Path $directory $rootModule
		Import-UnsignedModule -Name $rootModulePath
	}
	
	if ($psd1Data.ScriptsToProcess)
	{
		foreach ($scriptToProcess in $psd1Data.ScriptsToProcess)
		{
			& (Get-UnsignedScript $scriptToProcess)
		}
	}
}

function Invoke-UnsignedExpression
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Command
	)
	
	$Command = ConvertTo-UnsignedContent $Command
	Invoke-Expression $Command
}

function Get-UnsignedScript
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path
	)
	
	$script = (cmd /c type $Path) -join "`r`n"
	$unsignedConvert = ConvertTo-UnsignedContent $script $Path
	$scriptBlock = [ScriptBlock]::Create($unsignedConvert)
	return $scriptBlock
}

function ConvertTo-UnsignedContent
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Content,

        [Parameter(Mandatory = $false)]
        [string]
        $Path
	)
	
	$errors = @()
	$parsedContent = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$errors)
	if ($errors.Length -eq 0)
	{
		$contentBuilder = New-Object System.Text.StringBuilder($Content)
        $commands = $parsedContent.FindAll({param ($ast) $ast -is [System.Management.Automation.Language.CommandAst]}, $true).ToArray()
		for ($index = $commands.Length - 1; $index -ge 0; $index--)
		{
            $command = $commands[$index]
			$commandElement = $command.CommandElements[0]
			$commandName = $commandElement.Value
			$startIndex = $commandElement.Extent.StartOffset
			$endIndex = $commandElement.Extent.EndOffset
			$count = $endIndex - $startIndex
			if ($commandName -eq "Import-Module")
			{
				$contentBuilder.Replace("Import-Module", "Import-UnsignedModule", $startIndex, $count) | Out-Null
			}
			elseif ($commandName -eq "Invoke-Expression")
			{
				$contentBuilder.Replace("Import-Expression", "Import-UnsignedExpression", $startIndex, $count) | Out-Null
			}
			elseif ($commandElement.InvocationOperator -in $ampersandOperator, $dotOperator)
			{
				$contentBuilder.Insert($startIndex, "(Get-UnsignedPs1Content ") | Out-Null
				$contentBuilder.Insert($endIndex + 1, ")") | Out-Null
			}
			elseif ($commandName -match '\.ps1$')
			{
				$contentBuilder.Insert($startIndex, "& (Get-UnsignedPs1Content ") | Out-Null
				$contentBuilder.Insert($endIndex + 1, ")") | Out-Null
			}
		}
        if ($Path)
        {
            $psScriptRootInsertOffset = 0
            if ($parsedContent.ParamBlock)
            {
                $psScriptRootInsertOffset = $parsedContent.ParamBlock.Extent.EndOffset + 1
            }
            $contentBuilder.Insert($psScriptRootInsertOffset, "`r`n`$PSScriptRoot = '$(Split-Path -Parent (Resolve-Path $Path))'`r`n") | Out-Null
		}

		$Content = $contentBuilder.ToString()
	}
	
	return $Content
}

function Get-UnsignedPs1Content
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path
	)
	
	if ($Path -match '\.ps1$')
	{
		return (Get-UnsignedScript $Path)
	}
	
	return $Path
}

function Invoke-UnsignedPs1File
{
    $unsignedScript = Get-UnsignedScript $args[0]
    $arguments = ($args | Select-Object @{Name = "arg";Expression={if ($_ -contains ' '){"'$_'"}else{$_}}} -Skip 1 | Select-Object -ExpandProperty arg) -join ' '
    $scriptToRun = "& `$unsignedScript $arguments"
    $result = Invoke-Expression $scriptToRun
	return $result
}

Export-ModuleMember Import-UnsignedModule
Export-ModuleMember Invoke-UnsignedExpression
Export-ModuleMember Get-UnsignedPs1Content
Export-ModuleMember Invoke-UnsignedPs1File
