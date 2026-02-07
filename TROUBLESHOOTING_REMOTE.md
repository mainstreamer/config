# Troubleshooting Guide for Remote Server Installation

## Issue Summary

From the `ls -la` output, the symlinks are correctly created but configurations aren't being applied. Here are the likely causes and solutions:

## Root Causes

### 1. **Shell Not Reloaded Properly**
The most common issue - the shell session wasn't properly reloaded after installation.

### 2. **Missing Executable Permissions**
Some scripts in `.shared.d/` may not have executable permissions.

### 3. **Starship Not Installed**
The prompt styling requires `starship` to be installed.

### 4. **Path Issues**
The `PATH` modifications may not be taking effect.

## Immediate Fixes to Run on Remote Server

### Step 1: Check if starship is installed
```bash
command -v starship || echo "starship not found"
```

### Step 2: Manually source the configuration
```bash
source ~/.bashrc
```

### Step 3: Check for errors
```bash
source ~/.bashrc 2>&1 | head -20
```

### Step 4: Verify shared.d scripts are executable
```bash
find ~/.shared.d -type f -name "*.sh" -exec chmod +x {} \;
```

### Step 5: Test individual components
```bash
# Test aliases
source ~/.shared.d/aliases
echo "Aliases loaded: $(alias | wc -l)"

# Test prompt
source ~/.shared.d/prompt
echo "Prompt test: $PS1"
```

## Debugging Commands

### Check what's being sourced
```bash
echo "=== Checking .bashrc ==="
cat ~/.bashrc | grep -v "^#" | grep -v "^$"

echo "=== Checking shared.d contents ==="
ls -la ~/.shared.d/

echo "=== Testing starship ==="
if command -v starship; then
    echo "starship installed: $(starship --version)"
else
    echo "starship NOT installed"
fi
```

### Check PATH
```bash
echo "Current PATH:"
echo $PATH | tr ':' '\n' | nl
```

## Common Solutions

### 1. **Install Missing Dependencies**
```bash
# Install starship for prompt
brew install starship

# Install other CLI tools
brew install eza bat zoxide
```

### 2. **Fix Permissions**
```bash
chmod +x ~/.shared.d/*
chmod +x ~/.epicli-conf/shared/shared.d/*
```

### 3. **Force Shell Reload**
```bash
exec bash -l
```

### 4. **Check for Conflicting Configs**
```bash
# Check if .bash_profile is overriding .bashrc
if [ -f ~/.bash_profile ]; then
    echo "Found .bash_profile - may override .bashrc"
    cat ~/.bash_profile
fi
```

## Verification Commands

### Test if configurations are working
```bash
# Test aliases
type ll 2>/dev/null | grep -q "alias" && echo "✓ ll alias works" || echo "✗ ll alias missing"

# Test prompt
echo $PS1 | grep -q "starship" && echo "✓ starship prompt active" || echo "✗ starship prompt missing"

# Test PATH
echo $PATH | grep -q ".cargo/bin" && echo "✓ cargo in PATH" || echo "✗ cargo missing from PATH"
```

## Permanent Fix

Add this to the end of your `install.sh` script to ensure proper setup:

```bash
# Ensure proper permissions
echo "Setting proper permissions..."
find "$DOTFILES_DIR/shared/shared.d" -type f -exec chmod +x {} \;
chmod +x "$DOTFILES_DIR/shared/.bashrc"
chmod +x "$DOTFILES_DIR/shared/.zshrc"

# Verify critical tools are installed
echo "Verifying critical tools..."
if ! command -v starship &>/dev/null; then
    info "Installing starship for prompt..."
    brew install starship
fi

if ! command -v eza &>/dev/null; then
    info "Installing eza for better ls..."
    brew install eza
fi

if ! command -v bat &>/dev/null; then
    info "Installing bat for better cat..."
    brew install bat
fi

if ! command -v zoxide &>/dev/null; then
    info "Installing zoxide for better cd..."
    brew install zoxide
fi

# Force source the new configuration
info "Activating new configuration..."
source "$HOME/.bashrc"

ok "Configuration activated!"
```

## Final Verification

After applying fixes, run:
```bash
# Should show epicli-conf version
version

# Should show styled prompt
PS1=$(starship prompt)

# Should show enhanced ls
ll
```

If these work, your installation is properly configured!