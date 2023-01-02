<#Requires -RunAsAdministrator#>
#Requires -Version 3
<#
	Disable_and_Enable_Device_by_Instance_ID.ps1
	-----------------------------------------

	This script will allow the user to quickly disable and enable a pnputil device Instance ID.
		*See if($Help) for more
#>

#region Params

Param 
	(
		[Parameter( Position=0, Mandatory=$false )]
		[string]	$Query				= "",			# InstanceID or a search string of the device to search for and toggle.

		[Parameter( Position=1, Mandatory=$false )]
		[Int32]		$WaitOnDisable		= 3,			# Time in seconds to wait between disabling and enabling.

		[Switch] $Confirm				= $false,		# Switch to always select "Y" at prompts".

		[Switch] $NoExit				= $false,		# Switch to prevent program quitting after command line -Query start start

		[Switch] $Help					= $false		# Switch to display Help message.
	)

#endregion Params


#region Handle Params

if($Help)
{
	$msg = '

Disable_and_Enable_Device_Instance_ID
-------------------------------------

Purpose:
	This script will allow the user to quickly disable and enable a pnputil device Instance ID.

Usage:
	**Requires Administrator Privileges**

	There are three ways to use this program:

	1) Run the script as is. eg:

		.\Disable_and_Enable_Device_Instance_ID.ps1

			-It will scan for all Device Instance ID''s.
			-It will present the user with a numerical list.
			-It will request the user enter a # or Device Instance ID, or a search term.
			-It will then search and/or verify the request and ask the user to proceed.
			-When user proceeds to act on a target device it will be disabled and re-enabled.
			-The program will then loop until the user exits or enters Ctrl+C


	2) Run the script with the -Query <Device Instance ID> switch. eg:

		.\Disable_and_Enable_Device_Instance_ID.ps1 -Query HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803

		.\Disable_and_Enable_Device_Instance_ID.ps1 HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803

			-It will scan all Device Instance ID''s for the one specified.
			-If no device Instance ID is found, the program will exit.
			-If device Instance Id is found, it will request the user to proceed.
			-When user proceeds to act on a target device it will be disabled and re-enabled.
			-The program will then exit.
			-Program will continue if the -NoExit switch is used.


	3) Run the script with the -Query <any search string> switch. eg:

		.\Disable_and_Enable_Device_Instance_ID.ps1 -Query "Touch Screen"

		.\Disable_and_Enable_Device_Instance_ID.ps1 "Touch Screen"

			-It will scan all Device fields for the query.
			-If no matching Devices are found, the program will exit.
			-If any matching devices are found, it will present the user with a numerical list if more than one.
			-If more than one it will show a list to request the user enter a # or Device Instance ID, or a search term.
			-It will then search and/or verify the request and ask the user to proceed.
			-When user proceeds to act on a target device it will be disabled and re-enabled.
			-The program will then exit.
			-Program will continue if the -NoExit switch is used.


 Optional Parameters:

	-Query			<String>
		The String of the InstanceID, or a search term you wish to look for.
		a) if exact existing InstanceID: the user will be prompted to disable and re-enable.
		b) If no exact existing InstanceID is found, the search is expanded to all fields,
		and presents the user with either a single selection to decide on (if only 1 found),
		or list of devices to select.

	-WaitOnDisable	<Int32>
		The time to wait after disabling and before re-enabling.
		Default: 3 (second).

	-Confirm		[Switch]
		Always Selects Yes, or presses Enter at a user prompt

	-NoExit			[Switch]
		When the -Query param is used, this will continue into the program instead of exiting.

	-Help			[Switch]
		Display this help screen.

 Examples:

	.\Disable_and_Enable_Device_Instance_ID.ps1
	.\Disable_and_Enable_Device_Instance_ID.ps1 -WaitOnDisable 15
	.\Disable_and_Enable_Device_Instance_ID.ps1 -Query "HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803" -WaitOnDisable 5
	.\Disable_and_Enable_Device_Instance_ID.ps1 HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803 25
	.\Disable_and_Enable_Device_Instance_ID.ps1 -Query "HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803" -Confirm -WaitOnDisable 0

'
	return $msg
}
if($WaitOnDisable -le 0){$WaitOnDisable = 1} #Default to 1.

