#!/bin/bash
#
# Backup script that copies data locally and syncs it to the cloud.
# To limit the data usage onto the cloud, a hard limit to the maximum size of
# the backup directory can be set.
#
set -euo pipefail

# Only for debug (or invoke with bash -x)
#set -x

# Target directory for backups. Also used as mount point if $BACKUP_DISK is set
TARGET_DIR="/mnt/backup/weekly"

# Folder name prefix for the backup within TARGET_DIR
BACKUP_PREFIX="data-backup"

# Maximum backup size in GB. The script will delete old backups up to this limit
BACKUP_MAX_SIZE_GB=90

# Source directories.
#
# rsync does care about the trailing slash, but only on the source argument.
# For example, let a and b be two directories, with the file foo initially
# inside directory a. Then this command:
#     rsync -a a b
# produces b/a/foo, whereas this command:
#     rsync -a a/ b
# produces b/foo.
SOURCE_DIRS=("/mnt/data/Documenti" "/mnt/data/Foto" "/mnt/data/expenseowl"
             "/mnt/data/radicale-data" "/mnt/data/syncthing")

# Remote destination where the backup will be stored
REMOTE="nas_backup@opc.scaramuzza.me:~/data"

# Files to be excluded from backup. Use absolute path if run within cron
EXCLUDE_FILE="/home/pol/random_scripts/backup/exclude.cfg"

# Function that returns the space used in GB for $TARGET_DIR
function backup_folder_size_GB { 
	du -s --block-size=1G $TARGET_DIR | tail -1 | awk '{print $1}'
}

# Function to return the oldest backup folder name
function get_oldest_backup {
	find "$TARGET_DIR" -maxdepth 1 -name "$BACKUP_PREFIX*" | sort | head -n1
}

# Function to get the most recent backup folder name
function get_newest_backup {
	find "$TARGET_DIR" -maxdepth 1 -name "$BACKUP_PREFIX*" | sort | tail -n1
}

# Check whether the 'is_backup_target" file exists in $TARGET_DIR
# If it does not exist exit immediately
if [ ! -f "$TARGET_DIR/is_backup_target" ]
then
      echo "ERROR: Could not find 'is_backup_target' in $TARGET_DIR. Giving up."
      exit 1
fi

# Rotate indefinitely (will delete later if quota is exceeded)
local_destination="$TARGET_DIR/$BACKUP_PREFIX.$(date +"%Y%m%d")"

cp -alf $(get_newest_backup) $local_destination \
	|| echo "WARNING: $local_destination not hard linked."

# Execute backup to the newly created directory
mkdir -p "$local_destination/chroots"

for chroot in /opt/chroot/*/ ; do
      echo "INFO: Compressing $chroot..."
      tar c --zstd -f --warning=no-file-changed --exclude='var/lib/postgresql' \
		"$local_destination/chroots/$(basename $chroot).tar.zstd" $chroot
done

for src_dir in "${SOURCE_DIRS[@]}"
do
      echo "INFO: Copying '$src_dir'..."
      rsync -aAHX -h --info=stats1,del2 --delete \
            --exclude-from="$EXCLUDE_FILE" "$src_dir" $local_destination
done

echo "INFO: Dumping databases..."
# Reload with: zstdcat pg_dump.zstd | psql postgres
su - postgres -c 'pg_dumpall -h localhost' \
	| zstd -fo "$local_destination/pg_dump.zstd"

# Check and enforce quota usage
echo "INFO: Quota usage in $TARGET_DIR is $(backup_folder_size_GB)/$BACKUP_MAX_SIZE_GB GB"

while [ $(backup_folder_size_GB) -gt $BACKUP_MAX_SIZE_GB ]
do
	to_del=$(get_oldest_backup)
	echo "INFO: Deleting $to_del to free up space."
	rm -rf $to_del
	echo "INFO: Quota usage is now $(backup_folder_size_GB) GB."
done

# Copy to remote (with 2MBps bandwidth limit)
echo "INFO: Copying backup directory to $REMOTE"
rsync -aAXH -h --info=stats1 --bwlimit=2048 --delete "$TARGET_DIR" "$REMOTE"

