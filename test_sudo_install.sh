#!/bin/bash
# Mini-script to test sudo installation on Debian
# Run on fresh Debian without sudo: bash test_sudo_install.sh

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

# Install sudo (method from old script)
echo ""
echo "Step 1: Installing sudo package"
echo "Enter ROOT password:"
if su -c "apt-get update -qq && apt-get install -y -qq sudo"; then
    echo "✓ sudo package installed"
else
    echo "✗ Failed to install sudo"
    exit 1
fi

# Add user to sudoers (method from old script)
echo ""
echo "Step 2: Configuring sudoers"
echo "Enter ROOT password again:"
SUDOERS_LINE="$USERNAME ALL=(ALL:ALL) ALL"
if su -c "echo '$SUDOERS_LINE' | sudo EDITOR='tee -a' visudo"; then
    echo "✓ User added to sudoers"
else
    echo "✗ Failed to configure sudoers"
    exit 1
fi

# Verify sudo works
echo ""
echo "Step 3: Verifying sudo access"
echo "Enter YOUR password for sudo:"
if sudo -v; then
    echo "✓ sudo works!"
else
    echo "✗ sudo verification failed"
    exit 1
fi

echo ""
echo "=== SUCCESS ==="
