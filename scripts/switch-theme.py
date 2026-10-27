#!/usr/bin/env python3
"""Switch BUGHUNT / BUGHUNT-NEO without writing to the source packages.

See SWITCH-THEME.md. Python 3.10+, Linux; no third-party Python dependencies.
"""

import argparse
import configparser
import fcntl
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import signal
import subprocess
import sys
import time
import uuid


ROOT = Path(__file__).resolve().parents[1]
STATE = Path('.local/state/bughunt-switch')
MODES = ('BUGHUNT', 'BUGHUNT-NEO')
PAIRED = ('colors', 'kitty', 'waybar', 'fuzzel', 'eww', 'fastfetch', 'gtklock', 'starship')


def lexists(path):
    return os.path.lexists(path)


def read(path, default=''):
    return path.read_text() if path.is_file() else default


def ini(text):
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform = str
    parser.read_string(text)
    return parser


def set_ini(text, section, updates):
    """Change only requested keys, preserving comments, other sections and keys."""
    lines = text.splitlines(keepends=True)
    header = '[' + section + ']'
    start = next((i for i, line in enumerate(lines) if line.strip() == header), None)
    if start is None:
        text = text.rstrip() + ('\n\n' if text.strip() else '') + header + '\n'
        return text + ''.join(f'{key}={value}\n' for key, value in updates.items()
                              if value is not None)
    end = next((i for i in range(start + 1, len(lines))
                if lines[i].lstrip().startswith('[')), len(lines))
    if not lines[start].endswith('\n'):
        lines[start] += '\n'
    body = [line for line in lines[start + 1:end]
            if line.split('=', 1)[0].strip() not in updates]
    if body and not body[-1].endswith('\n'):
        body[-1] += '\n'
    body += [f'{key}={value}\n' for key, value in updates.items() if value is not None]
    return ''.join(lines[:start + 1] + body + lines[end:])


def palette(package):
    return dict(re.findall(r'@define-color\s+(\w+)\s+(#[0-9a-fA-F]{6});',
                          (ROOT / package / '.config/colors/colors.css').read_text()))


def recolor(text):
    """Fill the missing Neo variants using roles and the paired terminal palettes."""
    old, new = palette('colors'), palette('colors-neo')
    mapping = {old[key].lower(): new[key] for key in old.keys() & new.keys()}
    terminal = lambda package: dict(re.findall(
        r'^(color\d+)\s+(#[\da-fA-F]{6})',
        (ROOT / package / '.config/kitty/kitty.conf').read_text(), re.M))
    a, b = terminal('kitty'), terminal('kitty-neo')
    mapping.update({a[key].lower(): b[key] for key in a.keys() & b.keys()})
    mapping.update({'#c7bd94': new['superior'], '#251f0d': '#192319',
                    '#2a230f': '#243322', '#d6c98f': new['text'], '#f53c3c': new['alert']})
    return re.sub(r'#[\da-fA-F]{6}(?:[\da-fA-F]{2})?\b',
                  lambda m: mapping.get(m[0][:7].lower(), m[0][:7]) + m[0][7:], text)


def qt_palette(scheme):
    """QPalette enum order, matching qt5ct/qt6ct's 21-role color files.

    https://doc.qt.io/qt-6/qpalette.html#ColorRole-enum
    """
    def color(group, key):
        return '#ff' + ''.join(f'{int(n):02x}' for n in scheme['Colors:' + group][key].split(','))
    view = lambda key: color('View', key)
    window = lambda key: color('Window', key)
    button = lambda key: color('Button', key)
    values = [window('ForegroundNormal'), button('BackgroundNormal'),
              button('BackgroundAlternate'), button('BackgroundNormal'),
              view('BackgroundNormal'), window('BackgroundNormal'),
              view('ForegroundNormal'), view('ForegroundActive'), button('ForegroundNormal'),
              view('BackgroundNormal'), window('BackgroundNormal'), view('BackgroundNormal'),
              color('Selection', 'BackgroundNormal'), color('Selection', 'ForegroundNormal'),
              view('ForegroundLink'), view('ForegroundVisited'), view('BackgroundAlternate'),
              view('BackgroundNormal'), color('Tooltip', 'BackgroundNormal'),
              color('Tooltip', 'ForegroundNormal'), view('ForegroundInactive')]
    disabled = values.copy()
    for index in (0, 6, 7, 8, 13):
        disabled[index] = view('ForegroundInactive')
    return '[ColorScheme]\n' + ''.join(
        f'{name}_colors={", ".join(colors)}\n'
        for name, colors in [('active', values), ('inactive', values), ('disabled', disabled)])


