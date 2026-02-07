# Platform Installer Explained: Detailed Walkthrough

## 🎯 Overview

The `deps/platform/installer.sh` script is the **platform installation driver** that orchestrates the entire platform configuration process. It's not a "core" component, but rather a **driver** that coordinates the execution of hooks, dependency installation, and platform-specific setup.

## 🚗 The Driver Analogy

Think of it like a **bus driver**:
- **Driver** = `installer.sh` (coordinates everything)
- **Route** = Platform configuration process
- **Passengers** = Hooks and dependencies
- **Stops** = Pre-install → Install → Post-install

## 📋 High-Level Flow

```
Platform Installer (installer.sh)
│
├── 1. Initialize Configuration
│   ├── Set up directories
│   └── Define variables
│
├── 2. Run Pre-Installation Hooks
│   ├── generic_pre.sh (all platforms)
│   └── platform_pre.sh (platform-specific)
│
├── 3. Detect Package Manager
│   └── apt, dnf, pacman, apk, or brew
│
├── 4. Read Dependency File
│   └── data/$PLATFORM.deps
│
├── 5. Install Packages
│   └── Using detected package manager
│
└── 6. Run Post-Installation Hooks
    ├── generic_post.sh (all platforms)
    └── platform_post.sh (platform-specific)
```

## 🔍 Detailed Step-by-Step Walkthrough

### 1. **Initialization**

```bash
# Configuration
PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$PLATFORM_DIR/data"
HOOKS_DIR="$PLATFORM_DIR/hooks"
```

**What it does**:
- Sets up directory paths relative to the script location
- `PLATFORM_DIR`: Where the script is located
- `DATA_DIR`: Where dependency files are stored
- `HOOKS_DIR`: Where hook scripts are stored

**Why it matters**: Makes the script portable and self-contained.

### 2. **Detect Package Manager**

```bash
detect_package_manager() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apk &>/dev/null; then
        echo "apk"
    elif command -v brew &>/dev/null; then
        echo "brew"
    else
        echo "unknown"
    fi
}
```

**What it does**:
- Checks which package managers are available
- Returns the name of the first one found
- Falls back to "unknown" if none found

**Why it matters**:
- Automatically adapts to the system
- No hardcoding of package managers
- Works on any platform

### 3. **Install Packages**

```bash
install_packages() {
    local pkg_manager="$1"
    shift
    local packages=("$@")
    
    echo "INFO: Installing packages with $pkg_manager..."
    
    case "$pkg_manager" in
        apt)
            if command -v sudo &>/dev/null; then
                sudo apt update
                sudo apt install -y "${packages[@]}"
            else
                apt update
                apt install -y "${packages[@]}"
            fi
            ;;
        # ... other package managers
    esac
}
```

**What it does**:
- Takes package manager name and package list
- Installs packages using the appropriate commands
- Handles sudo vs non-sudo scenarios

**Why it matters**:
- Single function handles all package managers
- Consistent interface regardless of platform
- Graceful handling of permission scenarios

### 4. **Read Dependency File**

```bash
read_dependency_file() {
    local dep_file="$1"
    local packages=()
    
    if [ ! -f "$dep_file" ]; then
        echo "WARN: Dependency file not found: $dep_file"
        return 1
    fi
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
            continue
        fi
        packages+=("$line")
    done < "$dep_file"
    
    echo "${packages[@]}"
}
```

