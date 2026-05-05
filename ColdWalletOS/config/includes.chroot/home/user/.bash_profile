if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec /usr/local/bin/cwinit
fi
