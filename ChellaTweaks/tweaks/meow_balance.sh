#!/system/bin/sh
sync

# Functions
read_file() {
  if [[ -f $1 ]]; then
    [[ -r $1 ]] || chmod +r "$1"
    cat "$1"
  else
    echo "File '$1' not found"
  fi
}

# Path
BASEDIR=/data/adb/modules/chellatweaks
LOG=/storage/emulated/0/ChellaTweaks/meow_balance.log

# Helper function for writing with checks
apply_setting() {
    if [ -e "$1" ]; then
        echo "$2" > "$1" && echo "Applied $2 to $1" || echo "Failed to apply $2 to $1"
    else
        echo "Skipped: $1 not available"
    fi
}

# Ensure permissions for critical files
chmod 644 /sys/devices/virtual/thermal/thermal_message/cpu_limits

# Workqueue settings
apply_setting /sys/module/workqueue/parameters/power_efficient "Y"
apply_setting /sys/module/workqueue/parameters/disable_numa "Y"

# PPM settings
apply_setting /proc/ppm/enabled 1
for i in {0..9}; do
    apply_setting "/proc/ppm/policy_status" "$i 0"
done
apply_setting "/proc/ppm/policy_status" "1 6 7 9"

# Power and CPU settings
cmd power set-adaptive-power-saver-enabled true
cmd power set-fixed-performance-mode-enabled false

# Enable all CPU cores dynamically
cpu_count=$(nproc)
for cpu in $(seq 0 $((cpu_count - 1))); do
    if [ -f "/sys/devices/system/cpu/cpu${cpu}/online" ]; then
        echo 1 > "/sys/devices/system/cpu/cpu${cpu}/online"
    fi
done

# CPU frequency governors
for policy in /sys/devices/system/cpu/cpufreq/policy*; do
    apply_setting "$policy/scaling_governor" "schedutil"
done

# Device governors
for device in /sys/class/devfreq/*; do
    if [ -f "$device/governor" ]; then
        apply_setting "$device/governor" "simple_ondemand"
    fi
done

# GPU frequency
if [ -d /proc/gpufreq ]; then
    apply_setting "/proc/gpufreq/gpufreq_opp_freq" "0"
elif [ -d /proc/gpufreqv2 ]; then
    apply_setting "/proc/gpufreqv2/fix_target_opp_index" "-1"
fi

# Apply cluster frequency management dynamically
cluster=0
for path in /sys/devices/system/cpu/cpufreq/policy*; do
    max_freq=$(awk '{print $1}' "$path/scaling_available_frequencies" 2>/dev/null)
    min_freq=$(awk '{print $NF}' "$path/scaling_available_frequencies" 2>/dev/null)

    if [ -n "$max_freq" ] && [ -n "$min_freq" ]; then
        apply_setting "/proc/ppm/policy/hard_userlimit_min_cpu_freq" "$cluster $min_freq"
        apply_setting "/proc/ppm/policy/hard_userlimit_max_cpu_freq" "$cluster $max_freq"
    fi

    cluster=$((cluster + 1))
done

# GPU-specific power settings
apply_setting /sys/class/misc/mali0/device/power_policy "coarse_demand"
if [ -f "/proc/gpufreq/gpufreq_power_limited" ]; then
    for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
        apply_setting "/proc/gpufreq/gpufreq_power_limited" "$setting 0"
    done
fi
apply_setting /sys/kernel/ged/hal/custom_upbound_gpu_freq 0
apply_setting /sys/kernel/ged/hal/custom_boost_gpu_freq 0

# Disable EAS
apply_setting /sys/devices/system/cpu/eas/enable 1
apply_setting /proc/cpufreq/cpufreq_power_mode 0
apply_setting /proc/cpufreq/cpufreq_cci_mode 0
apply_setting /proc/cpufreq/cpufreq_sched_disable 1
apply_setting /sys/kernel/eara_thermal/enable 1
apply_setting /proc/pbm/pbm_stop "stop 0"

# CPUSET settings
for cs in /dev/cpuset/*; do
    apply_setting "$cs/cpus" "0-$((cpu_count - 1))"
    apply_setting "$cs/background/cpus" "0-5"
    apply_setting "$cs/system-background/cpus" "0-4"
    apply_setting "$cs/foreground/cpus" "0-$((cpu_count - 1))"
    apply_setting "$cs/top-app/cpus" "0-$((cpu_count - 1))"
    apply_setting "$cs/restricted/cpus" "0-5"
    apply_setting "$cs/camera-daemon/cpus" "0-$((cpu_count - 1))"
done

# Display low power settings
for dlp in /proc/displowpower/*; do
    apply_setting "$dlp/hrt_lp" 1
    apply_setting "$dlp/idlevfp" 1
    apply_setting "$dlp/idletime" 100
done

# Scheduler settings
apply_setting /proc/sys/kernel/perf_cpu_time_max_percent 25
apply_setting /proc/sys/kernel/sched_child_runs_first 1
apply_setting /proc/sys/kernel/sched_energy_aware 1
apply_setting /proc/sys/kernel/sched_schedstats 1

# Block device queue settings
for device in /sys/block/*; do
    if [ -d "$device/queue" ]; then
        apply_setting "$device/queue/nr_requests" 64
        apply_setting "$device/queue/read_ahead_kb" 128
    fi
done

# Performance Manager
apply_setting /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_fg_boost 50
apply_setting /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_ta_boost 50
apply_setting /proc/perfmgr/boost_ctrl/cpu_ctrl/perfserv_all_cpu_deisolated 0
apply_setting /proc/perfmgr/syslimiter/syslimiter_force_disable 0
apply_setting /proc/perfmgr/boost_ctrl/cpu_ctrl/cfp_enable 0
apply_setting /proc/perfmgr/boost_ctrl/cpu_ctrl/cfp_up_time 0

# Virtual memory settings
echo 120 > /proc/sys/vm/vfs_cache_pressure
echo 0 > /proc/sys/vm/compaction_proactiveness
echo 80 > /proc/sys/vm/swappiness

# FPSGO
apply_setting /sys/pnpmgr/fpsgo_boost/boost_enable "default_activity"

# Iowait
apply_setting /sys/devices/system/cpu/cpufreq/policy0/schedutil/iowait_boost_enable 0
apply_setting /sys/devices/system/cpu/cpufreq/policy4/schedutil/iowait_boost_enable 0

# Set balance
setprop mtk.mode balance
echo " •> Meow Balance set activated at $(date "+%H:%M:%S")" >> $LOG

# Report
sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ Meow Balance ] /g' "$BASEDIR/module.prop"
am start -a android.intent.action.MAIN -e toasttext "Meow Balance" -n bellavita.toast/.MainActivity

exit 0
