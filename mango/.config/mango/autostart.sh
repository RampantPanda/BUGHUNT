# Keep clipboard content after app closes
wl-clip-persist --clipboard regular --reconnect-tries 0 &

# Watch clipboard and store history
wl-paste --type text --watch cliphist store &

# watch idle
swayidle -w \
    timeout 600 "$HOME/scripts/gtklock.sh" \
    timeout 900 'wlr-dpms off' \
        resume 'wlr-dpms on' \
    before-sleep "$HOME/scripts/gtklock.sh" &

# bar
waybar>/dev/null &
