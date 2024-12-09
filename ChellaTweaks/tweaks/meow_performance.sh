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
LOG=/storage/emulated/0/ChellaTweaks/meow_performance.log
path="/sys/devices/system/cpu/cpu0/cpufreq"
thermal_limits="/sys/devices/virtual/thermal/thermal_message/cpu_limits"

apply_setting() {
    if [ -e "$1" ]; then
        echo "$2" > "$1" && echo "Applied $2 to $1" || echo "Failed to apply $2 to $1"
    else
        echo "Skipped: $1 not available"
    fi
}

# CPU Thermal Limits
chmod 644 /sys/devices/virtual/thermal/thermal_message/cpu_limits
affected_cpus=$(awk '{print $1}' /sys/devices/system/cpu/cpu0/cpufreq/affected_cpus)
cpu_maxfreq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
chmod 000 /sys/devices/virtual/thermal/thermal_message/cpu_limits
apply_setting "/sys/devices/virtual/thermal/thermal_message/cpu_limits" "cpu${affected_cpus} ${cpu_maxfreq}"

# Workqueue Settings
apply_setting /sys/module/workqueue/parameters/power_efficient "N"
apply_setting /sys/module/workqueue/parameters/disable_numa "N"

# PPM Settings
apply_setting /proc/ppm/enabled 1
for i in {0..9}; do
    apply_setting "/proc/ppm/policy_status" "$i 0"
done
apply_setting "/proc/ppm/policy_status" "7 1"

# Power and CPU Settings
cmd power set-adaptive-power-saver-enabled false
cmd power set-fixed-performance-mode-enabled true

# Enable All CPU Cores
for cpu in /sys/devices/system/cpu/cpu[0-7]; do
    if [ -f "$cpu/online" ]; then
        echo 1 > "$cpu/online"
    fi
done

# Set CPU Frequency Governors
for policy in /sys/devices/system/cpu/cpufreq/policy*; do
    apply_setting "$policy/scaling_governor" "performance"
done

# Set Device Governors to Performance
for device in /sys/class/devfreq/*; do
    if [ -f "$device/governor" ]; then
        apply_setting "$device/governor" "performance"
    fi
done

# GPU Frequency Optimization
if [ -d /proc/gpufreq ]; then
    gpu_freq=$(awk '/freq = [0-9]+/ {print $3}' /proc/gpufreq/gpufreq_opp_dump | sort -nr | head -n 1)
    apply_setting "/proc/gpufreq/gpufreq_opp_freq" "$gpu_freq"
elif [ -d /proc/gpufreqv2 ]; then
    apply_setting "/proc/gpufreqv2/fix_target_opp_index" "00"
fi

# Cluster Frequency Management
for path in /sys/devices/system/cpu/cpufreq/policy*; do
    max_freq=$(awk '{print $1}' "$path/scaling_available_frequencies")
    min_freq=$(awk '{print $NF}' "$path/scaling_available_frequencies")
    cluster=0
    apply_setting "/proc/ppm/policy/hard_userlimit_min_cpu_freq" "$cluster $min_freq"
    apply_setting "/proc/ppm/policy/hard_userlimit_max_cpu_freq" "$cluster $max_freq"
    cluster=$((cluster + 1))
done

# GPU-Specific Power Settings
apply_setting /sys/class/misc/mali0/device/power_policy "coarse_demand"
if [ -f "/proc/gpufreq/gpufreq_power_limited" ]; then
    for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
        apply_setting "/proc/gpufreq/gpufreq_power_limited" "$setting 1"
    done
fi
apply_setting /sys/kernel/ged/hal/custom_upbound_gpu_freq 1
apply_setting /sys/kernel/ged/hal/custom_boost_gpu_freq 1

# Scheduler Settings
apply_setting /proc/sys/kernel/perf_cpu_time_max_percent 5
apply_setting /proc/sys/kernel/sched_child_runs_first 1
apply_setting /proc/sys/kernel/sched_energy_aware 0
apply_setting /proc/sys/kernel/sched_schedstats 0

# Block Device Queue Settings
for device in /sys/block/*; do
    if [ -d "$device/queue" ]; then
        apply_setting "$device/queue/nr_requests" 128
        apply_setting "$device/queue/read_ahead_kb" 2048
    fi
done

# Clear Cache
echo 3 > /proc/sys/vm/drop_caches

# Drop Free Ram
echo 3 > /proc/sys/vm/drop_caches
am force-stop com.instagram.android
am force-stop com.android.vending
am force-stop app.grapheneos.camera
am force-stop com.google.android.gm
am force-stop com.google.android.apps.youtube.creator
am force-stop com.dolby.ds1appUI
am force-stop com.google.android.youtube
am force-stop com.twitter.android
am force-stop nekox.messenger
am force-stop com.shopee.id
am force-stop com.vanced.android.youtube
am force-stop com.speedsoftware.rootexplorer
am force-stop com.bukalapak.android
am force-stop org.telegram.messenger
am force-stop ru.zdevs.zarchiver
am force-stop com.android.chrome
am force-stop com.google.android.GoogleCameraEng
am force-stop com.facebook.orca
am force-stop com.lazada.android
am force-stop com.android.camera
am force-stop com.android.settings
am force-stop com.franco.kernel
am force-stop com.telkomsel.telkomselcm
am force-stop com.facebook.katana
am force-stop com.instagram.android
am force-stop com.facebook.lite

# Stop Unnecessary Services
stop logd
stop statsd
stop log

# Set performance
setprop mtk.mode performance
echo " •> Meow Gaming activated at $(date "+%H:%M:%S")" >> $LOG

# Report
sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ Meow Gaming ] /g' "$BASEDIR/module.prop"
am start -a android.intent.action.MAIN -e toasttext "Meow Gaming" -n bellavita.toast/.MainActivity

exit 0