class Plan:
    def __init__(self, target):
        self.target = target
        self.files = {}  # relative path -> (bytes, permissions)

    def text(self, relative, text, mode=0o644):
        self.files[Path(relative)] = (text.encode(), mode)

    def source(self, package, relative):
        path = ROOT / package / relative
        self.files[Path(relative)] = (path.read_bytes(), path.stat().st_mode & 0o777)

    def package(self, package):
        # Package trees may contain app state, swap files, and personal untracked files.
        # Only use tracked files, but read their current working-tree contents.
        result = subprocess.run(['git', '-C', str(ROOT), 'ls-files', '-z', '--', package],
                                check=True, capture_output=True)
        for name in result.stdout.decode().split('\0'):
            if not name:
                continue
            relative = Path(name).relative_to(package)
            if relative.parts[0] not in ('.config', '.local'):
                continue
            if relative.name.endswith(('-bak', '-not', '.swp', '~')):
                continue
            self.source(package, relative)

    def current(self, relative, fallback=''):
        if Path(relative) in self.files:
            return self.files[Path(relative)][0].decode()
        return read(self.target / relative, fallback)


def build_plan(target, mode, mango_profile='appearance', neo_icons='Neo-Wire'):
    plan = Plan(target)
    neo = mode == 'BUGHUNT-NEO'
    suffix = '-neo' if neo else ''
    for package in PAIRED:
        # Eww Neo relies on assets in the original package; install both in order.
        plan.package(package)
        if neo:
            plan.package(package + suffix)
    # Neo doesn't supply GTK CSS. Both variants need the shared import wrappers.
    for version in ('3.0', '4.0'):
        for name in ('gtk.css', 'compat.css'):
            plan.source('gtk', f'.config/gtk-{version}/{name}')
    for package in ('swaync', 'tofi', 'cursors'):
        plan.package(package)
    # Copy only icons from GTK packages, never app-created GTK bookmarks.
    for package, theme in [('gtk', 'Bughunt'), ('gtk-neo', 'Bughunt-Neo'), ('icons-neo', 'Neo-Wire')]:
        directory = Path('.local/share/icons') / theme
        for source in sorted((ROOT / package / directory).rglob('*')):
            if source.is_file():
                plan.source(package, source.relative_to(ROOT / package))

    icon = neo_icons if neo else 'Bughunt'
    for version in ('3.0', '4.0'):
        relative = f'.config/gtk-{version}/settings.ini'
        settings = (ROOT / ('gtk' + suffix) / relative).read_text()
        settings = set_ini(settings, 'Settings', {'gtk-icon-theme-name': icon,
                           'gtk-cursor-theme-name': 'Capitaine Cursors (Gruvbox)',
                           'gtk-cursor-theme-size': '32' if neo else '30'})
        plan.text(relative, settings)

    for relative, package in [('.config/tofi/config', 'tofi'),
                              ('.config/geany/colorschemes/bughunt.conf', 'geany'),
                              ('.config/rmpc/themes/BUGHUNT.ron', 'rmpc')]:
        content = (ROOT / package / relative).read_text()
        content = recolor(content) if neo else content
        if package == 'geany' and neo:
            content = set_ini(content, 'theme_info', {
                'name': 'BUGHUNT-NEO', 'description': 'Cyan, green and orange BUGHUNT-NEO palette.'})
        plan.text(relative, content)
    relative = '.config/geany/geany.conf'
    content = plan.current(relative, (ROOT / 'geany' / relative).read_text())
    plan.text(relative, set_ini(content, 'geany', {'color_scheme': 'bughunt.conf'}))
    relative = '.config/rmpc/config.ron'
    content = plan.current(relative, (ROOT / 'rmpc' / relative).read_text())
    content, count = re.subn(r'(?m)^(\s*theme\s*:)\s*[^\n]*', r'\1 "BUGHUNT",', content)
    if count != 1:
        raise ValueError('Cannot identify one theme setting in rmpc/config.ron')
    plan.text(relative, content)

    # KDE applications read kdeglobals, not just the installed .colors file.
    scheme_text = (ROOT / ('colors' + suffix) / '.local/share/color-schemes/Bughunt.colors').read_text()
    scheme = ini(scheme_text)
    plan.text('.local/share/color-schemes/k.colors', scheme_text)
    content = plan.current('.config/kdeglobals')
    for section in scheme.sections():
        if section.startswith(('Colors:', 'ColorEffects:')) or section == 'WM':
            content = set_ini(content, section, dict(scheme[section]))
    for section, values in [('General', {'ColorScheme': 'Bughunt', 'ColorSchemeHash': None}),
                            ('UiSettings', {'ColorScheme': 'Bughunt'}),
                            ('KDE', {'contrast': scheme['KDE']['contrast']}),
                            ('Icons', {'Theme': icon})]:
        content = set_ini(content, section, values)
    plan.text('.config/kdeglobals', content)
    for app in ('qt5ct', 'qt6ct'):
        relative = f'.config/{app}/colors/Bughunt.conf'
        plan.text(relative, qt_palette(scheme))
        config = f'.config/{app}/{app}.conf'
        plan.text(config, set_ini(plan.current(config), 'Appearance', {
            'custom_palette': 'true', 'color_scheme_path': str(target / relative), 'icon_theme': icon}))
    for app in ('katerc', 'kwriterc'):
        relative = '.config/' + app
        if (target / relative).is_file():
            plan.text(relative, set_ini(plan.current(relative), 'KTextEditor Renderer', {
                'Auto Color Theme Selection': 'false', 'Color Theme': 'BUGHUNT Neo' if neo else 'BUGHUNT'}))

    # Preserve machine-specific configuration unless explicitly selecting a full profile.
    if mango_profile != 'appearance' or not (target / '.config/mango/config.conf').is_file():
        package = 'mango-vm' if mango_profile == 'vm' else 'mango'
        plan.package(package + suffix)
    appearance = (ROOT / 'mango/.config/mango/cfg/appearance.conf').read_text()
    if neo:
        appearance += '\n' + (ROOT / 'mango-neo/.config/mango/cfg/appearance.conf').read_text()
        appearance += '\n' + (ROOT / 'mango-neo/.config/mango/cfg/animations.conf').read_text()
    theme = 'k.conf' if neo else 'bughunt.conf'
    appearance += '\n' + (ROOT / ('mango' + suffix) / '.config/mango/themes' / theme).read_text()
    appearance += '\ncursor_theme = Capitaine Cursors (Gruvbox)\n'
    plan.text('.config/mango/bughunt-look.conf', appearance)
    relative = '.config/mango/config.conf'
    content = re.sub(r'(?m)^\s*source\s*=\s*\./bughunt-look\.conf\s*$', '', plan.current(relative))
    plan.text(relative, content.rstrip() + '\nsource = ./bughunt-look.conf\n')

    # Keep the correct width launcher across logins, including when preserving Mango.
    command = ('exec python3 "$HOME/.config/waybar/launch.py" --width-percent 70' if neo else
               'exec waybar --config "$HOME/.config/waybar/config.jsonc" --style "$HOME/.config/waybar/style.css"')
    plan.text('.config/waybar/launch-theme.sh', '#!/bin/sh\n' + command + '\n', 0o755)
    relative = '.config/mango/cfg/autostart.conf'
    content = plan.current(relative)
    content = re.sub(r'(?m)^[ \t]*(exec_once|exec)[ \t]*=[ \t]*(?:waybar[ \t]*|(?:/usr/bin/)?python3[ \t]+~/.config/waybar/launch\.py[^\n]*|~/.config/waybar/launch-theme\.sh)[ \t]*$',
                     r'\1 = ~/.config/waybar/launch-theme.sh', content)
    surface = palette('colors' + suffix)['surface'][1:]
    content = re.sub(r'(\bswaybg\s+-c\s+)[#]?(?:0e0402|1d170b)\b',
                     lambda m: m[1] + surface, content)
    if content:
        plan.text(relative, content)
    return plan, icon


