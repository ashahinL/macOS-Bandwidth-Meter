-- Uninstall Bandwidth Meter
--
-- Compiled into "Uninstall Bandwidth Meter.app" by scripts/build-dmg.sh, with
-- uninstall.sh in its Resources. It lists what it found, asks before removing
-- anything, and asks separately before deleting saved totals and settings.

property appTitle : "Uninstall Bandwidth Meter"

on run
	set helper to "/bin/sh " & quoted form of (POSIX path of (path to resource "uninstall.sh"))

	set systemItems to {}
	set userItems to {}
	set dataPath to ""
	repeat with found in paragraphs of (do shell script helper & " status")
		set found to found as text
		if found starts with "system:" then
			set end of systemItems to text 8 thru -1 of found
		else if found starts with "user:" then
			set end of userItems to text 6 thru -1 of found
		else if found starts with "data:" then
			set dataPath to text 6 thru -1 of found
		end if
	end repeat
	set toRemove to systemItems & userItems

	if toRemove is {} and dataPath is "" then
		display dialog "Bandwidth Meter isn't installed on this Mac." buttons {"OK"} default button "OK" with title appTitle with icon note
		return
	end if

	if toRemove is not {} then
		set AppleScript's text item delimiters to return
		set listText to toRemove as text
		set AppleScript's text item delimiters to ""
		display dialog "Remove Bandwidth Meter from this Mac?" & return & return & listText & return & return & "Bandwidth+ is not touched." buttons {"Cancel", "Uninstall"} default button "Uninstall" cancel button "Cancel" with title appTitle with icon caution
	end if

	set deleteData to false
	if dataPath is not "" then
		set answer to display dialog "Also delete your saved totals and settings?" & return & return & dataPath & return & return & "Keep them if you might install Bandwidth Meter again." buttons {"Delete", "Keep"} default button "Keep" with title appTitle with icon caution
		if button returned of answer is "Delete" then set deleteData to true
	end if

	if toRemove is {} and not deleteData then
		display dialog "Nothing was removed." buttons {"OK"} default button "OK" with title appTitle with icon note
		return
	end if

	if systemItems is not {} then
		do shell script helper & " system" with prompt "Uninstall Bandwidth Meter wants to remove the app and the bandwidth-meter command." with administrator privileges
	end if
	if deleteData then
		do shell script helper & " user --delete-data"
	else
		do shell script helper & " user"
	end if

	if deleteData then
		set doneText to "Bandwidth Meter and its saved data have been removed."
	else if dataPath is not "" then
		set doneText to "Bandwidth Meter has been removed. Your saved totals are still in" & return & dataPath
	else
		set doneText to "Bandwidth Meter has been removed."
	end if
	display dialog doneText buttons {"OK"} default button "OK" with title appTitle with icon note
end run
