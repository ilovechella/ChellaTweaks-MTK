#!/system/bin/sh
#Chella Tweaks
MODDIR=${0%/*}

#boot for service.sh
while [ "$(getprop sys.boot_completed | tr -d '\r')" != "1" ]; do
    sleep 5
done

su -lp 2000 -c "cmd notification post -S bigtext -t 'Chella Tweaks' tag 'Wait for the Tweaks to apply! ฅ⁠^⁠•⁠ﻌ⁠•⁠^⁠ฅ'" >/dev/null 2>&1

# Function to apply a setting
apply_setting() {
    local path="$1"
    local value="$2"
    if [ -w "$path" ]; then
        echo "$value" > "$path"
        echo "Applied: $path = $value"
    else
        echo "Skipped: $path (not writable or doesn't exist)"
    fi
}

# MTK FPSGo and GPU Boost Optimized Parameters
apply_setting "/sys/kernel/fpsgo/fstb/boost_ta"                "1"
apply_setting "/sys/kernel/fpsgo/fbt/boost_VIP"                "1"
apply_setting "/sys/kernel/fpsgo/fbt/llf_task_policy"          "2"
apply_setting "/sys/kernel/ged/hal/gpu_boost_level"            "90"
apply_setting "/sys/kernel/fpsgo/fbt/thrm_temp_th"             "85000"
apply_setting "/sys/kernel/fpsgo/fstb/gpu_loading_policy"      "1"

# Advanced GED Performance Parameters
apply_setting "/sys/module/ged/parameters/gpu_dvfs_enable"     "1"
apply_setting "/sys/module/ged/parameters/gx_game_mode"        "1"
apply_setting "/sys/module/ged/parameters/ged_boost_enable"    "1"
apply_setting "/sys/module/ged/parameters/gpu_boost_enable"    "1"

# MTK FPSGo Performance Tuning
apply_setting "/sys/module/mtk_fpsgo/parameters/boost_affinity"     "1"
apply_setting "/sys/module/mtk_fpsgo/parameters/xgf_uboost"        "1"
apply_setting "/sys/module/mtk_fpsgo/parameters/xgf_stddev_multi"  "3"
apply_setting "/sys/module/mtk_fpsgo/parameters/gcc_up_sec_pct"    "85"

# Intelligent I/O Scheduler Optimization
for device in /sys/block/*; do
    queue="$device/queue"
    [ -f "$queue/scheduler" ]   && apply_setting "$queue/scheduler"   "deadline"
    [ -f "$queue/nomerges" ]    && apply_setting "$queue/nomerges"    "2"
    [ -f "$queue/rq_affinity" ] && apply_setting "$queue/rq_affinity" "2"
    [ -f "$queue/read_ahead_kb" ] && apply_setting "$queue/read_ahead_kb" "256"
done

# Kernel Performance Configuration
apply_setting "/proc/sys/kernel/printk"           "0 0 0 0"
apply_setting "/proc/sys/kernel/sched_child_runs_first" "1"
apply_setting "/proc/sys/kernel/sched_autogroup_enabled" "1"

# CPU Core Management
for cpu in /sys/devices/system/cpu/cpu[1-7]; do
    apply_setting "$cpu/online" "1"
    apply_setting "$cpu/cpufreq/scaling_governor" "performance"
done

# Virtual Memory Intelligent Tuning
apply_setting "/proc/sys/vm/watermark_scale_factor"   "1"
apply_setting "/proc/sys/vm/watermark_boost_factor"   "25"
apply_setting "/proc/sys/vm/extra_free_kbytes"        "32768"
apply_setting "/proc/sys/vm/min_free_kbytes"          "16384"

# Thermal Management Optimization
for zone in /sys/class/thermal/thermal_zone*; do
    apply_setting "$zone/trip_point_0_temp" "105000"
    apply_setting "$zone/trip_point_1_temp" "115000"
done

# GPU Power Management
apply_setting "/sys/kernel/ged/hal/dcs_mode" "55"
apply_setting "/sys/module/ged/parameters/gpu_idle" "1"
apply_setting "/sys/module/ged/parameters/gpu_dvfs_loading_mode" "1"

# Background Process Management
apply_setting "/proc/sys/kernel/sched_rt_runtime_us" "950000"
apply_setting "/proc/sys/kernel/sched_rt_period_us"  "1000000"

# Memory Allocation Optimization
apply_setting "/proc/sys/vm/page-cluster" "0"
apply_setting "/proc/sys/vm/swappiness" "30"
apply_setting "/proc/sys/vm/vfs_cache_pressure" "50"

# Performance Boost Configurations
apply_setting "/sys/module/mtk_fpsgo/parameters/gcc_enable" "1"
apply_setting "/sys/module/mtk_fpsgo/parameters/gcc_hwui_hint" "1"
apply_setting "/proc/touch_boost/enable" "1"
apply_setting "/proc/touch_boost/boost_duration" "800"

# Additional MTK-Specific Optimizations
apply_setting "/sys/module/mtk_fpsgo/parameters/boost_LR" "1"
apply_setting "/sys/pnpmgr/install" "1"
apply_setting "/sys/pnpmgr/mwn" "1"

# CPU Adjustments
for cpu in /sys/devices/system/cpu/cpu[1-7] /sys/devices/system/cpu/cpu1[0-7];
do
    apply_setting "$cpu/core_ctl/enable" "1"
    apply_setting "$cpu/core_ctl/core_ctl_boost" "1"
done

sleep 1

su -lp 2000 -c "cmd notification post -S bigtext -t 'Chella Tweaks' tag 'Alright, Your good to go Meow ฅ⁠^⁠•⁠ﻌ⁠•⁠^⁠ฅ'" >/dev/null 2>&1

nohup sh $MODDIR/tweaks/meow_auto.sh &
