#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# Neo-Wire Fuzzel application icon generator
# ------------------------------------------------------------

PRIMARY="#75e3ee"

THEME="$HOME/dotfiles/icons-neo/.local/share/icons/Neo-Wire"
APPS="$THEME/scalable/apps"
INDEX="$THEME/index.theme"

FUZzel_CONFIG="$HOME/.config/fuzzel/fuzzel.ini"

# ------------------------------------------------------------
# Sanity checks
# ------------------------------------------------------------

if [[ ! -d "$THEME" ]]; then
    echo "ERROR: Neo-Wire theme not found:"
    echo "       $THEME"
    exit 1
fi

if [[ ! -f "$INDEX" ]]; then
    echo "ERROR: Missing:"
    echo "       $INDEX"
    exit 1
fi

mkdir -p "$APPS"

# ------------------------------------------------------------
# Backup current generated application icons
# ------------------------------------------------------------

if find "$APPS" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
    BACKUP="${APPS}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -a "$APPS" "$BACKUP"
    echo "Existing app icons backed up to:"
    echo "  $BACKUP"
fi

# ------------------------------------------------------------
# Add scalable/apps to index.theme
# ------------------------------------------------------------

if ! grep -q 'scalable/apps' "$INDEX"; then

    sed -i \
        '/^Directories=/ s/$/,scalable\/apps/' \
        "$INDEX"

    cat >> "$INDEX" <<'EOF'

[scalable/apps]
Size=48
MinSize=16
MaxSize=512
Type=Scalable
Context=Applications
EOF

fi

# ------------------------------------------------------------
# Locate a symbolic source icon
# ------------------------------------------------------------

find_symbolic()
{
    local name="$1"

    local candidates=(
        "$THEME/scalable/actions/$name.svg"
        "$THEME/scalable/actions/$name-symbolic.svg"

        "/usr/share/icons/Adwaita/symbolic/apps/$name.svg"
        "/usr/share/icons/Adwaita/symbolic/apps/$name-symbolic.svg"

        "/usr/share/icons/Adwaita/symbolic/actions/$name.svg"
        "/usr/share/icons/Adwaita/symbolic/actions/$name-symbolic.svg"

        "/usr/share/icons/Adwaita/symbolic/places/$name.svg"
        "/usr/share/icons/Adwaita/symbolic/places/$name-symbolic.svg"

        "/usr/share/icons/Adwaita/symbolic/devices/$name.svg"
        "/usr/share/icons/Adwaita/symbolic/devices/$name-symbolic.svg"

        "/usr/share/icons/Adwaita/symbolic/mimetypes/$name.svg"
        "/usr/share/icons/Adwaita/symbolic/mimetypes/$name-symbolic.svg"
    )

    for file in "${candidates[@]}"; do
        if [[ -f "$file" ]]; then
            printf '%s\n' "$file"
            return 0
        fi
    done

    # Broader fallback search
    find /usr/share/icons/Adwaita/symbolic \
        -type f \
        \( -name "$name.svg" -o -name "$name-symbolic.svg" \) \
        -print -quit 2>/dev/null
}

# ------------------------------------------------------------
# Choose icon according to application
# ------------------------------------------------------------

choose_symbol()
{
    local text="${1,,}"

    case "$text" in

        *firefox*|*chromium*|*chrome*|*browser*|*vivaldi*|*brave*)
            echo "web-browser"
            ;;

        *kitty*|*alacritty*|*terminal*|*konsole*|*foot*)
            echo "utilities-terminal"
            ;;

        *thunar*|*nautilus*|*nemo*|*pcmanfm*|*file*manager*)
            echo "folder"
            ;;

        *codium*|*code*|*kate*|*geany*|*editor*|*zed*)
            echo "text-editor"
            ;;

        *steam*|*game*)
            echo "applications-games"
            ;;

        *settings*|*configuration*|*preferences*)
            echo "preferences-system"
            ;;

        *network*|*wifi*|*connection*)
            echo "network-wired"
            ;;

        *disk*|*gparted*|*btrfs*)
            echo "drive-harddisk"
            ;;

        *image*|*gimp*|*krita*)
            echo "image-x-generic"
            ;;

        *music*|*audio*|*spotify*)
            echo "audio-x-generic"
            ;;

        *video*|*vlc*|*mpv*)
            echo "video-x-generic"
            ;;

        *)
            echo "application-x-executable"
            ;;
    esac
}