def write_json(path, value):
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(value, indent=2) + '\n')
    os.replace(temporary, path)


class Transaction:
    """Journal moves before making them; never write through a directory symlink."""
    def __init__(self, target, directory, previous):
        self.target, self.directory = target, directory
        self.journal = {'previous': previous, 'operations': [], 'status': 'applying'}
        directory.mkdir()
        (directory / 'backup').mkdir()
        self.save()

    def save(self):
        write_json(self.directory / 'journal.json', self.journal)

    def record(self, path, kind):
        operation = {'path': str(path.relative_to(self.target)), 'kind': kind,
                     'existed': lexists(path), 'id': str(len(self.journal['operations']))}
        self.journal['operations'].append(operation)
        self.save()
        if operation['existed']:
            os.replace(path, self.directory / 'backup' / operation['id'])

    def parents(self, path):
        current = self.target
        for part in path.relative_to(self.target).parts[:-1]:
            current /= part
            if current.is_symlink():
                source = current.resolve(strict=True)
                if not source.is_dir():
                    raise ValueError(f'Parent is not a directory: {current}')
                children = list(source.iterdir())
                self.record(current, 'unfold')
                current.mkdir()
                # Preserve all unrelated files, sockets and local state as links.
                # Parents of managed files are unfolded again when needed.
                for child in children:
                    (current / child.name).symlink_to(child)
            elif not current.exists():
                self.record(current, 'mkdir')
                current.mkdir()
            elif not current.is_dir():
                raise ValueError(f'Parent is not a directory: {current}')

    def install(self, relative, data, permissions):
        path = self.target / relative
        self.parents(path)
        staged = self.directory / 'next-file'
        staged.write_bytes(data)
        staged.chmod(permissions)
        self.record(path, 'file')
        os.replace(staged, path)


