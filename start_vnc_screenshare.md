# Start VNC Screen Share 1st monitor

x11vnc -display :0 -clip 1920x1080+0+0 -listen 127.0.0.1 -nopw -shared -forever