#!/bin/bash -e
#
# Show events for today as a desktop notification
#

# Add an icon on the systray to stop the refresh
yad --notification --text "Calendar sync running" &
yad_pid=$!

# Wait for the startup to be complete
sleep 60

while kill -0 "$yad_pid" 2>/dev/null
do
	vdirsyncer sync
	notify-send "$(khal list now 23:59)"
	sleep 1h
done
