#!/bin/bash
#
# Bash script that dynamically updates the DNS records when the public IP has
# changed. Run it periodically using cron (or whatever you like)
#
set -euo pipefail

# Target DNS server to submit updates to
DNS_SERVER="ns1.scaramuzza.me"

# Zone to update
DNS_ZONE="scaramuzza.me"

# Domain to update
DOMAIN="go.scaramuzza.me"

# DNSSEC key file for authentication
KEY_FILE="/root/dnssec/gnu-nas.key"

##
# Print the current IP as reported by the DNS server
#
# Bash functions return the return value of the last command. Therefore if dig
# fails the program will stop (remember we set -e at the beginning)
##
function get_DNS_IP {
	dig +short $DOMAIN @$DNS_SERVER
}

##
# Print the public IP address
##
function get_public_IP {
	dig +short myip.opendns.com @208.67.222.222
}

##
# Update DNS records using the IP address supplied as the first parameter
##
function update_DNS_record {
	tempfile=$(mktemp)
	
	echo "server $DNS_SERVER" >>$tempfile
	echo "zone $DNS_ZONE" >>$tempfile
	echo "update delete $DOMAIN A" >>$tempfile
	echo "update add $DOMAIN 60 A $1" >>$tempfile
	echo "send" >>$tempfile
	
	nsupdate -d -k $KEY_FILE -v $tempfile
}

set -x # For debug, print command trace to standard error

dns_ip=$(get_DNS_IP)
pub_ip=$(get_public_IP)

# Update DNS records if IPs are not equal
if [ "$dns_ip" != "$pub_ip" ]; then
	update_DNS_record $pub_ip
fi

