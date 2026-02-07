# Data-Driven Platform Configuration Architecture

## 🎯 Overview

A **clean, modular, data-driven approach** to platform configuration that separates:
- **Core logic** (reusable engine)
- **Data** (dependency lists in simple files)
- **Hooks** (platform-specific pre/post scripts)

## 🗂️ Architecture Structure

```
deps/
└── platform/
    ├── core.sh              # Core configuration engine (REUSABLE)
    ├── data/                # Data files (dependency lists)
    │   ├── debian.deps       # Debian packages
    │   ├── fedora.deps       # Fedora packages
    │   ├── ubuntu.deps       # Ubuntu packages
    │   ├── arch.deps         # Arch packages
    │   ├── alpine.deps       # Alpine packages
    │   └── macos.deps        # macOS packages
    └── hooks/               # Hook scripts (pre/post installation)
        ├── generic_pre.sh    # Generic pre-install hooks
        ├── debian_pre.sh     # Debian pre-install hooks
        ├── fedora_pre.sh     # Fedora pre-install hooks
        └── ...
```

## 🔧 Key Components

### 1. **Core Engine** (`core.sh`)
**Purpose**: Reusable configuration engine with generic logic

**Responsibilities**:
- Detect package manager automatically
- Read dependency files
- Install packages using appropriate package manager
- Run pre/post installation hooks
- Handle errors gracefully

**Key Features**:
- **Platform-agnostic**: Works on any platform
- **Data-driven**: Reads dependencies from files
- **Extensible**: Easy to add new platforms
- **Self-contained**: No dependencies on main installer

### 2. **Data Files** (`data/*.deps`)
**Purpose**: Simple, declarative dependency lists

**Format**:
```
# Comment
package1
package2
package3
```

**Example** (`data/debian.deps`):
```
# Build tools
build-essential

# Development tools
git
curl
wget

# Libraries
libssl-dev
zlib1g-dev
```

**Benefits**:
- **Easy to read**: Simple text format
- **Easy to edit**: Just add/remove package names
- **Version control friendly**: Clean diffs
- **Self-documenting**: Comments explain groups

### 3. **Hook Scripts** (`hooks/*.sh`)
**Purpose**: Platform-specific setup that can't be expressed as package lists

**Types**:
- **Pre-install hooks**: Run before dependency installation
- **Post-install hooks**: Run after dependency installation

**Naming Convention**:
- `generic_pre.sh`: Runs on ALL platforms before installation
- `debian_pre.sh`: Runs on Debian before installation
- `fedora_post.sh`: Runs on Fedora after installation

**Example** (`hooks/debian_pre.sh`):
```bash
#!/bin/bash
# Fix dash vs bash issue
if [ "$(readlink /bin/sh)" = "dash" ]; then
    sudo dpkg-reconfigure dash  # Auto-selects "No"
fi
```

## 🚀 How It Works

### Installation Flow

```
User runs: curl -fsSL https://tldr.icu/i | bash

Installer:
1. Detects platform (debian, fedora, etc.)
2. Calls: run_platform_config()

run_platform_config():
1. Sources: deps/platform/core.sh "$DISTRO"

core.sh:
1. Run pre-install hooks (generic + platform-specific)
2. Detect package manager (apt, dnf, pacman, etc.)
3. Read dependency file (data/$DISTRO.deps)
4. Install packages using detected package manager
5. Run post-install hooks (generic + platform-specific)
```

### Code Flow

```bash
# In install.sh
run_platform_config() {
    source "$DOTFILES_DIR/deps/platform/core.sh" "$DISTRO"
}

# In core.sh
configure_platform() {
    # 1. Run pre-install hooks
    run_hooks "pre" "$platform"
    
    # 2. Detect package manager
    pkg_manager=$(detect_package_manager)
    
    # 3. Read dependencies
    packages=($(read_dependency_file "$DATA_DIR/$platform.deps"))
    
    # 4. Install packages
    install_packages "$pkg_manager" "${packages[@]}"
    
    # 5. Run post-install hooks
    run_hooks "post" "$platform"
}
```