#endregion Handle Params


#region Classes

#A class to hold each pnputil device:
Class Device
{
	[string] $InstanceId			= ""
	[string] $DeviceDescription		= ""
	[string] $ClassName				= ""
	[string] $ClassGUID				= ""
	[string] $ManufacturerName		= ""
	[string] $Status				= ""
	[string] $DriverName			= ""
	[string] $ExtensionDriverNames	= ""
}	

#endregion Classes


#region Functions

Function GetAllEnumDevices
{
	return pnputil /enum-devices
}


<# This function will parse the string array from pnputil /enum-devices into List[Device] sorted by DeviceDescription #>
function ParseAndSortAllEnumDevicesData([String[]] $EnumDevicesListing)
{
		# Output Patterns in /enum-devices:
	$InstanceIdPattern				= "Instance ID:"
	$DeviceDescriptionPattern		= "Device Description:"
	$ClassNamePattern				= "Class Name:"
	$ClassGUIDPattern				= "Class GUID:"
	$ManufacturerNamePattern		= "Manufacturer Name:"
	$StatusPattern					= "Status:"
	$DriverNamePattern				= "Driver Name:"
	$ExtensionDriverNamesPattern	= "Extension Driver Names:"

	[Collections.Generic.List[Device]] $NewDevices = New-Object Collections.Generic.List[Device]

	[Device] $CurrentDevice = New-Object Device

	foreach ($Line in $EnumDevicesListing)
	{
		# Add $CurrentDevice to $NewDevices if the line is empty (indicating a break in device listings), and $CurrentDevice has an Instance ID:
		if (($Line.ToString().Trim() -eq "") -and
			($CurrentDevice.InstanceId -ne ""))
		{
			$NewDevices.Add($CurrentDevice)
			$CurrentDevice = New-Object Device
		}

		# Handle $InstanceIdPattern
		elseif (($Line.Length -gt $InstanceIdPattern.Length) -And
				($Line.ToString().Substring(0,($InstanceIdPattern).length) -eq $InstanceIdPattern))
		{
			$CurrentDevice.InstanceId = $Line.ToString().Substring(($InstanceIdPattern).length+1).Trim()
		}

		# Handle $DeviceDescriptionPattern
		elseif (($Line.Length -gt $DeviceDescriptionPattern.Length) -And
				($Line.ToString().Substring(0,($DeviceDescriptionPattern).length) -eq $DeviceDescriptionPattern))
		{
			$CurrentDevice.DeviceDescription = $Line.ToString().Substring(($DeviceDescriptionPattern).length+1).Trim()
		}

		# Handle $ClassNamePattern
		elseif (($Line.Length -gt $ClassNamePattern.Length) -And
				($Line.ToString().Substring(0,($ClassNamePattern).length) -eq $ClassNamePattern))
		{
			$CurrentDevice.ClassName = $Line.ToString().Substring(($ClassNamePattern).length+1).Trim()
		}

		# Handle $ClassGUIDPattern
		elseif (($Line.Length -gt $ClassGUIDPattern.Length) -And
				($Line.ToString().Substring(0,($ClassGUIDPattern).length) -eq $ClassGUIDPattern))
		{
			$CurrentDevice.ClassGUID = $Line.ToString().Substring(($ClassGUIDPattern).length+1).Trim()
		}

		# Handle $ManufacturerNamePattern
		elseif (($Line.Length -gt $ManufacturerNamePattern.Length) -And
				($Line.ToString().Substring(0,($ManufacturerNamePattern).length) -eq $ManufacturerNamePattern))
		{
			$CurrentDevice.ManufacturerName = $Line.ToString().Substring(($ManufacturerNamePattern).length+1).Trim()
		}

		# Handle $StatusPattern
		elseif (($Line.Length -gt $StatusPattern.Length) -And
				($Line.ToString().Substring(0,($StatusPattern).length) -eq $StatusPattern))
		{
			$CurrentDevice.Status = $Line.ToString().Substring(($StatusPattern).length+1).Trim()
		}

		# Handle $DriverNamePattern
		elseif (($Line.Length -gt $DriverNamePattern.Length) -And
				($Line.ToString().Substring(0,($DriverNamePattern).length) -eq $DriverNamePattern))
		{
			$CurrentDevice.DriverName = $Line.ToString().Substring(($DriverNamePattern).length+1).Trim()
		}

		# Handle $ExtensionDriverNamesPattern
		elseif (($Line.Length -gt $ExtensionDriverNamesPattern.Length) -And
				($Line.ToString().Substring(0,($ExtensionDriverNamesPattern).length) -eq $ExtensionDriverNamesPattern))
		{
			$CurrentDevice.ExtensionDriverNames = $Line.ToString().Substring(($ExtensionDriverNamesPattern).length+1).Trim()
		}
	}

	# Add the last Device if it exists and has an Instance ID:
	if ($CurrentDevice.InstanceId -ne "")
	{
		$NewDevices.Add($CurrentDevice)
	}

	# Return the sorted list
	return ($NewDevices | Sort-Object -Property DeviceDescription)
}


