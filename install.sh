#!/bin/bash
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# zconfig installer script
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/barabasz/zconfig/main/install.sh)"
#
# This script installs zconfig by:
# 1. Checking system requirements (macOS or Debian-based Linux)
# 2. Installing sudo and updating system packages (Linux only)
# 3. Installing core utilities: curl, unzip, coreutils (Linux only)
# 4. Installing Homebrew (if not present)
# 5. Installing extra utilities: bat, eza, htop, gh, fzf, zoxide, yazi
# 6. Installing git and zsh
# 7. Installing oh-my-posh prompt theme engine
# 8. Installing kitty-terminfo (Linux only)
# 9. Checking for uncommitted changes (ALWAYS prompts if found, even in unattended mode)
# 10. Backing up or removing existing zsh configuration
# 11. Cloning the zconfig repository to ~/.config/zsh
# 12. Creating symlink ~/.zshenv -> ~/.config/zsh/.zshenv
# 13. Minimizing login info: .hushlogin, MOTD scripts (Linux only)
# 14. Setting zsh as default shell
# 15. Starting zsh with new configuration

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_VERSION="0.4.0"
SCRIPT_DATE="2026-02-08"
ZCONFIG_REPO="https://github.com/barabasz/zconfig.git"
ZCONFIG_DIR="$HOME/.config/zsh"
ZSHENV_LINK="$HOME/.zshenv"

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.local/cache}
XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}
XDG_LIB_HOME=${XDG_LIB_HOME:-$HOME/.local/lib}
XDG_TMP_HOME=${XDG_TMP_HOME:-$HOME/.local/tmp}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
TEMP=${TEMP:-$XDG_TMP_HOME}

# Ensure directories exist                                                                                                                                                     
mkdir -p $XDG_CONFIG_HOME $XDG_CACHE_HOME $XDG_BIN_HOME $XDG_LIB_HOME $XDG_TMP_HOME $XDG_DATA_HOME $XDG_STATE_HOME

URL_HOMEBREW="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
URL_OHMYPOSH="https://ohmyposh.dev/install.sh"

# Interactive mode (0 = automatic, 1 = ask questions)
INTERACTIVE=${INTERACTIVE:-0}

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
    d=$'\033[0;90m'     # dimmed (bright black) - for comments
    x=$'\033[0m'        # reset
else
    r='' g='' y='' b='' c='' w='' d='' x=''
fi

# Styled name (must be after colors)
ZCONFIG="${g}zconfig${x}"

# Installation tracking
INSTALLED=()
SKIPPED=()

# Step counter and timing
STEP_NUM=0
# Check if EPOCHREALTIME is available and has a value
if [[ -n "${EPOCHREALTIME:-}" ]]; then
    USE_EPOCH=1
    START_TIME=$EPOCHREALTIME
else
    USE_EPOCH=0
    START_TIME=$SECONDS
fi

