#!/bin/bash
#
# Setup traffic shaping for this device.
# The classes are simple as I'm am intrested to keep interactivity high by
# limiting the maximum throughput

SPEED_DOWN="24Mbit"
BURST_DOWN="24kb"
SPEED_UP="12Mbit"
BURST_UP="12kb"
LATENCY="100ms"
# see https://linux.die.net/man/8/tc-prio
PRIOMAP="1 1 1 1 1 1 0 0 1 1 1 1 1 1 1 1"

# Reset interfaces just to be safe
tc qdisc del dev eth0 root
tc qdisc del dev eth1 root

# Download is the data going out from eth0
# Use prio classful queue with two bands and route everything by default to 1:2
# 1:1 is for low latency 1:2 is for the rest and is connected to a tbf
tc qdisc add dev eth0 root handle 1: prio bands 2 priomap $PRIOMAP
tc qdisc add dev eth0 parent 1:1 handle 10: pfifo_fast
tc qdisc add dev eth0 parent 1:2 handle 20: tbf rate $SPEED_DOWN \
	latency $LATENCY burst $BURST_DOWN
# send packets marked as 10 to the pfifo for low latency
tc filter add dev eth0 parent 1:0 protocol ip prio 10 handle 10 fw flowid 1:1

# Upload is the data going out of eth1 (same as above)
tc qdisc add dev eth1 root handle 1: prio bands 2 priomap $PRIOMAP
tc qdisc add dev eth1 parent 1:1 handle 10: pfifo_fast
tc qdisc add dev eth1 parent 1:2 handle 20: tbf rate $SPEED_UP \
	latency $LATENCY burst $BURST_UP
tc filter add dev eth1 parent 1:0 protocol ip prio 10 handle 10 fw flowid 1:1

# mark high priority packets as 10 (works on both interfaces)
iptables -t mangle -A POSTROUTING -p tcp \
	--tcp-flags URG,ACK,PSH,RST,SYN,FIN ACK -m length --length 40:64 \
	-j MARK --set-mark 10
iptables -t mangle -A POSTROUTING -p udp -j MARK --set-mark 10
