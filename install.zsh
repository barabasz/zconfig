#!/bin/bash
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# zconfig installer script
# Usage: source <(curl -fsSL https://raw.githubusercontent.com/barabasz/zconfig/main/install.zsh)
#
# This script installs zconfig by:
# 1. Checking system requirements (macOS or Debian-based Linux)
# 2. Installing dependencies (git, zsh, kitty-terminfo)
# 3. Cloning the repository to ~/.config/zsh
# 4. Creating symlink ~/.zshenv -> ~/.config/zsh/.zshenv
# 5. Installing Homebrew if not present
# 6. Setting zsh as default shell
# 7. Reloading shell with new configuration

# =============================================================================
# Configuration
# =============================================================================

ZCONFIG_REPO="https://github.com/barabasz/zconfig.git"
ZCONFIG_DIR="$HOME/.config/zsh"
ZSHENV_LINK="$HOME/.zshenv"
HOMEBREW_INSTALL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# =============================================================================
# Colors and output functions (bash/zsh compatible)
# Same color scheme as inc/colors.zsh
# =============================================================================

if [[ -t 1 ]]; then
    r=$'\033[0;31m'     # red
    g=$'\033[0;32m'     # green
    y=$'\033[0;33m'     # yellow
    b=$'\033[0;34m'     # blue
    c=$'\033[0;36m'     # cyan
    w=$'\033[0;37m'     # white
    x=$'\033[0m'        # reset
else
    r='' g='' y='' b='' c='' w='' x=''
fi

print_header() {
    printf "\n${b}▸ %s${x}\n" "$1"
}

print_success() {
    printf "${g}✓${x} %s\n" "$1"
}

print_error() {
    printf "${r}✗${x} %s\n" "$1" >&2
}

print_warning() {
    printf "${y}!${x} %s\n" "$1"
}

print_info() {
    printf "${c}→${x} %s\n" "$1"
}

