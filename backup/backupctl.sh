#!/bin/bash
#
# Control script for backing up data. It is intended to run as a cgi script
#
# Supported commands:
#  status  - returns 1 if the script is running, 0 otherwise
#  get_log - returns the logfile as text
#  run     - start backup script if not already running

LOG_FILE="/tmp/backup.log"

# in the same directory as this file
BACKUP_SCRIPT=backup.sh

# device used for backup
TARGET_DEVICE="/dev/sde1"

# Check backup status
# Returns:
#	-1 if the target device is not plugged
#	 0 if tne script is stopped
#	 1 if the script is running
function backup_status() {
	if [ "$(ps -e | grep -c $BACKUP_SCRIPT)" -gt 0 ]; then
		echo 1
		return 1
	elif [ "$(df | grep -c $TARGET_DEVICE)" -eq 0 ]; then
		echo -1
		return -1
	else
		echo 0
		return 0
	fi
}

#
# Main
#
echo "Content-type: text/plain"
echo "Pragma: no-cache"
echo ""

# If QUERY_STRING is empty we are probably running from a shell.
# Try to read the command line parameter instead
if test -z "$QUERY_STRING"; then
	QUERY_STRING="$*"
fi

case $QUERY_STRING in
	"status")
		backup_status
		;;
	"get_log")
		cat $LOG_FILE 2>/dev/null
		;;
	"run")
		if [ $(backup_status) -eq 0 ]; then
			nohup sudo /var/www/backup/$BACKUP_SCRIPT >$LOG_FILE 2>&1 &
			echo OK
		else
			backup_status
		fi
		;;
	*)
		echo Command not recognized: $QUERY_STRING
		;;
esac

exit 0
