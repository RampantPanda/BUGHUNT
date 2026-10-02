#!/usr/bin/env bash

# ==============================================================================
# Bluetooth menu for Waybar / Fuzzel
#
# Requirements:
#   - bluetoothctl   (BlueZ)
#   - fuzzel
#
# Example Waybar config:
#
#   "on-click": "/home/pekka/.local/share/bin/bluetoothmenu.sh"
#
#
# Main menu:
#
#   DISABLE
#   CONNECTED
#   KNOWN
#   PAIR NEW
#   EXIT: ESC
#
#
# Behaviour:
#
#   DISABLE
#       Powers Bluetooth off.
#
#   CONNECTED
#       Shows currently connected devices.
#       Selecting one disconnects it.
#
#   KNOWN
#       Shows paired devices that are not currently connected.
#       Selecting one connects it.
#
#   PAIR NEW
#       Scans for nearby unpaired devices.
#       Selecting one:
#
#           1. pairs it
#           2. trusts it
#           3. connects it
#
#   EXIT: ESC
#       Exits the menu.
#
# Pressing the actual Escape key does exactly the same thing.
#
#
# Device labels look like:
#
#   JBL Flip 6  [DD:EE:FF]
#
# The short MAC suffix avoids ambiguity if two devices have the same name.
# ==============================================================================


# ==============================================================================
# BASH SETTINGS
# ==============================================================================

# Treat use of an undefined variable as an error.
#
# This is useful for catching typos such as:
#
#   "$devcie"
#
# instead of:
#
#   "$device"
#
set -u


# ==============================================================================
# FUZZEL FUNCTIONS
# ==============================================================================


# ------------------------------------------------------------------------------
# fuzzel_bt
#
# Common wrapper around Fuzzel.
#
# This keeps positioning and general appearance behaviour in one place.
#
# Anything passed to this function gets appended to the fuzzel command.
#
# Example:
#
#   fuzzel_bt --prompt="CONNECT > "
#
# becomes effectively:
#
#   fuzzel \
#       --dmenu \
#       --anchor=top-right \
#       --x-margin=10 \
#       --y-margin=40 \
#       --prompt="CONNECT > "
#
#
# If you later want the Bluetooth menu somewhere else on screen, only change
# these values here.
# ------------------------------------------------------------------------------

fuzzel_bt() {
    fuzzel \
        --dmenu \
        --anchor=top-right \
        --x-margin=10 \
        --y-margin=40 \
        "$@"
}


# ------------------------------------------------------------------------------
# menu
#
# Convenience function for simple text menus.
#
# Example:
#
#   choice="$(menu \
#       "OPTION ONE" \
#       "OPTION TWO" \
#       "EXIT: ESC")"
#
#
# "$@" means:
#
#   all arguments passed to this function
#
# printf prints each argument on its own line and pipes the result into Fuzzel.
# ------------------------------------------------------------------------------

menu() {
    printf '%s\n' "$@" |
        fuzzel_bt --prompt="BLUETOOTH > "
}


# ------------------------------------------------------------------------------
# message
#
# Displays a simple one-line informational window.
#
# Example:
#
#   message "NO DEVICES FOUND"
#
#
# This is not a desktop notification. It is simply a Fuzzel list containing
# one item.
#
# The user can close it using Enter or Escape.
# ------------------------------------------------------------------------------

message() {
    printf '%s\n' "$1" |
        fuzzel_bt --prompt="BLUETOOTH > " >/dev/null
}


# ==============================================================================
# BLUETOOTH QUERY FUNCTIONS
# ==============================================================================


# ------------------------------------------------------------------------------
# bluetooth_powered
#
# bluetoothctl show contains something similar to:
#
#   Powered: yes
#
# awk finds that line and prints the second field:
#
#   yes
#
# or:
#
#   no
# ------------------------------------------------------------------------------

bluetooth_powered() {
    bluetoothctl show |
        awk '/Powered:/ {print $2; exit}'
}


# ------------------------------------------------------------------------------
# get_connected_devices
#
# bluetoothctl normally outputs device lines like:
#
#   Device AA:BB:CC:DD:EE:FF JBL Flip 6
#
# sed removes the initial:
#
#   Device
#
# leaving:
#
#   AA:BB:CC:DD:EE:FF JBL Flip 6
#
#
# That format is used internally throughout this script.
# ------------------------------------------------------------------------------

get_connected_devices() {
    bluetoothctl devices Connected 2>/dev/null |
        sed 's/^Device //'
}


