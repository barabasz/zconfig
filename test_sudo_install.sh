#!/bin/bash
# Mini-script to test sudo installation on Debian
# Usage: /bin/bash -c "$(curl -fsSL URL)"
# NOTE: Do NOT use "curl | bash" - stdin must be free for password prompts!

VERSION="0.0.6"
echo "=== Test: sudo installation (v$VERSION) ==="

# Check if sudo exists
if command -v sudo &>/dev/null; then
    echo "sudo is already installed"
    exit 0
fi

echo "sudo not found. Installing..."

# Get current username
USERNAME=$(whoami)
echo "User: $USERNAME"

# Install sudo AND configure sudoers in one su -c command (single password prompt)
echo ""
echo "Step 1: Installing sudo and configuring sudoers"
echo -n "Enter ROOT password: "
SUDOERS_LINE="$USERNAME ALL=(ALL:ALL) ALL"
if su -c "LC_ALL=C apt-get update -qq >/dev/null 2>&1 && LC_ALL=C apt-get install -y -qq sudo >/dev/null 2>&1 && echo '$SUDOERS_LINE' >> /etc/sudoers"; then
    echo ""
    echo "✓ sudo installed and user added to sudoers"
else
    echo ""
    echo "✗ Failed to install/configure sudo"
    exit 1
fi

# Verify sudo works
echo ""
echo "Step 2: Verifying sudo access"
if sudo -v; then
    echo "✓ sudo works!"
else
    echo "✗ sudo verification failed"
    exit 1
fi

echo ""
echo "=== SUCCESS ==="