def restore_files(target, directory, journal):
    """Retain displaced current configs too, so a restore cannot discard later edits."""
    displaced = directory / 'displaced'
    displaced.mkdir(exist_ok=True)
    for operation in reversed(journal['operations']):
        path = target / operation['path']
        backup = directory / 'backup' / operation['id']
        if lexists(backup) or not operation['existed'] and lexists(path):
            for parent in path.parents:
                if parent == target:
                    break
                if parent.is_symlink():
                    raise ValueError(f'Refusing to restore through a changed parent symlink: {parent}')
        if operation['kind'] == 'mkdir':
            if path.is_dir() and not path.is_symlink():
                try:
                    path.rmdir()  # Keep directories populated by applications since the switch.
                except OSError:
                    pass
        elif not operation['existed'] or lexists(backup):
            if lexists(path):
                os.replace(path, displaced / operation['id'])
            if lexists(backup):
                os.replace(backup, path)
    journal['status'] = 'restored'
    write_json(directory / 'journal.json', journal)


def run(command):
    try:
        result = subprocess.run(command, text=True, capture_output=True, timeout=8)
        if result.returncode == 0:
            return result.stdout.strip()
        print(f'Warning: {shlex.join(command)}: {result.stderr.strip() or "command failed"}', file=sys.stderr)
    except (OSError, subprocess.TimeoutExpired) as error:
        print(f'Warning: {shlex.join(command)}: {error}', file=sys.stderr)
    return None


def processes(name):
    """Only processes owned by this user, in this Wayland session when identifiable."""
    matches = []
    for directory in Path('/proc').iterdir():
        if not directory.name.isdigit():
            continue
        try:
            if directory.stat().st_uid != os.getuid() or read(directory / 'comm').strip() != name:
                continue
            environ = (directory / 'environ').read_bytes().split(b'\0')
            display = os.environ.get('WAYLAND_DISPLAY')
            if display and b'WAYLAND_DISPLAY=' + display.encode() not in environ:
                continue
            args = (directory / 'cmdline').read_bytes().decode().rstrip('\0').split('\0')
            matches.append((int(directory.name), args))
        except (OSError, UnicodeError):
            pass
    return matches


def spawn(command, log):
    try:
        with log.open('ab') as output:
            process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=output,
                                       stderr=output, start_new_session=True)
        time.sleep(0.2)
        if process.poll() is not None and process.returncode:
            print(f'Warning: {shlex.join(command)} failed; see {log}', file=sys.stderr)
    except OSError as error:
        print(f'Warning: {error}', file=sys.stderr)


