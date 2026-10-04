#!/bin/bash
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# zconfig installer script
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/barabasz/zconfig/HEAD/install.sh)"
#
# This script installs zconfig by:
#  1. Checking system requirements (macOS or Debian-based Linux)
#  2. Installing sudo and updating system packages (Linux only)
#  3. Generating English and Polish locales, then installing core utilities (Linux only)
#  4. Installing git (xcode-select on macOS, apt on Linux)
#  5. Installing Homebrew (if not present)
#  6. Installing extra utilities like 7-Zip, eza, fzf, etc.
#  7. Installing the Z shell itself
#  8. Installing oh-my-posh prompt theme engine
#  9. Handling existing installation (backup/remove)
# 10. Cloning the zconfig repository to ~/.config/zsh
# 11. Creating symlink ~/.zshenv -> ~/.config/zsh/.zshenv
# 12. Minimizing login info: .hushlogin, MOTD scripts (Linux only)
# 13. Setting zsh as default shell
# 14. Starting zsh with new configuration
# Primary test targets: current macOS and Ubuntu Server.
# Older distribution releases are not a compatibility target.

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_VERSION="0.8.11"
SCRIPT_DATE="2026-10-04"
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
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_BIN_HOME" "$XDG_LIB_HOME" "$XDG_TMP_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" || exit 1

# Logging - clean log + verbose debug log
LOGFILE="$XDG_TMP_HOME/zconfig_$(date +%Y%m%d_%H%M%S).log"
DEBUGLOG="${LOGFILE%.log}.debug.log"

# Step counter - UPDATE THIS when adding/removing installation steps!
# macOS: 10 steps, Linux: 15 steps (set dynamically after OS detection)
TOTAL_STEPS=10
STEP_NUM=0

URL_HOMEBREW="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
URL_OHMYPOSH="https://ohmyposh.dev/install.sh"

# Interactive mode (0 = automatic, 1 = ask questions)
INTERACTIVE=${INTERACTIVE:-0}

# Bootstrap Linux with the always-available C locale. Requested UTF-8 locales
# may not exist yet on a minimal installation; configure_locales generates them.
if [[ "$(uname -s)" == "Linux" ]]; then
    export LANG=C LC_ALL=C LANGUAGE=C
else
    export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
fi

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
FAILED_TOOLS=()

# Linux retains the password only in shell memory until cleanup. It is used
# solely by sudo -S -v (authentication), never as the stdin of a command.
SUDO_PASS=""
export -n SUDO_PASS
SUDO_PASSWORD_READY=0
SUDO_INITIALIZED=0

# PID of background sudo keep-alive loop (both platforms)
SUDO_KEEPALIVE_PID=""

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
# Strips ANSI color codes before writing
# Usage: print_log "message"
print_log() {
    local clean="${1//$'\033['[0-9]m/}"
    clean="${clean//$'\033['[0-9][0-9]m/}"
    clean="${clean//$'\033['[0-9];[0-9]m/}"
    clean="${clean//$'\033['[0-9];[0-9][0-9]m/}"
    clean="${clean//$'\033['[0-9];[0-9];[0-9]*m/}"
    echo "$clean" >> "$LOGFILE"
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
            TOTAL_STEPS=10  # macOS has fewer steps (no sudo, apt, etc.)
            ;;
        Linux)
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
                    OS_TYPE="debian"
                    TOTAL_STEPS=15  # Linux has additional steps
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
    if [[ "$cmd" == "7zz" || "$cmd" == "7z" ]]; then
        # 7-Zip has no --version flag; its info command prints the banner.
        output=$("$cmd" i 2>/dev/null) || { echo "unknown"; return 1; }
    else
        output=$("$cmd" --version 2>/dev/null) || \
        output=$("$cmd" -v 2>/dev/null) || \
        output=$("$cmd" -V 2>/dev/null) || \
        { echo "unknown"; return 1; }
    fi

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
# Sudo wrapper functions - separate authentication from command input
# Recover Linux credentials after cache invalidation without another prompt.
# =============================================================================

