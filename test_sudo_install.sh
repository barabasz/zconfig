#!/bin/bash
# Mini-script to test sudo installation on Debian
# Usage: /bin/bash -c "$(curl -fsSL URL)"
# NOTE: Do NOT use "curl | bash" - stdin must be free for password prompts!

echo "=== Test: sudo installation ==="

# Check if sudo exists
if command -v sudo &>/dev/null; then
    echo "sudo is already installed"
    exit 0
fi

echo "sudo not found. Installing..."

# Get current username
USERNAME=$(whoami)
echo "User: $USERNAME"

# Suppress locale warnings
export LC_ALL=C

# Install sudo
echo ""
echo "Step 1: Installing sudo package"
echo -n "Enter ROOT password: "
if su -c "apt-get update -qq && apt-get install -y -qq sudo" 2>/dev/null; then
    echo "✓ sudo package installed"
else
    echo "✗ Failed to install sudo"
    exit 1
fi

# Add user to sudoers
echo ""
echo "Step 2: Configuring sudoers"
echo -n "Enter ROOT password: "
SUDOERS_LINE="$USERNAME ALL=(ALL:ALL) ALL"
if su -c "echo '$SUDOERS_LINE' | sudo EDITOR='tee -a' visudo" 2>/dev/null; then
    echo "✓ User added to sudoers"
else
    echo "✗ Failed to configure sudoers"
    exit 1
fi

# Verify sudo works
echo ""
echo "Step 3: Verifying sudo access"
if sudo -v; then
    echo "✓ sudo works!"
else
    echo "✗ sudo verification failed"
    exit 1
fi

echo ""
echo "=== SUCCESS ==="
