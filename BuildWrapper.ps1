#requires -Version 2.0

<#
		.SYNOPSIS
		Build Warpper
	
		.DESCRIPTION
		Internal Build Wrapper to use with our CI (TeamCity)
	
		.PARAMETER NewVersion
		New Version Number (e.g. 1.0.0.1)
	
		.PARAMETER ReleaseNotes
		Release Notes for this Build
	
		.PARAMETER upload
		Upload to the Gallery?
	
		.EXAMPLE
		# Fire up a test Build
		PS > .\BuildWrapper.ps1 -NewVersion 1.0.0.1

		.EXAMPLE
		# Fire up a test Build, with dedicated Release Notes
		PS > .\BuildWrapper.ps1 -NewVersion 1.0.0.1 -ReleaseNotes = 'This is the Release Notes'
	
		.NOTES
		For EnaTEC internal use...
#>
param
(
	[Parameter(Mandatory = $true,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 1,
	HelpMessage = 'New Version Number (e.g. 1.0.0.1)')]
	[ValidateNotNullOrEmpty()]
	[version]
	$NewVersion,
	[Parameter(ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
	Position = 2)]
	[ValidateNotNullOrEmpty()]
	[string]
	$ReleaseNotes = 'Internal Test Build',
	[Parameter(ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
	Position = 3)]
	[switch]
	$upload
)

BEGIN
{
	$ModName = 'ExchangeNodeMaintenanceMode'
	$SC = 'SilentlyContinue'
	$STP = 'Stop'
}
PROCESS
{
	try
	{
		$paramPushLocation = @{
			Path          = "$env:USERPROFILE\Documents\enatec.$ModName"
			ErrorAction   = $STP
			WarningAction = $SC
		}
		Push-Location @paramPushLocation
	}
	catch
	{
		$paramPopLocation = @{
			ErrorAction   = $SC
			WarningAction = $SC
		}
		Pop-Location @paramPopLocation
	
		$paramWriteError = @{
			Message     = 'Unable to find the Project Directory.'
			ErrorAction = $STP
		}
		Write-Error @paramWriteError 
	}

	try 
	{
		$paramRemoveModule = @{
			Name          = $ModName
			Force         = $true
			ErrorAction   = $SC
			WarningAction = $SC
		}
		$null = (Remove-Module @paramRemoveModule)
		$null = (Remove-Module @paramRemoveModule)
	}
	catch
	{
		$paramWriteVerbose = @{
			Message = 'Something went wrong while removing the Module!!!'
		}
		Write-Verbose @paramWriteVerbose 
	}

	try
	{
		$paramRemoveItem = @{
			Path          = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$ModName"
			Force         = $true
			confirm       = $false
			Recurse       = $true
			ErrorAction   = $STP
			WarningAction = $SC
		}
		Remove-Item @paramRemoveItem
	}
	catch
	{
		$paramPopLocation = @{
			ErrorAction   = $SC
			WarningAction = $SC
		}
		Pop-Location @paramPopLocation
	
		Write-Error -Message 'Unable to remove the old version of the installed Module!!!' -ErrorAction $STP
	}

	try
	{
		$parameters = @{
			NewVersion           = $NewVersion
			BuildModule          = $true
			InstallAndTestModule = $true
			ReleaseNotes         = $ReleaseNotes
		}
		$null = (.\Build.ps1 @parameters)
	}
	catch
	{
		$paramPopLocation = @{
			ErrorAction   = $SC
			WarningAction = $SC
		}
	
		$paramWriteError = @{
			Message     = 'The initial Build has failed...'
			ErrorAction = $STP
		}
		Write-Error @paramWriteError 
	}

	try 
	{
		$paramGetModule = @{
			ListAvailable = $true
			Refresh       = $true
			Name          = $ModName
			ErrorAction   = $SC
			WarningAction = $SC
		}
		$null = (Get-Module @paramGetModule)

		$paramRemoveModule = @{
			UnknownParameter1 = $ModName
			Force             = $true
			ErrorAction       = $SC
			WarningAction     = $SC
		}
		$null = (Remove-Module @paramRemoveModule)
		$null = (Remove-Module @paramRemoveModule)

		$paramImportModule = @{
			Name          = $ModName
			Force         = $true
			ErrorAction   = $SC
			WarningAction = $SC
		}
		#$null = (Import-Module @paramImportModule -Scope Local)
		$null = (Import-Module @paramImportModule -Scope Global)
	}
	catch
	{
		Write-Verbose -Message 'Something went wrong while we try to unload and then reload the new module version...'
	}

$paramImportModule = @{
			Name          = $ModName
			Force         = $true
			ErrorAction   = $SC
			WarningAction = $SC
		}
Import-Module @paramImportModule

	try
	{
		if ($upload)
		{
			.\Build.ps1 -BuildModule -UploadPSGallery
		}
		else
		{
			.\Build.ps1 -BuildModule
		}
	}
	catch
	{
		$paramPopLocation = @{
			ErrorAction   = $SC
			WarningAction = $SC
		}
		Pop-Location @paramPopLocation
	
		$paramWriteError = @{
			Message     = 'The sencond Build has failed...'
			ErrorAction = $STP
		}
		Write-Error @paramWriteError 
	}
}
END
{
	$paramPopLocation = @{
		ErrorAction   = $SC
		WarningAction = $SC
	}
	Pop-Location @paramPopLocation
}
