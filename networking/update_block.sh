#!/usr/bin/env bash
#
# Simple script to update the DNS blocklist for unbound
#

set -e # Exit when any command fails

# Lists to pull the hosts from
SOURCES=(
	"https://phishing.army/download/phishing_army_blocklist.txt"
	"https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-social-only/hosts"
	"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/pro.mini-onlydomains.txt"
	"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/fake-onlydomains.txt"
	"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/doh-vpn-proxy-bypass-onlydomains.txt"
	"https://raw.githubusercontent.com/xRuffKez/NRD/refs/heads/main/lists/14-day/domains-only/nrd-14day-mini.txt"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
	"https://raw.githubusercontent.com/danhorton7/pihole-block-tiktok/main/tiktok.txt"
	  )

# Temporary file where the hosts are stored
TEMPFILE=/tmp/rawlist.tmp

# File where the cleaned list will be installed
TARGET=/etc/unbound/unbound.conf.d/blocked-domains.conf

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
echo "server:" > $TEMPFILE.unbound
cat $TEMPFILE.dedup \
	| awk 'NF {print "\tlocal-zone: \""$1"\" redirect"
	           print "\tlocal-data: \""$1" A 0.0.0.0\""}' >> $TEMPFILE.unbound

# Install
cp $TEMPFILE.unbound $TARGET
unbound-control reload

