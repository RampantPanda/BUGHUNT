#!/usr/bin/env python3
"""Open a MUTHUR widget gallery without installing or changing GTK settings."""
import argparse
import os
from pathlib import Path
import shutil
import tempfile
import sys

import gi

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('version', nargs='?', choices=('3', '4'), default='4')
parser.add_argument('--installed', action='store_true',
                    help='Use GTK\'s normal configuration loading, without injecting the repository theme')
args = parser.parse_args()
gi.require_version('Gtk', f'{args.version}.0')
gi.require_version('Gdk', f'{args.version}.0')
from gi.repository import Gdk, Gio, Gtk

ROOT = Path(__file__).resolve().parents[1]
GTK4 = args.version == '4'


def append(box, widget):
    if GTK4:
        box.append(widget)
    else:
        box.pack_start(widget, False, False, 0)


def css_class(widget, name):
    widget.get_style_context().add_class(name)
    return widget


def label(text, style=None):
    widget = Gtk.Label(label=text, xalign=0)
    return css_class(widget, style) if style else widget


def activate(app, stylesheet):
    settings = Gtk.Settings.get_default()
    if stylesheet is not None:
        settings.set_property('gtk-theme-name', 'Adwaita')
        settings.set_property('gtk-application-prefer-dark-theme', True)
        provider = Gtk.CssProvider()
        provider.load_from_path(str(stylesheet))
        # Higher priority than the live user stylesheet, confined to this process.
        if GTK4:
            Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, 601)
        else:
            Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, 601)
    else:
        config = Path(os.environ.get('XDG_CONFIG_HOME') or Path.home() / '.config')
        css = config / f'gtk-{args.version}.0/gtk.css'
        print(f'Installed CSS: {css} (exists: {css.exists()})', flush=True)
        print(f'Base theme: {settings.get_property("gtk-theme-name")}', flush=True)
        print(f'Prefer dark: {settings.get_property("gtk-application-prefer-dark-theme")}', flush=True)
        print(f'GTK_THEME: {os.environ.get("GTK_THEME", "(unset)")}', flush=True)

    source = 'INSTALLED' if stylesheet is None else 'REPOSITORY'
    window = Gtk.ApplicationWindow(application=app, title=f'MUTHUR / GTK {args.version} / {source}')
    window.set_default_size(760, 640)
    header = Gtk.HeaderBar()
    if GTK4:
        header.set_title_widget(label(f'MUTHUR / {source}', 'heading'))
    else:
        header.set_title(f'MUTHUR / {source}')
        header.set_show_close_button(True)
    window.set_titlebar(header)
    body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
    for side in ('top', 'bottom', 'start', 'end'):
        getattr(body, f'set_margin_{side}')(20)
    append(body, label('CREW INTERFACE  /  TERMINAL 01', 'heading'))
    append(body, label('Primary text: The quick brown fox jumps over the lazy dog. 0123456789'))
    append(body, label('Secondary text / telemetry received / awaiting instructions', 'dim-label'))

    actions = Gtk.Box(spacing=10)
    for text, style in [('QUERY', None), ('TRANSMIT', 'suggested-action'), ('PURGE', 'destructive-action'), ('OFFLINE', None)]:
        button = Gtk.Button(label=text)
        if style:
            css_class(button, style)
        if text == 'OFFLINE':
            button.set_sensitive(False)
        append(actions, button)
    append(body, actions)
    entry = Gtk.Entry(placeholder_text='Enter command — use Tab to inspect keyboard focus')
    append(body, entry)
    states = Gtk.Box(spacing=16)
    for text, active in [('Life support', True), ('Silent mode', False)]:
        check = Gtk.CheckButton(label=text)
        check.set_active(active)
        append(states, check)
    switch = Gtk.Switch(active=True, valign=Gtk.Align.CENTER)
    append(states, switch)
    append(body, states)
    statuses = Gtk.Box(spacing=16)
    for text, style in [('ONLINE', 'success'), ('CAUTION', 'warning'), ('FAULT', 'error')]:
        append(statuses, label(text, style))
    append(body, statuses)
    scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
    scale.set_value(67)
    scale.set_hexpand(True)
    append(body, scale)
    progress = Gtk.ProgressBar(fraction=0.67, show_text=True, text='TRANSMISSION 67%')
    append(body, progress)
    listing = Gtk.ListBox()
    for text in ['NAVIGATION / Course verified', 'ENGINEERING / Reactor nominal', 'COMMS / Signal acquired']:
        row = Gtk.ListBoxRow()
        if GTK4:
            row.set_child(label(text))
            listing.append(row)
        else:
            row.add(label(text))
            listing.add(row)
    listing.select_row(listing.get_row_at_index(1))
    append(body, listing)
    append(body, Gtk.LinkButton.new_with_label('https://docs.gtk.org/', 'GTK system reference'))
    if GTK4:
        window.set_child(body)
        window.present()
    else:
        window.add(body)
        window.show_all()


def run(stylesheet):
    app = Gtk.Application(application_id='local.muthur.ThemePreview', flags=Gio.ApplicationFlags.NON_UNIQUE)
    app.connect('activate', activate, stylesheet)
    return app.run([sys.argv[0]])


if args.installed:
    sys.exit(run(None))
else:
    with tempfile.TemporaryDirectory(prefix='muthur-preview-') as directory:
        config = Path(directory)
        shutil.copytree(ROOT / 'colors/.config/colors', config / 'colors')
        shutil.copytree(ROOT / 'gtk/.config', config, dirs_exist_ok=True)
        sys.exit(run(config / f'gtk-{args.version}.0/gtk.css'))
