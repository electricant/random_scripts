#!/system/bin/sh
#
# Switch CPUs on or off depending on the screen state.
# Also limit the maximum frequencies

doScreenOn()
{
	# Enable all cpu cores
	for x in /sys/devices/system/cpu/cpu[1-9]*/online; do
		chmod 600 "$x"
		echo 1 >"$x"
		chmod 440 "$x"
	done
	
	# set maximum frequency to 1190400
	for x in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_max_freq; do
		chmod 600 "$x"
		echo 1190400 >"$x"
		chmod 440 "$x"
	done
}

doScreenOff()
{
	# Disable all cpu cores except cpu0
	for x in /sys/devices/system/cpu/cpu[1-9]*/online; do
		chmod 600 "$x"
		echo 0 >"$x"
		chmod 440 "$x"
	done
	
	# set maximum frequency to 998400
	for x in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_max_freq; do
		chmod 600 "$x"
		echo 998400 >"$x"
		chmod 440 "$x"
	done
}

########
# Main #
########
case $1 in
	on)
		doScreenOn
		;;
	off)
		doScreenOff
		;;
	*)
		echo "Whaaat??"
		echo "Got: $1, expected 'on' or 'off'"
		;;
esac
