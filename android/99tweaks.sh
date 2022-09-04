#!/system/bin/sh
#
# User tweaks here. (Edited by Pol on 2019-1-13)

# By default, the Linux kernel swaps in 8 pages of memory at a time.
# When using ZRAM, the incremental cost of reading 1 page at a time is 
# negligible and may help in case the device is under extreme memory pressure.
echo 0 > /proc/sys/vm/page-cluster

# Internet speed tweaks
# See also: https://www.speedguide.net/articles/linux-tweaking-121
echo "0" > /proc/sys/net/ipv4/tcp_timestamps;
echo "1" > /proc/sys/net/ipv4/tcp_tw_reuse;
echo "1" > /proc/sys/net/ipv4/tcp_sack;
echo "1" > /proc/sys/net/ipv4/tcp_tw_recycle;
echo "1" > /proc/sys/net/ipv4/tcp_window_scaling;
echo "5" > /proc/sys/net/ipv4/tcp_keepalive_probes;
echo "15" > /proc/sys/net/ipv4/tcp_keepalive_intvl;
echo "15" > /proc/sys/net/ipv4/tcp_fin_timeout;

# Scheduler tweaks
sysctl -w kernel.sched_min_granularity_ns=2000000
sysctl -w kernel.sched_latency_ns=10000000
sysctl -w kernel.sched_wakeup_granularity_ns=2500000
sysctl -w kernel.sched_child_runs_first=0
sysctl -w kernel.sched_tunable_scaling=1
sysctl -w kernel.sched_migration_cost=1000000
sysctl -w kernel.sched_nr_migrate=48
echo NO_RT_RUNTIME_SHARE > /sys/kernel/debug/sched_features

# Interactive governor tweaks
chown root:root /sys/devices/system/cpu/cpufreq/interactive/io_is_busy
chmod 600 /sys/devices/system/cpu/cpufreq/interactive/io_is_busy

chown root:root /sys/devices/system/cpu/cpufreq/interactive/sampling_down_factor
chmod 600 /sys/devices/system/cpu/cpufreq/interactive/sampling_down_factor

chown root:root /sys/devices/system/cpu/cpufreq/interactive/target_loads
chmod 600 /sys/devices/system/cpu/cpufreq/interactive/target_loads

chown root:root /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load
chmod 600 /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load

echo 0 > /sys/devices/system/cpu/cpufreq/interactive/io_is_busy
echo 1 > /sys/devices/system/cpu/cpufreq/interactive/sampling_down_factor
echo "75 600000:80 998400:95" > /sys/devices/system/cpu/cpufreq/interactive/target_loads
echo 95 > /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load

# Reclaim some memory from the cache until 1GB of internal storage is free
pm trim-caches 1G
