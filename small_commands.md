# Small Commands


### Start VNC Screen Share 1st monitor
```
x11vnc -display :0 -clip 1920x1080+0+0 -listen 127.0.0.1 -nopw -shared -forever -viewonly
```


### Mirrors a physical USB-connected Android phone to your PC while keeping the device awake and turning off its physical screen
```
scrcpy -d -S -w
```
scrcpy: Launches the screen mirroring and audio streaming application.

-d (--select-usb): Forces scrcpy to target the physical USB-connected device, bypassing any running emulators, Wi-Fi connections, or offline TCP/IP instances.

-S (--turn-screen-off): Mutes the physical display of the phone immediately upon connection to reduce battery drain and thermal throttling while preserving the live mirror on your PC.

-w (--stay-awake): Prevents the Android system from going to sleep or locking while the scrcpy session remains active.












