Disable_and_Enable_Device_Instance_ID
-------------------------------------

Purpose:
     This script will allow the user to quickly disable and enable a pnputil device Instance ID.

Usage:
	**Requires Administrator Privileges**

	There are three ways to use this program:

	1) Run the script as is.  eg:

		.\Disable_and_Enable_Device_Instance_ID.ps1

			-It will scan for all Device Instance ID''s.
			-It will present the user with a numerical list.
			-It will request the user enter a # or Device Instance ID, or a search term.
			-It will then search and/or verify the request and ask the user to proceed.
			-When user proceeds to act on a target device it will be disabled and re-enabled.
            -The program will then loop until the user exits or enters Ctrl+C


	2) Run the script with the -Query <Device Instance ID> switch.  eg:

		.\Disable_and_Enable_Device_Instance_ID.ps1 -Query HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803

		.\Disable_and_Enable_Device_Instance_ID.ps1 HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803

			-It will scan all Device Instance ID''s for the one specified.
            -If no device Instance ID is found, the program will exit.
			-If device Instance Id is found, it will request the user to proceed.
			-When user proceeds to act on a target device it will be disabled and re-enabled.
            -The program will then exit.
            -Program will continue if the -NoExit switch is used.


	3) Run the script with the -Query <any search string> switch.  eg:

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

    -Query <String>     
        The String of the InstanceID, or a search term you wish to look for.
        a) if exact existing InstanceID: the user will be prompted to disable and re-enable.
        b) If no exact existing InstanceID is found, the search is expanded to all fields,
           and presents the user with either a single selection to decide on (if only 1 found),
           or list of options to select.
      
    -WaitOnDisable  <Int32>
        The time to wait after disabling and before re-enabling.
        Default: 1 (second).
      
    -Confirm  [Switch]
        Always Selects Yes at the prompt

    -NoExit  [Switch]
        when the -Query param is used, this will continue into the program instead of exiting.

    -Help [Switch]
        Display this help screen.

  Examples:

    .\Disable_and_Enable_Device_Instance_ID.ps1

    .\Disable_and_Enable_Device_Instance_ID.ps1 -WaitOnDisable 15

    .\Disable_and_Enable_Device_Instance_ID.ps1 -Query "HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803" -WaitOnDisable 5

    .\Disable_and_Enable_Device_Instance_ID.ps1 HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803 25

    .\Disable_and_Enable_Device_Instance_ID.ps1 -Query "HID\VID_2746&PID_106J&Col08\7&1ne36495&0&0803" -Confirm -WaitOnDisable 0