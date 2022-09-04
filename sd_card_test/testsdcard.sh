#!/bin/sh -e

DEV="/dev/mmcblk0"
MOUNTPOINT="./mnt"

# First print some info
fdisk -l $DEV

# Then perform a destructive test on the device
echo ""
f3probe --destructive --time-ops $DEV

# Get first partition name, format it, mount it and run read/write tests
part=$(fdisk -l $DEV | awk 'END {print $1}')
echo ""
echo First partition is $part, formatting it to FAT32

umount $part || true
mkfs.fat -F32 $part

echo ""
echo Performing R/W test on $part

mount $part $MOUNTPOINT
f3write $MOUNTPOINT

umount $MOUNTPOINT

mount $part $MOUNTPOINT
f3read $MOUNTPOINT

# Done. Unmount
umount $MOUNTPOINT