<# This function will search the Device List for an InstanceID to find an exact TargetDevice #>
Function SearchDeviceListForInstanceIdWithQuery([Collections.Generic.List[Device]] $Devices, [string] $Query)
{
	[Device]						$IdentifiedDevice		= $Null

	foreach($Device in $Devices)
	{
		if($Device.InstanceId -eq $Query)
		{
			$IdentifiedDevice = $Device
			break;
		}
	}

	return $IdentifiedDevice
}


<# This will search all List[Device] fields for a query and return a list of found Devices #>
Function SearchDeviceListFieldsWithQuery([Collections.Generic.List[Device]] $Devices, [string] $Query)
{
	[Collections.Generic.List[Device]]	$NewDevices			= New-Object Collections.Generic.List[Device]

	[Device]							$CurrentDevice		= New-Object Device

	foreach($Device in $Devices)
	{

		if(	$Device.InstanceId.ToUpper().Contains($Query.ToUpper()) -or
			$Device.DeviceDescription.ToUpper().Contains($Query.ToUpper()) -or
			$Device.ClassName.ToUpper().Contains($Query.ToUpper()) -or
			$Device.ClassGUID.ToUpper().Contains($Query.ToUpper()) -or
			$Device.ManufacturerName.ToUpper().Contains($Query.ToUpper()) -or
			$Device.Status.ToUpper().Contains($Query.ToUpper()) -or
			$Device.DriverName.ToUpper().Contains($Query.ToUpper()) -or
			$Device.ExtensionDriverNames.ToUpper().Contains($Query.ToUpper()) )
		{
			$CurrentDevice = $Device
			$NewDevices.Add($CurrentDevice)
			$CurrentDevice = New-Object Device
		}
	}

	return $NewDevices
}



