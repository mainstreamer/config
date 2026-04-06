# epicli

Personal cross-platform developer environment for Linux and macOS.

## Installation

### Quick install (curl)

```bash
# Standard (no sudo required)
curl -fsSL https://tldr.icu/i | bash

# Developer mode (requires sudo — full dev toolchain, language servers, etc.)
curl -fsSL https://tldr.icu/i | bash -s -- --dev
```

### Homebrew

```bash
brew install mainstreamer/epicli/epicli
epicli          # run once to complete setup (install deps, create symlinks)
```

After the Homebrew install, running `epicli` once is required to bootstrap the environment (install dependencies, set up shell config, create symlinks).

## Usage

```bash
epicli status    # Show installed version and profile
epicli check     # Check for updates
epicli update    # Update to latest version
epicli uninstall # Remove epicli and all managed config
```

## Updating

- **curl install:** `epicli update`
- **Homebrew install:** `brew upgrade epicli` or `epicli update`

> **Tip:** Run `epicli help` to see all commands, shell extras, and the Homebrew install/update option.

## Uninstalling

```bash
epicli uninstall
```

This removes the epicli directory, CLI, managed config files (`.bashrc`, `.zshrc`, nvim config, starship, etc.), and Homebrew if it was installed by epicli. You'll be prompted to confirm before anything is deleted.

## Supported Platforms

| Platform | Package method |
|----------|---------------|
| Fedora | Homebrew |
| Debian | Homebrew |
| Ubuntu / Pop!_OS | apt + GitHub releases |
| Arch | pacman + AUR |
| Alpine | apk + cargo |
| macOS | Homebrew |

## Install Profiles

- **Standard** (default) — no sudo required. CLI tools (nvim, fzf, rg, fd, bat, eza, zoxide, starship, lazygit, delta, gh, htop, btop, atuin, tree), shell aliases, prompt themes, docker helpers, nvim with basic editing plugins.
- **Local** (`--local`) — everything in standard plus personal machine tools.
- **Dev** (`--dev`) — requires sudo. Everything in standard plus full dev toolchain, language servers, and nvim autocompletion.

See [CLAUDE.md](CLAUDE.md) for full documentation.

## Deployment

After making changes, use one of the `make` release commands to deploy. The entire flow is automated — a single command bumps the version, deploys to the server, pushes to GitHub, and updates Homebrew.

### Step-by-step release flow

```bash
# 1. Make and test your changes
make test                    # dry-run, see what would change
make install                 # apply locally to verify

# 2. Commit your changes (everything except install.sh version bump)
git add -A && git commit -m "description of changes"

# 3. Release — pick one:
make patch                   # 3.4.16 → 3.4.17
make minor                   # 3.4.16 → 3.5.0
make major                   # 3.4.16 → 4.0.0
```

### What `make patch` does under the hood

1. **Bumps version** — updates `VERSION=` in `install.sh` and the `latest` file
2. **Commits & tags** — `git commit -m "v3.4.17"` + `git tag v3.4.17`
3. **Deploys to server** — builds archive, signs with Ed25519 key, uploads via `scp` to `tldr.icu`
4. **Pushes to GitHub** — `git push && git push --tags`
5. **GitHub Actions** (triggered by the tag push):
   - Creates a GitHub release with a tarball attached
   - Computes SHA256 of the tarball
   - Clones `mainstreamer/homebrew-epicli`, updates the formula with the new URL + SHA256
   - Pushes the updated formula

```
make patch
  ├─ local:  bump → commit → tag → archive → sign → scp → push
  └─ CI:     tag triggers GitHub Actions → release → update Homebrew formula
```

### How Homebrew gets updated

Homebrew uses a **tap** (`mainstreamer/homebrew-epicli`) containing a formula that points to a GitHub release tarball. When a new tag is pushed, the GitHub Actions workflow automatically:

1. Builds a new tarball from the tagged commit
2. Attaches it to a GitHub release
3. Updates the formula in `homebrew-epicli` with the new download URL and SHA256

Users then get the update via `brew upgrade epicli`.

### Verifying a release

```bash
curl -fsSL https://tldr.icu/latest              # server version
gh release list --repo mainstreamer/config       # GitHub release
brew update && brew info mainstreamer/epicli/epicli  # Homebrew formula
```

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for prerequisites (signing key, SSH access, GitHub secrets).

## Troubleshooting

### Neovim Treesitter Issues

If you encounter the error `module 'nvim-treesitter.configs' not found` when starting Neovim:

```bash
# Run the fix script
./scripts/fix-treesitter.sh

# Or manually:
nvim --headless "+TSInstall all" +qa
nvim --headless "+Lazy! sync" +qa
```

This installs the required treesitter parsers for syntax highlighting.
