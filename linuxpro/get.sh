#!/bin/sh -e
#
# Shell script to gather the LinuxPro journal from the server.
# Tha jounal comes as a set of pages. As a result this script fetches a list of
# images and converts them into a pdf file.
#
# REQUIREMENTS:
# wget
# imagemagik
# awk
# sed
# 
# USAGE:
# get issue_number

##########
# Options
##########
# Maximum number of parallel downloads
MAX_DOWNLOADS=4

# Folder used to store temporary files
TEMP_FOLDER="/tmp"

# Source URL for the journal
url="http://www.paperator.com/user/SpreaEditori/LinuxPro"

# minimum valid issue number
MIN_ISSUE=100

################
# Actual script
################
if [ -z $1 ] || ! [ $1 -eq $1 ] 2>/dev/null || [ $1 -lt $MIN_ISSUE ]; then
	   echo "ERROR: Please enter a valid issue number." >&2
	   echo "\nUSAGE:"
	   echo "\tget issue_number\n"
	   exit 1
fi

tmpDir=$TEMP_FOLDER/LinuxPro$1
mkdir -p $tmpDir

echo Downloading...
i=1
# download the pages until there are images
while HEAD $url$1".pdf/pimages/"$(printf "%04d.jpg" $i) | awk \
	'BEGIN{ret = 1}/Content-Type: image?/{ret = 0}END{exit ret}'
do	
	wget -nc -nv -P $tmpDir $url$1".pdf/pimages/"$(printf "%04d.jpg" $i) &
	[ $((i % MAX_DOWNLOADS)) -eq 0 ] && wait

	i=$((i+1))
done

echo Download complete. Creating pdf...
convert $tmpDir/* LinuxPro$1.pdf

