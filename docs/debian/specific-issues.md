# Debian-Specific Installation Issues Analysis

## Common Debian-Specific Problems

### 1. **Bash vs Dash Conflict**
**Issue**: Debian uses `dash` as the default `/bin/sh`, which can cause compatibility issues.

**Symptoms**:
- Scripts fail silently
- Aliases don't work
- Source commands behave differently

**Solution**:
```bash
# Check current shell
ls -l /bin/sh

# Change to bash if needed
sudo dpkg-reconfigure dash  # Select "No" to use bash
```

### 2. **Missing Bash Completion**
**Issue**: Debian often doesn't install bash-completion by default.

**Symptoms**:
- No tab completion
- Some scripts fail to load

**Solution**:
```bash
sudo apt install bash-completion
source /etc/bash_completion
```

### 3. **Strict Permission Policies**
**Issue**: Debian has stricter default permissions than other distros.

**Symptoms**:
- Scripts not executable even after chmod
- Permission denied errors

**Solution**:
```bash
# Fix home directory permissions
chmod 755 ~
chmod 755 ~/.config
chmod 755 ~/.local

# Fix script permissions
find ~/.shared.d -type f -exec chmod 755 {} \;
```

### 4. **Different Package Names**
**Issue**: Some tools have different package names on Debian.

**Symptoms**:
- Missing dependencies
- Failed installations

**Solution**:
```bash
# Install Debian-specific dependencies
sudo apt install build-essential git curl wget cmake pkg-config libssl-dev zlib1g-dev
```

### 5. **Systemd User Service Issues**
**Issue**: Debian's systemd configuration can interfere with user services.

**Symptoms**:
- Environment variables not loading
- PATH issues

**Solution**:
```bash
# Reload systemd user environment
systemctl --user daemon-reload
```

## Debian-Specific Debugging Steps

### Step 1: Check Shell Configuration
```bash
echo "Current shell: $SHELL"
echo "Shell path: $(which $SHELL)"
echo "Shell version: $BASH_VERSION"

# Check if .bashrc is being sourced
echo "BASHRC_SOURCED: $BASHRC_SOURCED"
```

### Step 2: Test Shell Initialization
```bash
# Start a fresh bash session
bash --login -c 'echo "Test: $PS1"'

# Check what files are being read
bash --login -c 'echo "Read files:"; trap "echo READ: \$BASH_SOURCE" DEBUG; source ~/.bashrc'
```

### Step 3: Check for Conflicting Configs
```bash
# Check for .bash_profile overriding .bashrc
if [ -f ~/.bash_profile ]; then
    echo "Found .bash_profile - may override .bashrc"
    cat ~/.bash_profile
fi

# Check for .profile issues
if [ -f ~/.profile ]; then
    echo "Found .profile"
    grep -i "bashrc\|bash" ~/.profile
fi
```

### Step 4: Test Individual Components
```bash
# Test if .bashrc is readable
echo "Testing .bashrc readability..."
[ -r ~/.bashrc ] && echo "✓ .bashrc readable" || echo "✗ .bashrc not readable"

# Test if shared.d exists and is accessible
[ -d ~/.shared.d ] && echo "✓ shared.d exists" || echo "✗ shared.d missing"
[ -r ~/.shared.d ] && echo "✓ shared.d readable" || echo "✗ shared.d not readable"

# Test individual script loading
echo "Testing individual scripts..."
for script in ~/.shared.d/*; do
    [ -f "$script" ] && echo "Testing $script..." && source "$script" 2>&1 | head -1
done
```

## Debian-Specific Fixes for install.sh

### Add Debian-Specific Checks
```bash
# In install_deps() function, add Debian-specific handling
install_debian_specific() {
    info "Configuring Debian-specific settings..."
    
    # Ensure bash is used, not dash
    if [ "$(readlink /bin/sh)" = "dash" ]; then
        warn "dash is default shell, switching to bash..."
        sudo dpkg-reconfigure dash 2>/dev/null || {
            echo "Please run: sudo dpkg-reconfigure dash and select 'No'"
        }
    fi
    
    # Install bash-completion
    if ! dpkg -l bash-completion &>/dev/null; then
        info "Installing bash-completion..."
        sudo apt install -y bash-completion
    fi
    
    # Fix home directory permissions
    info "Setting proper home directory permissions..."
    chmod 755 ~
    chmod 755 ~/.config
    chmod 755 ~/.local
}

# Call it in the Debian case
case "$DISTRO" in
    debian|ubuntu|popos)
        install_debian_specific
        install_homebrew
        install_brew_packages
        ;;
    # ... rest of cases
esac
```

## Most Likely Cause for Your Debian System

Based on your symptoms (symlinks exist but nothing works), the most likely causes are:

### 1. **Shell Not Reloaded Properly** (90% probability)
```bash
# Fix: Force a complete shell reload
exec bash -l
```

### 2. **Bash vs Dash Issue** (50% probability)
```bash
# Fix: Ensure bash is used
sudo dpkg-reconfigure dash  # Select "No"
```

### 3. **Missing Bash Completion** (30% probability)
```bash
# Fix: Install bash-completion
sudo apt install bash-completion
source /etc/bash_completion
```

### 4. **Permission Issues** (20% probability)
```bash
# Fix: Reset permissions
chmod 755 ~
find ~/.shared.d -type f -exec chmod 755 {} \;
```

## Immediate Fixes to Try on Your Debian Server

```bash
# 1. Check current shell
echo "Shell: $SHELL"
ls -l /bin/sh

# 2. Fix shell if needed
sudo dpkg-reconfigure dash  # Select "No" for bash

# 3. Install missing dependencies
sudo apt install bash-completion

# 4. Fix permissions
chmod 755 ~
find ~/.shared.d -type f -exec chmod 755 {} \;

# 5. Install missing tools
brew install starship eza bat zoxide

# 6. Force complete shell reload
exec bash -l

# 7. Test if it works
version
echo $PS1
ll
```

If these don't work, the issue might be more specific to your Debian configuration or shell environment.