print_header() {
    ((STEP_NUM++))

    # Calculate elapsed time
    local elapsed
    if [[ $USE_EPOCH -eq 1 ]] && [[ -n "${EPOCHREALTIME:-}" ]]; then
        # Floating point with EPOCHREALTIME
        elapsed=$(awk "BEGIN {printf \"%.2f\", $EPOCHREALTIME - $START_TIME}")
    else
        # Integer seconds fallback
        elapsed=$((SECONDS - START_TIME))
    fi

    printf "\n${y}▸${x} [%d] ${y}%s${x} ${d}[%ss]${x}\n" "$STEP_NUM" "$1" "$elapsed"
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

print_comment() {
    printf "${d}# %s${x}\n" "$1"
}

print_banner() {
    local text="$1"
    local width=39
    local padding=$(( (width - ${#text}) / 2 ))
    local pad_left=$(printf '%*s' $padding '')
    local pad_right=$(printf '%*s' $((width - ${#text} - padding)) '')
    printf "\n${y}"
    printf "  ┌───────────────────────────────────────┐\n"
    printf "  │%s%s%s│\n" "$pad_left" "$text" "$pad_right"
    printf "  └───────────────────────────────────────┘${x}\n"
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

# Check if running on Debian-based Linux
is_debian() {
    [[ "$OS_TYPE" == "debian" ]]
}

# Ask yes/no question (default: yes)
# In non-interactive mode, returns yes (0)
confirm() {
    [[ $INTERACTIVE -eq 0 ]] && return 0
    local prompt="$1"
    local response
    printf "${y}?${x} %s [Y/n] " "$prompt"
    read -r response
    [[ -z "$response" || "$response" =~ ^[Yy]$ ]]
}

# Ask yes/no question (default: no)
# In non-interactive mode, returns no (1)
confirm_no() {
    [[ $INTERACTIVE -eq 0 ]] && return 1
    local prompt="$1"
    local response
    printf "${y}?${x} %s [y/N] " "$prompt"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Abort installation due to missing dependency
abort_missing() {
    local dep="$1"
    print_info "${g}$dep${x} is required to install $ZCONFIG."
    print_error "Cannot continue. Exiting."
    return 1
}

# Silent apt-get wrapper (no warnings, no needrestart prompts)
# Usage: apt_run update | upgrade -y | install -y <pkg>
apt_run() {
    sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
        apt-get -qq "$@" &>/dev/null
}

# Convenience wrapper for apt install
apt_install() {
    apt_run install -y "$@"
}

# Refresh sudo credentials (call before spin with sudo commands)
sudo_refresh() {
    sudo -v 2>/dev/null || sudo -v
}

# Run command with spinner
# Usage: spin "message" command [args...]
spin() {
    local msg="$1"
    shift
    local frames='|/-\'
    local delay=0.15
    local i=0

    # Disable job control messages (shell-agnostic)
    if [[ -n "$ZSH_VERSION" ]]; then
        setopt LOCAL_OPTIONS NO_MONITOR NO_NOTIFY
    else
        set +m
    fi

    # Run command in background, suppress all output
    "$@" &>/dev/null &
    local pid=$!

    # Hide cursor
    printf '\033[?25l'

    # Animate spinner while process is running
    while kill -0 $pid 2>/dev/null; do
        # Use string slicing instead of array (works in both bash and zsh)
        local idx=$((i % 4))
        local frame="${frames:$idx:1}"
        printf "\r\033[K${c}%s${x} %s" "$frame" "$msg"
        ((i++))
        sleep $delay
    done

    # Wait for process and capture exit code
    wait $pid 2>/dev/null
    local exit_code=$?

    # Clear line and show cursor
    printf "\r\033[K"
    printf '\033[?25h'

    # Re-enable job control (only needed for bash, zsh uses LOCAL_OPTIONS)
    [[ -z "$ZSH_VERSION" ]] && set -m

    return $exit_code
}

# Track installed/skipped packages
track_install() { INSTALLED+=("$1"); }
track_skip()    { SKIPPED+=("$1"); }

# Generic package installer
# Usage: install_pkg <cmd> <name> <brew_pkg> <apt_pkg> [critical=1]
# - cmd: command to check if already installed
# - name: display name
# - brew_pkg: Homebrew package name (empty = not available via brew)
# - apt_pkg: apt package name (empty = not available via apt)
# - critical: 1 = fail on error (default), 0 = warn and continue
install_pkg() {
    local cmd="$1" name="$2" brew_pkg="$3" apt_pkg="$4" critical="${5:-1}"

    print_header "Installing $name"

    # Check if already installed
    if cmd_exists "$cmd"; then
        local version
        version=$("$cmd" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        print_success "${g}$name${x} is available${version:+ ($version)}"
        track_skip "$name"
        return 0
    fi

    print_warning "${g}$name${x} is not installed"

    local success=0

    if [[ "$OS_TYPE" == "macos" ]]; then
        # macOS: use brew
        if [[ -n "$brew_pkg" ]] && cmd_exists brew; then
            spin "Installing $name via Homebrew..." brew install "$brew_pkg" && success=1
        fi
    else
        # Linux: prefer apt, fallback to brew
        if [[ -n "$apt_pkg" ]]; then
            sudo_refresh
            spin "Installing $name via apt..." apt_install "$apt_pkg" && success=1
        elif [[ -n "$brew_pkg" ]] && cmd_exists brew; then
            spin "Installing $name via Homebrew..." brew install "$brew_pkg" && success=1
        fi
    fi

    if (( success )); then
        print_success "${g}$name${x} installed successfully"
        track_install "$name"
        return 0
    fi

    if (( critical )); then
        print_error "Failed to install ${g}$name${x}"
        return 1
    else
        print_warning "Failed to install ${g}$name${x} (non-critical)"
        return 0
    fi
}

# Print installation header
install_header() {
    print_banner "zconfig installer"
    print_comment "Script version: $SCRIPT_VERSION ($SCRIPT_DATE)"
    print_info "This will install $ZCONFIG to ${c}$ZCONFIG_DIR${x}"
    # Note for Linux users (OS_TYPE not set yet, so check directly)
    [[ "$(uname -s)" == "Linux" ]] && print_comment "Note: sudo password may be requested several times"
}

# Print installation summary
print_summary() {
    if [[ ${#INSTALLED[@]} -gt 0 ]]; then
        print_info "Installed: ${g}${INSTALLED[*]}${x}"
    fi
    if [[ ${#SKIPPED[@]} -gt 0 ]]; then
        print_info "Already present: ${d}${SKIPPED[*]}${x}"
    fi
}

# Print installation successful message
installation_successful() {
    print_banner "Installation complete!"
    print_summary
    printf "\n"
    print_info "$ZCONFIG installed to: ${c}$ZCONFIG_DIR${x}"
    print_info "Entry point for zsh:  ${c}$ZSHENV_LINK${x}"
    printf "\n"
    print_info "On first run, $ZCONFIG will automatically:"
    print_info "  - Download and install required plugins"
    print_info "  - Compile zsh files for faster loading"
    printf "\n"
}

# Prompt to start zsh
prompt_start_zsh() {
    if confirm "Start zsh now?"; then
        print_info "Starting zsh..."
        printf "\n"
        exec zsh
    else
        print_info "Run '${g}exec zsh${x}' or open a new terminal to start using $ZCONFIG"
    fi
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
            print_info "$ZCONFIG requires Debian-based Linux (Debian, Ubuntu, Mint, etc.)"
            return 1
            ;;
        *)
            print_error "Unsupported operating system: $(uname -s)"
            print_info "$ZCONFIG supports macOS and Debian-based Linux only"
            return 1
            ;;
    esac
}

install_sudo() {
    is_debian || return 0

    print_header "Installing sudo"

    if cmd_exists sudo; then
        print_success "${g}sudo${x} is available"
        track_skip "sudo"
        return 0
    fi

    # sudo not found - install it via su
    print_warning "${g}sudo${x} is not installed"
    print_info "Installing ${g}sudo${x} (root password required)..."

    # Install sudo using su
    if ! su -c "apt-get update -qq && apt-get install -y -qq sudo" 2>/dev/null; then
        print_error "Failed to install ${g}sudo${x}"
        return 1
    fi

    # Add current user to sudoers
    local sudoers_line="$(whoami) ALL=(ALL:ALL) ALL"
    if su -c "echo '$sudoers_line' | EDITOR='tee -a' visudo" 2>/dev/null; then
        print_success "${g}sudo${x} installed and configured"
        track_install "sudo"
        return 0
    else
        print_error "Failed to configure sudoers"
        return 1
    fi
}

update_system() {
    is_debian || return 0

    print_header "Updating system packages"

    # Cache sudo credentials (will prompt for password if needed)
    sudo -v || return 1

    spin "Updating package lists..." apt_run update
    spin "Upgrading packages..." apt_run upgrade -y

    print_success "System packages updated"
    return 0
}

install_git() {
    install_pkg git Git git git 1
}

install_zsh() {
    install_pkg zsh Zsh zsh zsh 1
}

install_core_utils() {
    is_debian || return 0

    print_header "Installing core utilities"

    # Tools and their packages (command:package)
    local tools=(
        "curl:curl"
        "unzip:unzip"
        "realpath:coreutils"
        "dirname:coreutils"
    )

    local missing=()
    local cmd pkg

    for tool in "${tools[@]}"; do
        cmd="${tool%%:*}"
        pkg="${tool##*:}"
        if cmd_exists "$cmd"; then
            track_skip "$cmd"
        else
            print_warning "${g}$cmd${x} is not available"
            # Add package if not already in list
            [[ ! " ${missing[*]} " =~ " ${pkg} " ]] && missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        print_success "All core utilities available"
        return 0
    fi

    sudo_refresh
    if spin "Installing ${missing[*]}..." apt_install "${missing[@]}"; then
        print_success "Core utilities installed"
        for pkg in "${missing[@]}"; do
            track_install "$pkg"
        done
    else
        print_error "Failed to install core utilities"
        return 1
    fi
}

install_extra_utils() {
    print_header "Installing extra utilities"

    # -------------------------------------------------------------------------
    # Tool definitions - easy to extend
    # Format: "command:brew_package:apt_package"
    # - If apt_package is empty, tool is brew-only
    # -------------------------------------------------------------------------

    local tools=(
        # Platform-specific (brew on macOS, apt on Linux)
        "bat:bat:bat"
        "eza:eza:eza"
        "htop:htop:htop"
        # Brew-only (both systems)
        "ncurses:ncurses:"
        "gh:gh:"
        "fzf:fzf:"
        "zoxide:zoxide:"
        "yazi:yazi:"
    )

    # -------------------------------------------------------------------------

    local missing_brew=()
    local missing_apt=()
    local cmd brew_pkg apt_pkg

    for tool in "${tools[@]}"; do
        cmd="${tool%%:*}"
        local rest="${tool#*:}"
        brew_pkg="${rest%%:*}"
        apt_pkg="${rest#*:}"

        # Skip if already installed
        if cmd_exists "$cmd"; then
            track_skip "$cmd"
            continue
        fi

        # Determine installation method
        if [[ "$OS_TYPE" == "macos" ]]; then
            # macOS: always use brew
            [[ ! " ${missing_brew[*]} " =~ " ${brew_pkg} " ]] && missing_brew+=("$brew_pkg")
        else
            # Linux: prefer apt if available, otherwise brew
            if [[ -n "$apt_pkg" ]]; then
                [[ ! " ${missing_apt[*]} " =~ " ${apt_pkg} " ]] && missing_apt+=("$apt_pkg")
            else
                [[ ! " ${missing_brew[*]} " =~ " ${brew_pkg} " ]] && missing_brew+=("$brew_pkg")
            fi
        fi
    done

    # Nothing to install
    if [[ ${#missing_brew[@]} -eq 0 && ${#missing_apt[@]} -eq 0 ]]; then
        print_success "All extra utilities available"
        return 0
    fi

    # Install via apt (Linux only)
    if [[ ${#missing_apt[@]} -gt 0 ]]; then
        sudo_refresh
        if spin "Installing via apt: ${missing_apt[*]}..." apt_install "${missing_apt[@]}"; then
            print_success "Installed via ${g}apt${x}: ${missing_apt[*]}"
            for pkg in "${missing_apt[@]}"; do track_install "$pkg"; done
        else
            print_warning "Some apt packages failed to install (non-critical)"
        fi
    fi

    # Install via brew
    if [[ ${#missing_brew[@]} -gt 0 ]]; then
        if spin "Installing via brew: ${missing_brew[*]}..." brew install "${missing_brew[@]}"; then
            print_success "Installed via ${g}brew${x}: ${missing_brew[*]}"
            for pkg in "${missing_brew[@]}"; do track_install "$pkg"; done
        else
            print_warning "Some brew packages failed to install (non-critical)"
        fi
    fi

    return 0
}

install_omp() {
    print_header "Installing oh-my-posh"

    # Check common locations
    if cmd_exists oh-my-posh || [[ -x "$XDG_BIN_HOME/oh-my-posh" ]]; then
        print_success "${g}oh-my-posh${x} is available"
        track_skip "oh-my-posh"
        return 0
    fi

    # Not found - install it
    print_warning "${g}oh-my-posh${x} is not installed"

    # Download and run installer with spinner
    local omp_script
    omp_script=$(curl -fsSL "$URL_OHMYPOSH") || {
        print_warning "Failed to download ${g}oh-my-posh${x} installer (non-critical)"
        return 0
    }

    if spin "Installing oh-my-posh..." bash -c "$omp_script" -- -d "$XDG_BIN_HOME"; then
        print_success "${g}oh-my-posh${x} installed successfully"
        track_install "oh-my-posh"
        return 0
    else
        print_warning "Failed to install ${g}oh-my-posh${x} (non-critical)"
        return 0
    fi
}

install_kitty_terminfo() {
    is_debian || return 0

    print_header "Installing kitty-terminfo"

    # Check if already installed
    if dpkg -l kitty-terminfo &>/dev/null 2>&1; then
        print_success "${g}kitty-terminfo${x} already installed"
        track_skip "kitty-terminfo"
        return 0
    fi

    sudo_refresh
    if spin "Installing kitty-terminfo..." apt_install kitty-terminfo; then
        print_success "${g}kitty-terminfo${x} installed"
        track_install "kitty-terminfo"
    else
        print_warning "Could not install ${g}kitty-terminfo${x} (non-critical)"
    fi
    return 0
}

minimize_login_info() {
    is_debian || return 0

    print_header "Minimizing login information"

    # Create .hushlogin
    local hushlogin="$HOME/.hushlogin"
    if [[ ! -f "$hushlogin" ]]; then
        touch "$hushlogin"
        print_info "Created ${c}$hushlogin${x}"
    fi

    # Check MOTD directory
    local motd_dir="/etc/update-motd.d"
    [[ -d "$motd_dir" ]] || return 0

    # Detect distro and define scripts to disable
    local distro=""
    [[ -f /etc/os-release ]] && . /etc/os-release && distro="$ID"

    local scripts=()
    case "$distro" in
        ubuntu) scripts=("00-header" "10-help-text" "50-motd-news") ;;
        debian) scripts=("10-uname") ;;
        *) return 0 ;;
    esac

    # Disable MOTD scripts
    local script
    for script in "${scripts[@]}"; do
        if [[ -f "$motd_dir/$script" ]]; then
            sudo chmod -x "$motd_dir/$script" &>/dev/null
            print_info "Disabled MOTD script: ${c}$script${x}"
        fi
    done

    print_success "Login information minimized"
}

# =============================================================================
# Installation steps
# =============================================================================

handle_existing() {
    print_header "Checking for existing installation"

    local has_existing=0

    # Check what exists
    [[ -e "$ZCONFIG_DIR" ]] && has_existing=1 && print_warning "Directory exists: $c$ZCONFIG_DIR$x"
    [[ -e "$ZSHENV_LINK" || -L "$ZSHENV_LINK" ]] && has_existing=1 && print_warning "File exists: $c$ZSHENV_LINK$x"

    if [[ $has_existing -eq 0 ]]; then
        print_success "No existing installation found"
        return 0
    fi

    # CRITICAL: Check for uncommitted changes in existing git repo
    # This check ALWAYS runs, even in unattended mode, to prevent data loss
    if [[ -d "$ZCONFIG_DIR/.git" ]]; then
        local git_status
        git_status=$(git -C "$ZCONFIG_DIR" status --porcelain 2>/dev/null)

        if [[ -n "$git_status" ]]; then
            print_error "Uncommitted changes detected!"
            print_warning "The existing installation has local changes that are not committed:"
            printf "\n"
            git -C "$ZCONFIG_DIR" status --short 2>/dev/null | head -20
            printf "\n"
            print_warning "Continuing will permanently delete these changes!"
            printf "\n"

            # Force interactive prompt - override INTERACTIVE setting
            local response
            printf "${r}!${x} Are you sure you want to continue and lose these changes? [yes/NO] "
            read -r response

            if [[ "$response" != "yes" ]]; then
                print_info "Installation cancelled. Your changes are safe."
                print_info "Commit your changes first: ${g}cd $ZCONFIG_DIR && git add -A && git commit -m 'backup'${x}"
                return 1
            fi

            print_warning "Proceeding despite uncommitted changes..."
        fi
    fi

    # Ask if user wants backup (default: no)
    printf "\n"
    if confirm_no "Do you want to create backups?"; then
        # Create backups
        local backup_timestamp
        backup_timestamp=$(date +%Y%m%d_%H%M%S)

        if [[ -e "$ZCONFIG_DIR" ]]; then
            mv "$ZCONFIG_DIR" "${ZCONFIG_DIR}.bak.${backup_timestamp}"
        fi
        if [[ -e "$ZSHENV_LINK" || -L "$ZSHENV_LINK" ]]; then
            mv "$ZSHENV_LINK" "${ZSHENV_LINK}.bak.${backup_timestamp}"
        fi
        print_info "Existing files backed up with .bak.${backup_timestamp} suffix"
    else
        # Just remove existing files
        [[ -e "$ZCONFIG_DIR" ]] && rm -rf "$ZCONFIG_DIR"
        [[ -e "$ZSHENV_LINK" || -L "$ZSHENV_LINK" ]] && rm -f "$ZSHENV_LINK"
        print_info "Existing files removed"
    fi

    return 0
}

clone_repository() {
    print_header "Cloning $ZCONFIG repository"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$ZCONFIG_DIR")"

    # Clone repository
    if spin "Cloning from $c$ZCONFIG_REPO$x..." git clone --quiet --depth 1 "$ZCONFIG_REPO" "$ZCONFIG_DIR"; then
        print_success "Repository cloned to $c$ZCONFIG_DIR$x"
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
        print_error "Source file not found: $c$source_file$x"
        return 1
    fi

    # Create symlink
    if ln -s "$source_file" "$ZSHENV_LINK"; then
        print_success "Created symlink: $c$ZSHENV_LINK$x -> $c$source_file$x"
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
    print_header "Installing Homebrew"

    # Check if Homebrew is already installed
    local brew_paths=(
        "/opt/homebrew/bin/brew"               # macOS Apple Silicon
        "/usr/local/bin/brew"                  # macOS Intel
        "/home/linuxbrew/.linuxbrew/bin/brew"  # Linux
        "$HOME/.linuxbrew/bin/brew"            # Linux (user install)
    )

    for brew_path in "${brew_paths[@]}"; do
        if [[ -x "$brew_path" ]]; then
            print_success "Homebrew found at $c$brew_path$x"
            track_skip "Homebrew"
            init_brew_shellenv
            brew analytics off &>/dev/null
            return 0
        fi
    done

    # Homebrew not found - ask to install
    print_warning "${g}Homebrew${x} is not installed"

    if ! confirm "Install Homebrew now?"; then
        abort_missing "Homebrew"
        return 1
    fi

    # Fix for Linux: ensure /home/linuxbrew exists with correct permissions
    if is_debian; then
        sudo mkdir -p /home/linuxbrew/
        sudo chmod 755 /home/linuxbrew/
    fi

    # Download and run Homebrew installer with spinner
    local brew_script
    brew_script=$(curl -fsSL "$URL_HOMEBREW") || {
        print_error "Failed to download ${g}Homebrew${x} installer"
        return 1
    }

    if spin "Installing ${g}Homebrew${x}..." env NONINTERACTIVE=1 bash -c "$brew_script"; then
        print_success "${g}Homebrew${x} installed successfully"
        track_install "Homebrew"
        init_brew_shellenv
        brew analytics off &>/dev/null
        return 0
    else
        print_error "${g}Homebrew${x} installation failed"
        return 1
    fi
}

set_default_shell() {
    print_header "Setting default shell"

    local zsh_path
    zsh_path=$(command -v zsh)
    local current_shell="${SHELL##*/}"

    if [[ "$current_shell" == "zsh" ]]; then
        print_success "${g}zsh${x} is already the default shell"
        return 0
    fi

    print_info "Current default shell: ${g}$current_shell${x}"

    if ! confirm "Change default shell to ${g}zsh${x}?"; then
        print_info "Skipping default shell change"
        print_info "You can change it later with: ${g}chsh -s ${c}$zsh_path${x}"
        return 0
    fi

    # Ensure zsh is in /etc/shells
    if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
        print_info "Adding ${c}$zsh_path${x} to ${c}/etc/shells${x}"
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # Change default shell
    if chsh -s "$zsh_path"; then
        print_success "Default shell changed to ${g}zsh${x}"
        return 0
    else
        print_warning "Failed to change default shell"
        print_info "You can change it manually with: ${g}chsh -s ${c}$zsh_path${x}"
        return 0
    fi
}

post_install_fixes() {
    print_header "Performing post-installation fixes"

    # Fix permissions for .config directory (common issue on Linux)
    if [[ -d "$XDG_CONFIG_HOME" ]]; then
        sudo chown -R "$(whoami)" "$XDG_CONFIG_HOME"
        print_info "Ensured ownership of ${c}$XDG_CONFIG_HOME${x}"
    fi

    # Create symlink for bat if batcat exists (common on Debian-based Linux)
    if is_debian && [[ -x /usr/bin/batcat ]]; then
        sudo ln -s /usr/bin/batcat /usr/local/bin/bat 2>/dev/null
        print_info "Created symlink for bat: ${c}bat${x} -> ${c}batcat${x}"
    fi
}

# =============================================================================
# Main installation flow
# =============================================================================

main() {
    # Print header
    install_header

    # Requirement checks
    check_os || return 1
    install_sudo || return 1
    update_system
    install_core_utils || return 1
    install_homebrew || return 1
    install_extra_utils
    install_git || return 1
    install_zsh || return 1
    install_omp

    # Optional installs for Linux
    install_kitty_terminfo

    # Handle existing installation
    handle_existing || return 1

    # Cloning zconfig repository
    clone_repository || return 1

    # Creating .zshenv symlink
    create_symlink || return 1

    # Minimize login info on Linux
    minimize_login_info

    # Set default shell to zsh
    set_default_shell

    # Perform any necessary post-installation fixes
    post_install_fixes

    # Success message
    installation_successful

    # Prompt to start zsh
    prompt_start_zsh
}

# Run main function
main

