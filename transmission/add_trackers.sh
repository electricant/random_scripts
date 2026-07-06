#!/bin/sh
#
# Add trackers when torrent is added
# Script taken from https://github.com/Entware/Entware/wiki/Using-Transmission#adding-more-trackers
#
# Usage:
#       set the values below then call add_trackers 'user:password'
#

# Authentication parameters as passed on the cli (keep it secret!)
AUTH="$1"

# URL to fetch the trackers from. Must be one per line
#TRACKERS_URL="https://newtrackon.com/api/stable"
TRACKERS_URL="https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt"
#TRACKERS_URL="https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt"

# Limit adding this number of trackers
MAX_TRACKERS=10

if [ -z "$TR_TORRENT_HASH" ] ; then
    echo 'This script should be called from transmission-daemon.'
    exit 1
fi

logger -t $(basename $0) "Adding trackers to $TR_TORRENT_NAME..."
count=0
for tracker in $(curl -sS "$TRACKERS_URL") ; do
	transmission-remote --auth="$AUTH" -t "$TR_TORRENT_HASH" \
		-td "$tracker" >/dev/null

	count=$((count + 1))
	if [ "$count" -ge "$MAX_TRACKERS" ]; then
		break
	fi
done
logger -t $(basename $0) "Done. Added $count trackers."