print_banner() {
    local text="$1"
    local width=39
    local padding=$(( (width - ${#text}) / 2 ))
    local pad_left=$(printf '%*s' $padding '')
    local pad_right=$(printf '%*s' $((width - ${#text} - padding)) '')
    printf "\n${g}"
    printf "  ╔═══════════════════════════════════════╗\n"
    printf "  ║%s%s%s║\n" "$pad_left" "$text" "$pad_right"
    printf "  ╚═══════════════════════════════════════╝${x}\n"
    printf "\n"
}

# =============================================================================
# Helper functions
# =============================================================================

# Detect OS type
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS_TYPE="macos"
            ;;
        Linux)
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
                    OS_TYPE="debian"
                else
                    OS_TYPE="linux-other"
                fi
            else
                OS_TYPE="linux-unknown"
            fi
            ;;
        *)
            OS_TYPE="unknown"
            ;;
    esac
}

# Check if command exists
cmd_exists() {
    command -v "$1" &>/dev/null
}

# Ask yes/no question (default: yes)
confirm() {
    local prompt="$1"
    local response
    printf "${y}?${x} %s [Y/n] " "$prompt"
    read -r response
    [[ -z "$response" || "$response" =~ ^[Yy]$ ]]
}

# Ask yes/no question (default: no)
confirm_no() {
    local prompt="$1"
    local response
    printf "${y}?${x} %s [y/N] " "$prompt"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# =============================================================================
# Requirement checks
# =============================================================================

check_os() {
    print_header "Checking operating system"
    detect_os

    case "$OS_TYPE" in
        macos)
            print_success "macOS detected"
            return 0
            ;;
        debian)
            print_success "Debian-based Linux detected"
            return 0
            ;;
        linux-other|linux-unknown)
            print_error "Unsupported Linux distribution"
            print_info "zconfig requires Debian-based Linux (Debian, Ubuntu, Mint, etc.)"
            return 1
            ;;
        *)
            print_error "Unsupported operating system: $(uname -s)"
            print_info "zconfig supports macOS and Debian-based Linux only"
            return 1
            ;;
    esac
}

check_sudo() {
    if [[ "$OS_TYPE" != "debian" ]]; then
        return 0
    fi

    print_header "Checking sudo availability"

    if cmd_exists sudo; then
        print_success "sudo is available"
        return 0
    else
        print_error "sudo is not installed"
        print_info "Install sudo with: apt install sudo (as root)"
        print_info "Then add your user to sudo group: usermod -aG sudo \$USER"
        return 1
    fi
}

update_system() {
    if [[ "$OS_TYPE" != "debian" ]]; then
        return 0
    fi

    print_header "Updating system packages"
    print_info "This may take a moment..."

    # This also forces sudo password prompt early
    if sudo apt update &>/dev/null && sudo apt upgrade -y &>/dev/null; then
        print_success "System packages updated"
    else
        print_warning "System update failed (non-critical)"
    fi
    return 0
}

check_git() {
    print_header "Checking git availability"

    if cmd_exists git; then
        print_success "git is available ($(git --version | cut -d' ' -f3))"
        return 0
    fi

    # git not found - install it
    print_warning "git is not installed"

    if [[ "$OS_TYPE" == "macos" ]]; then
        # On macOS, install via Homebrew
        if cmd_exists brew; then
            print_info "Installing git via Homebrew..."
            if brew install git &>/dev/null; then
                print_success "git installed successfully"
                return 0
            else
                print_error "Failed to install git"
                return 1
            fi
        else
            print_error "Homebrew is required to install git on macOS"
            print_info "Install Xcode Command Line Tools manually with:"
            printf "    ${c}xcode-select --install${x}\n"
            return 1
        fi
    else
        # On Linux, install via apt
        print_info "Installing git via apt..."
        if sudo apt install git -y &>/dev/null; then
            print_success "git installed successfully"
            return 0
        else
            print_error "Failed to install git"
            return 1
        fi
    fi
}

check_zsh() {
    print_header "Checking zsh availability"

    if cmd_exists zsh; then
        local zsh_version
        zsh_version=$(zsh --version | cut -d' ' -f2)
        print_success "zsh is available ($zsh_version)"
        return 0
    fi

    # zsh not found - install on Debian-based systems
    if [[ "$OS_TYPE" == "debian" ]]; then
        print_warning "zsh is not installed"
        if confirm "Install zsh now?"; then
            print_info "Installing zsh..."
            if sudo apt install zsh -y &>/dev/null; then
                print_success "zsh installed successfully"
                return 0
            else
                print_error "Failed to install zsh"
                return 1
            fi
        else
            print_error "zsh is required for zconfig"
            return 1
        fi
    else
        # macOS should always have zsh
        print_error "zsh is not available"
        return 1
    fi
}

install_kitty_terminfo() {
    if [[ "$OS_TYPE" != "debian" ]]; then
        return 0
    fi

    print_header "Installing kitty-terminfo"

    # Check if already installed
    if dpkg -l kitty-terminfo &>/dev/null 2>&1; then
        print_success "kitty-terminfo already installed"
        return 0
    fi

    print_info "Installing kitty-terminfo..."
    if sudo apt install -y kitty-terminfo &>/dev/null; then
        print_success "kitty-terminfo installed"
    else
        print_warning "Could not install kitty-terminfo (non-critical)"
    fi
    return 0
}

# =============================================================================
# Installation steps
# =============================================================================

backup_existing() {
    print_header "Checking for existing installation"

    local needs_backup=0
    local backup_timestamp
    backup_timestamp=$(date +%Y%m%d_%H%M%S)

    # Check ~/.config/zsh
    if [[ -e "$ZCONFIG_DIR" ]]; then
        print_warning "Directory exists: $ZCONFIG_DIR"
        needs_backup=1
    fi

    # Check ~/.zshenv
    if [[ -e "$ZSHENV_LINK" || -L "$ZSHENV_LINK" ]]; then
        print_warning "File exists: $ZSHENV_LINK"
        needs_backup=1
    fi

    if [[ $needs_backup -eq 0 ]]; then
        print_success "No existing installation found"
        return 0
    fi

    # Ask user
    printf "\n"
    print_info "Existing files will be backed up with .bak.$backup_timestamp suffix"
    if ! confirm "Create backups and continue?"; then
        print_error "Installation cancelled by user"
        return 1
    fi

    # Backup ~/.config/zsh
    if [[ -e "$ZCONFIG_DIR" ]]; then
        local zconfig_backup="${ZCONFIG_DIR}.bak.${backup_timestamp}"
        print_info "Moving $ZCONFIG_DIR to $zconfig_backup"
        if mv "$ZCONFIG_DIR" "$zconfig_backup"; then
            print_success "Backup created: $zconfig_backup"
        else
            print_error "Failed to backup $ZCONFIG_DIR"
            return 1
        fi
    fi

    # Backup ~/.zshenv
    if [[ -e "$ZSHENV_LINK" || -L "$ZSHENV_LINK" ]]; then
        local zshenv_backup="${ZSHENV_LINK}.bak.${backup_timestamp}"
        print_info "Moving $ZSHENV_LINK to $zshenv_backup"
        if mv "$ZSHENV_LINK" "$zshenv_backup"; then
            print_success "Backup created: $zshenv_backup"
        else
            print_error "Failed to backup $ZSHENV_LINK"
            return 1
        fi
    fi

    return 0
}

clone_repository() {
    print_header "Cloning zconfig repository"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$ZCONFIG_DIR")"

    # Clone repository
    print_info "Cloning from $ZCONFIG_REPO"
    if git clone --quiet --depth 1 "$ZCONFIG_REPO" "$ZCONFIG_DIR" 2>/dev/null; then
        print_success "Repository cloned to $ZCONFIG_DIR"
        return 0
    else
        print_error "Failed to clone repository"
        return 1
    fi
}

create_symlink() {
    print_header "Creating .zshenv symlink"

    local source_file="$ZCONFIG_DIR/.zshenv"

    # Check if source exists
    if [[ ! -f "$source_file" ]]; then
        print_error "Source file not found: $source_file"
        return 1
    fi

    # Create symlink
    if ln -s "$source_file" "$ZSHENV_LINK"; then
        print_success "Created symlink: $ZSHENV_LINK -> $source_file"
        return 0
    else
        print_error "Failed to create symlink"
        return 1
    fi
}

init_brew_shellenv() {
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
}

install_homebrew() {
    print_header "Checking Homebrew"

    # Check if Homebrew is already installed
    local brew_paths=(
        "/opt/homebrew/bin/brew"               # macOS Apple Silicon
        "/usr/local/bin/brew"                  # macOS Intel
        "/home/linuxbrew/.linuxbrew/bin/brew"  # Linux
        "$HOME/.linuxbrew/bin/brew"            # Linux (user install)
    )

    for brew_path in "${brew_paths[@]}"; do
        if [[ -x "$brew_path" ]]; then
            print_success "Homebrew found at $brew_path"
            init_brew_shellenv
            brew analytics off &>/dev/null
            return 0
        fi
    done

    # Homebrew not found - ask to install
    print_warning "Homebrew is not installed"
    print_info "Homebrew is recommended for installing tools"

    if ! confirm "Install Homebrew now?"; then
        print_info "Skipping Homebrew installation"
        print_info "You can install it later with:"
        printf "    ${c}/bin/bash -c \"\$(curl -fsSL %s)\"${x}\n" "$HOMEBREW_INSTALL"
        return 1
    fi

    # Fix for Linux: ensure /home/linuxbrew exists with correct permissions
    if [[ "$OS_TYPE" == "debian" ]]; then
        sudo mkdir -p /home/linuxbrew/
        sudo chmod 755 /home/linuxbrew/
    fi

    print_info "Installing Homebrew..."
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL")"; then
        print_success "Homebrew installed successfully"
        init_brew_shellenv
        brew analytics off &>/dev/null
        return 0
    else
        print_error "Homebrew installation failed"
        return 1
    fi
}

set_default_shell() {
    print_header "Setting default shell"

    local zsh_path
    zsh_path=$(command -v zsh)
    local current_shell="${SHELL##*/}"

    if [[ "$current_shell" == "zsh" ]]; then
        print_success "zsh is already the default shell"
        return 0
    fi

    print_info "Current default shell: $current_shell"

    if ! confirm "Change default shell to zsh?"; then
        print_info "Skipping default shell change"
        print_info "You can change it later with: chsh -s $zsh_path"
        return 0
    fi

    # Ensure zsh is in /etc/shells
    if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
        print_info "Adding $zsh_path to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # Change default shell
    if chsh -s "$zsh_path"; then
        print_success "Default shell changed to zsh"
        return 0
    else
        print_warning "Failed to change default shell"
        print_info "You can change it manually with: chsh -s $zsh_path"
        return 0
    fi
}

# =============================================================================
# Main installation flow
# =============================================================================

main() {
    print_banner "zconfig installer v1.0.0"
    print_info "This will install zconfig to $ZCONFIG_DIR"
    printf "\n"

    # Requirement checks
    check_os || return 1
    check_sudo || return 1
    update_system
    install_homebrew || return 1
    check_git || return 1
    check_zsh || return 1

    # Optional installs for Linux
    install_kitty_terminfo

    # Handle existing installation
    backup_existing || return 1

    # Main installation
    clone_repository || return 1
    create_symlink || return 1
    set_default_shell

    # Success message
    print_banner "Installation complete! 🎉"
    print_info "zconfig installed to: $ZCONFIG_DIR"
    print_info "Configuration loaded from: $ZSHENV_LINK"
    printf "\n"
    print_info "On first run, zconfig will automatically:"
    print_info "  - Download and install required plugins"
    print_info "  - Compile zsh files for faster loading"
    printf "\n"

    if confirm "Start zsh now?"; then
        print_info "Starting zsh..."
        exec zsh
    else
        print_info "Run 'exec zsh' or open a new terminal to start using zconfig"
    fi
}

# Run main function
main
