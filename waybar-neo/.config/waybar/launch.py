#!/usr/bin/python3
"""Launch Waybar at a percentage of each monitor's logical width.

Requires Python GObject bindings and GTK 3. Restart after changing monitors.
"""

import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

import gi

gi.require_version("Gdk", "3.0")
from gi.repository import Gdk


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--width-percent", type=float, default=70)
    args = parser.parse_args()
    if not 0 < args.width_percent <= 100:
        parser.error("--width-percent must be greater than 0 and at most 100")

    display = Gdk.Display.get_default()
    if display is None:
        parser.error("cannot connect to the graphical session")
    screen = display.get_default_screen()
    # Keep the installed path: resolving a Stow symlink would break CSS imports.
    config_dir = Path(__file__).absolute().parent
    bars = []
    for index in range(display.get_n_monitors()):
        monitor = display.get_monitor(index)
        output = screen.get_monitor_plug_name(index)
        if not output:
            parser.error("cannot determine monitor output name")
        bars.append({
            "output": output,
            "width": max(1, round(monitor.get_geometry().width * args.width_percent / 100)),
            "include": str(config_dir / "config.jsonc"),
        })
    if not bars:
        parser.error("no monitors found")

    # Included config remains editable; Waybar's reload can reread it.
    with tempfile.TemporaryDirectory(prefix="waybar-", dir=os.environ.get("XDG_RUNTIME_DIR")) as directory:
        config = Path(directory) / "config.json"
        config.write_text(json.dumps(bars))
        return subprocess.call([
            "waybar", "--config", str(config),
            "--style", str(config_dir / "style.css"),
        ])


if __name__ == "__main__":
    raise SystemExit(main())