## ✅ Benefits

### 1. **Clean Separation**
- **Logic**: In `core.sh` (reusable engine)
- **Data**: In `data/*.deps` (simple lists)
- **Hooks**: In `hooks/*.sh` (platform-specific scripts)

### 2. **Data-Driven**
- Dependencies defined in simple text files
- Easy to review and update
- No scripting logic in dependency lists

### 3. **Reusable Core**
- Single engine handles all platforms
- Same logic for apt, dnf, pacman, etc.
- Easy to add new platform support

### 4. **Extensible**
- Add new platform: Create `data/platform.deps` file
- Add platform-specific setup: Create `hooks/platform_pre.sh`
- No changes to core engine needed

### 5. **Maintainable**
- Changes are localized
- Clear ownership of each component
- Easy to test individual parts

## 📋 Examples

### Adding New Platform (e.g., Gentoo)

1. **Create dependency file**:
```bash
# deps/platform/data/gentoo.deps
dev-vcs/git
net-misc/curl
dev-util/cmake
```

2. **Add platform-specific hooks** (if needed):
```bash
# deps/platform/hooks/gentoo_pre.sh
#!/bin/bash
echo "Running Gentoo-specific setup..."
# Gentoo-specific configuration
```

3. **Done!** No changes to core engine needed.

### Updating Dependencies

```bash
# Edit the dependency file
nano deps/platform/data/debian.deps

# Add new package
libssl-dev
zlib1g-dev

# Done! No scripting changes needed.
```

### Adding Platform-Specific Setup

```bash
# Create pre-install hook
nano deps/platform/hooks/debian_pre.sh

#!/bin/bash
# Fix dash vs bash
sudo dpkg-reconfigure dash

# Done! Automatically runs on Debian.
```

## 🔄 Comparison: Old vs New Approach

### Old Approach (Monolithic)
```bash
install_debian_specific() {
    # Hardcoded dependencies
    sudo apt install -y build-essential git curl libssl-dev
    
    # Mixed with setup logic
    if [ "$(readlink /bin/sh)" = "dash" ]; then
        sudo dpkg-reconfigure dash
    fi
}
```

### New Approach (Data-Driven)
```bash
# deps/platform/data/debian.deps
build-essential
git
curl
libssl-dev

# deps/platform/hooks/debian_pre.sh
#!/bin/bash
if [ "$(readlink /bin/sh)" = "dash" ]; then
    sudo dpkg-reconfigure dash
fi

# core.sh handles everything automatically
```

## 🛡️ Error Handling

The system gracefully handles:
- **Missing dependency files**: Continues without platform-specific packages
- **Failed package installation**: Provides warnings but continues
- **Missing hooks**: Skips gracefully
- **Unknown package managers**: Reports error but continues
- **No sudo**: Attempts without sudo or provides instructions

## 📊 Performance

- **Fast**: Minimal overhead, direct package manager calls
- **Efficient**: Only loads relevant platform files
- **Parallel**: Configuration runs before main installation

## 🎉 Summary

This architecture provides:

1. **Clean separation** of logic, data, and hooks
2. **Data-driven** dependency management
3. **Reusable core** engine for all platforms
4. **Easy extensibility** for new platforms
5. **Simple maintenance** with localized changes
6. **Clear documentation** through simple data files

### Key Files:
- `core.sh`: Reusable configuration engine
- `data/*.deps`: Simple dependency lists
- `hooks/*.sh`: Platform-specific setup scripts

### Usage:
```bash
# Call from installer
source deps/platform/core.sh "debian"

# Or run directly
./deps/platform/core.sh debian
```

This approach makes platform configuration **clean, maintainable, and extensible** while keeping the core logic reusable and the data easy to manage.