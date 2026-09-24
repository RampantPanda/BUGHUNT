# Keep clipboard content after app closes
wl-clip-persist --clipboard regular --reconnect-tries 0 &

# Watch clipboard and store history
# wl-paste --type text --watch cliphist store &

# watch idle
swayidle -w \
    timeout 300 "lock-screen.sh" \
    timeout 600 "wlopm --off '*'" \
        resume "wlopm --on '*'" \
    timeout 1800 'systemctl suspend' \
    before-sleep "lock-screen.sh" \
    after-resume "wlopm --on '*'" &
# bar
waybar>/dev/null &
