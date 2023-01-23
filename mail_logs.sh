#!/bin/bash

TEMP_FILE=/tmp/mailLog.tmp
RECIPIENT="paoscr@gmail.com"
SUBJECT="Daily log files"
LOG_SEPARATOR="******************************"
WELCOME_MSG="Good morning.\n"

# Very fancy trick to redirect all ouptut to a file
# See: https://tldp.org/LDP/abs/html/x17974.html
exec 6>&1           # Link file descriptor #6 with stdout (saves stdout).

# If no command line parameter are supplied then run in normal mode.
# Any other parameter prevents IO redirection, printing all output to stdout
if [ -z $1 ]; then
	exec > $TEMP_FILE     # Stdout replaced with $TEMP_FILE.
fi	

function render_title {
	echo "$LOG_SEPARATOR"
	echo " $1"
	echo "$LOG_SEPARATOR"
}

# Mail header for monospaced font with HTML email
echo '<html><body><pre style="font: monospace">'

# Initial greetings.
# How to get the ip address is taken from here:
# http://unix.stackexchange.com/questions/22615/how-can-i-get-my-external-ip-address-in-bash
echo -e "$WELCOME_MSG"
ip=$(dig +short myip.opendns.com @208.67.222.222)
echo The IP address is $ip
echo ""
echo Download speed test:
wget --progress=dot:giga http://cachefly.cachefly.net/10mb.test \
	-O /dev/null 2>&1 | tail -n2
echo ""

# uptime & temperatures (just for an overview)
render_title "uptime & temperatures"
uptime
echo "" 
sensors | grep temp1
echo ""
hddtemp /dev/sd[abcd] 2>&1
echo ""


# Successful logins
render_title "Successful logins"
last -f /var/log/wtmp.1 | head -n -2
echo ""
echo $(lastb -f /var/log/btmp.1 | wc -l) "failed login attempts."
echo ""

# kernel log
render_title "dmesg (important only)"
dmesg -T -l err,crit,alert,emerg
echo ""

# memory
render_title "Free memory"
free -h
echo ""

# disk info
render_title "RAID status"
btrfs filesystem usage /mnt/data
echo ""

btrfs scrub status /mnt/data
echo ""

# Notify about upgradable packages
render_title "Software updates"
# skip update part if apt-daily.timer is running
systemctl list-timers | grep -q apt-daily.timer || apt-get update > /dev/null
apt-get -s upgrade | grep upgraded,

# email footer
echo "</pre></body></html>"

# If in normal mode, send email message
if [ -z $1 ]; then
	mail -a 'Content-type: text/html; charset="UTF-8"' \
		-s "$SUBJECT" "$RECIPIENT" <$TEMP_FILE
fi