def reload_desktop(target, state_dir):
    # Files are already committed. Failed/absent desktop services must not lose backups.
    if os.environ.get('MANGO_INSTANCE_SIGNATURE') and shutil.which('mmsg'):
        run(['mmsg', 'dispatch', 'reload_config'])
    bars = processes('waybar')
    for pid, _ in bars:
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    if bars:
        deadline = time.monotonic() + 3
        while any(Path(f'/proc/{pid}').exists() for pid, _ in bars) and time.monotonic() < deadline:
            time.sleep(0.05)
        if any(Path(f'/proc/{pid}').exists() for pid, _ in bars):
            print('Warning: Waybar is still stopping; restart it manually.', file=sys.stderr)
        else:
            launcher = target / '.config/waybar/launch-theme.sh'
            # On restore, the original profile might not have our generated launcher.
            neo_launcher = target / '.config/waybar/launch.py'
            command = [str(launcher)] if launcher.exists() else (
                [sys.executable, str(neo_launcher)] if neo_launcher.exists() else ['waybar'])
            spawn(command, state_dir / 'desktop.log')
    for pid, _ in processes('kitty'):
        try:
            os.kill(pid, signal.SIGUSR1)
        except ProcessLookupError:
            pass
    if processes('swaync') and shutil.which('swaync-client'):
        run(['swaync-client', '-rs'])
    if processes('eww') and shutil.which('eww'):
        run(['eww', 'reload'])
    colors = read(target / '.config/colors/colors.css')
    surface = re.search(r'@define-color\s+surface\s+#([\da-fA-F]{6});', colors)
    if surface:
        for pid, args in processes('swaybg'):
            # Leave image wallpaper services alone; only update this repo's solid backgrounds.
            if '-i' in args or '--image' in args or '-c' not in args:
                continue
            index = args.index('-c') + 1
            if index < len(args) and args[index].lstrip('#') in ('0e0402', '1d170b'):
                args[index] = surface[1]
                try:
                    os.kill(pid, signal.SIGTERM)
                    spawn(args, state_dir / 'desktop.log')
                except ProcessLookupError:
                    pass
    print('Reload requested. Reopen GTK/Qt apps and Geany/Kate if they retain old colors; '
          'the lockscreen changes on its next launch. Starship updates on the next prompt.')


def preferences(target=None, saved=None):
    """Snapshot/restore appearance preferences which can override GTK's INI files."""
    commands = []
    if saved is not None:
        for key, value in saved.get('gsettings', {}).items():
            commands.append(['gsettings', 'set', 'org.gnome.desktop.interface', key, value])
        if saved.get('xfconf') is not None:
            commands.append(['xfconf-query', '-c', 'xsettings', '-p', '/Net/IconThemeName', '-s', saved['xfconf']])
        elif saved.get('xfconf_available'):
            commands.append(['xfconf-query', '-c', 'xsettings', '-p', '/Net/IconThemeName', '-r'])
    else:
        saved = {}
        settings = ini((target / '.config/gtk-3.0/settings.ini').read_text())['Settings']
        icon = settings['gtk-icon-theme-name']
        if shutil.which('gsettings'):
            saved['gsettings'] = {}
            desired = {'icon-theme': icon, 'gtk-theme': settings['gtk-theme-name'],
                       'font-name': settings['gtk-font-name'],
                       'cursor-theme': settings['gtk-cursor-theme-name'],
                       'cursor-size': settings['gtk-cursor-theme-size'], 'color-scheme': 'prefer-dark'}
            for key, value in desired.items():
                previous = run(['gsettings', 'get', 'org.gnome.desktop.interface', key])
                if previous is not None:
                    saved['gsettings'][key] = previous
                    commands.append(['gsettings', 'set', 'org.gnome.desktop.interface', key, value])
        if shutil.which('xfconf-query'):
            saved['xfconf_available'] = True
            saved['xfconf'] = run(['xfconf-query', '-c', 'xsettings', '-p', '/Net/IconThemeName'])
            commands.append(['xfconf-query', '-c', 'xsettings', '-p', '/Net/IconThemeName',
                             '--create', '-t', 'string', '-s', icon])
    return saved, commands


