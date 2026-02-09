#!/bin/bash
# Complete installation test script for Debian/Ubuntu
# Usage: /bin/bash -c "$(curl -fsSL URL)"
# NOTE: Do NOT use "curl | bash" - stdin must be free for password prompts!

VERSION="0.5.0"
LOGFILE="/tmp/test_install_$$.log"

echo "=== Complete Installation Test (v$VERSION) ==="
echo "Log: $LOGFILE"
echo ""

# Get current username
USERNAME=$(whoami)
echo "User: $USERNAME"

# =============================================================================
# Sudo wrapper - uses stored password via sudo -S
# This approach is used by many professional installers
# =============================================================================
SUDO_PASS=""

# Ask for password once and validate it
init_sudo() {
    if command -v sudo &>/dev/null; then
        echo ""
        echo "Sudo password required (will be asked only once):"
        read -s -p "[sudo] password for $USERNAME: " SUDO_PASS
        echo ""

        # Validate password
        if echo "$SUDO_PASS" | sudo -S -v 2>/dev/null; then
            echo "✓ Sudo password verified"
            return 0
        else
            echo "✗ Invalid password"
            return 1
        fi
    fi
}

# Run command with sudo using stored password
do_sudo() {
    echo "$SUDO_PASS" | sudo -S "$@" 2>/dev/null
}

# Silent apt-get with sudo
apt_install() {
    echo "$SUDO_PASS" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" >> "$LOGFILE" 2>&1
}

apt_update() {
    echo "$SUDO_PASS" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get update -qq >> "$LOGFILE" 2>&1
}

apt_upgrade() {
    echo "$SUDO_PASS" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq >> "$LOGFILE" 2>&1
}

# =============================================================================
# Step 1: Install sudo (if needed) - Debian only
# =============================================================================
echo ""
echo "Step 1: Checking/installing sudo"

if command -v sudo &>/dev/null; then
    echo "✓ sudo is already installed"
else
    echo "sudo not found. Installing..."
    echo -n "Enter ROOT password: "

    # Add user to sudoers with extended timeout (30 min)
    SUDOERS_LINE="$USERNAME ALL=(ALL:ALL) ALL"
    SUDOERS_TIMEOUT="Defaults:$USERNAME timestamp_timeout=30"

    if su -c "LC_ALL=C apt-get update -qq >/dev/null 2>&1 && LC_ALL=C apt-get install -y -qq sudo >/dev/null 2>&1 && printf '%s\n' '$SUDOERS_LINE' '$SUDOERS_TIMEOUT' >> /etc/sudoers"; then
        echo ""
        echo "✓ sudo installed"
    else
        echo ""
        echo "✗ Failed to install sudo"
        exit 1
    fi
fi

# =============================================================================
# Step 2: Get sudo password (will be used for all subsequent operations)
# =============================================================================
echo ""
echo "Step 2: Initializing sudo"

if ! init_sudo; then
    echo "✗ Failed to initialize sudo"
    exit 1
fi

# =============================================================================
# Step 3: Update system packages
# =============================================================================
echo ""
echo "Step 3: Updating system packages"

echo "Updating package lists..."
if apt_update; then
    echo "✓ Package lists updated"
else
    echo "✗ Failed to update package lists"
fi

echo "Upgrading packages..."
if apt_upgrade; then
    echo "✓ Packages upgraded"
else
    echo "! Package upgrade had issues (continuing)"
fi

# =============================================================================
# Step 4: Install core utilities via apt
# =============================================================================
echo ""
echo "Step 4: Installing core utilities via apt"

for pkg in curl unzip coreutils; do
    if dpkg -l "$pkg" &>/dev/null; then
        echo "✓ $pkg already installed"
    else
        echo "Installing $pkg..."
        if apt_install "$pkg"; then
            echo "✓ $pkg installed"
        else
            echo "✗ Failed to install $pkg"
        fi
    fi
done

# =============================================================================
# Step 5: Install git via apt
# =============================================================================
echo ""
echo "Step 5: Installing git via apt"

if command -v git &>/dev/null; then
    echo "✓ git is already installed"
else
    echo "Installing git..."
    if apt_install git; then
        echo "✓ git installed"
    else
        echo "✗ Failed to install git"
        exit 1
    fi
fi

# =============================================================================
# Step 6: Install Homebrew
# =============================================================================
echo ""
echo "Step 6: Installing Homebrew"

