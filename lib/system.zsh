#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Operating system detection and information functions
# Depends on: date.zsh (format_duration, optional)
# /etc/os-release is parsed once at load time into ZSH_OS_RELEASE (assoc array)
##

## os-release cache

# Parsed /etc/os-release (keys: ID, ID_LIKE, VERSION_ID, VERSION_CODENAME, PRETTY_NAME, ...)
typeset -gA ZSH_OS_RELEASE=()

# Parse /etc/os-release into ZSH_OS_RELEASE (internal; called at load time)
# Usage: _os_release_load
# Returns: 0 loaded, 1 file not available
_os_release_load() {
    ZSH_OS_RELEASE=()
    [[ -r /etc/os-release ]] || return 1
    local line key val
    for line in "${(@f)$(</etc/os-release)}"; do
        [[ $line == [A-Z_]*=* ]] || continue
        key=${line%%=*}
        val=${(Q)line#*=}     # (Q) removes surrounding quotes
        ZSH_OS_RELEASE[$key]=$val
    done
    return 0
}
_os_release_load

## OS detection (boolean checks)

# Check if current OS is Debian-based (includes Ubuntu, Mint, Raspberry Pi OS, etc.)
# Usage: is_debian_based
# Returns: 0 true, 1 false, 2 invalid usage
is_debian_based() {
    (( ARGC == 0 )) || return 2
    [[ -f /etc/debian_version ]]
}

# Check if current OS is specifically Debian (not derivatives)
# Usage: is_debian
# Returns: 0 true, 1 false, 2 invalid usage
is_debian() {
    (( ARGC == 0 )) || return 2
    [[ ${ZSH_OS_RELEASE[ID]} == debian ]]
}

# Check if current OS is specifically Ubuntu
# Usage: is_ubuntu
# Returns: 0 true, 1 false, 2 invalid usage
is_ubuntu() {
    (( ARGC == 0 )) || return 2
    [[ ${ZSH_OS_RELEASE[ID]} == ubuntu ]]
}

# Check if current OS is macOS
# Usage: is_macos
# Returns: 0 true, 1 false, 2 invalid usage
is_macos() {
    (( ARGC == 0 )) || return 2
    [[ $OSTYPE == darwin* ]]
}

# Check if current OS is Linux
# Usage: is_linux
# Returns: 0 true, 1 false, 2 invalid usage
is_linux() {
    (( ARGC == 0 )) || return 2
    [[ $OSTYPE == linux* ]]
}

# Check if running under Windows Subsystem for Linux (WSL)
# Usage: is_wsl
# Returns: 0 true, 1 false, 2 invalid usage
is_wsl() {
    (( ARGC == 0 )) || return 2
    [[ -r /proc/version ]] || return 1
    local version=$(</proc/version)
    [[ $version == *[Mm]icrosoft* || $version == *WSL* ]]
}

# Check if running inside a container (Docker, Podman, LXC, systemd-nspawn, ...)
# Usage: is_container
# Returns: 0 true, 1 false, 2 invalid usage
is_container() {
    (( ARGC == 0 )) || return 2
    [[ -f /.dockerenv || -f /run/.containerenv || -n $container ]] && return 0
    if [[ -r /proc/1/cgroup ]]; then
        local cgroup=$(</proc/1/cgroup)
        [[ $cgroup == *docker* || $cgroup == *lxc* || $cgroup == *kubepods* || $cgroup == *containerd* ]] && return 0
    fi
    return 1
}

# Check if running on a Raspberry Pi
# Usage: is_raspberry_pi
# Returns: 0 true, 1 false, 2 invalid usage
is_raspberry_pi() {
    (( ARGC == 0 )) || return 2
    [[ -r /proc/device-tree/model ]] || return 1
    local model=$(</proc/device-tree/model)
    [[ $model == *"Raspberry Pi"* ]]
}

## System information

# Get OS name (ID)
# Usage: os_name
# Output: "macos", "ubuntu", "debian", "fedora", ..., "linux" or "unknown" (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
os_name() {
    (( ARGC == 0 )) || return 2
    case $OSTYPE in
        darwin*) REPLY=macos ;;
        linux*)  REPLY=${ZSH_OS_RELEASE[ID]:-linux} ;;
        *)       REPLY=unknown ;;
    esac
    print -r -- "$REPLY"
}

# Get OS code name
# Usage: os_codename
# Output: "Tahoe", "Noble", "Bookworm", etc. (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
os_codename() {
    (( ARGC == 0 )) || return 2
    if is_macos; then
        _macos_codename
    else
        _linux_codename
    fi
}

# Get Linux code name from os-release (internal)
# Usage: _linux_codename
# Output: code name (stdout); also sets REPLY
# Returns: 0 success, 1 unknown
_linux_codename() {
    REPLY=${ZSH_OS_RELEASE[VERSION_CODENAME]:-${ZSH_OS_RELEASE[PRETTY_NAME]}}
    [[ -n $REPLY ]] || return 1
    REPLY=${(C)REPLY}
    print -r -- "$REPLY"
}