# ------------------------------------------------------------------------------
# get_paired_devices
#
# Returns devices already paired with this computer.
#
# Example:
#
#   AA:BB:CC:DD:EE:FF JBL Flip 6
# ------------------------------------------------------------------------------

get_paired_devices() {
    bluetoothctl devices Paired 2>/dev/null |
        sed 's/^Device //'
}


# ------------------------------------------------------------------------------
# get_all_devices
#
# Returns everything BlueZ currently knows about.
#
# This can include:
#
#   - paired devices
#   - currently visible devices
#   - devices remembered from previous scans
#
# We later compare these against paired devices when looking for new devices.
# ------------------------------------------------------------------------------

get_all_devices() {
    bluetoothctl devices |
        sed 's/^Device //'
}


# ==============================================================================
# DEVICE PARSING FUNCTIONS
# ==============================================================================


# ------------------------------------------------------------------------------
# device_mac
#
# Input:
#
#   AA:BB:CC:DD:EE:FF JBL Flip 6
#
# Output:
#
#   AA:BB:CC:DD:EE:FF
#
#
# "${line%% *}" removes the first space and everything after it.
# ------------------------------------------------------------------------------

device_mac() {
    local line="$1"

    printf '%s\n' "${line%% *}"
}


# ------------------------------------------------------------------------------
# device_name
#
# Input:
#
#   AA:BB:CC:DD:EE:FF JBL Flip 6
#
# Output:
#
#   JBL Flip 6
#
#
# "${line#* }" removes everything up to and including the first space.
# ------------------------------------------------------------------------------

device_name() {
    local line="$1"

    printf '%s\n' "${line#* }"
}


# ------------------------------------------------------------------------------
# device_short_mac
#
# Input:
#
#   AA:BB:CC:DD:EE:FF
#
# Output:
#
#   DD:EE:FF
#
#
# The full MAC is unnecessarily ugly in the menu, but a short suffix is useful
# to distinguish two identical device names.
# ------------------------------------------------------------------------------

device_short_mac() {
    local mac="$1"

    printf '%s\n' "$mac" |
        awk -F: '{print $(NF-2) ":" $(NF-1) ":" $NF}'
}


# ------------------------------------------------------------------------------
# device_label
#
# Converts an internal device record:
#
#   AA:BB:CC:DD:EE:FF JBL Flip 6
#
# into a human-readable Fuzzel entry:
#
#   JBL Flip 6  [DD:EE:FF]
#
#
# This separation between:
#
#   internal value
#
# and:
#
#   displayed label
#
# is a very useful pattern for custom Fuzzel menus.
#
# You can use the same idea for:
#
#   Wi-Fi networks
#   audio devices
#   monitors
#   VPN profiles
#   processes
#   disks
#   SSH hosts
#   etc.
# ------------------------------------------------------------------------------

device_label() {
    local device="$1"

    local mac
    local name
    local short_mac

    mac="$(device_mac "$device")"
    name="$(device_name "$device")"
    short_mac="$(device_short_mac "$mac")"

    printf '%s  [%s]\n' "$name" "$short_mac"
}


# ==============================================================================
# DEVICE SELECTION MENU
# ==============================================================================


# ------------------------------------------------------------------------------
# select_device
#
# Arguments:
#
#   $1      = Fuzzel prompt
#   $2...   = internal device records
#
#
# Example:
#
#   selected="$(
#       select_device \
#           "CONNECT > " \
#           "${devices[@]}"
#   )"
#
#
# The function:
#
#   1. Converts all device records into pretty labels.
#   2. Adds:
#
#          EXIT: ESC
#
#      to the bottom of the list.
#
#   3. Displays the list using Fuzzel.
#   4. Converts the selected pretty label back into the original device record.
#
#
# Return behaviour:
#
#   Device selected:
#       prints the full device record and returns success.
#
#   EXIT: ESC selected:
#       returns failure.
#
#   Actual Escape pressed:
#       Fuzzel returns an empty string, and this function returns failure.
#
#
# Calling code can therefore simply do:
#
#   selected="$(select_device ...)" || exit 0
# ------------------------------------------------------------------------------

