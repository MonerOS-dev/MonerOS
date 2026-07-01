if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec sudo /usr/local/bin/udinit
fi
