#!/bin/bash
#
# Yet another backup script, inspired by:
# http://www.mikerubel.org/computers/rsync_snapshots/#Rsync
# https://borgbackup.readthedocs.io/en/stable/deployment/automated-local.html
#
# It requires the surce directory to live within a btrfs filesystem, so that
# we can create a read-only snapshot to freeze the content before copying.
set -euo pipefail

# Only for debug
#set -x

# Number of old backups to keep (excluding the current)
# Therefore, the total number of backups stored is $NUM_OLD + 1
NUM_OLD=11 # 1 year's worth of backups

# Source directory, without trailing slash.
SRC_DIR="/mnt/data"

# Target directory for backups. Also used as mount point if $BACKUP_DISK is set
TARGET_DIR="/mnt/backup/monthly"

# Folder name for the backup within TARGET_DIR
BACKUP_FOLDER="data-backup"

# To exclude files and folders use this file
EXCLUDE_FILE="/home/pol/random_scripts/backup/exclude.cfg"

# If this variable is set then, the corresponding disk is mounted to
# $TARGET_DIR before running the backup and unmounted when the backup is done
#BACKUP_DISK="/dev/disk/by-id/usb-Generic_External_FF1000DF00000000000000F1DB2FFF-0:0"
BACKUP_DISK=""
#BACKUP_PART="${BACKUP_DISK}-part1"

# Read command line parameters (if any)
# Parameters:
#	-l --list-snapshots	Prints a list of the available snapshots and
#	                   	their creation time.
#
while [[ "$#" -gt 0 ]]; do
	case $1 in
		-l|--list-snapshots)
			find $SRC_DIR -mindepth 1 -maxdepth 1 -name "snap-*" \
				-exec btrfs subvolume show {} \; | egrep "snap-|Creation"
			shift ;;
		*)
			echo "Unknown parameter passed: $1"
			exit 1 ;;
    esac
    shift
done

# Mount file system if not already done.
# This assumes that if something is already mounted at $TARGET_DIR, it is the
# backup drive. It won't find the drive if it was mounted somewhere else.
if [ -n "$BACKUP_DISK" ]
then 
	(mount | grep "$TARGET_DIR") || mount "$BACKUP_PART" "$TARGET_DIR"
fi

# Check whether the 'is_backup_target" file exists in $TARGET_DIR
# If it does not exist exit immediately
if [ ! -f "$TARGET_DIR/is_backup_target" ]
then
	echo "Could not find 'is_backup_target' in $TARGET_DIR. Giving up."
	exit 1
fi

# First rotate
echo "Recycling $BACKUP_FOLDER.$NUM_OLD..."
mv "$TARGET_DIR/$BACKUP_FOLDER.$NUM_OLD" \
   "$TARGET_DIR/$BACKUP_FOLDER.tmp" 2>/dev/null \
   	|| mkdir "$TARGET_DIR/$BACKUP_FOLDER.tmp"

for i in $(seq $NUM_OLD -1 1)
do
	echo "Moving $BACKUP_FOLDER.$((i-1))..." 
	mv "$TARGET_DIR/$BACKUP_FOLDER.$((i-1))" \
	   "$TARGET_DIR/$BACKUP_FOLDER.$i" 2>/dev/null \
		|| echo "Not found hence not rotated."
done

mv "$TARGET_DIR/$BACKUP_FOLDER.tmp" \
   "$TARGET_DIR/$BACKUP_FOLDER.0"

cp -alf "$TARGET_DIR/$BACKUP_FOLDER.1/." \
   "$TARGET_DIR/$BACKUP_FOLDER.0" || echo "$BACKUP_FOLDER.0 not hard-linked."

# Then take a snapshot using the current timestamp and copy latest files
timestamp=$(date +%s)
btrfs subvolume snapshot -r "$SRC_DIR" "$SRC_DIR/snap-$timestamp"

echo "Backup for $SRC_DIR/snap-$timestamp started."
rsync -aAXH -h --info=stats1 --delete --exclude-from="$EXCLUDE_FILE" \
	"$SRC_DIR/snap-$timestamp/" "$TARGET_DIR/$BACKUP_FOLDER.0"

# Print total space used for backup
echo "Backup done."
du -h -d1 $TARGET_DIR

# Finally unmount and stop disk
sync
if [ -n "$BACKUP_DISK" ]
then
	echo "Unmounting $TARGET_DIR (on $BACKUP_PART)."
	umount $TARGET_DIR
	echo "Stopping $BACKUP_DISK."
      /sbin/hdparm -Y $BACKUP_DISK
fi