Function WorkWithDevicesList ([Collections.Generic.List[Device]] $Devices)
{
	[int] $DescriptionColumnWidth = 0;

	#Determine the size of the Description column:
	foreach ($Device in $Devices)
	{
		if (($Device.DeviceDescription).Length -gt $DescriptionColumnWidth)
		{
			$DescriptionColumnWidth = ($Device.DeviceDescription).Length
		}
	}

	$DescriptionColumnWidth += 2;
	
	#Print out Header for devices:
	Write-Host "#$(" " * $((($Devices).Count.ToString()).Length + 2))".Substring(0,$(($Devices).Count.ToString()).Length + 2) -ForeGroundColor Green -NoNewLine
	Write-Host "Description$(" " * $DescriptionColumnWidth)".Substring(0,$DescriptionColumnWidth) -ForeGroundColor White -NoNewLine
	Write-Host "Instance ID" -ForeGroundColor Cyan 
	Write-Host "$("-" * $((($Devices).Count.ToString()).Length + 2))".Substring(0,$(($Devices).Count.ToString()).Length + 2) -ForeGroundColor Green -NoNewLine
	Write-Host "$("-" * $DescriptionColumnWidth)".Substring(0,$DescriptionColumnWidth) -ForeGroundColor White -NoNewLine
	Write-Host "$("-" * $DescriptionColumnWidth)".Substring(0,$DescriptionColumnWidth) -ForeGroundColor Cyan

	#Print out devices
	$Count = 1
	foreach ($Device in $Devices)
	{
		Write-Host "$($Count)$(" " * $((($Devices).Count.ToString()).Length + 2))".Substring(0,$(($Devices).Count.ToString()).Length + 2) -ForeGroundColor Green -NoNewLine
		Write-Host "$($Device.DeviceDescription)$(" " * $DescriptionColumnWidth)".Substring(0,$DescriptionColumnWidth) -ForeGroundColor White -NoNewLine
		Write-Host "$($Device.InstanceID)" -ForeGroundColor Cyan

		$Count++
	}

	# User Request Line
	Write-Host "Enter the above "										-NoNewLine
	Write-Host "# (1-$($Devices.Count))"	-ForeGroundColor Green		-NoNewLine
	Write-Host ", "														-NoNewLine
	Write-Host "Instance ID"				-ForeGroundColor Cyan		-NoNewLine
	Write-Host ", or type a "											-NonewLine
	Write-Host "Search Query"				-ForegroundColor Yellow		-NoNewline
	Write-Host ", to select or search for a device to work with. Or "	-NonewLine
	Write-Host "Quit"						-ForeGroundColor Red		-NoNewLine
	$Global:UserQuery = Read-Host " to exit "

	$Global:UserQuery = $Global:UserQuery.Trim()
	
	$Global:TargetDevice = $Null;

	#Handle new $Global:UserQuery
	if ($Global:UserQuery -eq "Quit")
	{
		$Global:RunProgram = $False

		return
	}
	elseif ($Global:UserQuery -In 1..$($Devices.Count))
	{
		$Global:TargetDevice = $Devices[[int]$Global:UserQuery - 1]

		$Global:UserQuery = ""
	}
	else
	{
		foreach ($Device in $Devices)
		{
			if ($Device.InstanceID -eq $Global:UserQuery)
			{
				$Global:TargetDevice = $Device

				$Global:UserQuery = ""

				break;
			}
		}
	}
}


Function WorkWithSelectedDevice ([Device] $TargetDevice)
{
	Write-Host "Target Device:`r`n"		-ForegroundColor Gray -NoNewline
	Write-Host "`t`t$($TargetDevice.InstanceId)"			-Foregroundcolor Cyan
	Write-Host "`t`t$($TargetDevice.DeviceDescription)"		-Foregroundcolor Cyan
	Write-Host "`t`t$($TargetDevice.ClassName)"				-ForeGroundColor Cyan
	Write-Host "`t`t$($TargetDevice.ClassGUID)"				-ForeGroundColor Cyan
	Write-Host "`t`t$($TargetDevice.ManufacturerName)"		-ForeGroundColor Cyan
	Write-Host "`t`t$($TargetDevice.Status)"				-ForeGroundColor Cyan
	Write-Host "`t`t$($TargetDevice.DriverName)"			-ForeGroundColor Cyan
	Write-Host "`t`t$($TargetDevice.ExtensionDriverNames)"	-ForeGroundColor Cyan

	if (-Not $Confirm)
	{
		$Proceed = Read-Host "Would you like to disable and re-enable this device (Y/N)?"
	}
	if ($Confirm -Or $Proceed -eq "y")
	{
		DisableAndRenableInstanceId $TargetDevice

		if (-Not $Confirm)
		{
			Write-Host "Press any key to continue.."

			[Console]::ReadKey() > $Null
		}
	}
}


