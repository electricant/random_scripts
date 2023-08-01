#!/bin/bash
#
# Simple backup script for this server
#
set -euo pipefail

# Config variables
# See: http://www.mikerubel.org/computers/rsync_snapshots/#Rsync

# Source directories.
#
# rsync does care about the trailing slash, but only on the source argument.
# For example, let a and b be two directories, with the file foo initially
# inside directory a. Then this command:
# 	rsync -a a b
# produces b/a/foo, whereas this command:
# 	rsync -a a/ b
# produces b/foo.
SOURCE_DIRS=("/mnt/data/Documenti" "/mnt/data/radicale-data" "/tmp/chroots"
             "/mnt/data/syncthing" "/mnt/data/Foto" "/mnt/data/pg_database")

# Place where the backup will be stored
DESTINATION="nas_backup@opc.scaramuzza.me:~/data"

# Files to be excluded from backup. Use absolute path if run within cron
EXCLUDE_FILE="/home/pol/random_scripts/backup/exclude.cfg"

# Send chroots to tar archives to be retrieved later
mkdir -p /tmp/chroots

for chroot in /opt/chroot/*/ ; do
	date '+%a %d %b %Y, %X'
	echo Compressing $chroot
	tar c --zstd -f "/tmp/chroots/$(basename $chroot).tar.zstd" $chroot
done

# Actual remote backup
for src_dir in "${SOURCE_DIRS[@]}"
do
	echo ""
	date '+%a %d %b %Y, %X'
	echo "Copying '$src_dir'..."
	rsync -aAHX -h --info=stats1,del2 --bwlimit=1024 --delete \
	     	--exclude-from="$EXCLUDE_FILE" "$src_dir" "$DESTINATION"
done

echo ""
date '+%a %d %b %Y, %X'
echo Backup complete.

