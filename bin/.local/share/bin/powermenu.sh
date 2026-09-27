#!/usr/bin/env bash

# ==============================================================================
# Power menu for Mango / Waybar / Fuzzel
#
# Requirements:
#   - fuzzel
#   - systemd / systemctl / loginctl
#
# Optional:
#   - gtklock          Used for LOCK if installed
#   - dm-tool          LightDM switch-user support
#   - gdmflexiserver   GDM switch-user support
#
#
# Menu:
#
#   LOCK
#   LOGOUT
#   SWITCH USER
#   SUSPEND
#   HIBERNATE          <- only shown when systemd-logind says it is available
#   REBOOT
#   POWER OFF
#   EXIT: ESC
#
#
# Example Waybar config:
#
#   "on-click": "/home/pekka/.local/share/bin/powermenu.sh"
#
#
# This script deliberately separates:
#
#   1. Menu presentation
#   2. Capability detection
#   3. System actions
#
# That's a useful structure for larger Fuzzel menus.
# ==============================================================================


# ==============================================================================
# BASH SETTINGS
# ==============================================================================

# Fail if we accidentally reference an undefined variable.
set -u


# ==============================================================================
# FUZZEL
# ==============================================================================

# ------------------------------------------------------------------------------
# fuzzel_power
#
# Common Fuzzel wrapper.
#
# All menus therefore open in exactly the same location.
#
# Change these three values to reposition every power-menu window:
#
#   --anchor
#   --x-margin
#   --y-margin
# ------------------------------------------------------------------------------

fuzzel_power() {
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
# Turns function arguments into a Fuzzel list.
#
# Example:
#
#   choice="$(menu "LOCK" "SUSPEND" "EXIT: ESC")"
# ------------------------------------------------------------------------------

menu() {
    printf '%s\n' "$@" |
        fuzzel_power --prompt="SYSTEM > "
}


# ------------------------------------------------------------------------------
# message
#
# Small informational popup using Fuzzel itself.
#
# Example:
#
#   message "HIBERNATION NOT AVAILABLE"
# ------------------------------------------------------------------------------

message() {
    printf '%s\n' "$1" |
        fuzzel_power --prompt="SYSTEM > " >/dev/null
}


# ==============================================================================
# CONFIRMATION MENU
# ==============================================================================

# ------------------------------------------------------------------------------
# confirm
#
# Used for destructive actions such as:
#
#   LOGOUT
#   REBOOT
#   POWER OFF
#
#
# Usage:
#
#   if confirm "REBOOT"; then
#       systemctl reboot
#   fi
#
#
# The menu becomes:
#
#   YES: REBOOT
#   CANCEL: ESC
#
# Actual Escape also cancels.
# ------------------------------------------------------------------------------

confirm() {
    local action="$1"
    local answer

    answer="$(
        printf '%s\n' \
            "YES: $action" \
            "CANCEL: ESC" |
            fuzzel_power --prompt="CONFIRM > "
    )"

    [[ "$answer" == "YES: $action" ]]
}


# ==============================================================================
# HIBERNATION CAPABILITY
# ==============================================================================

# ------------------------------------------------------------------------------
# can_hibernate
#
# systemd-logind exposes a CanHibernate() method intended specifically for
# checking whether:
#
#   - the system supports hibernation
#   - hibernation is configured sufficiently
#   - the current user is permitted to request it
#
#
# busctl returns something such as:
#
#   s "yes"
#
# Other possible answers include:
#
#   no
#   challenge
#   na
#
#
# "yes":
#     immediately available
#
# "challenge":
#     available, but PolicyKit authentication may be required
#
# We include HIBERNATE for either of those cases.
# ------------------------------------------------------------------------------

can_hibernate() {
    local result

    result="$(
        busctl call \
            org.freedesktop.login1 \
            /org/freedesktop/login1 \
            org.freedesktop.login1.Manager \
            CanHibernate \
            2>/dev/null
    )" || return 1

    case "$result" in
        *'"yes"'*|*'"challenge"'*)
            return 0
            ;;

        *)
            return 1
            ;;
    esac
}


