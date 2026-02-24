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
| `s1` | Daft Punk — hot magenta/gold/cyan ▓▒░ |
| `s2` | Moderat — warm rust/amber/teal ▓▒░ |
| `s3` | Neon Grid — pure red/green/blue ▓▒░ |
| `s4` | Pastel Grid — muted rose/mint/periwinkle ▓▒░ |
| `s5` | Fog Machine — desaturated wine/olive/steel ▓▒░ |

```bash
themes catppuccin      # Switched to starship theme: catppuccin
themes s1              # Switched to starship theme: s1
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
| `Alt+O` | Fuzzy open file in editor (Enter=nvim, Alt+Enter=preview) |
| `Alt+F` | Fuzzy files **and** folders — files open in editor, dirs cd into |
| `Esc, C` | Same as Alt+C (portable fallback) |

**macOS note**: Alt keys require iTerm2 with Left Option = Esc+
(Profiles > Keys > General > Left Option Key > Esc+).
macOS sends: Alt+C → `ç`, Alt+O → `ø`, Alt+F → `ƒ`.

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

### Shortcuts (oh-my-zsh compatible)

**Status & Log**
```bash
gs / gst               # git status
gss                    # git status --short
glog                   # git log --oneline --graph --decorate
gloga                  # git log --oneline --graph --decorate --all
glg                    # git log --stat
gsh                    # git show
```

**Add & Commit**
```bash
ga                     # git add
gaa                    # git add --all
gapa                   # git add --patch
gc                     # git commit --verbose
gc!                    # git commit --amend
gca                    # git commit --all --verbose
gca!                   # git commit --all --amend
gcam "fix login bug"   # git add -A && commit; auto-prefixes ticket if branch=ABC-123
                       # e.g. on branch PROJ-42: commits as "PROJ-42: fix login bug"
gcmsg                  # git commit --message
gcn!                   # git commit --amend --no-edit
```

**Branch & Checkout**
```bash
gbr                    # git branch
gba                    # git branch --all
gbd                    # git branch --delete
gbD                    # git branch --delete --force
gco                    # git checkout
gcb                    # git checkout -b (new branch)
gsw                    # git switch
gswc                   # git switch --create
```

**Push, Pull & Fetch**
```bash
gp                     # git push origin <current-branch> (auto branch name)
gpf                    # git push --force-with-lease origin <current-branch>
gpf!                   # git push --force origin <current-branch>
gpsup                  # git push --set-upstream origin <current-branch>
gl                     # git pull
gf                     # git fetch
gfo                    # git fetch origin
```

**Diff** (powered by delta — syntax-highlighted, side-by-side)
```bash
gd                     # git diff (working tree vs index)
gdh                    # git diff HEAD (unstaged vs last commit)
gdhf                   # git diff HEAD --stat (files + lines summary only)
gds                    # git diff --staged
gdca                   # git diff --cached
gdm                    # diff current branch vs main/master (whole branch diff)
gdmf                   # summary of branch diff vs main (files + lines only)
gdl                    # diff vs last commit (HEAD~1)
gdl 3                  # diff vs 3 commits ago (HEAD~3)
gdc                    # fzf commit picker — select any commit to diff against
gdc abc1234            # diff vs specific commit hash
```

**Merge & Rebase**
```bash
gm                     # git merge
gma                    # git merge --abort
grb                    # git rebase
grbc                   # git rebase --continue
grba                   # git rebase --abort
grbs                   # git rebase --skip
gri                    # git rebase -i HEAD~2 (default: last 2 commits)
gri 5                  # git rebase -i HEAD~5
```

**Reset & Restore**
```bash
grh                    # git reset
grhh                   # git reset --hard
grs                    # git restore
grss                   # git restore --staged
gcl                    # git clean -fd
```

**Stash**
```bash
gsta                   # git stash push
gstp                   # git stash pop
gstaa                  # git stash apply
gstd                   # git stash drop
gstl                   # git stash list
```

**Cherry-pick, Remote & Tags**
```bash
gcp                    # git cherry-pick
gcpa                   # git cherry-pick --abort
gcpc                   # git cherry-pick --continue
gr                     # git remote
grv                    # git remote --verbose
gt                     # git tag
lg                     # lazygit — full terminal UI for git
```

### Fancy Diffs (delta)

All `git diff`, `git show`, `git log -p` output is automatically rendered by
**delta** with syntax highlighting, line numbers, and side-by-side view.
No extra commands needed — just use `gd`, `git diff`, `git show` as usual.

Navigate in delta output: `n` = next file, `N` = previous file.

```bash
gitdiff file1 file2    # Compare any two files with delta (not just git-tracked)
```

### Interactive Git with fzf

```bash
gb                     # Interactive branch picker — all branches sorted by
                       # last commit, preview shows log, Enter = checkout

gitlog                 # Interactive commit browser — full log graph,
                       # preview shows diff for selected commit

gdc                    # Commit diff picker — fzf list of all commits,
                       # preview shows changed files, Enter = diff vs that commit
```

`gb` details:
- Lists local + remote branches sorted by most recent commit
- Preview pane shows last 20 commits on that branch
- Press Enter to checkout the branch
- Remote branches (origin/...) are auto-checked-out as local tracking branches

### Branch Graph

```bash
gitgraph               # Pretty colored branch graph with dates and authors
```

Shows all branches as a compact colored graph:
```
* a1b2c3d (2 hours ago) feat: add themes - user  (HEAD -> master)
* e4f5g6h (3 hours ago) fix: starship presets - user
| * i7j8k9l (1 day ago) wip: experiment - user  (origin/feature)
|/
* m0n1o2p (2 days ago) refactor: modularize - user
```

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
