$authenticodeCertificate = $null
$ampersandOperator = [System.Management.Automation.Language.TokenKind]::Ampersand
$dotOperator = [System.Management.Automation.Language.TokenKind]::Dot

function Set-AuthenticodeCertificate
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNull]
		[System.Security.Cryptography.X509Certificates.X509Certificate2]
		$Certificate
	)
	
	$script:authenticodeCertificate = $Certificate
}

function Import-SignedModule
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
					$signedModulePath = Set-SignedContent $moduleFile
					$newModuleNames += $signedModulePath
				}
				elseif ($moduleExtension -eq ".psd1")
				{
					$signedModulePath = Set-SignedPsd1Content $moduleFile
					$newModuleNames += $signedModulePath
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

function Invoke-SignedExpression
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Command
	)
	
	$Command = ConvertTo-JustInTimeSignedContent $Command
	Invoke-Expression $Command
}

function ConvertTo-JustInTimeSignedContent
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
				$contentBuilder.Replace("Import-Module", "Import-SignedModule", $startIndex, $count)
			}
			elseif ($commandName -eq "Invoke-Expression")
			{
				$contentBuilder.Replace("Import-Expression", "Import-SignedExpression", $startIndex, $count)
			}
			elseif ($commandElement.InvocationOperator -in $ampersandOperator, $dotOperator)
			{
				$contentBuilder.Insert($startIndex, "(Set-SignedPs1Content ")
				$contentBuilder.Insert($endIndex + 1, ")")
			}
			elseif ($commandName -match '\.ps1$')
			{
				$signedPs1File = Set-SignedContent $commandName
				$contentBuilder.Replace($commandElement.Extent.Text, $signedPs1File, $startIndex, $count)
			}
		}
		
		$Content = $contentBuilder.ToString()
	}
	
	return $Content
}

function Set-SignedPs1Content
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path
	)
	
	if ($Path -match '\.ps1$')
	{
		$Path = Set-SignedContent $Path
	}
	
	return $Path
}

function Set-SignedPsd1Content
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
	if ($psd1Data.ModuleToProcess)
	{
		$psd1Data.Add("RootModule", $psd1.ModuleToProcess)
		$psd1Data.Remove("ModuleToProcess")
	}
	if ($psd1Data.RootModule)
	{
		$signedModuleFile = Set-SignedContent $psd1Data.RootModule
		$psd1Data.RootModule = $signedModuleFile
	}
	if ($psd1Data.ScriptsToProcess)
	{
		for ($index = 0; $index -lt $psd1Data.ScriptsToProcess.Length; $index++)
		{
			$currentScript = $psd1Data.ScriptsToProcess[$index]
			$signedScript = Set-SignedContent $currentScript
			$psd1Data.ScriptsToProcess[$index] = $signedScript
		}
	}
	
	$extension = [System.IO.Path]::GetExtension($Path)
	$signedPath = [System.IO.Path]::ChangeExtension($Path, "signed$moduleExtension"
	$psd1Data.Add("Path", $signedPath)
	New-ModuleManifest @psd1Data
	return $signedPath
}

function Set-SignedContent
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		
		[Parameter(Mandatory = $false)]
		[System.Security.Cryptography.X509Certificates.X509Certificate2]
		$Certificate
	)
	
	$content = Get-Content $Path -Raw
	$content = ConvertTo-JustInTimeSignedContent $content
	$extension = [System.IO.Path]::GetExtension($moduleFile)
	$signedPath = [System.IO.Path]::ChangeExtension($moduleFile, "signed$moduleExtension"
	Set-Content $signedPath $content
	if ($Certificate)
	{
		$script:authenticodeCertificate = $Certificate
	}
	elseif (!$script:authenticodeCertificate)
	{
		throw "Authenticode certificate not found."
	}
	
	Set-AuthenticodeSignature -Certificate $script:authenticodeCertificate -FilePath $Path
	return $signedPath
}

function Invoke-SignedPs1File
{
	$signedPs1File = Set-SignedPs1Content $args[0]
	Invoke-Expression "'$signedPs1File' $($args | Select-Object -Skip 1)"
}

Export-ModuleMember Set-AuthenticodeCertificate
Export-ModuleMember Import-SignedModule
Export-ModuleMember Invoke-SignedExpression
Export-ModuleMember Set-SignedPs1Content
Export-ModuleMember Invoke-SignedPs1File
