#!/bin/bash
#
# Simple backup script for this server
#
set -e
set -o pipefail

# Config variables
SOURCE=/mnt/data
DESTINATION=/mnt/backup
EXCLUDE_FILE=exclude.cfg

date '+%a %d %b %Y, %X'
echo Archiving old backups... Use \'pkill -SIGUSR1 tar\' to print progress
rm -rf "$DESTINATION/old_back.tar*"
# tar prints status information on signals using --totals=$SIGNO
# In this script, the Total bytes written: [...] information gets printed on
# every USR1 signal. Use pkill -SIGUSR1 tar to print it
tar --totals=USR1 --exclude-from="$EXCLUDE_FILE" \
	-cf "$DESTINATION/old_back.tar" "$DESTINATION/back"

date '+%a %d %b %Y, %X'
echo Creating snapshot for $SOURCE...
timestamp=$(date +%s)
btrfs subvolume snapshot -r "$SOURCE" "$SOURCE/snap-$timestamp"

date '+%a %d %b %Y, %X'
echo Copying new data...
rsync -a --delete --exclude-from="$EXCLUDE_FILE" "$SOURCE/snap-$timestamp/" \
	"$DESTINATION/back/"

date '+%a %d %b %Y, %X'
echo DONE.
btrfs fi show "$DESTINATION"
echo Consider rebalancing if needed.

