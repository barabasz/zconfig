#!/bin/bash
# Test script to verify version extraction from various tools

# Extract version number from command output
# Searches all lines for version pattern (not just first line)
get_version() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null || { echo "not installed"; return 1; }

    # Try --version first, then -v, then -V
    local output
    output=$("$cmd" --version 2>/dev/null) || \
    output=$("$cmd" -v 2>/dev/null) || \
    output=$("$cmd" -V 2>/dev/null) || \
    { echo "unknown"; return 1; }

    # Extract version number from any line (handles multi-line output like eza)
    local version
    version=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)

    echo "${version:-unknown}"
}

echo "=== Version extraction test ==="
echo ""

# Test various commands
commands=(
    "bat"
    "eza"
    "htop"
    "git"
    "zsh"
    "fzf"
    "gh"
    "zoxide"
    "yazi"
    "curl"
    "brew"
    "oh-my-posh"
)

for cmd in "${commands[@]}"; do
    version=$(get_version "$cmd")
    printf "%-15s %s\n" "$cmd:" "$version"
done

echo ""
echo "=== Raw output samples ==="
echo ""

echo "--- bat --version ---"
bat --version 2>/dev/null || echo "(not installed)"
echo ""

echo "--- eza --version ---"
eza --version 2>/dev/null || echo "(not installed)"
echo ""

echo "--- brew --version ---"
brew --version 2>/dev/null || echo "(not installed)"
echo ""

echo "--- oh-my-posh --version ---"
oh-my-posh --version 2>/dev/null || echo "(not installed)"
