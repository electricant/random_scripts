#!/usr/bin/env bash
#
# Dump the systemd services in the list below

# Treat unset variables and parameters other than the special parameters ‘@’ or
# ‘*’ as an error when performing parameter expansion. An 'unbound variable'
# error message will be written to the standard error, and a non-interactive
# shell will exit.
set -o nounset

# Exit immediately if a pipeline returns non-zero.
set -o errexit

# Print a helpful message if a pipeline with non-zero exit code causes the
# script to exit as described above. 
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR
set -o errtrace

# Return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
set -o pipefail

# List of services to dump
services=(
	"lighttpd-chroot.service"
	"postgresql-chroot.service"
	"transmission-daemon-chroot.service"
	"unbound-chroot.service"
)

for s in "${services[@]}"; do
	echo $s
	systemctl cat $s > $s
done

