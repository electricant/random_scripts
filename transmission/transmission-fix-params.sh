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
AUTH="$1"
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
# TODO: ignore finished torrents. How do they appear on this list?
function list_active_ids {
	transmission-remote --auth $AUTH -l | \
		awk '$1 ~ /[0-9]+/{print $1}'
}

# Get the data directory for the specified torrent id
function get_data_dir {
	transmission-remote --auth $AUTH --torrent $1 --info | \
		awk '/Location:/ {print $2}'
}

# Get the name for the specified torrent id
function get_name {
	transmission-remote --auth $AUTH --torrent $1 --info | \
		awk '/Name:/ {print $2}'
}

# Get the current seed ratio for the specified torrent id
function get_cur_ratio {
	transmission-remote --auth $AUTH --torrent $1 --info | \
		awk '/Ratio:/ {print $2}'
}

# Get the target seed ratio for the specified torrent id
function get_target_ratio {
	transmission-remote --auth $AUTH --torrent $1 --info | \
		awk '/Ratio Limit:/ {print $3}'
}

# Get the time when the torrent was added as unix epoch
function get_added_epoch {
	date +%s -d "$(transmission-remote --auth $AUTH -t $1 --info | \
		awk '/Date added:/ {print $3,$4,$5,$6,$7}')"
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
for id in `list_active_ids`; do
	echo ""
	echo "Processing $(get_name $id) (ID: $id)..."
	if [[ $(get_data_dir $id) = $MATCH_DIR ]]; then
		echo "Data directory matched." \
			"Current ratio: $(get_cur_ratio $id)/$(get_target_ratio $id)" 
		
		if [ $(get_added_epoch $id) -lt $AUTOREMOVE_DATE ]
		then
			echo "Torrent too old: removed."
			transmission-remote --auth $AUTH -t $id --remove-and-delete
		else
			set_seed_ratio $id $TARGET_RATIO
			set_priority $id $PRIORITY
		fi
	fi
done
echo DONE.