def detect_mode(target, state):
    if state.get('mode') in MODES:
        return state['mode']
    content = read(target / '.config/colors/colors.css')
    if '#75e3ee' in content:
        return 'BUGHUNT-NEO'
    if '#756000' in content:
        return 'BUGHUNT'
    return None


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', help='BUGHUNT, BUGHUNT-NEO (aliases: original, neo), toggle, status, restore')
    parser.add_argument('--dry-run', action='store_true', help='Print the full file plan; write nothing and run no desktop commands')
    parser.add_argument('--no-reload', action='store_true', help='Only change files; skip desktop preferences and all live reloads')
    parser.add_argument('--target', type=Path, default=Path.home(), help='Home directory to configure; other targets never affect the live desktop')
    parser.add_argument('--mango-profile', choices=('appearance', 'desktop', 'vm'), default='appearance',
                        help='Default: preserve Mango behavior; desktop/vm explicitly replaces its full profile')
    parser.add_argument('--neo-icons', choices=('Neo-Wire', 'Bughunt-Neo'), default='Neo-Wire')
    args = parser.parse_args(argv)
    mode = {'original': 'BUGHUNT', 'bughunt': 'BUGHUNT', 'neo': 'BUGHUNT-NEO',
            'bughunt-neo': 'BUGHUNT-NEO'}.get(args.mode.lower(), args.mode.lower())
    if mode not in (*MODES, 'toggle', 'status', 'restore'):
        parser.error('Unknown mode: ' + args.mode)
    target = args.target.expanduser().absolute()
    if target.is_symlink() or not target.is_dir() or target.resolve().is_relative_to(ROOT):
        parser.error('Target must be an existing real home directory outside the source checkout')
    target = target.resolve()
    live = target == Path.home().resolve() and not args.no_reload
    if target == Path.home().resolve():
        for key, relative in [('XDG_CONFIG_HOME', '.config'), ('XDG_DATA_HOME', '.local/share')]:
            if os.environ.get(key) and Path(os.environ[key]).absolute() != target / relative:
                parser.error(f'{key} is nonstandard, but these configs use ~/{relative} explicitly')
    state_dir = target / STATE
    for path in (state_dir, *state_dir.parents):
        if path == target:
            break
        if path.is_symlink():
            parser.error(f'State directory must not pass through a symlink: {path}')
    state_file = state_dir / 'state.json'
    state = json.loads(read(state_file, '{}'))
    current = detect_mode(target, state)
    if state.get('last'):
        last = json.loads((state_dir / state['last'] / 'journal.json').read_text())
        if last['status'] == 'applying' and mode not in ('restore', 'status'):
            parser.error('An interrupted switch needs recovery; run restore first')
    if mode == 'status':
        print(current or 'Unmanaged / unknown')
        if state.get('last'):
            print('Latest backup: ' + str(state_dir / state['last']))
        return 0
    if mode == 'toggle':
        if current is None:
            parser.error('Cannot detect the current theme; select BUGHUNT or BUGHUNT-NEO first')
        mode = MODES[1 - MODES.index(current)]
    if mode == 'restore':
        if not state.get('last'):
            parser.error('No previous switch to restore')
        print('Restore: ' + str(state_dir / state['last']))
        if args.dry_run:
            return 0
    else:
        plan, icon = build_plan(target, mode, args.mango_profile, args.neo_icons)
        print(f'{current or "Unmanaged"} -> {mode}; {len(plan.files)} files; target: {target}')
        print(f'Mango: {args.mango_profile}; icons: {icon}')
        if args.dry_run:
            for relative in sorted(plan.files):
                print(('REPLACE ' if lexists(target / relative) else 'CREATE  ') + str(relative))
            print('Dry run: no files, preferences, or processes changed. Existing paths will be backed up.')
            return 0
    state_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (state_dir / 'lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        if json.loads(read(state_file, '{}')) != state:
            raise ValueError('Another switch completed during planning; run the command again')
        if mode == 'restore':
            directory = state_dir / state['last']
            journal = json.loads((directory / 'journal.json').read_text())
            restore_files(target, directory, journal)
            write_json(state_file, journal['previous'])
            if live:
                for command in preferences(saved=journal.get('preferences', {}))[1]:
                    run(command)
                reload_desktop(target, state_dir)
            print('Restored previous files and links. Displaced files retained in ' + str(directory / 'displaced'))
            return 0
        directory = state_dir / (time.strftime('%Y%m%d-%H%M%S-') + uuid.uuid4().hex[:8])
        transaction = Transaction(target, directory, state)
        # Write an in-progress pointer before replacing any file; restore also recovers interruption.
        write_json(state_file, {'mode': current, 'last': directory.name})
        try:
            for relative, (data, permissions) in sorted(plan.files.items()):
                transaction.install(relative, data, permissions)
            transaction.journal['status'] = 'committed'
            transaction.save()
            write_json(state_file, {'mode': mode, 'last': directory.name})
        except BaseException:
            restore_files(target, directory, transaction.journal)
            write_json(state_file, state)
            raise
        if live:
            saved, commands = preferences(target=target)
            transaction.journal['preferences'] = saved
            transaction.save()
            for command in commands:
                run(command)
            reload_desktop(target, state_dir)
        print(f'Applied {mode}. Backup: {directory}')
        print('Undo with: python3 ' + shlex.quote(str(Path(__file__))) + ' restore'
              + ('' if target == Path.home().resolve() else ' --target ' + shlex.quote(str(target))))
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        raise SystemExit(1)
