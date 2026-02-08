# epicli v2.0.0

Personal cross-platform developer environment for Linux and macOS.

## Install

```bash
# Standard (no sudo required)
curl -fsSL https://tldr.icu/i | bash

# Developer (requires sudo)
curl -fsSL https://tldr.icu/i | bash -s -- --dev
```

## Manage

```bash
epicli status    # Show installed version
epicli check     # Check for updates
epicli update    # Update to latest
```

## Supported Platforms

Fedora, Debian, Ubuntu, Pop!_OS, Arch, Alpine, macOS

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
