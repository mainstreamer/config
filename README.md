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