# ==============================================================================
# LOCK SCREEN
# ==============================================================================

# ------------------------------------------------------------------------------
# lock_screen
#
# Your Mango setup already uses gtklock, so that is the preferred locker.
#
# If gtklock disappears at some point, we fall back to asking systemd-logind
# to lock the current session.
#
# loginctl's generic lock command only works when the session/compositor has
# something listening for the lock request, so gtklock is more deterministic
# in your current setup.
# ------------------------------------------------------------------------------

lock_screen() {

    if command -v gtklock >/dev/null 2>&1; then

        gtklock

    else

        loginctl lock-session

    fi
}


# ==============================================================================
# LOGOUT
# ==============================================================================

# ------------------------------------------------------------------------------
# logout_session
#
# XDG_SESSION_ID normally contains the current systemd-logind session ID.
#
# Example:
#
#   XDG_SESSION_ID=3
#
# loginctl terminate-session then terminates the complete graphical session.
#
# This does not depend on Mango having a compositor-specific "quit" command.
# ------------------------------------------------------------------------------

logout_session() {

    if [[ -n "${XDG_SESSION_ID:-}" ]]; then

        loginctl terminate-session "$XDG_SESSION_ID"

    else

        # loginctl accepts an empty session argument to mean the calling
        # session. This fallback is useful if XDG_SESSION_ID is unavailable.
        loginctl terminate-session ""

    fi
}


# ==============================================================================
# SWITCH USER
# ==============================================================================

# ------------------------------------------------------------------------------
# switch_user
#
# Unfortunately there is no single standard command meaning:
#
#     "show me my display manager's user-switching screen"
#
# across SDDM, GDM, LightDM, etc.
#
# We therefore try several methods.
#
#
# METHOD 1:
#   Look for an already-running display-manager greeter session.
#
#   SDDM/GDM/LightDM greeters normally have their own logind session owned by
#   users such as:
#
#       sddm
#       gdm
#       lightdm
#
#   If one exists, `loginctl activate` switches the seat to it.
#
#
# METHOD 2:
#   LightDM:
#
#       dm-tool switch-to-greeter
#
#
# METHOD 3:
#   GDM:
#
#       gdmflexiserver
#
#
# If none of those is possible we display an error instead of doing something
# dangerous like terminating the current session.
# ------------------------------------------------------------------------------

switch_user() {

    local greeter_session


    # --------------------------------------------------------------------------
    # Look for an existing greeter login session.
    #
    # Typical loginctl output:
    #
    #   2  974 sddm   seat0 ...
    #   3 1000 pekka  seat0 ...
    #
    # We look for one owned by a known display-manager user.
    # --------------------------------------------------------------------------

    greeter_session="$(
        loginctl list-sessions --no-legend 2>/dev/null |
            awk '
                $3 == "sddm"   ||
                $3 == "gdm"    ||
                $3 == "lightdm"
                {
                    print $1
                    exit
                }
            '
    )"


    if [[ -n "$greeter_session" ]]; then

        # Lock our own session before exposing the greeter.
        #
        # If the user switches back to this session later, it should still
        # require authentication.
        if command -v gtklock >/dev/null 2>&1; then

            # Start gtklock in the background because we must continue running
            # long enough to activate the greeter.
            gtklock &

            # Give the locker a moment to establish itself.
            sleep 0.3

        else

            loginctl lock-session
        fi


        loginctl activate "$greeter_session"

        return $?
    fi


    # --------------------------------------------------------------------------
    # LightDM fallback
    # --------------------------------------------------------------------------

    if command -v dm-tool >/dev/null 2>&1; then

        dm-tool switch-to-greeter

        return $?
    fi


    # --------------------------------------------------------------------------
    # GDM fallback
    # --------------------------------------------------------------------------

    if command -v gdmflexiserver >/