if command -v brew &>/dev/null || [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    echo "✓ Homebrew is already installed"
    [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
    echo "Installing Homebrew (this takes a while)..."

    # Ensure directory exists
    do_sudo mkdir -p /home/linuxbrew/
    do_sudo chmod 755 /home/linuxbrew/

    # Install Homebrew
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOGFILE" 2>&1; then
        echo "✓ Homebrew installed"
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        echo "✗ Failed to install Homebrew"
        exit 1
    fi
fi

# =============================================================================
# Step 7: Install extra utilities via apt (Linux-native)
# =============================================================================
echo ""
echo "Step 7: Installing extra utilities via apt"

for pkg in bat eza htop; do
    if command -v "$pkg" &>/dev/null || command -v "${pkg}cat" &>/dev/null; then
        echo "✓ $pkg already installed"
    else
        echo "Installing $pkg..."
        if apt_install "$pkg"; then
            echo "✓ $pkg installed"
        else
            echo "! Failed to install $pkg (non-critical)"
        fi
    fi
done

# =============================================================================
# Step 8: Install utilities via brew
# =============================================================================
echo ""
echo "Step 8: Installing utilities via brew"

for pkg in ncurses gh fzf zoxide yazi; do
    if command -v "$pkg" &>/dev/null; then
        echo "✓ $pkg already installed"
    else
        echo "Installing $pkg via brew..."
        if brew install "$pkg" >> "$LOGFILE" 2>&1; then
            echo "✓ $pkg installed"
        else
            echo "! Failed to install $pkg (non-critical)"
        fi
    fi
done

# =============================================================================
# Step 9: Install zsh via apt
# =============================================================================
echo ""
echo "Step 9: Installing zsh via apt"

if command -v zsh &>/dev/null; then
    echo "✓ zsh is already installed"
else
    echo "Installing zsh..."
    if apt_install zsh; then
        echo "✓ zsh installed"
    else
        echo "✗ Failed to install zsh"
        exit 1
    fi
fi

# =============================================================================
# Step 10: Install oh-my-posh
# =============================================================================
echo ""
echo "Step 10: Installing oh-my-posh"

if command -v oh-my-posh &>/dev/null || [[ -x ~/.local/bin/oh-my-posh ]]; then
    echo "✓ oh-my-posh is already installed"
else
    echo "Installing oh-my-posh..."
    if curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin >> "$LOGFILE" 2>&1; then
        echo "✓ oh-my-posh installed"
    else
        echo "! Failed to install oh-my-posh (non-critical)"
    fi
fi

# =============================================================================
# Step 11: Install kitty-terminfo via apt
# =============================================================================
echo ""
echo "Step 11: Installing kitty-terminfo via apt"

if dpkg -l kitty-terminfo &>/dev/null; then
    echo "✓ kitty-terminfo already installed"
else
    echo "Installing kitty-terminfo..."
    if apt_install kitty-terminfo; then
        echo "✓ kitty-terminfo installed"
    else
        echo "! Failed to install kitty-terminfo (non-critical)"
    fi
fi

# =============================================================================
# Step 12: Set zsh as default shell
# =============================================================================
echo ""
echo "Step 12: Setting zsh as default shell"

ZSH_PATH=$(command -v zsh)
CURRENT_SHELL="${SHELL##*/}"

if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    echo "✓ zsh is already the default shell"
else
    echo "Changing default shell to zsh..."

    # Ensure zsh is in /etc/shells
    if ! grep -q "^${ZSH_PATH}$" /etc/shells 2>/dev/null; then
        echo "$ZSH_PATH" | do_sudo tee -a /etc/shells >/dev/null
    fi

    # Use sudo chsh
    if do_sudo chsh -s "$ZSH_PATH" "$USERNAME"; then
        echo "✓ Default shell changed to zsh"
    else
        echo "! Failed to change default shell"
    fi
fi

# =============================================================================
# Cleanup - clear password from memory
# =============================================================================
SUDO_PASS=""
unset SUDO_PASS

# =============================================================================
# Done
# =============================================================================
echo ""
echo "=========================================="
echo "=== SUCCESS ==="
echo "=========================================="
echo ""
echo "Password prompts summary:"
echo "  - Debian (no sudo): should be 2 (root + sudo)"
echo "  - Ubuntu (has sudo): should be 1 (sudo)"
echo ""
echo "Log file: $LOGFILE"