# Initialize sudo in the foreground, before any privileged background command.
# Linux: called after install_sudo. macOS: called when privileges are needed.
init_sudo() {
    [[ "$SUDO_INITIALIZED" -eq 1 ]] && return 0

    print_log "Sudo implementation: $(sudo --version 2>/dev/null | head -n 1)"
    print_log "Sudo terminal: $(tty 2>/dev/null)"
    if is_debian; then
        print_info "Sudo password required once; authentication can be restored during installation:"
        read_sudo_password || return 1
        # Ensure the supplied password is really checked even if sudo was used
        # earlier in this terminal. Do not combine -k with -v: cache it normally.
        sudo -k >> "$DEBUGLOG" 2>&1 || return 1
        if ! sudo_validate_password; then
            print_error "Cannot authenticate with sudo (see $DEBUGLOG)"
            return 1
        fi
    else
        # Keep native macOS authentication, including its PAM/Touch ID setup.
        print_info "Administrator access required (sudo may ask for your password):"
        if ! sudo -v; then
            print_error "Cannot obtain sudo access"
            return 1
        fi
    fi

    SUDO_INITIALIZED=1

    # Check the same background context that spin uses. Some sudo policies
    # cache credentials by parent PID rather than by terminal session.
    if ! spin "Checking cached sudo access in background..." sudo_background_check; then
        print_error "Sudo access is unavailable in background commands"
        print_info "Run from an interactive terminal (SSH: use ssh -t) and check $DEBUGLOG"
        return 1
    fi

    sudo_keepalive_start
    print_success "Sudo access ready; authentication is separate from command stdin"
    return 0
}

# Read from the terminal even when the installer itself receives piped input.
read_sudo_password() {
    if ! IFS= read -r -s -p "[sudo] password for $(whoami): " SUDO_PASS </dev/tty; then
        printf '\n'
        print_error "Cannot read sudo password; run from an interactive terminal"
        return 1
    fi
    printf '\n'
    SUDO_PASSWORD_READY=1
}

# This sudo invocation validates credentials only: it executes no child command.
# Suppress xtrace locally so bash -x cannot print the password expansion.
sudo_validate_password() {
    local tracing=0 status
    if [[ "$-" == *x* ]]; then
        tracing=1
        set +x
    fi
    printf '%s\n' "$SUDO_PASS" | sudo -S -p '' -v >> "$DEBUGLOG" 2>&1
    status=$?
    [[ "$tracing" -eq 1 ]] && set -x
    return "$status"
}

# Refresh a usable cache or restore it from the retained Linux password.
sudo_refresh() {
    local status=0
    sudo -n -v >> "$DEBUGLOG" 2>&1 || status=$?
    [[ "$status" -eq 0 ]] && return 0

    print_log "Sudo cache unavailable (exit: $status, shell PID: ${BASHPID:-$$}, elapsed: $(get_elapsed_time)); restoring authentication"
    if is_debian && [[ "$SUDO_PASSWORD_READY" -eq 1 ]]; then
        if sudo_validate_password; then
            print_log "Sudo authentication restored from retained password"
            return 0
        fi
    fi
    return 1
}

# Keep a shell parent alive, as apt_run/do_sudo do inside the spinner.
sudo_background_check() {
    sudo_refresh || return 1
    sudo -n true
    local status=$?
    return "$status"
}

