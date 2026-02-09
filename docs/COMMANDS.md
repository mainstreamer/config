# epicli Commands Reference

View this anytime: `epicli man`

## CLI Commands

The `epicli` binary is available after installation at `~/.local/bin/epicli`.

```
epicli status          # Show installed version, mode, platform, and manifest
epicli check           # Check for available updates (compares local vs remote)
epicli update          # Update to latest version
epicli force-update    # Force reinstall (ignore version check)
epicli uninstall       # Remove epicli, symlinks, and Homebrew
epicli man             # Show this reference (paged)
epicli help            # Short help summary
```

### Examples

```bash
epicli status          # epicli v2.3.0 (2026-02-09) ...
epicli check           # Installed: 2.3.0 / Available: 2.3.1
epicli update          # Updating 2.3.0 -> 2.3.1
epicli man             # Open this manual in pager
```

---

## Prompt & Themes

```bash
themes                 # List all available starship themes (shows active)
themes <name>          # Switch to a theme
themes -l              # Same as no args — list themes
```

Available themes:

| Theme | Style |
|-------|-------|
| `gruvbox-rainbow` | Warm earth tones (default) |
| `minimal` | Clean, no powerline arrows (tokyo-night) |
| `nord` | Cool arctic blues and greens |
| `catppuccin` | Pastel mocha purples and teals |
| `p1` | Soft pastel peach/mint/blue |
| `p2` | Rose Pine — dusty rose, pine, foam |
| `p3` | Everforest — green-core sage and teal |
| `p4` | Kanagawa — Japanese ink violet/blue/green |
| `p5` | Aurora — rainbow purple/indigo/cyan |
| `p6` | Nord Ember — warm aurora twist on nordic |
| `p7` | Nord Frost — icy all-blue gradient |
| `p8` | Neon — electric pink/purple/cyan |
| `p9` | Slate — muted charcoal grey/brown/blue |
| `p10` | Honeybee — black bg, gold/amber text |
| `p11` | Nightshade — dark bg, violet/purple core |

```bash
themes catppuccin      # Switched to starship theme: catppuccin
themes p8              # Switched to starship theme: p8
themes default         # Back to gruvbox-rainbow
```

---

## File & Directory Navigation

### Keyboard Shortcuts (fzf)

These work in any interactive shell once fzf is loaded:

| Shortcut | Action |
|----------|--------|
| `Ctrl+T` | Fuzzy file search — inserts selected path at cursor |
| `Ctrl+R` | Fuzzy history search — browse and rerun past commands |
| `Alt+C` | Fuzzy cd — pick a directory and cd into it |
| `Esc, C` | Same as Alt+C (portable, works on macOS) |

**macOS note**: Alt+C requires iTerm2 configured with Left Option = Esc+
(Profiles > Keys > General > Left Option Key > Esc+).
Alternative: press Esc then C (two keystrokes, works everywhere).

### Commands

```bash
fo                     # Fuzzy-open file in editor (bat preview)
fcd                    # Fuzzy-cd into directory (eza tree preview)
fj                     # Same as fcd (shorter alias)
z <query>              # zoxide: smart cd (learns your frequent dirs)
..                     # cd ..
...                    # cd ../..
....                   # cd ../../..
```

### Directory Listing (eza)

Colors are aligned with the Nord palette.

```bash
ls                     # eza with icons, directories first
ll                     # Long listing with git status and headers
la                     # Long listing including hidden files
l                      # Simple long listing
lt                     # Tree view (2 levels)
lta                    # Tree view (3 levels, including hidden)
tree                   # Full tree view
```

### Recommended: broot (interactive tree)

For deeply nested projects, `broot` is a game-changer — it's an interactive
tree browser where you can expand/collapse directories, search, and navigate:

```bash
brew install broot     # Install (or: cargo install broot)
broot                  # Launch interactive tree browser
br                     # Same, with cd-on-exit (after first run setup)
```

