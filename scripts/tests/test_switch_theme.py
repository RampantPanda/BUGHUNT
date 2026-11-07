"""Exercise real switch/restore operations in temporary homes; never reload a desktop."""

import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'scripts/switch-theme.py'
spec = importlib.util.spec_from_file_location('switch_theme', SCRIPT)
theme = importlib.util.module_from_spec(spec)
spec.loader.exec_module(theme)


def fingerprint(root):
    result = {}
    for path in sorted(root.rglob('*')):
        relative = str(path.relative_to(root))
        if path.is_symlink():
            result[relative] = ('link', os.readlink(path))
        elif path.is_file():
            result[relative] = ('file', hashlib.sha256(path.read_bytes()).hexdigest())
        elif path.is_dir():
            result[relative] = ('dir',)
    return result


class ThemeSwitch(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='bughunt-test-')
        self.addCleanup(self.tmp.cleanup)
        self.target = Path(self.tmp.name) / 'home with spaces'
        self.target.mkdir()

    def invoke(self, *arguments, ok=True):
        result = subprocess.run([sys.executable, '-B', str(SCRIPT), *arguments,
                                 '--target', str(self.target), '--no-reload'],
                                text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def write(self, relative, text):
        path = self.target / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def link_package(self, package, relative):
        path = self.target / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.symlink_to(os.path.relpath(ROOT / package / relative, path.parent))

    def test_dry_run_is_read_only_and_invalid_arguments_do_nothing(self):
        for mode in ('BUGHUNT', 'BUGHUNT-NEO'):
            before = fingerprint(self.target)
            result = self.invoke(mode, '--dry-run')
            self.assertIn('Dry run:', result.stdout)
            self.assertEqual(fingerprint(self.target), before)
        for arguments in [('typo',), ('toggle',), ('restore',), ('neo', '--mango-profile', 'bad')]:
            self.invoke(*arguments, ok=False)
            self.assertEqual(fingerprint(self.target), {})

    def test_full_round_trip_with_folded_stow_links_and_local_files(self):
        for package, relative in [('waybar-neo', '.config/waybar'),
                                  ('gtklock-neo', '.config/gtklock'),
                                  ('gtk-neo', '.config/gtk-3.0'),
                                  ('geany', '.config/geany'),
                                  ('colors-neo', '.local/share/color-schemes')]:
            self.link_package(package, relative)
        self.write('.config/mango/config.conf', 'source = ./cfg/autostart.conf\nsource = ./cfg/input.conf\n')
        self.write('.config/mango/cfg/input.conf', 'repeat_rate = 37\n')
        self.write('.config/mango/cfg/autostart.conf',
                   'exec_once = waybar\nexec_once = personal-app --flag\nexec_once = swaybg -c 0e0402\n')
        self.write('.config/gtk-4.0/bookmarks', 'file:///keep-me\n')
        self.write('.config/kdeglobals', '[General]\nfont=Keep Me\nColorScheme=Other\n[Icons]\nTheme=Old\n')
        self.write('.config/katerc', '[KTextEditor Renderer]\nColor Theme=Old\nText Font=Keep Me\n')
        before = fingerprint(self.target)
        source_before = fingerprint(ROOT / 'geany')
        lock_before = fingerprint(ROOT / 'gtklock-neo')
        modules = theme.ini((self.target / '.config/gtklock/config.ini').read_text()).get(
            'main', 'modules', fallback=None)
        self.invoke('BUGHUNT-NEO')
        self.assertFalse((self.target / '.config/waybar').is_symlink())
        self.assertFalse((self.target / '.config/geany/geany.conf').is_symlink())
        self.assertEqual(source_before, fingerprint(ROOT / 'geany'))
        self.assertEqual((self.target / '.config/waybar/config.jsonc').read_bytes(),
                         (ROOT / 'waybar-neo/.config/waybar/config.jsonc').read_bytes())
        self.assertIn('BUGHUNT-NEO', self.invoke('status').stdout)
        self.assertIn('repeat_rate = 37', (self.target / '.config/mango/cfg/input.conf').read_text())
        startup = (self.target / '.config/mango/cfg/autostart.conf').read_text()
        self.assertIn('personal-app --flag', startup)
        self.assertIn('launch-theme.sh', startup)
        settings = (self.target / '.config/gtk-3.0/settings.ini').read_text()
        self.assertEqual(settings.count('gtk-icon-theme-name='), 1)
        self.assertIn('gtk-icon-theme-name=Neo-Wire', settings)
        self.assertTrue((self.target / '.config/gtk-3.0/gtk.css').exists())
        self.assertTrue((self.target / '.config/eww/assets/wy.png').exists())
        self.assertIn('#0e0402', (self.target / '.config/tofi/config').read_text())
        self.assertNotIn('#1d170b', (self.target / '.config/rmpc/themes/BUGHUNT.ron').read_text())
        self.assertIn('font=Keep Me', (self.target / '.config/kdeglobals').read_text())
        self.assertIn('Color Theme=BUGHUNT Neo', (self.target / '.config/katerc').read_text())
        neo_palette = (self.target / '.config/qt6ct/colors/Bughunt.conf').read_text()
        self.assertIn('#ff0e0402', neo_palette)
        # Exercise opposite mode, repeat application, and the full backup stack.
        self.invoke('toggle')
        self.assertIn('BUGHUNT\n', self.invoke('status').stdout)
        self.assertEqual((self.target / '.config/waybar/config.jsonc').read_bytes(),
                         (ROOT / 'waybar/.config/waybar/config.jsonc').read_bytes())
        self.assertIn('swaybg -c 1d170b', (self.target / '.config/mango/cfg/autostart.conf').read_text())
        lock = theme.ini((self.target / '.config/gtklock/config.ini').read_text())
        self.assertEqual(lock.get('main', 'modules', fallback=None), modules)
        self.assertTrue(Path(lock['main']['layout']).is_file())
        self.invoke('toggle')
        self.assertIn('BUGHUNT-NEO\n', self.invoke('status').stdout)
        self.assertIn('swaybg -c 0e0402', (self.target / '.config/mango/cfg/autostart.conf').read_text())
        self.invoke('BUGHUNT-NEO')
        for _ in range(4):
            self.invoke('restore')
        after = {key: value for key, value in fingerprint(self.target).items()
                 if not key.startswith('.local/state')}
        # State storage leaves its otherwise empty .local parent in a fresh target.
        self.assertEqual(after, before)
        self.assertEqual(source_before, fingerprint(ROOT / 'geany'))
        self.assertEqual(lock_before, fingerprint(ROOT / 'gtklock-neo'))

    def test_gtklock_preserves_module_selection_and_uses_bundled_layout(self):
        relative = Path('.config/gtklock/config.ini')
        for modules in (None, '', '/usr/lib/gtklock/custom-module.so'):
            content = '[main]\n#modules=/usr/lib/gtklock/runshell-module.so\n'
            if modules is not None:
                content += 'modules=' + modules + '\n'
            self.write(relative, content)
            for mode in theme.MODES:
                with self.subTest(modules=modules, mode=mode):
                    plan, _ = theme.build_plan(self.target, mode)
                    config = theme.ini(plan.files[relative][0].decode())
                    self.assertEqual(config.get('main', 'modules', fallback=None), modules)
                    layout = Path(config['main']['layout'])
                    self.assertEqual(layout, self.target / '.config/gtklock/layout.xml')
                    self.assertIn(layout.relative_to(self.target), plan.files)

    def test_fresh_target_does_not_enable_optional_gtklock_modules(self):
        for mode in theme.MODES:
            with self.subTest(mode=mode):
                plan, _ = theme.build_plan(self.target, mode)
                config = theme.ini(plan.files[Path('.config/gtklock/config.ini')][0].decode())
                self.assertFalse(config.get('main', 'modules', fallback=''))

    def test_current_rmpc_ansi_theme_and_working_tree_configs_are_used(self):
        rmpc = Path('.config/rmpc/themes/BUGHUNT.ron')
        source = (ROOT / 'rmpc' / rmpc).read_bytes()
        for mode in theme.MODES:
            with self.subTest(mode=mode):
                plan, _ = theme.build_plan(self.target, mode)
                # The revised theme uses terminal colors; both modes must preserve
                # its defaults and names so Kitty's selected ANSI palette applies.
                self.assertEqual(plan.files[rmpc][0], source)
                self.assertIn(b'background_color: None', source)
                self.assertIn(b'fg: "blue"', source)
                suffix = '-neo' if mode == 'BUGHUNT-NEO' else ''
                for package, relative in [('waybar', '.config/waybar/config.jsonc'),
                                          ('waybar', '.config/waybar/style.css'),
                                          ('gtklock', '.config/gtklock/buglock.css'),
                                          ('kitty', '.config/kitty/kitty.conf')]:
                    self.assertEqual(plan.files[Path(relative)][0],
                                     (ROOT / (package + suffix) / relative).read_bytes())
                self.assertFalse(any(path.is_relative_to('.config/mpd') for path in plan.files))

    def test_thunderbird_palettes_preserve_the_current_layout(self):
        source = (ROOT / theme.THUNDERBIRD_STYLE).read_text()
        self.assertEqual(theme.thunderbird_style(True), source)
        original = theme.thunderbird_style(False)
        self.assertRegex(original, r'--bh-bg:\s*#1d170b;')
        self.assertRegex(original, r'--bh-cyan:\s*#c5a629;')
        self.assertRegex(original, r'--bh-text:\s*#d6c98f;')
        self.assertNotIn('#69e7f3', original)
        # Palette declarations and the palette label are the only differences.
        def layout(css):
            return re.sub(r'(?m)^.*--bh-\w+\s*:.*\n', '', css).replace(
                'Neo-Wire / Cyan Terminal', 'BUGHUNT / Amber Terminal')
        self.assertEqual(layout(original), layout(source))
        colors = theme.palette('colors')
        with patch.object(Path, 'read_text', return_value=source.replace('--bh-bg:', '--other-bg:')):
            with patch.object(theme, 'palette', return_value=colors):
                with self.assertRaisesRegex(ValueError, '--bh-bg'):
                    theme.thunderbird_style(False)

    def test_thunderbird_discovers_existing_profiles_without_creating_a_salted_profile(self):
        plan, _ = theme.build_plan(self.target, 'BUGHUNT')
        self.assertFalse(any('thunderbird' in str(path) for path in plan.files))
        relative = Path('.config/thunderbird/custom.default-release')
        absolute = Path('mail profiles/work')
        legacy = Path('.thunderbird/old.default')
        for profile in (relative, absolute, legacy):
            (self.target / profile).mkdir(parents=True)
        self.write('.config/thunderbird/profiles.ini',
                   '[Profile0]\nIsRelative=1\nPath=custom.default-release\n'
                   f'[Profile1]\nIsRelative=0\nPath={self.target / absolute}\n'
                   '[Profile2]\nIsRelative=1\nPath=missing.default\n')
        self.write('.thunderbird/profiles.ini', '[Profile0]\nIsRelative=1\nPath=old.default\n')
        self.assertEqual(set(theme.thunderbird_profiles(self.target)), {relative, absolute, legacy})
        plan, _ = theme.build_plan(self.target, 'BUGHUNT-NEO')
        styles = {path for path in plan.files if path.name == 'userChrome.css'}
        self.assertEqual(styles, {profile / 'chrome/userChrome.css'
                                  for profile in (relative, absolute, legacy)})

    def test_thunderbird_skips_profiles_outside_the_target(self):
        outside = Path(self.tmp.name) / 'external-profile'
        outside.mkdir()
        self.write('.config/thunderbird/profiles.ini',
                   f'[Profile0]\nIsRelative=0\nPath={outside}\n'
                   '[Profile1]\nIsRelative=1\nPath=../../../external-profile\n')
        with patch('sys.stderr'):
            self.assertEqual(theme.thunderbird_profiles(self.target), [])
        self.assertEqual(fingerprint(outside), {})

    def test_thunderbird_switch_and_restore_preserve_profile_data_and_stow_links(self):
        profile = Path('.config/thunderbird/custom.default-release')
        css = profile / 'chrome/userChrome.css'
        self.write(css, '/* personal stylesheet */\n')
        self.write(profile / 'chrome/userContent.css', '/* message styling */\n')
        self.write(profile / 'prefs.js', 'user_pref("mail.accountmanager.accounts", "account1");\n')
        self.write(profile / 'user.js', '// personal settings\n')
        self.write(profile / 'Mail/Inbox', 'keep this mail\n')
        self.write('.config/thunderbird/profiles.ini',
                   '[Profile0]\nIsRelative=1\nPath=custom.default-release\n')
        stowed = self.target / '.thunderbird/stowed.default/chrome'
        stowed.parent.mkdir(parents=True)
        stowed.symlink_to((ROOT / theme.THUNDERBIRD_STYLE).parent)
        (self.target / '.local').mkdir()
        before = fingerprint(self.target)
        source_before = fingerprint(ROOT / 'thunderbird')
        result = self.invoke('original', '--dry-run')
        self.assertIn(str(css), result.stdout)
        self.assertEqual(fingerprint(self.target), before)
        self.invoke('original')
        for path in (self.target / css, stowed / 'userChrome.css'):
            self.assertRegex(path.read_text(), r'--bh-bg:\s*#1d170b;')
        self.invoke('toggle')
        for path in (self.target / css, stowed / 'userChrome.css'):
            self.assertEqual(path.read_bytes(), (ROOT / theme.THUNDERBIRD_STYLE).read_bytes())
        # Only UI CSS is managed; mail and application-written prefs remain intact.
        for relative, value in before.items():
            if relative.endswith(('prefs.js', 'user.js', 'Mail/Inbox', 'userContent.css', 'profiles.ini')):
                self.assertEqual(fingerprint(self.target)[relative], value)
        self.assertEqual(fingerprint(ROOT / 'thunderbird'), source_before)
        self.invoke('restore')
        self.invoke('restore')
        after = {key: value for key, value in fingerprint(self.target).items()
                 if not key.startswith('.local/state')}
        self.assertEqual(after, before)
        self.assertTrue(stowed.is_symlink())
        self.assertEqual(fingerprint(ROOT / 'thunderbird'), source_before)

    def test_failed_install_rolls_back_unfolded_symlinks(self):
        source = Path(self.tmp.name) / 'source'
        (source / 'nested').mkdir(parents=True)
        (source / 'nested/settings').write_text('original')
        (source / 'unrelated').write_text('personal')
        (self.target / '.config').symlink_to(source)
        state = self.target / theme.STATE
        state.mkdir(parents=True)
        before = fingerprint(self.target)
        transaction = theme.Transaction(self.target, state / 'test', {})
        transaction.install(Path('.config/nested/settings'), b'changed', 0o644)
        with self.assertRaises(OSError):
            with patch.object(theme.os, 'replace', side_effect=OSError('injected failure')):
                transaction.install(Path('.config/new'), b'data', 0o644)
        theme.restore_files(self.target, transaction.directory, transaction.journal)
        after = {key: value for key, value in fingerprint(self.target).items()
                 if not key.startswith('.local/state/bughunt-switch/test')}
        self.assertEqual(after, before)
        self.assertEqual((source / 'nested/settings').read_text(), 'original')

    def test_restore_keeps_later_edits_and_broken_links(self):
        path = self.target / 'settings'
        path.symlink_to('missing-original')
        directory = self.target / 'backup'
        transaction = theme.Transaction(self.target, directory, {})
        transaction.install(Path('settings'), b'theme', 0o644)
        path.write_text('later edit')
        theme.restore_files(self.target, directory, transaction.journal)
        self.assertTrue(path.is_symlink())
        self.assertEqual(os.readlink(path), 'missing-original')
        self.assertEqual((directory / 'displaced/0').read_text(), 'later edit')

    def test_generated_modes_cover_every_variant_and_no_live_commands_for_other_targets(self):
        for mode in theme.MODES:
            plan, icon = theme.build_plan(self.target, mode)
            neo = mode.endswith('-NEO')
            self.assertEqual(icon, 'Neo-Wire' if neo else 'Bughunt')
            for package in theme.PAIRED:
                variant = package + ('-neo' if neo else '')
                result = subprocess.check_output(['git', '-C', str(ROOT), 'ls-files', '-z', '--', variant])
                for name in result.decode().split('\0'):
                    if not name:
                        continue
                    relative = Path(name).relative_to(variant)
                    if relative.parts[0] in ('.config', '.local') and not relative.name.endswith(('-bak', '-not')):
                        self.assertIn(relative, plan.files)
        with patch.object(theme, 'reload_desktop', side_effect=AssertionError('live reload')):
            with patch.object(theme, 'preferences', side_effect=AssertionError('live preferences')):
                theme.main(['neo', '--target', str(self.target)])

    def test_preferences_are_saved_before_their_set_commands_and_can_be_restored(self):
        self.write('.config/gtk-3.0/settings.ini',
                   '[Settings]\ngtk-icon-theme-name=Neo-Wire\ngtk-theme-name=adw-gtk3-dark\n'
                   'gtk-font-name=Noto Sans 10\ngtk-cursor-theme-name=Capitaine Cursors (Gruvbox)\n'
                   'gtk-cursor-theme-size=32\n')
        with patch.object(theme.shutil, 'which', return_value='/fake/command'):
            with patch.object(theme, 'run', return_value="'old-value'") as run:
                saved, commands = theme.preferences(target=self.target)
        self.assertEqual(len(saved['gsettings']), 6)
        self.assertTrue(all('get' in call.args[0] or call.args[0][0] == 'xfconf-query'
                            for call in run.call_args_list))
        self.assertIn(['gsettings', 'set', 'org.gnome.desktop.interface', 'icon-theme', 'Neo-Wire'], commands)
        _, restore = theme.preferences(saved=saved)
        self.assertIn(['gsettings', 'set', 'org.gnome.desktop.interface', 'icon-theme', "'old-value'"], restore)

    def test_incomplete_switch_requires_recovery(self):
        state = self.target / theme.STATE
        state.mkdir(parents=True)
        transaction = theme.Transaction(self.target, state / 'interrupted', {})
        transaction.install(Path('.config/example'), b'partial', 0o644)
        theme.write_json(state / 'state.json', {'mode': None, 'last': 'interrupted'})
        result = self.invoke('neo', ok=False)
        self.assertIn('interrupted switch', result.stderr)
        self.invoke('restore')
        self.assertFalse((self.target / '.config/example').exists())

    def test_no_write_through_state_symlink_or_into_repository(self):
        outside = Path(self.tmp.name) / 'outside'
        outside.mkdir()
        (self.target / '.local').mkdir()
        (self.target / '.local/state').symlink_to(outside)
        self.invoke('neo', ok=False)
        self.assertEqual(fingerprint(outside), {})
        result = subprocess.run([sys.executable, '-B', str(SCRIPT), 'neo', '--target', str(ROOT)],
                                text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)

    def test_real_file_that_blocks_a_parent_rolls_back_earlier_changes(self):
        self.write('.config/colors/colors.css', 'personal palette\n')
        self.write('.config/eww', 'not a directory\n')
        before = fingerprint(self.target)
        result = self.invoke('neo', ok=False)
        self.assertIn('Parent is not a directory', result.stderr)
        after = {key: value for key, value in fingerprint(self.target).items()
                 if not key.startswith('.local')}
        self.assertEqual(after, before)

    def test_restore_refuses_to_write_through_a_replaced_parent(self):
        self.write('.config/app/settings', 'original')
        transaction = theme.Transaction(self.target, self.target / 'backup', {})
        transaction.install(Path('.config/app/settings'), b'theme', 0o644)
        app = self.target / '.config/app'
        app.rename(self.target / 'moved-app')
        outside = Path(self.tmp.name) / 'outside'
        outside.mkdir()
        (outside / 'settings').write_text('do not change')
        app.symlink_to(outside)
        with self.assertRaisesRegex(ValueError, 'changed parent symlink'):
            theme.restore_files(self.target, transaction.directory, transaction.journal)
        self.assertEqual((outside / 'settings').read_text(), 'do not change')

    def test_ini_updates_preserve_unrelated_keys_and_normalize_duplicates(self):
        text = '[Settings]\n# comment\nicon=old\nkeep=value\nicon=other\n[Elsewhere]\nicon=keep\n'
        updated = theme.set_ini(text, 'Settings', {'icon': 'new'})
        self.assertEqual(theme.ini(updated)['Settings']['icon'], 'new')
        self.assertIn('# comment\n', updated)
        self.assertEqual(theme.ini(updated)['Elsewhere']['icon'], 'keep')
        self.assertEqual(theme.set_ini('[Settings]', 'Settings', {'icon': 'new'}),
                         '[Settings]\nicon=new\n')


if __name__ == '__main__':
    unittest.main()
