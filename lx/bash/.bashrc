# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
    PATH="$PATH:$HOME/.config/composer/vendor/bin" # add global composer packages folder
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

EXCLUDE_FILES=("dep.lst")
# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            # Extract the filename from the full path
            filename=$(basename "$rc")
            
            # Check if the file is in the exclusion list
            if [[ " ${EXCLUDE_FILES[@]} " =~ " $filename " ]]; then
                echo "Skipping $filename (excluded)"
            else
                # Source the file if it's not excluded
                . "$rc"
            fi
        fi
    done
fi
unset rc
#Built Sun 23 Mar 21:46:28 GMT 2025
