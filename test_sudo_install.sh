#!/bin/bash
# Mini-script to test sudo + git + Homebrew installation on Debian
# Usage: /bin/bash -c "$(curl -fsSL URL)"
# NOTE: Do NOT use "curl | bash" - stdin must be free for password prompts!

VERSION="0.1.0"
LOGFILE="/tmp/test_install_$$.log"

echo "=== Test: sudo + git + Homebrew (v$VERSION) ==="
echo "Log: $LOGFILE"
echo ""

# Get current username
USERNAME=$(whoami)
echo "User: $USERNAME"

# =============================================================================
# Step 1: Install sudo (if needed)
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
        echo "✓ sudo installed (with timestamp_timeout=30)"
    else
        echo ""
        echo "✗ Failed to install sudo"
        exit 1
    fi
fi

# =============================================================================
# Step 2: First sudo usage (will prompt for password, then cache for 30 min)
# =============================================================================
echo ""
echo "Step 2: Activating sudo (this will ask for password once)"

if sudo -v; then
    echo "✓ sudo activated"
else
    echo "✗ sudo activation failed"
    exit 1
fi

# =============================================================================
# Step 3: Install git via apt (should NOT ask for password)
# =============================================================================
echo ""
echo "Step 3: Installing git via apt"

if command -v git &>/dev/null; then
    echo "✓ git is already installed"
else
    echo "Installing git..."
    if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git >> "$LOGFILE" 2>&1; then
        echo "✓ git installed"
    else
        echo "✗ Failed to install git"
        exit 1
    fi
fi

# =============================================================================
# Step 4: Install Homebrew (should NOT ask for password)
# =============================================================================
echo ""
echo "Step 4: Installing Homebrew"

if command -v brew &>/dev/null || [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    echo "✓ Homebrew is already installed"
else
    echo "Installing Homebrew (this takes a while)..."

    # Ensure directory exists
    sudo mkdir -p /home/linuxbrew/
    sudo chmod 755 /home/linuxbrew/

    # Install Homebrew
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOGFILE" 2>&1; then
        echo "✓ Homebrew installed"

        # Setup brew in current session
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        echo "✗ Failed to install Homebrew"
        exit 1
    fi
fi

# =============================================================================
# Step 5: Install something via brew (to verify it works)
# =============================================================================
echo ""
echo "Step 5: Testing brew install (fzf)"

if command -v fzf &>/dev/null; then
    echo "✓ fzf is already installed"
else
    echo "Installing fzf via brew..."
    if brew install fzf >> "$LOGFILE" 2>&1; then
        echo "✓ fzf installed via brew"
    else
        echo "✗ Failed to install fzf"
        exit 1
    fi
fi

# =============================================================================
# Done
# =============================================================================
echo ""
echo "=== SUCCESS ==="
echo ""
echo "If you only saw 2 password prompts (root + sudo), the fix works!"
echo "Log file: $LOGFILE"