# Check privileges after an external installer may have invalidated its cache.
# This runs in the foreground, before more apt or chsh operations are started.
sudo_checkpoint() {
    local stage="$1" status=0
    [[ "$SUDO_INITIALIZED" -eq 1 ]] || return 0
    sudo_keepalive_stop

    sudo -n true >> "$DEBUGLOG" 2>&1 || status=$?
    print_log "Sudo checkpoint [$stage]: cached command exit=$status"
    if ! sudo_refresh; then
        if [[ "$OS_TYPE" == "macos" ]]; then
            print_info "Sudo credentials need renewal after $stage"
            sudo -v || { print_error "Cannot renew sudo access"; return 1; }
        else
            print_error "Cannot restore sudo access after $stage (see $DEBUGLOG)"
            return 1
        fi
    fi
    if ! spin "Checking sudo access after $stage..." sudo_background_check; then
        print_error "Sudo background check failed after $stage (see $DEBUGLOG)"
        return 1
    fi
    sudo_keepalive_start
    print_success "Sudo access verified after $stage"
    return 0
}

# Preserve the command's stdin; never pipe a password into its input.
do_sudo() {
    # macOS may first need sudo when changing the default shell.
    if [[ "$SUDO_INITIALIZED" -ne 1 ]]; then
        init_sudo || return 1
    fi
    if ! sudo_refresh; then
        print_error "Cannot authenticate before privileged command: ${1:-unknown} (see $DEBUGLOG)"
        return 1
    fi
    sudo -n "$@" 2>> "$DEBUGLOG"
    local status=$?
    [[ "$status" -ne 0 ]] && print_log "Privileged command failed: ${1:-unknown}, exit=$status"
    return "$status"
}

# Silent apt-get wrapper (no warnings, no needrestart prompts)
# Usage: apt_run update | upgrade -y | install -y <pkg>
apt_run() {
    do_sudo env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
        apt-get -qq "$@"
}

# Convenience wrapper for apt install
apt_install() {
    apt_run install -y "$@"
}

# Stop refresh first, then invalidate this session's cached credentials.
cleanup_sudo() {
    sudo_keepalive_stop
    if [[ "$SUDO_INITIALIZED" -eq 1 ]]; then
        sudo -k 2>/dev/null || true
        SUDO_INITIALIZED=0
    fi
    SUDO_PASS=""
    unset SUDO_PASS
    SUDO_PASSWORD_READY=0
}

# Keep sudo credentials cached while a long non-interactive command runs
# (e.g. Homebrew installer with NONINTERACTIVE=1 only uses `sudo -n`)
sudo_keepalive_start() {
    [[ -n "$SUDO_KEEPALIVE_PID" ]] && return 0
    (
        local sleeper=""
        trap '[[ -n "$sleeper" ]] && kill "$sleeper" 2>/dev/null; exit 0' TERM INT
        while kill -0 "$$" 2>/dev/null; do
            if ! sudo_refresh; then
                print_log "WARNING: Sudo keep-alive cannot restore authentication"
                break
            fi
            sleep 20 &
            sleeper=$!
            wait "$sleeper" || break
            sleeper=""
        done
    ) &>/dev/null &
    SUDO_KEEPALIVE_PID=$!
    print_log "Sudo keep-alive started (PID: $SUDO_KEEPALIVE_PID)"
}

sudo_keepalive_stop() {
    [[ -z "$SUDO_KEEPALIVE_PID" ]] && return 0
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    SUDO_KEEPALIVE_PID=""
}

