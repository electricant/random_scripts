#!/system/bin/sh
#
# Governor tweaks from pol
#
INTERACTIVE_PATH="/sys/devices/system/cpu/cpufreq/interactive"
# Forbid system to mess with governor settings
chown root:root $INTERACTIVE_PATH/target_loads
chown root:root $INTERACTIVE_PATH/go_hispeed_load

# Actual settings
echo 20000 > $INTERACTIVE_PATH/timer_rate
echo 20000 > $INTERACTIVE_PATH/boostpulse_duration
echo 20000 > $INTERACTIVE_PATH/min_sample_time
echo 0     > $INTERACTIVE_PATH/io_is_busy
echo '-1'  > $INTERACTIVE_PATH/timer_slack
echo 95    > $INTERACTIVE_PATH/go_hispeed_load
echo 40000 > $INTERACTIVE_PATH/above_hispeed_delay
echo 2     > $INTERACTIVE_PATH/sampling_down_factor
echo '90 338400:80 998400:99' > $INTERACTIVE_PATH/target_loads
#echo 300000 > $INTERACTIVE_PATH/hispeed_freq

# The existing power saving loadbalancer CONFIG_SCHED_MC attempts to run
# the workload in the system on minimum number of CPU packages and tries
# to keep rest of the CPU packages idle for longer duration. Thus
# consolidating workloads to fewer packages help other packages to be in
# idle state and save power.
#
# 0 - off
# 1 - balanced
# 2 - aggressive (degrades performance for higher power savings)
echo 1 > /sys/devices/system/cpu/sched_mc_power_savings