# ------------------------------------------------------------
# Bake cyan into copied SVG
# ------------------------------------------------------------

cyanise()
{
    local file="$1"

    # Common Adwaita symbolic foreground colours.
    sed -i \
        -e "s/#2e3436/$PRIMARY/Ig" \
        -e "s/#241f31/$PRIMARY/Ig" \
        -e "s/#3d3846/$PRIMARY/Ig" \
        -e "s/#000000/$PRIMARY/Ig" \
        -e "s/#000/$PRIMARY/Ig" \
        "$file"

    # Symbolic SVGs sometimes use CSS rather than explicit fill values.
    sed -i \
        -e "s/currentColor/$PRIMARY/g" \
        "$file"
}

# ------------------------------------------------------------
# Generate one application icon
# ------------------------------------------------------------

generate_icon()
{
    local icon_name="$1"
    local app_text="$2"

    # Ignore absolute icon paths; Fuzzel can use those directly and they
    # cannot sensibly be overridden through an icon theme.
    [[ "$icon_name" = /* ]] && return

    # Ignore empty names.
    [[ -z "$icon_name" ]] && return

    local symbol
    symbol="$(choose_symbol "$app_text")"

    local source
    source="$(find_symbolic "$symbol" || true)"

    # Try increasingly generic fallbacks.
    if [[ -z "$source" ]]; then
        source="$(find_symbolic application-x-executable || true)"
    fi

    if [[ -z "$source" ]]; then
        echo "WARNING: no symbolic source for $icon_name"
        return
    fi

    local dest="$APPS/$icon_name.svg"

    cp "$source" "$dest"
    cyanise "$dest"
}

# ------------------------------------------------------------
# Clear previously generated app icons
# ------------------------------------------------------------

find "$APPS" -maxdepth 1 -type f -name '*.svg' -delete

# ------------------------------------------------------------
# Scan desktop launchers
# ------------------------------------------------------------

declare -A SEEN

desktop_dirs=(
    "/usr/share/applications"
    "/usr/local/share/applications"
    "$HOME/.local/share/applications"
)

count=0

for dir in "${desktop_dirs[@]}"; do

    [[ -d "$dir" ]] || continue

    while IFS= read -r -d '' desktop; do

        icon="$(
            sed -n 's/^Icon=//p' "$desktop" |
            head -n1
        )"

        name="$(
            sed -n 's/^Name=//p' "$desktop" |
            head -n1
        )"

        [[ -n "$icon" ]] || continue

        # Don't regenerate duplicate icon names.
        if [[ -n "${SEEN[$icon]:-}" ]]; then
            continue
        fi

        SEEN["$icon"]=1

        generate_icon \
            "$icon" \
            "$name $icon $(basename "$desktop")"

        ((count+=1)) || true

    done < <(
        find "$dir" \
            -maxdepth 1 \
            -type f \
            -name '*.desktop' \
            -print0
    )

done

# ------------------------------------------------------------
# Ensure Fuzzel uses Neo-Wire
# ------------------------------------------------------------

mkdir -p "$(dirname "$FUZzel_CONFIG")"

if [[ -f "$FUZzel_CONFIG" ]]; then

    if grep -q '^icon-theme=' "$FUZzel_CONFIG"; then

        sed -i \
            's/^icon-theme=.*/icon-theme=Neo-Wire/' \
            "$FUZzel_CONFIG"

    else

        printf '\nicon-theme=Neo-Wire\n' >> "$FUZzel_CONFIG"

    fi

fi

# ------------------------------------------------------------
# Rebuild icon cache
# ------------------------------------------------------------

rm -f "$THEME/icon-theme.cache"

gtk-update-icon-cache \
    -f \
    "$THEME" \
    >/dev/null

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

echo
echo "========================================"
echo " NEO-WIRE APPLICATION REGISTRY COMPLETE"
echo "========================================"
echo
echo "Desktop icons inspected : $count"
echo "Generated icons         : $(find "$APPS" -maxdepth 1 -name '*.svg' | wc -l)"
echo "Theme                   : $THEME"
echo
echo "EVERYTHING IS CYAN."
echo "COMPLIANCE IS VISUALLY PLEASING."
