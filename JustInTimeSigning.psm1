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
	
	if (!$Assembly -and !$CimSession -and !$FullyQualifiedName -and !$ModuleInfo -and !$PSSession)
	{
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
			
			if (Test-Path $moduleFile)
			{
				$moduleExtension = [System.IO.Path]::GetExtension($moduleFile)
				$signedModulePath = [System.IO.Path]::ChangeExtension($moduleFile, "signed$moduleExtension")
				if ($moduleExtension -eq ".psm1")
				{
					New-Module -Name $moduleName -ScriptBlock (Get-UnsignedContent $moduleFile)
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
	Import-Module @parameters
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
			& (Get-UnsignedContent $scriptToProcess)
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
	
	$script = Get-Content $Path -Raw
	$unsignedConvert = ConvertTo-UnsignedContent $script
	$scriptBlock = [ScriptBlock]::Create($unsignedConvert)
	return $scriptBlock
}

function ConvertTo-UnsignedContent
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Content
	)
	
	$errors = @()
	$parsedContent = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$errors)
	if ($errors.Length -eq 0)
	{
		$contentBuilder = New-Object System.Text.StringBuilder($Content)
		foreach ($command in $parsedContent.FindAll({param ($ast) $ast -is [System.Management.Automation.Language.CommandAst]}, $true))
		{
			$commandElement = $command.CommandElements[0]
			$commandName = $commandElement.Value
			$startIndex = $commandElement.Extent.StartOffset
			$endIndex = $commandElement.Extent.EndOffset
			$count = $endIndex - $startIndex
			if ($commandName -eq "Import-Module")
			{
				$contentBuilder.Replace("Import-Module", "Import-UnsignedModule", $startIndex, $count)
			}
			elseif ($commandName -eq "Invoke-Expression")
			{
				$contentBuilder.Replace("Import-Expression", "Import-UnsignedExpression", $startIndex, $count)
			}
			elseif ($commandElement.InvocationOperator -in $ampersandOperator, $dotOperator)
			{
				$contentBuilder.Insert($startIndex, "(Get-UnsignedPs1Content ")
				$contentBuilder.Insert($endIndex + 1, ")")
			}
			elseif ($commandName -match '\.ps1$')
			{
				$contentBuilder.Insert($startIndex, "& (Get-UnsignedPs1Content ")
				$contentBuilder.Insert($endIndex + 1, ")")
			}
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
	$result = Invoke-Command -ScriptBlock (Get-UnsignedScript $args[0]) -ArgumentList ($args | Select-Object -Skip 1)
	return $result
}

Export-ModuleMember Import-UnsignedModule
Export-ModuleMember Invoke-UnsignedExpression
Export-ModuleMember Get-UnsignedPs1Content
Export-ModuleMember Invoke-UnsignedPs1File
