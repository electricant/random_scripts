#!/usr/bin/env bash
#
# Simple script to update the DNS blocklist for unbound
#

set -e # Exit when any command fails

# Lists to pull the hosts from
SOURCES=("https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Dead/hosts"
	   "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
	   "https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/hosts"
	   "https://raw.githubusercontent.com/azet12/KADhosts/master/KADhosts.txt"
	   "https://someonewhocares.org/hosts/hosts"
	   "https://raw.githubusercontent.com/d43m0nhLInt3r/socialblocklists/master/TikTok/tiktokblocklist.txt"
	   "https://raw.githubusercontent.com/d43m0nhLInt3r/socialblocklists/master/Tracking/trackingblocklist.txt"
	   "https://phishing.army/download/phishing_army_blocklist.txt"
	   "https://raw.githubusercontent.com/smed79/mdlm/master/hosts.txt"
	   "https://reddestdream.github.io/Projects/MinimalHosts/etc/MinimalHostsBlocker/minimalhosts"
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
	# Filter out comment lines and extract hostnames only
	curl -s $src | grep -v '#' \
		| sed -nr 's/.*\s(\w+\.[a-zA-Z]+)$/\1/p' >>$TEMPFILE
done

echo Lines before cleanup:
wc -l $TEMPFILE

# Remove duplicated hostnames
sort -u $TEMPFILE > $TEMPFILE.dedup

echo Lines after cleanup:
wc -l $TEMPFILE.dedup

# Now convert everything into a format that unbound can handle
# see: https://deadc0de.re/articles/unbound-blocking-ads.html
# https://stackoverflow.com/questions/11687216/awk-to-skip-the-blank-lines
cat $TEMPFILE.dedup \
	| awk 'NF {print "local-zone: \""$1"\" redirect"
	           print "local-data: \""$1" A 0.0.0.0\""}' > $TEMPFILE.unbound

# Install
cp $TEMPFILE.unbound $TARGET
systemctl reload unbound-chroot

