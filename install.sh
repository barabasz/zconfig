#!/bin/bash
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# zconfig installer script
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/barabasz/zconfig/HEAD/install.sh)"
#
# This script installs zconfig by:
# 1. Checking system requirements (macOS or Debian-based Linux)
# 2. Installing sudo and updating system packages (Linux only)
# 3. Installing core utilities (Linux only)
# 4. Installing git (xcode-select on macOS, apt on Linux)
# 5. Installing Homebrew (if not present)
# 6. Installing utilities: zsh, bat, eza, htop, gh, fzf, zoxide, yazi, kitty-terminfo
# 7. Installing oh-my-posh prompt theme engine
# 8. Handling existing installation (backup/remove)
# 9. Cloning the zconfig repository to ~/.config/zsh
# 10. Creating symlink ~/.zshenv -> ~/.config/zsh/.zshenv
# 11. Minimizing login info: .hushlogin, MOTD scripts (Linux only)
# 12. Setting zsh as default shell
# 13. Starting zsh with new configuration

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_VERSION="0.8.2"
SCRIPT_DATE="2026-02-09"
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

# Logging - all output is logged to this file
LOGFILE="$XDG_TMP_HOME/zconfig_$(date +%Y%m%d_%H%M%S).log"

# Step counter - UPDATE THIS when adding/removing installation steps!
# macOS: 10 steps, Linux: 14 steps (set dynamically after OS detection)
TOTAL_STEPS=10
STEP_NUM=0

URL_HOMEBREW="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
URL_OHMYPOSH="https://ohmyposh.dev/install.sh"

# Interactive mode (0 = automatic, 1 = ask questions)
INTERACTIVE=${INTERACTIVE:-0}

# Force English locale during installation to avoid parsing issues
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Homebrew environment - cleaner output
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_EMOJI=1

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

# Sudo password storage (for sudo -S approach)
SUDO_PASS=""

# Timing - record start time
START_TIME=$SECONDS

# Generate repeated character string
# Usage: repeat_char "char" count
repeat_char() {
    local char="$1" count="$2" result="" i
    for ((i=0; i<count; i++)); do result+="$char"; done
    printf '%s' "$result"
}

# Get elapsed time in MM:SS format
get_elapsed_time() {
    local elapsed=$((SECONDS - START_TIME))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))
    printf "%02d:%02d" $minutes $seconds
}

# Log message to file only (not displayed to user)
# Usage: print_log "message"
print_log() {
    echo "█ $1" >> "$LOGFILE"
}