# Get macOS marketing name from the product version (internal)
# Usage: _macos_codename
# Output: code name (stdout); also sets REPLY
# Returns: 0 success
_macos_codename() {
    local product_ver
    product_ver=$(sw_vers -productVersion 2>/dev/null)
    local -a ver_parts=(${(s:.:)product_ver})
    local major=${ver_parts[1]}
    local minor=${ver_parts[2]}

    case $major in
        27) REPLY="Golden Gate" ;;
        26) REPLY="Tahoe" ;;
        15) REPLY="Sequoia" ;;
        14) REPLY="Sonoma" ;;
        13) REPLY="Ventura" ;;
        12) REPLY="Monterey" ;;
        11) REPLY="Big Sur" ;;
        10)
            case $minor in
                16|15) REPLY="Catalina" ;;
                14)    REPLY="Mojave" ;;
                13)    REPLY="High Sierra" ;;
                12)    REPLY="Sierra" ;;
                11)    REPLY="El Capitan" ;;
                *)     REPLY="macOS $product_ver" ;;
            esac
            ;;
        *)  REPLY="Unknown ($product_ver)" ;;
    esac
    print -r -- "$REPLY"
}

# Get OS version number
# Usage: os_version
# Output: e.g. "26.1" or "24.04" (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
os_version() {
    (( ARGC == 0 )) || return 2
    if is_macos; then
        REPLY=$(sw_vers -productVersion 2>/dev/null)
    else
        REPLY=${ZSH_OS_RELEASE[VERSION_ID]}
    fi
    [[ -n $REPLY ]] || return 1
    print -r -- "$REPLY"
}

# Get kernel version
# Usage: get_kernel_version
# Output: kernel release, e.g. "6.8.0-45-generic" (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
get_kernel_version() {
    (( ARGC == 0 )) || return 2
    if [[ -r /proc/sys/kernel/osrelease ]]; then
        REPLY=$(</proc/sys/kernel/osrelease)
    else
        REPLY=$(uname -r)
    fi
    print -r -- "$REPLY"
}

# Get OS icon (Nerd Fonts required)
# Usage: os_icon
# Output: icon character (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
os_icon() {
    (( ARGC == 0 )) || return 2
    if is_wsl; then
        REPLY=$'\Uf17a'   # Windows logo
        print -r -- "$REPLY"
        return 0
    fi
    os_name >/dev/null
    case $REPLY in
        macos)      REPLY=$'\Uf179' ;; # Apple logo
        ubuntu)     REPLY=$'\Uf31b' ;;
        debian)     REPLY=$'\Uf306' ;;
        rhel|redhat) REPLY=$'\Uf316' ;;
        fedora)     REPLY=$'\Uf30a' ;;
        arch)       REPLY=$'\Uf303' ;;
        opensuse*)  REPLY=$'\Uf314' ;;
        raspbian)   REPLY=$'\Uf315' ;;
        alpine)     REPLY=$'\Uf300' ;;
        *)          REPLY=$'\Ue712' ;; # Generic Linux penguin
    esac
    print -r -- "$REPLY"
}

# Get system uptime (human readable, via format_duration)
# Usage: get_uptime
# Output: e.g. "2d 4h 15m" (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
get_uptime() {
    (( ARGC == 0 )) || return 2
    local -i uptime_sec boot_time
    local raw

    if is_macos; then
        # sysctl returns: { sec = 1700000000, usec = 0 } ...
        raw=$(sysctl -n kern.boottime 2>/dev/null)
        boot_time=${${raw[(w)4]}//,}
        uptime_sec=$(( EPOCHSECONDS - boot_time ))
    elif [[ -r /proc/uptime ]]; then
        # First field of /proc/uptime is seconds (with decimals)
        raw=$(</proc/uptime)
        uptime_sec=${raw%%.*}
    else
        return 1
    fi

    if (( ${+functions[format_duration]} )); then
        format_duration $uptime_sec
    else
        REPLY="$(( uptime_sec / 86400 ))d $(( uptime_sec % 86400 / 3600 ))h $(( uptime_sec % 3600 / 60 ))m"
        print -r -- "$REPLY"
    fi
}

# Get CPU load average (1 minute)
# Usage: get_load_average
# Output: e.g. "1.50" (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
get_load_average() {
    (( ARGC == 0 )) || return 2
    local load
    if is_macos; then
        # sysctl returns "{ 1.50 1.20 1.00 }"
        load=$(sysctl -n vm.loadavg 2>/dev/null)
        REPLY=${load[(w)2]}
    elif [[ -r /proc/loadavg ]]; then
        load=$(</proc/loadavg)
        REPLY=${load[(w)1]}
    else
        return 1
    fi
    print -r -- "$REPLY"
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
