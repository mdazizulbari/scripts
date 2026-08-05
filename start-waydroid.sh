#!/bin/bash

# ==============================================================================
# Script: start-waydroid.sh
# Location: /home/smabari/Documents/smacodes/scripts/start-waydroid.sh
# Description: Launches Waydroid inside a locked Weston container on X11.
# ==============================================================================

# Cleanup lingering processes when exiting
trap 'pkill -9 -f weston 2>/dev/null; waydroid session stop 2>/dev/null' EXIT INT TERM

# [1] Terminate stale sessions and socket files
waydroid session stop 2>/dev/null
pkill -9 -f weston 2>/dev/null
rm -f /run/user/$UID/wayland-* 2>/dev/null
sleep 1

# [2] Rebuild network bridge & enable host IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null
sudo systemctl restart waydroid-container
sleep 2

# [3] Set display environment variables (X11 only)
unset WAYLAND_DISPLAY
export DISPLAY=${DISPLAY:-:0}
export XDG_RUNTIME_DIR="/run/user/$UID"

# [4] Launch Weston with floating 1920x1020 resolution
weston --backend=x11-backend.so --socket=wayland-0 --width=1920 --height=1020 --no-config > /tmp/weston.log 2>&1 &

# [5] Block execution until the socket file is ready
counter=0
while [ ! -S "/run/user/$UID/wayland-0" ]; do
    sleep 0.5
    counter=$((counter+1))
    if [ $counter -gt 20 ]; then
        echo "Error: Weston failed to start. Logs:"
        cat /tmp/weston.log
        exit 1
    fi
done

# [6] Inject DNS configuration
waydroid prop set net.dns1 1.1.1.1 2>/dev/null
waydroid prop set net.dns2 8.8.8.8 2>/dev/null

# [7] Hide Waydroid Android apps from the PC app menu
for file in ~/.local/share/applications/waydroid.*.desktop; do
    if [ -f "$file" ] && ! grep -q "NoDisplay=true" "$file"; then
        sed -i '/^\[Desktop Entry\]/a NoDisplay=true' "$file"
    fi
done

# [8] Launch Waydroid UI with scoped Wayland variable
echo "Launching Waydroid..."
WAYLAND_DISPLAY=wayland-0 waydroid show-full-ui