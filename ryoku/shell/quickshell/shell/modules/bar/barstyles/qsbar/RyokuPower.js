.pragma library

var batteryDataCmd =
    "BAT_PATH=$(upower -e 2>/dev/null | grep BAT | head -n1); [ -n \"$BAT_PATH\" ] || exit 0; " +
    "INFO=$(upower -i \"$BAT_PATH\" 2>/dev/null); [ -n \"$INFO\" ] || exit 0; " +
    "BAT=${BAT_PATH##*/}; BAT=${BAT#battery_}; " +
    "PCT=$(printf '%s\\n' \"$INFO\" | awk '/percentage/ { gsub(\"%\", \"\", $2); print int($2); exit }'); " +
    "STATE=$(printf '%s\\n' \"$INFO\" | awk '/state/ { print $2; exit }'); " +
    "RATE=$(printf '%s\\n' \"$INFO\" | awk '/energy-rate/ { rounded=sprintf(\"%.1f\", $2); sub(/\\.0$/, \"\", rounded); print rounded; exit }'); " +
    "SIZE=$(printf '%s\\n' \"$INFO\" | awk '/energy-full:/ { printf \"%d Wh\", $2; exit }'); " +
    "TIME=$(printf '%s\\n' \"$INFO\" | awk '/time to (empty|full)/ { value=$4; unit=$5; if (unit ~ /^minute/) printf \"%dm\", int(value); else { hours=int(value); minutes=int((value-hours)*60); if (minutes>0) printf \"%dh %dm\", hours, minutes; else printf \"%dh\", hours } exit }'); " +
    "LABEL=$(case \"$STATE\" in charging) echo 'Time to full';; *) echo 'Time left';; esac); " +
    "SYS=/sys/class/power_supply/$BAT; " +
    "FULL=$(cat \"$SYS/charge_full\" 2>/dev/null || cat \"$SYS/energy_full\" 2>/dev/null || echo 0); " +
    "DESIGN=$(cat \"$SYS/charge_full_design\" 2>/dev/null || cat \"$SYS/energy_full_design\" 2>/dev/null || echo 0); " +
    "HEALTH=$(awk -v f=\"$FULL\" -v d=\"$DESIGN\" 'BEGIN{ if(d>0){ h=f*100/d; if(h>100) h=100; printf \"%d%%\", h } }'); " +
    "CYC=$(cat \"$SYS/cycle_count\" 2>/dev/null || echo 0); " +
    "printf '%s|%s|%s|%s|%s|%s|%s|%s|%s\\n' \"$BAT\" \"$PCT\" \"$STATE\" \"$LABEL\" \"$TIME\" \"$RATE\" \"$SIZE\" \"$HEALTH\" \"$CYC\""