<# This function is the one that disables and re-enables the targetdevice #> #Done
Function DisableAndRenableInstanceId([Device] $TargetDevice)
{
	if ($TargetDevice.Status -eq "Started")
	{
		Write-Host "Disabling Device:"

		$result = pnputil /disable-device "$($TargetDevice.InstanceId)"
	
		if ($Result[2].contains("Failed to disable") -AND $Result[3].Contains("Access is denied"))
		{
			Write-Host "Access Denied to disable $($TargetDevice.InstanceID)." -ForegroundColor Red -NoNewLine
			Write-Host " Try Run As Administrator" -ForegroundColor Yellow
		}
		elseif($Result[2].contains("Failed to disable"))
		{
			Write-Host "Failed to disable $($TargetDevice.InstanceID)." -ForegroundColor Red
		}
		elseif($Result[3].Contains("disabled successfully"))
		{
			Write-Host "Disabled $($TargetDevice.InstanceID)" -ForegroundColor Green

			[int] $CountDown = $WaitOnDisable

			While ($Countdown -ge 0)
			{
				Write-Host "`Waiting $($Countdown)(s) before enabling..   `r" -ForegroundColor Yellow -NonewLine

				Start-Sleep -Seconds 1

				$CountDown--
			}
			Write-Host ""

			Write-Host "Enabling Device:"

			$result = pnputil /enable-device "$($TargetDevice.InstanceID)"
		
			if ($Result[2].contains("Failed to enable") -AND $Result[3].Contains("Access is denied"))
			{
				Write-Host "Access Denied to disable $($TargetDevice.InstanceID)." -ForegroundColor Red -NoNewLine

				Write-Host " Try Run As Administrator" -ForegroundColor Yellow
			}
			elseif($Result[2].contains("Failed to enable"))
			{
				Write-Host "Failed to enable $($TargetDevice.InstanceID)" -ForegroundColor Red -NoNewLine
			}
			else
			{
				Write-Host "Enabled $($TargetDevice.InstanceID)" -ForegroundColor Green
			}
		}
	}
	else
	{
		Write-Host "Aborted because device status is: '$($TargetDevice.Status)'. Expected: 'Started'" -ForegroundColor Red
	}
}


#endregion Functions



#region ---> Main Program <---

[bool]								$Global:RunProgram		= $True

[bool]								$Global:QueryParamUsed	= $(if($Query.Trim() -ne ""){$True}else{$False})

[String]							$Global:UserQuery		= $(if($Query.Trim() -ne ""){$Query.Trim()}else{""})

[Device]							$Global:TargetDevice	= $Null

[Collections.Generic.List[Device]]	$Global:EnumDevices		= $Null

[Collections.Generic.List[Device]]	$Global:SearchedDevices	= $Null

while($Global:RunProgram)
{
	[String[]]							$AllEnumDevices		= GetAllEnumDevices
	[Collections.Generic.List[Device]]	$Global:EnumDevices	= ParseAndSortAllEnumDevicesData $AllEnumDevices

	if ($Global:UserQuery -ne "")
	{
		Write-Host "Searching for '$($Global:UserQuery)'"

		$Global:TargetDevice = SearchDeviceListForInstanceIdWithQuery $Global:EnumDevices $Global:UserQuery

		if ($Global:TargetDevice -eq $Null)
		{
			# Try to find a match in any fields on items of the list
			[Collections.Generic.List[Device]]	$Global:SearchedDevices	= SearchDeviceListFieldsWithQuery $Global:EnumDevices $Global:UserQuery

			if ($Global:SearchedDevices.Count -eq 1)
			{
				Write-Host "Found Target Device." -ForegroundColor Green

				$Global:TargetDevice = $Global:SearchedDevices[0]

				$Global:SearchedDevices = $Null
			}
			elseif ($Global:SearchedDevices.Count -gt 1)
			{
				Write-Host "Found $($Global:SearchedDevices.Count) matches!" -ForegroundColor Green
			}
			else
			{
				Write-Host "No Devices Found." -ForegroundColor Red

				$Global:SearchedDevices = $Null
			}
		}
		else
		{
				Write-Host "Found Target Device!" -ForegroundColor Green
		}
	}

	if ($Global:TargetDevice -eq $Null -and $Global:SearchedDevices -ne $Null)
	{
		WorkWithDevicesList $Global:SearchedDevices
	}
	elseif (-not $Global:QueryParamUsed -and $Global:TargetDevice -eq $Null -and $Global:EnumDevices -ne $Null)
	{
		WorkWithDevicesList $Global:EnumDevices
	}

	if ($Global:TargetDevice -ne $Null)
	{
		WorkWithSelectedDevice $Global:TargetDevice

		$Global:TargetDevice = $Null
	}

	if ($Global:QueryParamUsed)
	{
		if ($NoExit)
		{
			$NoExit = $False
			$Confirm = $False
			$Global:UserQuery = ""
			$Global:QueryParamUsed = $False
			$Global:TargetDevice = $Null
			$Global:SearchedDevices = $Null
			$Global:EnumDevices = $Null

		}
		else
		{
			$Global:RunProgram = $False
		}
	}
}


#endregion Main Program