# Run command with spinner
# Usage: spin "message" command [args...]
spin() {
    local msg="$1"
    shift
    local frames='|/-\'
    local delay=0.15
    local i=0
    local monitor_was_enabled=0
    [[ "$-" == *m* ]] && monitor_was_enabled=1

    # Log the command being executed (short form to clean log, full to debug)
    print_log "Executing: ${*%% *}"
    echo "█ Executing: $*" >> "$DEBUGLOG"

    # Disable job control messages (shell-agnostic)
    if [[ -n "$ZSH_VERSION" ]]; then
        setopt LOCAL_OPTIONS NO_MONITOR NO_NOTIFY
    else
        set +m
    fi

    # Run command in background, verbose output to debug log only
    "$@" >> "$DEBUGLOG" 2>&1 &
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

    # Restore the original job-control state (zsh uses LOCAL_OPTIONS).
    if [[ -z "$ZSH_VERSION" && "$monitor_was_enabled" -eq 1 ]]; then
        set -m
    fi

    # Log result to both files
    if [[ $exit_code -eq 0 ]]; then
        print_log "Command completed successfully"
        echo "█ Command completed successfully" >> "$DEBUGLOG"
    else
        print_log "Command FAILED with exit code: $exit_code"
        echo "█ Command FAILED with exit code: $exit_code" >> "$DEBUGLOG"
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
            if [[ "$(dpkg-query -W -f='${Status}' "$apt_pkg" 2>/dev/null)" == "install ok installed" ]]; then
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
            FAILED_TOOLS+=("$cmd_name")
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
            FAILED_TOOLS+=("$cmd_name")
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
    print_comment "Debug log: $DEBUGLOG"
    print_info "This will install $ZCONFIG to ${c}$ZCONFIG_DIR${x}"
    # Note for Linux users (OS_TYPE not set yet, so check directly)
    [[ "$(uname -s)" == "Linux" ]] && print_comment "Note: sudo authenticates once; cached access is kept alive during installation"
}