# Print title in a box (used at script start)
# ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
# █ zconfig installer v0.5 █
# ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
print_title() {
    local text="$1"
    local len=$((${#text} + 4))
    printf "${y}$(repeat_char '▁' "$len")\n"
    printf "${y}█ ${w}%s${y} █\n" "$text"
    printf "$(repeat_char '▔' "$len")${x}\n"
    # Log title to file
    {
        echo ""
        echo "$(repeat_char '=' 60)"
        echo "$text"
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "$(repeat_char '=' 60)"
    } >> "$LOGFILE"
}

# Print section header with step counter and elapsed time
# █ 2/9: git setup (elapsed: 00:03)
# ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
print_header() {
    ((STEP_NUM++))
    local elapsed
    elapsed=$(get_elapsed_time)
    local text="${STEP_NUM}/${TOTAL_STEPS}: $1"
    local text_elapsed=" ${w}(elapsed: ${elapsed})${x}"
    local len=$((${#text} + 2))

    printf "\n${y}█ %s${x}%s\n" "$text" "$text_elapsed"
    printf "${y}$(repeat_char '▔' "$len")${x}\n"

    # Log section to file
    {
        echo ""
        echo "█ SECTION $text"
        echo "█ Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "█ Elapsed: $elapsed"
        echo "$(repeat_char '▔' 40)"
    } >> "$LOGFILE"
}

# Print end header (green, for completion)
print_end_header() {
    local text="$1"
    local elapsed
    elapsed=$(get_elapsed_time)
    local text_elapsed=" ${w}(total: ${elapsed})${x}"
    local len=$((${#text} + 4))

    printf "\n${g}$(repeat_char '▁' "$len")\n"
    printf "${g}█ ${w}%s${g} █${x}%s\n" "$text" "$text_elapsed"
    printf "${g}$(repeat_char '▔' "$len")${x}\n\n"
}

print_success() {
    printf "${g}✓${x} %s\n" "$1"
    print_log "SUCCESS: $1"
}

print_error() {
    printf "${r}✗${x} %s\n" "$1" >&2
    print_log "ERROR: $1"
}

print_warning() {
    printf "${y}!${x} %s\n" "$1"
    print_log "WARNING: $1"
}

print_info() {
    printf "${c}→${x} %s\n" "$1"
    print_log "INFO: $1"
}

print_comment() {
    printf "${d}# %s${x}\n" "$1"
}

# =============================================================================
# Helper functions
# =============================================================================

# Detect OS type and set TOTAL_STEPS accordingly
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS_TYPE="macos"
            TOTAL_STEPS=11  # macOS has fewer steps (no sudo, apt, etc.)
            ;;
        Linux)
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
                    OS_TYPE="debian"
                    TOTAL_STEPS=14  # Linux has additional steps
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

# Get version of a command (searches all output lines for version pattern)
# Usage: get_version <command>
# Returns: version string or "unknown"
get_version() {
    local cmd="$1"
    cmd_exists "$cmd" || { echo "unknown"; return 1; }

    local output
    output=$("$cmd" --version 2>/dev/null) || \
    output=$("$cmd" -v 2>/dev/null) || \
    output=$("$cmd" -V 2>/dev/null) || \
    { echo "unknown"; return 1; }

    # Extract version number from any line
    local version
    version=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    echo "${version:-unknown}"
}

# Format version for display: (version) with cyan version and white parentheses
fmt_version() {
    local cmd="$1"
    local ver
    ver=$(get_version "$cmd")
    [[ "$ver" != "unknown" ]] && echo " (${c}${ver}${x})"
}

# Get apt package version
# Usage: get_apt_version <package>
get_apt_version() {
    local pkg="$1"
    dpkg -s "$pkg" 2>/dev/null | grep -oP '^Version: \K[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1
}

# Format apt package version for display
fmt_apt_version() {
    local pkg="$1"
    local ver
    ver=$(get_apt_version "$pkg")
    [[ -n "$ver" ]] && echo " (${c}${ver}${x})"
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

# =============================================================================
# Sudo wrapper functions - uses stored password via sudo -S
# This approach ensures only one password prompt for all sudo operations
# =============================================================================

# Initialize sudo - ask for password once and validate it
# Called after install_sudo (Debian) or at start (Ubuntu/macOS)
init_sudo() {
    [[ "$OS_TYPE" == "macos" ]] && return 0  # macOS doesn't need this

    if [[ -n "$SUDO_PASS" ]]; then
        return 0  # Already initialized
    fi

    print_info "Sudo password required (will be asked only once):"
    read -s -p "[sudo] password for $(whoami): " SUDO_PASS
    echo ""

    # Validate password
    if echo "$SUDO_PASS" | sudo -S -v 2>/dev/null; then
        print_success "Sudo password verified"
        return 0
    else
        print_error "Invalid password"
        return 1
    fi
}

# Run command with sudo using stored password
do_sudo() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        sudo "$@"
    else
        echo "$SUDO_PASS" | sudo -S "$@" 2>/dev/null
    fi
}

# Silent apt-get wrapper (no warnings, no needrestart prompts)
# Usage: apt_run update | upgrade -y | install -y <pkg>
apt_run() {
    echo "$SUDO_PASS" | sudo -S DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
        apt-get -qq "$@" 2>/dev/null
}

# Convenience wrapper for apt install
apt_install() {
    apt_run install -y "$@"
}

# Cleanup sudo password from memory
cleanup_sudo() {
    SUDO_PASS=""
    unset SUDO_PASS
}

# Run command with spinner
# Usage: spin "message" command [args...]
spin() {
    local msg="$1"
    shift
    local frames='|/-\'
    local delay=0.15
    local i=0

    # Log the command being executed
    print_log "Executing: $*"

    # Disable job control messages (shell-agnostic)
    if [[ -n "$ZSH_VERSION" ]]; then
        setopt LOCAL_OPTIONS NO_MONITOR NO_NOTIFY
    else
        set +m
    fi

    # Run command in background, log output to file
    "$@" >> "$LOGFILE" 2>&1 &
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

    # Log result
    if [[ $exit_code -eq 0 ]]; then
        print_log "Command completed successfully"
    else
        print_log "Command failed with exit code: $exit_code"
    fi

    return $exit_code
}

# Track installed/skipped packages
track_install() { INSTALLED+=("$1"); }
track_skip()    { SKIPPED+=("$1"); }

# =============================================================================
# install_utils - Universal package installer
# =============================================================================
# Usage: install_utils "Header" tool1 tool2 ...
# Format: "command:brew_package:apt_package[:critical]"
#
# Installation logic:
#   | brew_pkg | apt_pkg | macOS       | Linux           |
#   |----------|---------|-------------|-----------------|
#   | set      | set     | brew        | apt             |
#   | set      | empty   | brew        | brew            |
#   | empty    | set     | skip        | apt             |
#
# Fields:
#   - command: check if installed (or package name for dpkg check)
#   - critical: 1 = fail on error, 0 = warn and continue (default: 0)
#
# Examples:
#   "bat:bat:bat"       # macOS: brew, Linux: apt
#   "gh:gh:"            # Both platforms: brew
#   "unzip::unzip"      # Linux only: apt
#   "zsh:zsh:zsh:1"     # Critical (fail if can't install)
# =============================================================================
install_utils() {
    local header="$1"
    shift
    local tools=("$@")

    print_header "$header"

    local missing_brew=()
    local missing_apt=()
    local critical_tools=()
    local cmd brew_pkg apt_pkg critical

    # Phase 1: Check what's missing
    for tool in "${tools[@]}"; do
        # Parse format: command:brew_package:apt_package[:critical]
        IFS=':' read -r cmd brew_pkg apt_pkg critical <<< "$tool"
        critical="${critical:-0}"

        # Skip if already installed (check command)
        if cmd_exists "$cmd"; then
            track_skip "$cmd"
            continue
        fi

        # For apt-only packages without a command, check via dpkg
        if [[ "$OS_TYPE" != "macos" && -n "$apt_pkg" && -z "$brew_pkg" ]]; then
            if dpkg -l "$apt_pkg" &>/dev/null 2>&1; then
                track_skip "$apt_pkg"
                continue
            fi
        fi

        # Track critical tools
        (( critical )) && critical_tools+=("$cmd")

        # Determine installation method
        if [[ "$OS_TYPE" == "macos" ]]; then
            # macOS: use brew (skip if brew_pkg is empty = apt-only)
            if [[ -n "$brew_pkg" ]]; then
                [[ ! " ${missing_brew[*]} " =~ " ${brew_pkg} " ]] && missing_brew+=("$brew_pkg:$cmd")
            fi
        else
            # Linux: prefer apt if available, otherwise brew
            if [[ -n "$apt_pkg" ]]; then
                [[ ! " ${missing_apt[*]} " =~ " ${apt_pkg} " ]] && missing_apt+=("$apt_pkg:$cmd")
            elif [[ -n "$brew_pkg" ]]; then
                [[ ! " ${missing_brew[*]} " =~ " ${brew_pkg} " ]] && missing_brew+=("$brew_pkg:$cmd")
            fi
        fi
    done

    # Nothing to install
    if [[ ${#missing_brew[@]} -eq 0 && ${#missing_apt[@]} -eq 0 ]]; then
        print_success "All utilities available"
        return 0
    fi

    local failed=()
    local pkg pkg_name cmd_name

    # Phase 2: Install via apt (Linux only)
    for pkg in "${missing_apt[@]}"; do
        pkg_name="${pkg%%:*}"
        cmd_name="${pkg#*:}"
        if spin "Installing ${g}$pkg_name${x} via apt..." apt_install "$pkg_name"; then
            print_success "Installed ${g}$pkg_name${x}$(fmt_apt_version "$pkg_name")"
            track_install "$pkg_name"
        else
            print_warning "Failed to install ${g}$pkg_name${x}"
            failed+=("$cmd_name")
        fi
    done

    # Phase 3: Install via brew
    for pkg in "${missing_brew[@]}"; do
        pkg_name="${pkg%%:*}"
        cmd_name="${pkg#*:}"
        if spin "Installing ${g}$pkg_name${x} via brew..." brew install "$pkg_name"; then
            print_success "Installed ${g}$pkg_name${x}$(fmt_version "$cmd_name")"
            track_install "$pkg_name"
        else
            print_warning "Failed to install ${g}$pkg_name${x}"
            failed+=("$cmd_name")
        fi
    done

    # Phase 4: Check if any critical tool failed
    for cmd in "${critical_tools[@]}"; do
        if [[ " ${failed[*]} " =~ " ${cmd} " ]]; then
            print_error "Critical package ${g}$cmd${x} failed to install"
            return 1
        fi
    done

    return 0
}

# Print installation header
install_header() {
    print_title "zconfig installer v${SCRIPT_VERSION}"
    print_comment "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    print_comment "Log file: $LOGFILE"
    print_info "This will install $ZCONFIG to ${c}$ZCONFIG_DIR${x}"
    # Note for Linux users (OS_TYPE not set yet, so check directly)
    [[ "$(uname -s)" == "Linux" ]] && print_comment "Note: sudo password will be asked only once"
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
    # Ensure terminal is in a sane state
    stty sane 2>/dev/null || true

    # Ensure TERM is set to a safe value if kitty-terminfo is not available
    if ! infocmp xterm-kitty &>/dev/null; then
        export TERM=xterm-256color
        export COLORTERM=truecolor
    fi

    print_end_header "Installation complete!"
    print_summary
    printf "\n"
    print_info "$ZCONFIG installed to: ${c}$ZCONFIG_DIR${x}"
    print_info "Entry point for zsh:  ${c}$ZSHENV_LINK${x}"
    print_info "Installation log:     ${c}$LOGFILE${x}"
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
        print_success "${g}sudo${x} is available$(fmt_version sudo)"
        track_skip "sudo"
        return 0
    fi

    # sudo not found - install it via su (single password prompt)
    print_warning "${g}sudo${x} is not installed"
    print_info "Installing ${g}sudo${x} and configuring sudoers..."
    print_info "Root password required:"

    # Install sudo AND configure sudoers in one su -c command
    local username
    username=$(whoami)
    # Add user to sudoers with extended timeout (30 min) to avoid repeated prompts during install
    local sudoers_line="$username ALL=(ALL:ALL) ALL"
    local sudoers_timeout="Defaults:$username timestamp_timeout=30"

    if su -c "LC_ALL=C apt-get update -qq >/dev/null 2>&1 && LC_ALL=C apt-get install -y -qq sudo >/dev/null 2>&1 && printf '%s\n' '$sudoers_line' '$sudoers_timeout' >> /etc/sudoers"; then
        print_success "${g}sudo${x} installed$(fmt_version sudo)"
        print_info "User added to sudoers with 30min timeout"
        track_install "sudo"
        return 0
    else
        print_error "Failed to install/configure ${g}sudo${x}"
        return 1
    fi
}

update_system() {
    is_debian || return 0

    print_header "Updating system packages"

    spin "Updating package lists..." apt_run update
    spin "Upgrading packages..." apt_run upgrade -y

    print_success "System packages updated"
    return 0
}

install_core_utils() {
    is_debian || return 0

    local utils=(
        "unzip::unzip:1"
        "realpath::coreutils:1" # realpath is part of coreutils
    )
    install_utils "Installing core utilities" "${utils[@]}"
}

install_extra_utils() {
    local utils=(
        "zsh:zsh:zsh:1"
        "bat:bat:bat"
        "eza:eza:eza"
        "htop:htop:htop"
        "ncurses:ncurses:"
        "gh:gh:"
        "fzf:fzf:"
        "zoxide:zoxide:"
        "yazi:yazi:"
        "kitty-terminfo::kitty-terminfo"
        "tmux:tmux:tmux"
    )
    install_utils "Installing utilities" "${utils[@]}"
}

install_git() {
    print_header "Installing git"

    if cmd_exists git; then
        print_success "${g}git${x} is available$(fmt_version git)"
        track_skip "git"
        return 0
    fi

    print_warning "${g}git${x} is not installed"

    if [[ "$OS_TYPE" == "macos" ]]; then
        # macOS: git comes with Xcode Command Line Tools
        print_info "On macOS, git is installed with Xcode Command Line Tools"
        print_info "Run: ${g}xcode-select --install${x}"
        if confirm "Install Xcode Command Line Tools now?"; then
            xcode-select --install 2>/dev/null
            print_info "Follow the dialog to complete installation, then re-run this script"
        fi
        return 1
    else
        # Linux: install via apt
        if spin "Installing git via apt..." apt_install git; then
            print_success "${g}git${x} installed$(fmt_version git)"
            track_install "git"
            return 0
        else
            print_error "Failed to install ${g}git${x}"
            return 1
        fi
    fi
}

install_omp() {
    print_header "Installing oh-my-posh"

    # Check common locations
    if cmd_exists oh-my-posh || [[ -x "$XDG_BIN_HOME/oh-my-posh" ]]; then
        local omp_ver
        omp_ver=$(oh-my-posh --version 2>/dev/null || "$XDG_BIN_HOME/oh-my-posh" --version 2>/dev/null)
        print_success "${g}oh-my-posh${x} is available${omp_ver:+ (${c}${omp_ver}${x})}"
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
        local omp_ver
        omp_ver=$("$XDG_BIN_HOME/oh-my-posh" --version 2>/dev/null)
        print_success "${g}oh-my-posh${x} installed${omp_ver:+ (${c}${omp_ver}${x})}"
        track_install "oh-my-posh"
        return 0
    else
        print_warning "Failed to install ${g}oh-my-posh${x} (non-critical)"
        return 0
    fi
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
            do_sudo chmod -x "$motd_dir/$script" &>/dev/null
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
            init_brew_shellenv
            print_success "${g}Homebrew${x} is available$(fmt_version brew)"
            track_skip "Homebrew"
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
        do_sudo mkdir -p /home/linuxbrew/
        do_sudo chmod 755 /home/linuxbrew/
    fi

    # Download and run Homebrew installer with spinner
    if spin "Installing Homebrew (this may take a while)..." env NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$URL_HOMEBREW")"; then
        init_brew_shellenv
        print_success "${g}Homebrew${x} installed$(fmt_version brew)"
        track_install "Homebrew"
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
        echo "$zsh_path" | do_sudo tee -a /etc/shells >/dev/null
    fi

    # Change default shell (use do_sudo to avoid extra password prompt)
    if do_sudo chsh -s "$zsh_path" "$USER"; then
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
        do_sudo chown -R "$(whoami)" "$XDG_CONFIG_HOME"
        print_info "Ensured ownership of ${c}$XDG_CONFIG_HOME${x}"
    fi

    # Create symlink for bat if batcat exists (common on Debian-based Linux)
    if is_debian && [[ -x /usr/bin/batcat ]]; then
        do_sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null
        print_info "Created symlink for bat: ${c}bat${x} -> ${c}batcat${x}"
    fi

    # Set timezone for Linux
    if is_debian; then
        do_sudo timedatectl set-timezone Europe/Warsaw 2>/dev/null
        print_info "Set timezone to ${c}Europe/Warsaw${x}"
    fi
}

# =============================================================================
# Main installation flow
# =============================================================================

main() {
    # Detect OS first (sets TOTAL_STEPS for correct counter display)
    detect_os

    # Print header
    install_header

    # Requirement checks
    check_os || return 1
    install_sudo || return 1
    init_sudo || return 1 # Get sudo password
    update_system

    # Installation steps
    install_core_utils || return 1
    install_git || return 1
    install_homebrew || return 1
    install_extra_utils || return 1
    install_omp

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

    # Post-installation fixes
    post_install_fixes

    # Cleanup sudo password from memory
    cleanup_sudo

    # Success message
    installation_successful

    # Prompt to start zsh
    prompt_start_zsh
}

# Run main function
main
