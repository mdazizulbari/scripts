#!/bin/bash

echo "[1/6] Gracefully stopping active Waydroid sessions..."
waydroid session stop 2>/dev/null
sleep 1

echo "[2/6] Restarting Waydroid container service..."
sudo systemctl restart waydroid-container
sleep 1

echo "[3/6] Terminating existing Weston instances..."
pkill -9 -f weston 2>/dev/null
rm -f /run/user/$UID/wayland-* 2>/dev/null
sleep 1

echo "[4/6] Setting up display environment..."
unset WAYLAND_DISPLAY
export DISPLAY=${DISPLAY:-:0}
export XDG_RUNTIME_DIR="/run/user/$UID"

echo "[5/6] Launching Weston window..."
# Removed invalid --resizable flag so Weston doesn't crash on launch
weston --backend=x11-backend.so --socket=wayland-0 --width=1280 --height=720 > /tmp/weston.log 2>&1 &

echo "[6/6] Waiting for Wayland socket..."
# Loop until socket file is created (timeout after 10 seconds)
counter=0
while [ ! -S "/run/user/$UID/wayland-0" ]; do
    sleep 0.5
    counter=$((counter+1))
    if [ $counter -gt 20 ]; then
        echo "Error: Weston failed to start. Logs from /tmp/weston.log:"
        cat /tmp/weston.log
        exit 1
    fi
done

export WAYLAND_DISPLAY=wayland-0

# Set DNS fallback property for container internet access
waydroid prop set net.dns1 8.8.8.8 2>/dev/null

echo "Launching Waydroid..."
waydroid show-full-ui
