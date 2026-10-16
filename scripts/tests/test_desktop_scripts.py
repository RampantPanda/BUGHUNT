"""Read-only regression tests; installer and desktop commands are mocked."""
import json
import os
from pathlib import Path
import re
import shutil
import shlex
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
BASH = shutil.which('bash')


def bash(program, **kwargs):
    return subprocess.run([BASH, '-c', program], text=True, capture_output=True,
                          cwd=ROOT, **kwargs)


class DesktopScripts(unittest.TestCase):
    def test_notification_failure_and_states(self):
        for package in ('waybar', 'waybar-neo'):
            script = f'{package}/.config/waybar/noti-waybar.sh'
            failed = bash(f'swaync-client() {{ return 7; }}; source {script}')
            self.assertEqual(failed.returncode, 7)
            for state in ('notification', 'none', 'dnd-notification', 'dnd-none'):
                payload = json.dumps({'text': '2', 'class': state})
                result = bash(f"swaync-client() {{ printf '%s\\n' '{payload}'; }}; source {script}")
                self.assertEqual(result.returncode, 0, result.stderr)
                data = json.loads(result.stdout)
                self.assertEqual(data['class'], state)
                self.assertTrue(data['tooltip'])
                if package.endswith('-neo'):
                    self.assertEqual(data['alt'], state)

    def test_lock_network_wifi_wired_offline(self):
        for package in ('gtklock', 'gtklock-neo'):
            source = (ROOT / package / '.config/gtklock/buglock.sh').read_text()
            # Run the collector's actual network block without its unrelated probes.
            escape = source[source.index('escape_markup()'):source.index('field()')]
            block = source[source.index('ssid=$('):source.index('# Root filesystem free space')]
            fixtures = [
                ('yes:Office & Lab', '', 'OFFICE &amp; LAB'),
                ('', 'eth0:ethernet:connected', 'ETHERNET (eth0)'),
                ('', 'lo:loopback:connected\neth0:ethernet:disconnected', 'DISCONNECTED'),
            ]
            for wifi, devices, expected in fixtures:
                env = dict(os.environ, TEST_WIFI=wifi, TEST_DEVICES=devices)
                mock = '''nmcli() {
                    if [[ "$*" == *'dev wifi'* ]]; then
                        printf '%s\\n' "$TEST_WIFI"
                    else printf '%s\\n' "$TEST_DEVICES"; fi
                }
                '''
                result = bash(mock + escape + block + '\nprintf "%s" "$network"', env=env)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, expected)

    def test_screenshot_success_failure_and_cancellation(self):
        mock = '''mkdir() { :; }
        grim() { printf 'CAPTURE\\n'; return "$TEST_GRIM_STATUS"; }
        notify-send() { printf 'NOTIFY %s\\n' "$*"; }
        slurp() { printf '%s' "$TEST_GEOMETRY"; return "$TEST_SLURP_STATUS"; }
        source bin/.local/share/bin/snip.sh "$TEST_MODE"
        '''
        for mode, grim, slurp, geometry, expected in [
            ('full', 0, 0, '', 'Saved:'),
            ('full', 1, 0, '', 'SCREEN CAPTURE FAILED'),
            ('region', 0, 0, '1,2 3x4', 'Saved:'),
            ('region', 0, 1, '', ''),
            ('region', 0, 0, '', ''),
        ]:
            env = dict(os.environ, TEST_MODE=mode, TEST_GRIM_STATUS=str(grim),
                       TEST_SLURP_STATUS=str(slurp), TEST_GEOMETRY=geometry)
            result = bash(mock, env=env)
            if not expected:
                self.assertEqual(result.stdout, '')
            else:
                self.assertIn(expected, result.stdout)
                self.assertLess(result.stdout.index('CAPTURE'), result.stdout.index('NOTIFY'))
                self.assertEqual(result.returncode, grim)
                if grim:
                    self.assertNotIn('Saved:', result.stdout)

    def test_installer_dry_run_and_argument_validation(self):
        with tempfile.TemporaryDirectory() as directory:
            tmp = Path(directory)
            for name in ('bash', 'dirname'):
                (tmp / name).symlink_to(shutil.which(name))
            pacman = tmp / 'pacman'
            pacman.write_text('#!/bin/bash\n[[ "$*" == -Slq ]] || exit 99\nprintf "%s\\n" base-devel git gtklock\n')
            pacman.chmod(0o755)
            for name in ('sudo', 'yay', 'paru', 'git', 'meson', 'mkdir', 'stow'):
                p = tmp / name
                p.write_text('#!/bin/bash\nprintf "%s\\n" "Unexpected mutation: $0" >&2\nexit 99\n')
                p.chmod(0o755)
            env = dict(os.environ, PATH=str(tmp))
            for theme in ('original', 'neo'):
                result = subprocess.run([BASH, str(ROOT / 'scripts/install.sh'), '--dry-run',
                                         '--theme', theme], env=env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('Dry run complete', result.stdout)
                self.assertIn(f'--dir={ROOT}', result.stdout)
                self.assertIn('nm-connection-editor', result.stdout)
                self.assertIn('python-gobject', result.stdout)
                self.assertNotIn('nextcloud-client', result.stdout)
                self.assertNotIn('pacman-key', result.stdout)
                if theme == 'neo':
                    self.assertIn('mango-vm-neo', result.stdout)
                    self.assertIn('--ignore=', result.stdout)
            optional = subprocess.run([BASH, str(ROOT / 'scripts/install.sh'), '--dry-run',
                                       '--with-apps'], env=env, text=True, capture_output=True)
            self.assertEqual(optional.returncode, 0)
            self.assertIn('nextcloud-client', optional.stdout)
            for arguments in (['--theme'], ['--theme', 'bad'], ['--aur-helper', 'bad'], ['--unknown']):
                result = subprocess.run([BASH, str(ROOT / 'scripts/install.sh'), *arguments],
                                        env=env, text=True, capture_output=True)
                self.assertNotEqual(result.returncode, 0)

    @unittest.skipUnless(shutil.which('stow') and shutil.which('pacman'), 'Stow/pacman not installed')
    def test_printed_stow_commands(self):
        for variant in ('original', 'neo'):
            result = subprocess.run([BASH, str(ROOT / 'scripts/install.sh'), '--dry-run',
                                     '--theme', variant], capture_output=True, text=True, check=True)
            with tempfile.TemporaryDirectory() as directory:
                for line in result.stdout.splitlines():
                    if not line.strip().startswith('stow '):
                        continue
                    command = shlex.split(line)
                    command = ['--target=' + directory if arg.startswith('--target=') else arg
                               for arg in command if arg != '--simulate']
                    subprocess.run(command, capture_output=True, text=True, check=True)
                target = Path(directory)
                self.assertTrue((target / '.config/gtk-3.0/gtk.css').exists())
                settings = (target / '.config/gtk-3.0/settings.ini').read_text()
                self.assertIn('Bughunt-Neo' if variant == 'neo' else 'Bughunt', settings)
                self.assertTrue(os.access(target / '.local/share/bin/snip.sh', os.X_OK))
                self.assertTrue(os.access(target / '.local/share/bin/tofi-script.sh', os.X_OK))

    @unittest.skipUnless(shutil.which('starship'), 'Starship is not installed')
    def test_ssh_prompt_username(self):
        with tempfile.TemporaryDirectory() as tmp:
            env = dict(os.environ, STARSHIP_CONFIG=str(ROOT / 'starship/.config/starship.toml'),
                       STARSHIP_CACHE=tmp, SSH_CONNECTION='127.0.0.1 1234 127.0.0.1 22')
            output = ''
            for module in ('username', 'hostname'):
                result = subprocess.run(['starship', 'module', module], env=env,
                                        text=True, capture_output=True, check=True)
                output += re.sub(r'\x1b\[[0-9;]*m', '', result.stdout)
            self.assertRegex(output, r'\S+@\S+')


if __name__ == '__main__':
    unittest.main()
