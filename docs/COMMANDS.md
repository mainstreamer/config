# epicli Commands Reference

## CLI Commands

The `epicli` binary is available after installation at `~/.local/bin/epicli`.

```
epicli status          # Show installed version, mode, platform, and manifest
epicli check           # Check for available updates (compares local vs remote)
epicli update          # Update to latest version
epicli force-update    # Force reinstall (ignore version check)
epicli uninstall       # Remove epicli, symlinks, and Homebrew
epicli help            # Show help message
```

### Examples

```bash
epicli status          # epicli v2.3.0 (2026-02-09) ...
epicli check           # Installed: 2.3.0 / Available: 2.3.1
epicli update          # Updating 2.3.0 -> 2.3.1
```

---

## Shell Commands

These are available in interactive shells after installation. They are loaded from `~/.shared.d/`.

### Prompt & Themes

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
| `p2` | Rose Pine - dusty rose, pine, foam |
| `p3` | Everforest - green-core, sage and teal |
| `p4` | Kanagawa - Japanese ink violet/blue/green |
| `p5` | Aurora - rainbow purple/indigo/cyan |
| `p6` | Nord Ember - warm aurora twist on nordic |

```bash
themes catppuccin      # Switched to starship theme: catppuccin
themes p2              # Switched to starship theme: p2
themes default         # Back to gruvbox-rainbow
```

### File Navigation (fzf)

Requires: `fzf`

```bash
fo                     # Fuzzy-open: search files, preview with bat, open in $EDITOR
fcd                    # Fuzzy-cd: search directories, preview with eza, cd into selection
```

Keyboard shortcuts (when fzf is loaded):
- `Ctrl+T` — Fuzzy file search (insert path)
- `Ctrl+R` — Fuzzy history search
- `Alt+C` — Fuzzy cd into directory

### URL Decode

```bash
dec "hello%20world"            # hello world
dec "%2Fpath%2Fto%2Ffile"      # /path/to/file
dec "foo%3Dbar%26baz%3Dqux"    # foo=bar&baz=qux
echo "%40user" | dec           # @user (supports pipe input)
```

### Encryption

Requires: `openssl`, hardware key mounted via `key insert`

```bash
enc file.txt                   # Encrypt -> file.txt.enc
enc -d file.txt.enc            # Decrypt -> file.txt
enc -o output.txt file.txt     # Encrypt to specific output path
enc -d -o out.txt file.enc     # Decrypt to specific output path
```

### Hardware Key Management

Requires: physical USB key labeled "kstor"

```bash
key insert             # Mount key (read-only)
key insert -w          # Mount key (read-write)
key remove             # Unmount key
key stat               # Check key status (inserted/mode/none)
key path               # Print key file path
```

### VPN

Requires: `openvpn`, `enc`, `key`

```bash
hidevpn -c config.enc         # Connect using encrypted OpenVPN config
hidevpn -d                    # Disconnect
```

### Docker

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

### Recording (ffmpeg)

Requires: `ffmpeg`, webcam at `/dev/video0`, nvidia GPU for hardware encoding

```bash
rec <stream_url>       # Record webcam + stream stacked vertically (HQ, nvenc p7)
rec_fast <stream_url>  # Same but fast preset (nvenc p1, lower quality)
rec_sbs <stream_url>   # Record webcam + stream side-by-side
recd <stream_url>      # Record webcam + stream stacked (software x264)
```

### File Cleanup

```bash
cleanup                # Move media files (>512KB, last 1 day) to ~/Documents/Cleanup/YYYY-MM-DD/
cleanup 7              # Same but for files modified in the last 7 days
```

### System Utilities

```bash
where                  # Show your current country via IP geolocation
depcheck               # Check all expected dependencies are installed (from dep.lst)
version                # Alias for epicli status
fix01                  # Restart GDM (fix screen glitches, requires sudo)
```

### Git Shortcuts

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

### Directory & File Listing (eza)

Requires: `eza`

```bash
ls                     # eza with icons, directories first
ll                     # Long listing with git status and headers
la                     # Long listing including hidden files
l                      # Simple long listing
lt                     # Tree view (2 levels)
lta                    # Tree view (3 levels, including hidden)
tree                   # Tree view (alias for eza --tree)
```

### Navigation

```bash
..                     # cd ..
...                    # cd ../..
....                   # cd ../../..
z <query>              # zoxide: smart cd (learns your directories)
```

### Safety Aliases

```bash
rm                     # rm -i (confirm before delete)
cp                     # cp -i (confirm before overwrite)
mv                     # mv -i (confirm before overwrite)
```

### Other

```bash
cat                    # bat (syntax highlighting, no pager) — if bat is installed
grep                   # grep --color=auto
mkdir                  # mkdir -pv (create parents, verbose)
df                     # df -h (human-readable)
du                     # du -h (human-readable)
```
