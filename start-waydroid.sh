#!/bin/bash

# ==============================================================================
# Script: start-waydroid.sh
# Location: /home/smabari/Documents/smacodes/scripts/start-waydroid.sh
# Description: Launches Waydroid inside a locked Weston container on X11.

# COMMAND TO ADD THIS SCRIPT TO PATH TO USE FROM TERMINAL DIRECTLY BY FILENAME(without file extention)
# 1) Make script executable:
#    chmod +x ~/Documents/smacodes/scripts/start-waydroid.sh
#
# 2) Add command shortcut to ~/.bashrc:
#    echo "alias start-waydroid='~/Documents/smacodes/scripts/start-waydroid.sh'" >> ~/.bashrc
#
# 3) Reload terminal configuration:
#    source ~/.bashrc
# ==============================================================================

# [1] Terminate stale sessions and socket files
waydroid session stop 2>/dev/null
pkill -9 -f weston 2>/dev/null
rm -f /run/user/$UID/wayland-* 2>/dev/null
sleep 1

# [2] Rebuild network bridge & enable host IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null
sudo systemctl restart waydroid-container
sleep 2

# [3] Set display environment variables
unset WAYLAND_DISPLAY
export DISPLAY=${DISPLAY:-:0}
export XDG_RUNTIME_DIR="/run/user/$UID"

# [4] Launch Weston with floating 1920x1020 resolution (Prevents auto-maximization)
# MODIFICATION: Height reduced to 1020px to prevent Cinnamon WM from triggering maximized window snapping
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

export WAYLAND_DISPLAY=wayland-0

# [6] Inject fallback DNS to guarantee internet stability inside Android
waydroid prop set net.dns1 1.1.1.1 2>/dev/null
waydroid prop set net.dns2 8.8.8.8 2>/dev/null
waydroid prop set persist.waydroid.clipboard true 2>/dev/null

# [7] Launch Waydroid UI
echo "Launching Waydroid (Locked Floating Window)..."
waydroid show-full-ui