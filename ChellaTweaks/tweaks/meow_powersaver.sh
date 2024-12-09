#!/system/bin/sh
sync

# Functions
read_file(){
  if [[ -f $1 ]]; then
    if [[ ! -r $1 ]]; then
      chmod +r "$1"
    fi
    cat "$1"
  else
    echo "File $1 not found"
  fi
}

# Path
BASEDIR=/data/adb/modules/chellatweaks
LOG=/storage/emulated/0/ChellaTweaks/meow_powersaver.log

apply_setting() {
    if [ -e "$1" ]; then
        echo "$2" > "$1" && echo "Applied $2 to $1" || echo "Failed to apply $2 to $1"
    else
        echo "Skipped: $1 not available"
    fi
}

# Disable Specific CPU Cores
for cpu in /sys/devices/system/cpu/cpu2 /sys/devices/system/cpu/cpu3; do
    if [ -f "$cpu/online" ]; then
        echo 0 > "$cpu/online"
    fi
done

# CPU Frequency Governors
for policy in /sys/devices/system/cpu/cpufreq/policy*; do
    apply_setting "$policy/scaling_governor" "powersave"
done

# Device Governors
for device in /sys/class/devfreq/*; do
    if [ -f "$device/governor" ]; then
        apply_setting "$device/governor" "powersave"
    fi
done

# GPU Frequency
if [ -d /proc/gpufreq ]; then
    min_gpu_freq=$(awk '/freq = [0-9]+/ {print $3}' /proc/gpufreq/gpufreq_opp_dump | sort -n | head -n 1)
    apply_setting "/proc/gpufreq/gpufreq_opp_freq" "$min_gpu_freq"
elif [ -d /proc/gpufreqv2 ]; then
    apply_setting "/proc/gpufreqv2/fix_target_opp_index" "-1"
fi

# Scheduler Settings for Power Efficiency
apply_setting /proc/sys/kernel/perf_cpu_time_max_percent 50
apply_setting /proc/sys/kernel/sched_child_runs_first 0
apply_setting /proc/sys/kernel/sched_energy_aware 1
apply_setting /proc/sys/kernel/sched_schedstats 1

# Virtual Memory Settings
echo 150 > /proc/sys/vm/vfs_cache_pressure
echo 0 > /proc/sys/vm/compaction_proactiveness
echo 90 > /proc/sys/vm/swappiness

# Display Low Power Settings
for dlp in /proc/displowpower; do
    apply_setting "$dlp/hrt_lp" 1
    apply_setting "$dlp/idlevfp" 1
    apply_setting "$dlp/idletime" 300
done

# CPUSET for Energy Efficiency
for cs in /dev/cpuset; do
    apply_setting "$cs/cpus" "0-1"
    apply_setting "$cs/background/cpus" "0"
    apply_setting "$cs/system-background/cpus" "0"
    apply_setting "$cs/foreground/cpus" "0-1"
    apply_setting "$cs/top-app/cpus" "0-1"
    apply_setting "$cs/restricted/cpus" "0"
done

# Block Device Queue Settings
for device in /sys/block/*; do
    if [ -d "$device/queue" ]; then
        apply_setting "$device/queue/nr_requests" 64
        apply_setting "$device/queue/read_ahead_kb" 128
    fi
done

# GPU-Specific Power Settings
apply_setting /sys/class/misc/mali0/device/power_policy "coarse_demand"
if [ -f "/proc/gpufreq/gpufreq_power_limited" ]; then
    for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
        apply_setting "/proc/gpufreq/gpufreq_power_limited" "$setting 0"
    done
fi

# Turn Off Background Apps to Conserve Energy
apps_to_stop=(
    "com.instagram.android"
    "com.facebook.katana"
    "com.android.vending"
    "com.google.android.youtube"
    "org.telegram.messenger"
    "com.android.chrome"
)
for app in "${apps_to_stop[@]}"; do
    am force-stop "$app"
done

# Clear Cache to Free Up Memory
echo 3 > /proc/sys/vm/drop_caches

# Set powersave
setprop mtk.mode powersaver
echo " •> Meow Powersaver activated at $(date "+%H:%M:%S")" >> $LOG

# Throw
sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[  Meow Powersaver ] /g' "$BASEDIR/module.prop"
am start -a android.intent.action.MAIN -e toasttext " Meow Powersaver" -n bellavita.toast/.MainActivity

exit 0