select_device() {
    local prompt="$1"

    # Remove the prompt from "$@".
    shift

    # Everything remaining is now a device record.
    local devices=("$@")

    local labels=()

    local device
    local selected_label


    # --------------------------------------------------------------------------
    # Build human-readable labels.
    # --------------------------------------------------------------------------

    for device in "${devices[@]}"; do
        labels+=("$(device_label "$device")")
    done


    # --------------------------------------------------------------------------
    # Add explicit exit option.
    #
    # Escape still works normally, but this also makes the exit behaviour
    # visible to the user.
    # --------------------------------------------------------------------------

    labels+=("EXIT: ESC")


    # --------------------------------------------------------------------------
    # Display the device list.
    # --------------------------------------------------------------------------

    selected_label="$(
        printf '%s\n' "${labels[@]}" |
            fuzzel_bt --prompt="$prompt"
    )"


    # --------------------------------------------------------------------------
    # Actual Escape:
    #
    # Fuzzel returns an empty string.
    # --------------------------------------------------------------------------

    [[ -z "$selected_label" ]] && return 1


    # --------------------------------------------------------------------------
    # Explicit EXIT entry.
    # --------------------------------------------------------------------------

    [[ "$selected_label" == "EXIT: ESC" ]] && return 1


    # --------------------------------------------------------------------------
    # Convert selected display label back to the original device record.
    # --------------------------------------------------------------------------

    for device in "${devices[@]}"; do

        if [[ "$(device_label "$device")" == "$selected_label" ]]; then

            printf '%s\n' "$device"

            return 0
        fi

    done


    return 1
}


# ==============================================================================
# CHECK BLUETOOTH POWER STATE
# ==============================================================================

powered="$(bluetooth_powered)"


# ------------------------------------------------------------------------------
# BLUETOOTH OFF
#
# If Bluetooth is disabled, don't show connection options that can't work.
#
# Only offer:
#
#   ENABLE
#   EXIT: ESC
# ------------------------------------------------------------------------------

if [[ "$powered" != "yes" ]]; then

    choice="$(
        menu \
            "ENABLE" \
            "EXIT: ESC"
    )"


    case "$choice" in

        "ENABLE")

            bluetoothctl power on >/dev/null
            ;;


        "EXIT: ESC"|"")

            # "" means the user pressed the actual Escape key.
            exit 0
            ;;

    esac


    exit 0
fi


# ==============================================================================
# MAIN MENU
# ==============================================================================

choice="$(
    menu \
        "DISABLE" \
        "CONNECTED" \
        "KNOWN" \
        "PAIR NEW" \
        "EXIT: ESC"
)"


case "$choice" in


# ==============================================================================
# DISABLE
# ==============================================================================

    "DISABLE")

        bluetoothctl power off >/dev/null
        ;;


