#!/usr/bin/env bash
#
# Simple script to update the DNS blocklist for unbound
#

set -e # Exit when any command fails

# Lists to pull the hosts from
SOURCES=("http://www.malwaredomainlist.com/hostslist/hosts.txt"
         "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Dead/hosts"
	   "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
	   "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
	   "https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/hosts"
	   "https://raw.githubusercontent.com/azet12/KADhosts/master/KADhosts.txt"
	   "https://someonewhocares.org/hosts/hosts"
	   "https://raw.githubusercontent.com/d43m0nhLInt3r/socialblocklists/master/TikTok/tiktokblocklist.txt"
	   "https://raw.githubusercontent.com/d43m0nhLInt3r/socialblocklists/master/Tracking/trackingblocklist.txt"
	   "https://phishing.army/download/phishing_army_blocklist.txt"
	  )

# Temporary file where the hosts are stored
TEMPFILE=/tmp/rawlist.tmp

# File where the cleaned list will be installed
TARGET=/etc/unbound/blocked-domains.conf

# Clean temporary download file
echo "" > $TEMPFILE

# Download sources and append them to the temp file
for src in ${SOURCES[@]}
do
	echo Downloading $src
	# remove unneeded whitespace and make all ips 0.0.0.0
	curl -s $src | awk '{sub("127.0.0.1", "0.0.0.0"); print}' >>$TEMPFILE 
done

echo Lines before cleanup:
wc -l $TEMPFILE

# Filter only lines in the form 0.0.0.0 hostname
# ignoring also comments & removing localhost stuff
cat $TEMPFILE | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ .+$/ { print $1,$2 }' \
     | grep -vE 'local$|localhost.*$|broadcasthost$|ip6-.*$' > $TEMPFILE.dedup
# Cleanup 2nd pass: remove duplicates
sort -u $TEMPFILE.dedup > $TEMPFILE

echo Lines after cleanup:
wc -l $TEMPFILE

# Now convert it into a format that unbound can handle
# see: https://deadc0de.re/articles/unbound-blocking-ads.html
# https://stackoverflow.com/questions/11687216/awk-to-skip-the-blank-lines
cat $TEMPFILE \
	| awk 'NF {print "local-zone: \""$2"\" redirect"
	           print "local-data: \""$2" A "$1"\""}' > $TEMPFILE.unbound

# Install
cp $TEMPFILE.unbound $TARGET
#systemctl reload unbound-chroot
