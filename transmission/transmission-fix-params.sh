#!/usr/bin/env bash
#
# This script sets some parameters for active torrents in $MATCH_DIR to the
# values below. Useful to download a certain torrent into a directory and adjust
# its parameres automatically.
#
# Usage:
#	set the values below then call transmission-fix-params 'user:password'
#

# Authentication user&password is passed on the cli (keep it secret!)
AUTH="${1:-}"

if [[ -z "$AUTH" ]]; then
    echo "Missing auth (user:password)"
    exit 1
fi

# Support an optional --dry-run switch to prevent destructive changes
DRY_RUN=0

if [[ "${2:-}" == "--dry-run" ]]; then
    DRY_RUN=1
fi

# This scrpt will match torrents in this directory (supports globbing)
MATCH_DIR='*/distro-iso'
# Set seed ratio for matched torrents to this value
TARGET_RATIO='20.0'
# Set priority. Can be one of either high|normal|low
PRIORITY='low'
# Automatically remove torrents older than this date. Set to 0 to disable
AUTOREMOVE_DATE=$(date +%s -d "6 months ago")

# Function to list all available (active) torrents by id
# For details about awk matching see:
#	https://www.math.utah.edu/docs/info/gawk_5.html#SEC28
function list_active_ids {
	transmission-remote --auth "$AUTH" -l | \
		awk 'NR>1 && $1 ~ /^[0-9]+$/ {print $1}'
}
# Set the seed ratio of a certain torrent id to the declared value
function set_seed_ratio {
	transmission-remote --auth $AUTH --torrent $1 --seedratio $2
}

# Set the priority of a certain torrent id to the declared value
function set_priority {
	transmission-remote --auth $AUTH --torrent $1 --bandwidth-$2
}

# Main
for id in $(list_active_ids); do
	info=$(transmission-remote --auth "$AUTH" -t "$id" --info)

	name=$(echo "$info" | awk -F': ' '/Name:/ {print $2}')
	location=$(echo "$info" | awk -F': ' '/Location:/ {print $2}')
	added=$(echo "$info" | awk -F': ' '/Date added:/ {print $2}')

	if [[ -z "$added" ]]; then
		echo "Skipping ID $id (no date found)"
		continue
	fi

	added_epoch=$(date +%s -d "$added")

	echo ""
	echo "Processing $name (ID: $id)..."

	if [[ "$location" == $MATCH_DIR ]]; then
		echo "Matched directory: $location"

		if [[ "$added_epoch" -lt "$AUTOREMOVE_DATE" ]]; then
			if [[ "$DRY_RUN" -eq 1 ]]; then
				echo "[DRY] Would remove torrent: $name"
			else
				echo "Removing torrent: $name"
				transmission-remote --auth "$AUTH" -t "$id" \
					--remove-and-delete
			fi
		else
			if [[ "$DRY_RUN" -eq 1 ]]; then
				echo "[DRY] Would set ratio=$TARGET_RATIO and" \
					"priority=$PRIORITY"
			else
				transmission-remote --auth "$AUTH" -t "$id" \
					--seedratio "$TARGET_RATIO"
				transmission-remote --auth "$AUTH" -t "$id" \
					--bandwidth-"$PRIORITY"
			fi
		fi
	fi
done

echo "DONE"

