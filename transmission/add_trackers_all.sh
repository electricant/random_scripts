#!/bin/bash
#
# Add trackers to all torrents
# 
# Usage:
#       set the values below then call add_trackers 'user:password'
#
set -o xtrace

# Authentication parameters as passed on the cli (keep it secret!)
AUTH="$1"

# URL to fetch the trackers from. Must be one per line
#TRACKERS_URL="https://newtrackon.com/api/stable"
TRACKERS_URL="https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt"
#TRACKERS_URL="https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt"

function all_torrents() {
	transmission-remote --auth=$AUTH -l | grep -vE 'Stopped|Finished' | \
		awk '$1 ~ /[0-9]+/{print $1}' | xargs | sed -e 's/ /,/g' -e 's/*//g'
}

echo "Adding trackers..."

count=0
for tracker in $(curl -sS $TRACKERS_URL) ; do
	transmission-remote --auth=$AUTH -t$(all_torrents) \
		-td "${tracker}"
	count=$((count + 1))
done

echo "Done. Added $count trackers."

