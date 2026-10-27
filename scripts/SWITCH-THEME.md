# BUGHUNT / BUGHUNT-NEO switcher

From the repository root:

```sh
python3 scripts/switch-theme.py BUGHUNT-NEO --dry-run
python3 scripts/switch-theme.py BUGHUNT-NEO
python3 scripts/switch-theme.py BUGHUNT
python3 scripts/switch-theme.py toggle
python3 scripts/switch-theme.py status
python3 scripts/switch-theme.py restore
```

`original` and `neo` are shorter aliases. Python 3.10+, Git, and the desktop's
existing applications are required. The switcher does not install dependencies.

The source packages are read only. Applying a mode replaces installed files in
your home directory with copies, backing up each displaced file or link first.
Your working-tree changes, including edits to a variant's Waybar modules, are
used as the source. No existing repository file needs an edit to use this script.

## What switches

| Component | Behavior |
| --- | --- |
| Waybar | Complete variant config, modules, styling, menus, helpers, and Neo's 70% monitor-width launcher |
| Mango | Colors, borders, gaps, corners, cursor, blur, shadows, and animations |
| GTK 3/4 and SwayNC | Shared palette and CSS, GTK settings, notification styling |
| Icons | Bughunt for BUGHUNT; Neo-Wire for BUGHUNT-NEO; desktop and Qt icon selections agree |
| Kitty | Main terminal, fonts, ANSI colors, and the nmtui profile |
| Fuzzel and Tofi | Launcher and power-menu appearance; Neo Tofi colors are generated |
| Eww | Variant layout and styles, scripts, and shared image assets |
| Fastfetch and Starship | Complete variant config and bundled Fastfetch artwork |
| gtklock | Variant layout, CSS, scripts, and shared lock colors |
| KDE and Qt | Bughunt and legacy `k.colors`, active `kdeglobals` colors, Qt5ct/Qt6ct palettes and icon selection |
| Geany, Kate/KWrite, rmpc | Editor/music-player schemes and selections; missing Neo Geany/rmpc palettes are generated |

Neo's conflicting GTK icon entries are normalized in the generated settings.
Select its smaller icon set with `--neo-icons Bughunt-Neo` if preferred.
Both modes retain their own checked-in palettes; this does not redesign them.
Applications with independent themes outside this repository, such as browser
extensions or VS Code themes, are outside the switcher's scope.

Mango's keybindings, monitor/input settings, rules, environment, and personal
startup applications are preserved by default. A final appearance include
overrides its current theme. The existing Waybar startup command is redirected
to the selected mode's launcher, and the repo's solid-color `swaybg` command
receives the selected background color. Image wallpapers are left alone.
If no Mango config exists, the desktop package supplies the initial configuration.
`--mango-profile desktop` or `--mango-profile vm` explicitly opts into replacing
Mango's full profile; neither is needed for an appearance switch.

## Preview, apply, and reload

`--dry-run` lists the complete file plan without creating directories, backups,
locks, or state, and without running desktop commands. To test an installation
away from your real home:

```sh
mkdir -p /tmp/bughunt-preview
python3 scripts/switch-theme.py neo --target /tmp/bughunt-preview
python3 scripts/switch-theme.py restore --target /tmp/bughunt-preview
```

A different `--target` never sends commands to your running desktop. The configs
contain `~/.config` references, so this is an installation test, not an isolated
graphical preview. Custom `XDG_CONFIG_HOME` / `XDG_DATA_HOME` layouts are rejected
for the real home because the existing configs explicitly use the standard paths.

When applying to your real home, the switcher updates GSettings appearance
preferences and the XFCE icon preference if those tools are available. It then
reloads Mango, running Kitty terminals, SwayNC, and Eww, and restarts a running
Waybar through the correct launcher. Desktop commands have timeouts; failures
are reported without discarding the installed configuration or its backup.
Waybar startup output is saved in `~/.local/state/bughunt-switch/desktop.log`.

Use `--no-reload` to change files only, skipping all desktop preference changes,
signals, and process starts. Applications that cache their theme may require a
restart, especially GTK/Qt apps and Geany/Kate. The lockscreen changes on its next
launch; it is never killed. Starship uses the new config at the next prompt, and
Fastfetch uses it on its next invocation. Apps that write preferences on exit may
overwrite a newly selected scheme; close the app and reapply in that case.

## Backups and restoration

Every switch gets a journal under `~/.local/state/bughunt-switch/`. Existing
paths are moved into that switch's `backup/` directory before replacement.
Stow directory links are unfolded into real directories before any child is
replaced, so writes cannot follow those links into the checkout. Unrelated
children stay linked to their original locations, including application state.
Managed files are regular copies after switching, so edits there do not update
the repository. Reapply after editing or pulling source configurations.

`restore` undoes the most recent switch, including original Stow links and saved
desktop preferences. Repeated restores walk back earlier switches. Current files
displaced by restoration are retained in `displaced/`, including edits made since
the switch. Backups are never automatically deleted. An ordinary file-installation
failure rolls back; an interrupted switch can be recovered with `restore` before
trying again. Do not run Stow or another theme manager concurrently with a switch.
Do not independently rearrange managed parent directories before restoration;
the script refuses to restore through a parent replaced with a symlink.

After switching, this script manages those installed files. Existing Stow
commands may report conflicts with the copies. Restore the original installation
before returning control to Stow.

Run the filesystem and rollback checks without affecting your desktop:

```sh
python3 -B scripts/tests/test_switch_theme.py
```
