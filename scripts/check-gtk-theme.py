#!/usr/bin/env python3
"""Check GTK imports/syntax and the desktop palette's text contrast headlessly."""
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import warnings

ROOT = Path(__file__).resolve().parents[1]


def parse_styles(version, paths):
    import gi
    gi.require_version('Gtk', version)
    from gi.repository import Gtk

    for path in paths:
        provider = Gtk.CssProvider()
        errors = []
        provider.connect('parsing-error', lambda p, s, e: errors.append(str(e)))
        provider.load_from_path(str(path))
        if errors:
            raise RuntimeError(f'{path}: {errors}')
        print(f'GTK {version}: {path.parent.name}/{path.name}: OK')


def check_contrast():
    import gi
    gi.require_version('Gtk', '3.0')
    gi.require_version('Gdk', '3.0')
    from gi.repository import Gdk, Gtk

    # These deprecated GTK 3 APIs let GTK resolve mix()/shade() itself without
    # a display. The GTK 4 CSS is validated separately in its own process.
    warnings.filterwarnings('ignore', category=DeprecationWarning)
    colors = Gtk.StyleProperties.new()

    def symbolic(expression):
        expression = expression.strip()
        if expression.startswith('@'):
            return Gtk.SymbolicColor.new_name(expression[1:])
        if expression.startswith('#'):
            rgba = Gdk.RGBA()
            if not rgba.parse(expression):
                raise ValueError(expression)
            return Gtk.SymbolicColor.new_literal(rgba)
        match = re.fullmatch(r'(mix|shade)\((.*)\)', expression)
        if not match:
            raise ValueError(f'Unsupported color expression: {expression}')
        # Split arguments outside nested function calls.
        args, start, depth = [], 0, 0
        for i, char in enumerate(match[2]):
            depth += (char == '(') - (char == ')')
            if char == ',' and depth == 0:
                args.append(match[2][start:i])
                start = i + 1
        args.append(match[2][start:])
        if match[1] == 'mix':
            return Gtk.SymbolicColor.new_mix(symbolic(args[0]), symbolic(args[1]), float(args[2]))
        return Gtk.SymbolicColor.new_shade(symbolic(args[0]), float(args[1]))

    palette = (ROOT / 'colors/.config/colors/colors.css').read_text()
    for name, expression in re.findall(r'@define-color\s+(\w+)\s+([^;]+);', palette):
        colors.map_color(name, symbolic(expression))

    def luminance(name):
        ok, rgba = colors.lookup_color(name).resolve(colors)
        if not ok:
            raise ValueError(f'Unresolved color: {name}')
        channels = (rgba.red, rgba.green, rgba.blue)
        linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
        return sum(c * w for c, w in zip(linear, (0.2126, 0.7152, 0.0722)))

    pairs = [(fg, bg) for fg in ('gtk_fg', 'gtk_muted', 'gtk_link', 'gtk_success', 'gtk_warning', 'gtk_error')
             for bg in ('gtk_bg', 'gtk_panel', 'gtk_view', 'gtk_hover')]
    pairs += [('gtk_accent_fg', 'gtk_accent'), ('gtk_selection_fg', 'gtk_selection'),
              ('gtk_fg', 'gtk_error_bg'), ('gtk_bg', 'gtk_error'), ('gtk_disabled', 'gtk_bg')]
    ratios = []
    for fg, bg in pairs:
        low, high = sorted((luminance(fg), luminance(bg)))
        ratio = (high + 0.05) / (low + 0.05)
        if ratio < 4.5:
            raise AssertionError(f'{fg} on {bg}: {ratio:.2f}:1; expected >= 4.5:1')
        ratios.append(ratio)
    print(f'Contrast: {len(pairs)} text pairs pass 4.5:1; minimum {min(ratios):.2f}:1')
    low, high = sorted((luminance('gtk_fg'), luminance('gtk_bg')))
    print(f'Body text: {(high + 0.05) / (low + 0.05):.2f}:1')


def main():
    if len(sys.argv) > 1:
        parse_styles(sys.argv[1], [Path(p) for p in sys.argv[2:]])
        return
    with tempfile.TemporaryDirectory(prefix='bughunt-theme-check-') as directory:
        config = Path(directory)
        for app in ('colors', 'waybar', 'swaync', 'gtklock', 'eww'):
            shutil.copytree(ROOT / app / '.config' / app, config / app)
        shutil.copytree(ROOT / 'gtk/.config', config, dirs_exist_ok=True)
        groups = {
            '3.0': ('gtk-3.0/gtk.css', 'waybar/style.css', 'waybar/cheatsheet.css',
                    'gtklock/buglock.css', 'eww/eww.css'),
            '4.0': ('gtk-4.0/gtk.css', 'swaync/style.css'),
        }
        for version, paths in groups.items():
            subprocess.run([sys.executable, __file__, version, *(str(config / p) for p in paths)], check=True)
    check_contrast()


if __name__ == '__main__':
    main()
