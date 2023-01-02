Disable_and_Enable_Device_Instance_ID
-------------------------------------

Purpose:
	This script will allow the user to quickly disable and enable a pnputil device Instance ID.

Usage:
	**Requires Administrator Privileges**

	There are three ways to use this script:

	1) Run the script as is. eg:

		.\Disable_and_Enable_Device_Instance_ID.ps1

			-It will scan for all Device Instance ID''s.
			-It will present the user with a numerical list of devices.
			-It will prompt the user enter a # or Device Instance ID, a search term, or quit.
			-It will then verify user input (Quit, #, InstanceID), or search again.
			-When user selects a single target device to act upon, the device will be disabled and re-enabled.
			-The script will then loop until the user exits with ''Quit'' or Ctrl+C.


	2) Run the script with the -Query <Device Instance ID> switch. eg:

		.\Disable_and_Enable_Device_Instance_ID.ps1 -Query "HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803"

		.\Disable_and_Enable_Device_Instance_ID.ps1 ""HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803"

			-It will scan all Device Instance ID''s for the one specified.
			-If no device Instance ID is found, the script will note this and exit.
			-If device Instance Id is found, it will prompt the user to proceed.
			-When user selects a single target device to act upon, the device will be disabled and re-enabled.
			-The script will then exit, unless the ''-NoExit'' switch was also used (See: -NoExit).


	3) Run the script with the -Query <any search string> switch. eg:

		.\Disable_and_Enable_Device_Instance_ID.ps1 -Query "Touch Screen"

		.\Disable_and_Enable_Device_Instance_ID.ps1 "Touch Screen"

			-It will scan all Device fields for the query.
			-If no matching Devices are found, the script will exit.
			-If any matching devices are found:
				-If 1 device is found, it will prompt the user to work with that device.
				-If more than 1 device is found it will present a numerical list and request the user enter
				a #, Device Instance ID, another search term, or ''Quit''.
			-When user selects a single target device to act upon, the device will be disabled and re-enabled.
			-The script will then exit, unless the ''-NoExit'' switch was also used (See: -NoExit).


 Optional Parameters:

	-Query			<String>
		The String of the InstanceID, or a search term you wish to look for.
		All searches should be enclosed in double quotations, "like this".
		a) if exact existing InstanceID: the user will be prompted to disable and re-enable.
		b) If no exact existing InstanceID is found, the search is expanded to a case-insensitive search of fields,
		and presents the user with either a single selection to decide on, or list of devices to select one from.

	-WaitOnDisable	<Int32>
		The time to wait after disabling and before the device is re-enabled.
		Default: 3 (Seconds).

	-Confirm		[Switch]
		Always selects yes, or presses Enter at a user prompt, for unassisted execution.
		Works best with an exact InstanceID, or manual use.
		NOTE: If planning to use a search term for unassisted execution, be aware that if more
		than one device is identified, it will present a list requiring user input to select.

	-NoExit			[Switch]
		When the -Query param is used, this will continue into the script instead of exiting.

	-Help			[Switch]
		Display this help screen.

 Examples:

	.\Disable_and_Enable_Device_Instance_ID.ps1
	.\Disable_and_Enable_Device_Instance_ID.ps1 -WaitOnDisable 15
	.\Disable_and_Enable_Device_Instance_ID.ps1 -Query "HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803" -WaitOnDisable 5
	.\Disable_and_Enable_Device_Instance_ID.ps1 "HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803" 25
	.\Disable_and_Enable_Device_Instance_ID.ps1 -Query "HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803" -Confirm -WaitOnDisable 0