Key bindings in broot:
- Type to filter/search the tree
- Arrow keys or hjkl to navigate
- Enter to open file or cd into directory
- Alt+Enter to cd and exit
- Ctrl+Left to collapse, Ctrl+Right to expand

---

## Git

### Shortcuts

```bash
g                      # git
gs                     # git status
ga                     # git add
gc                     # git commit
gp                     # git push
gl                     # git pull
gd                     # git diff
gco                    # git checkout
gb                     # git branch
glog                   # git log --oneline --graph --decorate
```

### Interactive Git with fzf

```bash
gbr                    # Interactive branch picker — shows all branches sorted
                       # by last commit, preview shows log, Enter = checkout

gfzf                   # Interactive commit browser — shows full log graph,
                       # preview shows diff for selected commit
```

`gbr` details:
- Lists local + remote branches sorted by most recent commit
- Preview pane shows last 20 commits on that branch
- Press Enter to checkout the branch
- Remote branches (origin/...) are auto-checked-out as local tracking branches

---

## URL Decode

```bash
dec "hello%20world"            # hello world
dec "%2Fpath%2Fto%2Ffile"      # /path/to/file
dec "foo%3Dbar%26baz%3Dqux"    # foo=bar&baz=qux
echo "%40user" | dec           # @user (supports pipe input)
```

---

## Encryption

Requires: `openssl`, hardware key mounted via `key insert`

```bash
enc file.txt                   # Encrypt -> file.txt.enc
enc -d file.txt.enc            # Decrypt -> file.txt
enc -o output.txt file.txt     # Encrypt to specific output path
enc -d -o out.txt file.enc     # Decrypt to specific output path
```

## Hardware Key Management

Requires: physical USB key labeled "kstor"

```bash
key insert             # Mount key (read-only)
key insert -w          # Mount key (read-write)
key remove             # Unmount key
key stat               # Check key status (inserted/mode/none)
key path               # Print key file path
```

## VPN

Requires: `openvpn`, `enc`, `key`

```bash
hidevpn -c config.enc         # Connect using encrypted OpenVPN config
hidevpn -d                    # Disconnect
```

---

## Docker

```bash
d                      # docker
dc                     # docker compose
dce <service>          # docker compose exec -it <service>
ds                     # Stop all running containers
dsh <container>        # Shell into a container (bash or sh)
dclean                 # Remove stopped containers and dangling images
cdc                    # Switch docker context (macOS Desktop)
cdc <context>          # Switch to specific docker context
```

---

## Recording (ffmpeg)

Requires: `ffmpeg`, webcam at `/dev/video0`, nvidia GPU for hardware encoding

```bash
rec <stream_url>       # Record webcam + stream stacked vertically (HQ, nvenc p7)
rec_fast <stream_url>  # Same but fast preset (nvenc p1, lower quality)
rec_sbs <stream_url>   # Record webcam + stream side-by-side
recd <stream_url>      # Record webcam + stream stacked (software x264)
```

---

## File Cleanup

```bash
cleanup                # Move media files (>512KB, last 1 day) to ~/Documents/Cleanup/YYYY-MM-DD/
cleanup 7              # Same but for files modified in the last 7 days
```

---

## System Utilities

```bash
where                  # Show your current country via IP geolocation
depcheck               # Check all expected dependencies are installed (from dep.lst)
version                # Alias for epicli status
fix01                  # Restart GDM (fix screen glitches, requires sudo)
```

---

## Overridden Defaults

```bash
cat                    # bat (syntax highlighting, no pager) — if bat installed
grep                   # grep --color=auto
mkdir                  # mkdir -pv (create parents, verbose)
df                     # df -h (human-readable)
du                     # du -h (human-readable)
rm                     # rm -i (confirm before delete)
cp                     # cp -i (confirm before overwrite)
mv                     # mv -i (confirm before overwrite)
```
