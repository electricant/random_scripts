#!/bin/sh
#
# Script that sends an e-mail in case of UPS events within NUT

printf '%s\n\n%s' "$(date)" "$*" | mail -s "UPS event" paoscr@gmail.com

