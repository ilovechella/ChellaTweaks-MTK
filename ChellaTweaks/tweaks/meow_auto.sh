#!/system/bin/sh

# Paths
BASEDIR=/data/adb/modules/chellatweaks
INT=/storage/emulated/0
RWD=$INT/ChellaTweaks
LOG=$RWD/meow_auto.log
MSC=$BASEDIR/tweaks
BAL=$MSC/meow_balance.sh
PERF=$MSC/meow_performance.sh
SAV=$MSC/meow_powersaver.sh

# Ensure the rewrite directory exists
if [ ! -d "$RWD" ]; then
  mkdir -p "$RWD"
fi

# Check applist file
if [ ! -e "$RWD/meowlist.txt" ]; then
  cp -f "$MSC/meowlist.txt" "$RWD"
fi

# Begin AI
sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ Wait ] /g' "$BASEDIR/module.prop"
am start -a android.intent.action.MAIN -e toasttext "Wait for the Tweaks to apply! ฅ⁠^⁠•⁠ﻌ⁠•⁠^⁠ฅ" -n bellavita.toast/.MainActivity

# Set initial AI mode
setprop mtk.mode notset

# Initialize screen status for powersaver
prev_screen_status=""

# Start AI loop
while true; do
    sleep 15

    # Build app filter list
    app_list_filter="grep -o -e applist.app.add"
    while IFS= read -r applist || [[ -n "$applist" ]]; do
        filter=$(echo "$applist" | awk '!/ /')
        if [[ -n "$filter" ]]; then
            app_list_filter+=" -e $filter"
        fi
    done < "$RWD/meowlist.txt"

    # Check if an app from the applist is active
    window=$(dumpsys window | grep package | $app_list_filter | tail -1)

    # Get the current mode once for efficiency
    current_mode=$(getprop mtk.mode)
    
    if [[ -n "$window" ]]; then
        package=$(echo "$window" | awk '{print $NF}')
        cmd device_config put game_overlay "$package" mode=2,downscaleFactor=0.7,fps=120,loadingBoost=999999999

        # Activate performance mode if needed
        if [[ "$current_mode" != "performance" ]]; then
            echo "Switching to Performance mode" >> "$LOG"  # Log this action
            sh "$PERF"
        fi
        sleep 5
    else
        # Activate balance mode if no window is active
        if [[ "$current_mode" != "balance" ]]; then
            echo "Switching to Balance mode" >> "$LOG"  # Log this action
            sh "$BAL"
        fi
        sleep 2
    fi

    # Check for screen status for power saver mode
    screen_status=$(dumpsys window | grep "mScreenOn" | grep false)
    if [[ "$screen_status" != "$prev_screen_status" ]]; then
        prev_screen_status="$screen_status"
        if [[ -n "$screen_status" ]]; then
            # Activate power saver mode if needed
            if [[ "$current_mode" != "powersaver" ]]; then
                echo "Switching to Power Saver mode" >> "$LOG"  # Log this action
                sh "$SAV"
            fi
            sleep 1
        fi
    fi
done