# Print installation summary
print_summary() {
    if [[ ${#INSTALLED[@]} -gt 0 ]]; then
        print_info "Installed: ${g}${INSTALLED[*]}${x}"
    fi
    if [[ ${#SKIPPED[@]} -gt 0 ]]; then
        print_info "Already present: ${d}${SKIPPED[*]}${x}"
    fi
    if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
        print_warning "Utilities not installed: ${FAILED_TOOLS[*]}"
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

    if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
        print_end_header "Installation finished with missing utilities"
        print_log "Installation result: completed with missing utilities"
    else
        print_end_header "Installation complete!"
        print_log "Installation result: completed successfully"
    fi
    print_summary
    printf "\n"
    print_info "$ZCONFIG installed to: ${c}$ZCONFIG_DIR${x}"
    print_info "Entry point for zsh:  ${c}$ZSHENV_LINK${x}"
    print_info "Installation log:     ${c}$LOGFILE${x}"
    print_info "Debug log:            ${c}$DEBUGLOG${x}"
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

    # Install sudo AND configure a validated drop-in in one su -c command.
    local username
    username=$(whoami)

    # This name is used in a sudoers entry, filename and root shell command.
    if [[ ! "$username" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*[$]?$ ]]; then
        print_error "Cannot safely create a sudoers entry for user: $username"
        return 1
    fi

    local root_script
    root_script="username='$username'"$'\n'"$(cat <<'ROOT_SCRIPT'
set -e
export LC_ALL=C
apt-get -qq -o APT::Update::Error-Mode=any update
DEBIAN_FRONTEND=noninteractive apt-get -qq install -y sudo
install -d -m 0750 /etc/sudoers.d
sudoers_file="/etc/sudoers.d/zconfig-$username"
if [ -e "$sudoers_file" ] || [ -L "$sudoers_file" ]; then
    printf 'Refusing to overwrite %s\n' "$sudoers_file" >&2
    exit 1
fi
# The temporary filename contains a dot, so includedir ignores it.
sudoers_temp=$(mktemp /etc/sudoers.d/.zconfig.XXXXXX)
trap 'rm -f "$sudoers_temp"' EXIT
printf '%s ALL=(ALL:ALL) ALL\n' "$username" > "$sudoers_temp"
chmod 0440 "$sudoers_temp"
visudo -cf "$sudoers_temp"
mv "$sudoers_temp" "$sudoers_file"
if ! visudo -c; then
    rm -f "$sudoers_file"
    exit 1
fi
ROOT_SCRIPT
)"

    if su -c "$root_script"; then
        print_success "${g}sudo${x} installed$(fmt_version sudo)"
        print_info "User granted sudo access via /etc/sudoers.d/zconfig-$username (default timeout)"
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

    # Let systemd choose the installed NTP provider (e.g. chrony or timesyncd).
    # Enabling NTP does not mean synchronization has already completed.
    if do_sudo timedatectl set-timezone Europe/Warsaw; then
        print_info "Set timezone to ${c}Europe/Warsaw${x}"
    else
        print_warning "Could not set timezone to Europe/Warsaw (see $DEBUGLOG)"
    fi
    if do_sudo timedatectl set-ntp true; then
        local synced
        synced=$(timedatectl show --property=NTPSynchronized --value 2>>"$DEBUGLOG")
        case "$synced" in
            yes) print_info "System clock is synchronized" ;;
            no) print_info "Network time synchronization enabled; clock synchronization is pending" ;;
            *) print_warning "Network time synchronization enabled; could not read clock synchronization status" ;;
        esac
    else
        print_warning "Could not enable network time synchronization (see $DEBUGLOG)"
    fi
    print_info "Current time: ${c}$(date '+%Y-%m-%d %H:%M:%S %Z')${x}"

    # Treat partial repository download failures as errors as well.
    if ! spin "Updating package lists..." apt_run -o APT::Update::Error-Mode=any update; then
        print_error "Failed to update package lists (see $DEBUGLOG)"
        return 1
    fi
    if ! spin "Upgrading packages..." apt_run upgrade -y; then
        print_error "Failed to upgrade system packages (see $DEBUGLOG)"
        return 1
    fi

    print_success "System packages updated"
    return 0
}

# zconfig uses English messages and Polish formatting in inc/locales.zsh.
# Generate both before starting zsh: its sudo-based repair cannot run after
# cleanup_sudo has invalidated the installer credentials.
configure_locales() {
    is_debian || return 0
    print_header "Configuring English and Polish locales"

    if [[ "$(dpkg-query -W -f='${Status}' locales 2>/dev/null)" != "install ok installed" ]]; then
        if ! spin "Installing locales via apt..." apt_install locales; then
            print_error "Failed to install locales (see $DEBUGLOG)"
            return 1
        fi
        track_install "locales"
    fi

    local required=(en_US.UTF-8 pl_PL.UTF-8)
    local loc available needs_generation=0
    available=$(LC_ALL=C locale -a 2>>"$DEBUGLOG") || return 1
    for loc in "${required[@]}"; do
        if ! printf '%s\n' "$available" | grep -Fqix "${loc/UTF-8/utf8}"; then
            needs_generation=1
        fi
    done

    if [[ "$needs_generation" -eq 1 ]]; then
        # Preserve other locales and enable only the two required entries.
        if ! do_sudo sed -i -E '/^[[:space:]]*#[[:space:]]*(en_US|pl_PL)\.UTF-8[[:space:]]+UTF-8[[:space:]]*$/s/^[[:space:]]*#[[:space:]]*//' /etc/locale.gen; then
            print_error "Failed to enable required locales in /etc/locale.gen"
            return 1
        fi
        for loc in "${required[@]}"; do
            if ! grep -Eq "^[[:space:]]*${loc/./\\.}[[:space:]]+UTF-8[[:space:]]*$" /etc/locale.gen; then
                if ! printf '\n%s UTF-8\n' "$loc" | do_sudo tee -a /etc/locale.gen >/dev/null; then
                    print_error "Failed to add $loc to /etc/locale.gen"
                    return 1
                fi
            fi
        done
        if ! spin "Generating en_US.UTF-8 and pl_PL.UTF-8..." do_sudo env LC_ALL=C locale-gen; then
            print_error "Failed to generate required locales (see $DEBUGLOG)"
            return 1
        fi
    fi

    available=$(LC_ALL=C locale -a 2>>"$DEBUGLOG") || return 1
    for loc in "${required[@]}"; do
        if ! printf '%s\n' "$available" | grep -Fqix "${loc/UTF-8/utf8}"; then
            print_error "Required locale $loc is still unavailable (see $DEBUGLOG)"
            return 1
        fi
    done
    export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANGUAGE=en_US:en:C
    print_success "Locales available: en_US.UTF-8, pl_PL.UTF-8"
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
    # Current apt packages provide 7z; Homebrew sevenzip provides 7zz.
    local sevenzip_cmd=7z
    [[ "$OS_TYPE" == "macos" ]] && sevenzip_cmd=7zz
    local utils=(
        "$sevenzip_cmd:sevenzip:7zip" # Official 7-Zip: apt on Linux, Homebrew on macOS
        "bat:bat:"       # cat replacement with syntax highlighting
        "curl::curl"     # URL transfers - used by network.zsh, wanip
        "dig::dnsutils"  # DNS lookup - used by network.zsh, mdig, wanip
        "eza:eza:"       # ls replacement; Homebrew on both platforms
        "fzf:fzf:"       # fuzzy finder
        "glow:glow:"     # markdown viewer
        "gh:gh:"         # GitHub CLI
        "grep::grep"     # pattern matching - used by cmdinfo, fn.zsh, etc.
        "htop:htop:htop" # interactive process viewer
        "kitty-terminfo::kitty-terminfo" # terminal info for Kitty
        "lsof::lsof"    # list open files - used by network.zsh
        "man::man-db"    # manual pages - used by cmdinfo.zsh
        "sed:gsed:sed"   # stream editor - used by fn.zsh, strings.zsh
        "tldr:tlrc:"     # tldr client written in Rust
        "tmux:tmux:tmux" # terminal multiplexer
        "tput::ncurses-bin" # terminal capabilities - used by print.zsh
        "yazi:yazi:"     # blazing fast terminal file manager written in Rust
        "yq:yq:"         # YAML processor written in Go
        "zoxide:zoxide:" # smarter cd replacement with fuzzy search and frecency
        "zsh:zsh:zsh:1"  # Z shell itself - critical for zconfig
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
            print_info "Follow the macOS GUI dialog to complete installation, then re-run this script"
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

    # Disable MOTD scripts (Ubuntu/Debian only)
    local motd_dir="/etc/update-motd.d"
    if [[ -d "$motd_dir" ]]; then
        local distro=""
        [[ -f /etc/os-release ]] && . /etc/os-release && distro="$ID"

        local scripts=()
        case "$distro" in
            ubuntu) scripts=("00-header" "10-help-text" "50-motd-news") ;;
            debian) scripts=("10-uname") ;;
        esac

        local script
        for script in "${scripts[@]}"; do
            if [[ -f "$motd_dir/$script" ]]; then
                do_sudo chmod -x "$motd_dir/$script" &>/dev/null
                print_info "Disabled MOTD script: ${c}$script${x}"
            fi
        done
    fi

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
    local brew_path brew_env
    if [[ -x /opt/homebrew/bin/brew ]]; then
        brew_path=/opt/homebrew/bin/brew
    elif [[ -x /usr/local/bin/brew ]]; then
        brew_path=/usr/local/bin/brew
    elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        brew_path=/home/linuxbrew/.linuxbrew/bin/brew
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        brew_path="$HOME/.linuxbrew/bin/brew"
    else
        return 1
    fi

    brew_env=$("$brew_path" shellenv) || return 1
    eval "$brew_env" || return 1
    cmd_exists brew
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
            init_brew_shellenv || { print_error "Failed to initialize Homebrew environment"; return 1; }
            print_success "${g}Homebrew${x} is available$(fmt_version brew)"
            track_skip "Homebrew"
            brew analytics off &>/dev/null
            sudo_checkpoint "Homebrew detection" || return 1
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
        do_sudo mkdir -p /home/linuxbrew/ || return 1
        do_sudo chmod 755 /home/linuxbrew/ || return 1
    fi

    # macOS: Homebrew installer in NONINTERACTIVE mode never prompts for
    # a password, it only checks `sudo -n` and aborts without cached
    # credentials. Ask for the password here (in the foreground) and keep
    # the credentials alive while the installer runs in the background.
    if [[ "$OS_TYPE" == "macos" ]]; then
        print_info "Homebrew requires administrator privileges (sudo)"
        init_sudo || return 1
    fi

    # Download Homebrew installer to a temp file (keeps the debug log short
    # and catches download errors instead of running an empty script)
    local brew_installer brew_status=0
    brew_installer=$(mktemp "${TMPDIR:-/tmp}/brew-install.XXXXXX") || return 1
    if ! curl -fsSL "$URL_HOMEBREW" -o "$brew_installer"; then
        rm -f "$brew_installer"
        print_error "Failed to download ${g}Homebrew${x} installer"
        return 1
    fi

    # Run Homebrew installer with spinner
    spin "Installing Homebrew (this may take a while)..." env NONINTERACTIVE=1 /bin/bash "$brew_installer" || brew_status=$?
    rm -f "$brew_installer"

    if [[ $brew_status -eq 0 ]]; then
        init_brew_shellenv || { print_error "Failed to initialize Homebrew environment"; return 1; }
        sudo_checkpoint "Homebrew installation" || return 1
        print_success "${g}Homebrew${x} installed$(fmt_version brew)"
        track_install "Homebrew"
        brew analytics off &>/dev/null
        return 0
    else
        print_error "${g}Homebrew${x} installation failed (see ${c}$DEBUGLOG${x})"
        return 1
    fi
}

set_default_shell() {
    print_header "Setting default shell"

    local zsh_path
    zsh_path=$(command -v zsh) || { print_error "Cannot find zsh"; return 1; }
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
    if ! grep -Fqx "$zsh_path" /etc/shells 2>/dev/null; then
        print_info "Adding ${c}$zsh_path${x} to ${c}/etc/shells${x}"
        if ! do_sudo sh -c 'printf "%s\n" "$1" >> /etc/shells' sh "$zsh_path"; then
            print_error "Failed to add zsh to /etc/shells"
            return 1
        fi
    fi

    # Change default shell (use do_sudo to avoid extra password prompt)
    if do_sudo chsh -s "$zsh_path" "$USER"; then
        print_success "Default shell changed to ${g}zsh${x}"
        return 0
    else
        print_error "Failed to change default shell"
        print_info "You can change it manually with: ${g}chsh -s ${c}$zsh_path${x}"
        return 1
    fi
}

post_install_fixes() {
    print_header "Performing post-installation fixes"

    # Create symlink for bat if batcat exists (common on Debian-based Linux)
    if is_debian && [[ -x /usr/bin/batcat ]]; then
        if do_sudo ln -sf /usr/bin/batcat /usr/local/bin/bat; then
            print_info "Created symlink for bat: ${c}bat${x} -> ${c}batcat${x}"
        else
            print_warning "Failed to create bat symlink"
        fi
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
    if is_debian; then
        init_sudo || return 1
    fi
    update_system || return 1
    configure_locales || return 1

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
    set_default_shell || return 1

    # Post-installation fixes
    post_install_fixes

    # Stop keep-alive and clear cached credentials before exec zsh.
    cleanup_sudo

    # Success message
    installation_successful

    # Prompt to start zsh
    prompt_start_zsh
}

# Always clean up on success, failure, Ctrl+C or termination.
installer_exit() {
    local exit_code=$?
    cleanup_sudo
    [[ -t 1 ]] && printf '\033[?25h'
    if [[ "$exit_code" -ne 0 ]]; then
        print_error "Installation stopped (exit code: $exit_code)"
        print_info "Installation log: $LOGFILE"
        print_info "Debug log: $DEBUGLOG"
    fi
    return "$exit_code"
}

trap installer_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Run main function
main