**What it does**:
- Reads a dependency file line by line
- Skips comments (lines starting with #)
- Skips empty lines
- Returns array of package names

**Why it matters**:
- Handles the simple data format
- Robust against malformed files
- Provides clean package list to install function

### 5. **Run Hooks**

```bash
run_hooks() {
    local hook_type="$1"
    local platform="$2"
    local hook_file=""
    
    # Run generic hooks first
    hook_file="$HOOKS_DIR/${hook_type}_pre.sh"
    if [ -f "$hook_file" ]; then
        echo "INFO: Running generic $hook_type hooks..."
        source "$hook_file"
    fi
    
    # Run platform-specific hooks
    hook_file="$HOOKS_DIR/${platform}_${hook_type}.sh"
    if [ -f "$hook_file" ]; then
        echo "INFO: Running $platform $hook_type hooks..."
        source "$hook_file"
    fi
}
```

**What it does**:
- Runs hook scripts in specific order
- First: generic hooks (apply to all platforms)
- Then: platform-specific hooks
- Only runs hooks that exist

**Why it matters**:
- Provides extension points for platform-specific setup
- Maintains consistent execution order
- Gracefully handles missing hooks

### 6. **Main Configuration Function**

```bash
configure_platform() {
    local platform="$1"
    local dep_file="$DATA_DIR/${platform}.deps"
    local packages=()
    local pkg_manager=""
    
    echo "INFO: Configuring platform: $platform"
    
    # 1. Run pre-install hooks
    run_hooks "pre" "$platform"
    
    # 2. Detect package manager
    pkg_manager=$(detect_package_manager)
    echo "INFO: Detected package manager: $pkg_manager"
    
    # 3. Read dependencies
    if [ -f "$dep_file" ]; then
        packages=($(read_dependency_file "$dep_file"))
        echo "INFO: Found ${#packages[@]} packages to install"
        
        # 4. Install packages
        if [ ${#packages[@]} -gt 0 ]; then
            install_packages "$pkg_manager" "${packages[@]}"
        fi
    fi
    
    # 5. Run post-install hooks
    run_hooks "post" "$platform"
    
    echo "OK: Platform configuration complete for $platform"
}
```

**What it does**:
- Orchestrates the entire configuration process
- Calls other functions in the right order
- Provides status updates
- Handles edge cases

**Why it matters**:
- This is the "driver" that coordinates everything
- Single point of control for the process
- Clear, linear flow

## 🎯 Example: Debian Configuration

```bash
# User runs installer on Debian
./deps/platform/installer.sh debian

# 1. Initialize
PLATFORM_DIR=/home/user/.epicli-conf/deps/platform
DATA_DIR=$PLATFORM_DIR/data
HOOKS_DIR=$PLATFORM_DIR/hooks

# 2. Run pre-install hooks
# First: generic_pre.sh
source $HOOKS_DIR/generic_pre.sh
# Installs bash-completion, sets permissions

# Then: debian_pre.sh  
source $HOOKS_DIR/debian_pre.sh
# Fixes dash→bash issue

# 3. Detect package manager
pkg_manager=$(detect_package_manager)
# Returns: apt

# 4. Read dependencies
packages=($(read_dependency_file "$DATA_DIR/debian.deps"))
# Returns: build-essential, git, curl, libssl-dev, zlib1g-dev

# 5. Install packages
install_packages "apt" "${packages[@]}"
# Runs: sudo apt update && sudo apt install -y build-essential git curl libssl-dev zlib1g-dev

# 6. Run post-install hooks
# generic_post.sh (if exists)
# debian_post.sh (if exists)

# Done!
```

## 🔧 Key Design Principles

### 1. **Single Responsibility**
Each function does one thing well:
- `detect_package_manager()`: Only detects package manager
- `install_packages()`: Only installs packages
- `read_dependency_file()`: Only reads files
- `run_hooks()`: Only runs hooks
- `configure_platform()`: Only coordinates

### 2. **Data-Driven**
- Dependencies come from data files
- No hardcoded package lists
- Easy to modify without changing logic

### 3. **Platform-Agnostic**
- Same code works on all platforms
- Package manager detection handles differences
- Hooks provide platform-specific extensions

### 4. **Graceful Degradation**
- Missing files? Continue anyway
- Failed commands? Warn but continue
- No sudo? Try without or provide instructions

### 5. **Clear Separation**
- Logic vs Data
- Generic vs Platform-specific
- Pre vs Post installation

## 🛠️ Functions Reference

### `detect_package_manager()`
**Purpose**: Identify which package manager is available
**Returns**: String (apt, dnf, pacman, apk, brew, or unknown)
**Used by**: `configure_platform()`

### `install_packages(pkg_manager, packages...)`
**Purpose**: Install packages using specified package manager
**Parameters**: Package manager name, list of packages
**Returns**: 0 on success, 1 on failure
**Used by**: `configure_platform()`

### `read_dependency_file(file)`
**Purpose**: Read and parse dependency file
**Parameters**: Path to dependency file
**Returns**: Array of package names (via echo)
**Used by**: `configure_platform()`

### `run_hooks(hook_type, platform)`
**Purpose**: Execute pre or post installation hooks
**Parameters**: Hook type (pre/post), platform name
**Returns**: None (sources hook scripts)
**Used by**: `configure_platform()`

### `configure_platform(platform)`
**Purpose**: Main driver function
**Parameters**: Platform name (debian, fedora, etc.)
**Returns**: 0 on success, 1 on failure
**Used by**: Main script or directly

## 📊 Execution Flow Diagram

```
configure_platform("debian")
│
├─ run_hooks("pre", "debian")
│  ├─ source hooks/generic_pre.sh
│  └─ source hooks/debian_pre.sh
│
├─ detect_package_manager()
│  └─ return "apt"
│
├─ read_dependency_file("data/debian.deps")
│  └─ return (build-essential git curl libssl-dev zlib1g-dev)
│
├─ install_packages("apt", build-essential, git, curl, libssl-dev, zlib1g-dev)
│  └─ sudo apt update && sudo apt install -y ...
│
└─ run_hooks("post", "debian")
   ├─ source hooks/generic_post.sh
   └─ source hooks/debian_post.sh
```

## 🎉 Summary

The `installer.sh` script is a **platform installation driver** that:

1. **Coordinates** the configuration process
2. **Delegates** to specialized functions
3. **Orchestrates** hooks and dependencies
4. **Adapts** to different platforms automatically
5. **Provides** clear status updates

It's **not** a core system component, but rather a **driver** that makes the right things happen in the right order, using the right tools for each platform.

The architecture is:
- **Clean**: Separation of concerns
- **Modular**: Easy to extend
- **Data-driven**: Simple to maintain
- **Robust**: Handles edge cases gracefully
- **Portable**: Works on any platform

This makes platform configuration **simple, maintainable, and extensible** while keeping the core logic reusable and the data easy to manage.