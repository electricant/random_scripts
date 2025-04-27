#!/usr/bin/env bash
#
# Simple script to update the DNS blocklist for unbound
#

set -e # Exit when any command fails

# Lists to pull the hosts from
SOURCES=(
	"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro-compressed.txt"
	"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/fake-onlydomains.txt"
	"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/doh.txt"
	"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/tif-compressed.txt"
	"https://v.firebog.net/hosts/static/w3kbl.txt"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
	"https://raw.githubusercontent.com/danhorton7/pihole-block-tiktok/main/tiktok.txt"
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
	curl -s $src \
		| awk 'NF && !/^#/ { if (NF == 1) print $1; else print $2 }' \
		>> $TEMPFILE
	wc -l $TEMPFILE
done

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