# ==============================================================================
# CONNECTED
#
# Shows currently connected devices.
#
# Selecting a device disconnects it.
# ==============================================================================

    "CONNECTED")

        # mapfile reads lines from a command directly into a Bash array.
        #
        # Example command output:
        #
        #   device1
        #   device2
        #
        # becomes:
        #
        #   devices[0]="device1"
        #   devices[1]="device2"
        #
        mapfile -t devices < <(
            get_connected_devices
        )


        # ${#devices[@]} gives the number of array elements.
        if ((${#devices[@]} == 0)); then

            message "NO CONNECTED DEVICES"

            exit 0
        fi


        selected="$(
            select_device \
                "DISCONNECT > " \
                "${devices[@]}"
        )" || exit 0


        mac="$(device_mac "$selected")"
        name="$(device_name "$selected")"


        if bluetoothctl disconnect "$mac" >/dev/null; then

            message "DISCONNECTED: $name"

        else

            message "DISCONNECT FAILED: $name"

        fi
        ;;


# ==============================================================================
# KNOWN
#
# Shows paired devices that are not currently connected.
#
# Selecting one attempts to connect it.
# ==============================================================================

    "KNOWN")

        # Get paired devices.
        mapfile -t paired < <(
            get_paired_devices
        )


        # Get currently connected devices.
        mapfile -t connected < <(
            get_connected_devices
        )


        # This array will contain paired-but-not-connected devices.
        available=()


        # ----------------------------------------------------------------------
        # Remove currently connected devices from the paired-device list.
        # ----------------------------------------------------------------------

        for device in "${paired[@]}"; do

            mac="$(device_mac "$device")"

            is_connected=false


            for connected_device in "${connected[@]}"; do

                connected_mac="$(device_mac "$connected_device")"


                if [[ "$mac" == "$connected_mac" ]]; then

                    is_connected=true

                    break
                fi

            done


            if [[ "$is_connected" == false ]]; then

                available+=("$device")

            fi

        done


        # ----------------------------------------------------------------------
        # Nothing available.
        # ----------------------------------------------------------------------

        if ((${#available[@]} == 0)); then

            message "NO DISCONNECTED KNOWN DEVICES"

            exit 0
        fi


        # ----------------------------------------------------------------------
        # Ask user which known device to connect.
        # ----------------------------------------------------------------------

        selected="$(
            select_device \
                "CONNECT > " \
                "${available[@]}"
        )" || exit 0


        mac="$(device_mac "$selected")"
        name="$(device_name "$selected")"


        # ----------------------------------------------------------------------
        # Connect.
        # ----------------------------------------------------------------------

        if bluetoothctl connect "$mac"; then

            message "CONNECTED: $name"

        else

            message "CONNECTION FAILED: $name"

        fi
        ;;


# ==============================================================================
# PAIR NEW
#
# Scans for nearby devices and removes everything already paired.
#
# The selected new device is then:
#
#   1. paired
#   2. trusted
#   3. connected
# ==============================================================================

    "PAIR NEW")

        # ----------------------------------------------------------------------
        # Scan for nearby devices.
        #
        # --timeout 8 means bluetoothctl exits automatically after roughly
        # eight seconds.
        #
        # Increase this if devices frequently fail to appear quickly enough.
        # ----------------------------------------------------------------------

        bluetoothctl --timeout 8 scan on >/dev/null 2>&1


        # Explicitly make sure discovery is stopped afterwards.
        bluetoothctl scan off >/dev/null 2>&1


        # ----------------------------------------------------------------------
        # Get everything BlueZ currently knows about.
        # ----------------------------------------------------------------------

        mapfile -t all_devices < <(
            get_all_devices
        )


        # ----------------------------------------------------------------------
        # Get everything already paired.
        # ----------------------------------------------------------------------

        mapfile -t paired_devices < <(
            get_paired_devices
        )


        # This array will contain only unpaired devices.
        new_devices=()


        # ----------------------------------------------------------------------
        # Remove paired devices from scan results.
        # ----------------------------------------------------------------------

        for device in "${all_devices[@]}"; do

            mac="$(device_mac "$device")"

            is_paired=false


            for paired_device in "${paired_devices[@]}"; do

                paired_mac="$(device_mac "$paired_device")"


                if [[ "$mac" == "$paired_mac" ]]; then

                    is_paired=true

                    break
                fi

            done


            if [[ "$is_paired" == false ]]; then

                new_devices+=("$device")

            fi

        done


        # ----------------------------------------------------------------------
        # Nothing new discovered.
        # ----------------------------------------------------------------------

        if ((${#new_devices[@]} == 0)); then

            message "NO NEW DEVICES FOUND"

            exit 0
        fi


        # ----------------------------------------------------------------------
        # Ask which new device to pair.
        # ----------------------------------------------------------------------

        selected="$(
            select_device \
                "PAIR > " \
                "${new_devices[@]}"
        )" || exit 0


        mac="$(device_mac "$selected")"
        name="$(device_name "$selected")"


        # ----------------------------------------------------------------------
        # Pair.
        #
        # Some devices may require confirmation or a PIN.
        #
        # bluetoothctl communicates with BlueZ's agent to handle that.
        # ----------------------------------------------------------------------

        if ! bluetoothctl pair "$mac"; then

            message "PAIRING FAILED: $name"

            exit 1
        fi


        # ----------------------------------------------------------------------
        # Trust.
        #
        # Pairing establishes the relationship between the devices.
        #
        # Trusting tells BlueZ that this device may reconnect in the future
        # without repeatedly asking for permission.
        #
        # For your own speakers, headphones, keyboards, etc. this is normally
        # what you want.
        # ----------------------------------------------------------------------

        bluetoothctl trust "$mac" >/dev/null


        # ----------------------------------------------------------------------
        # Connect immediately after pairing.
        # ----------------------------------------------------------------------

        if bluetoothctl connect "$mac"; then

            message "CONNECTED: $name"

        else

            message "PAIRED, BUT CONNECTION FAILED: $name"

        fi
        ;;


# ==============================================================================
# EXIT
#
# Two equivalent exit paths:
#
#   EXIT: ESC
#
# or:
#
#   actual Escape key
#
# Escape causes Fuzzel to return an empty string.
# ==============================================================================

    "EXIT: ESC"|"")

        exit 0
        ;;

esac
