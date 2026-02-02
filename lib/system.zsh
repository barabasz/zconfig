#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# OS related functions
# zsh-specific functions - requires zsh, will not work in bash

# --- OS Detection (Boolean Checks) ---

# Check if current OS is Debian-based (includes Ubuntu, Mint, etc.)
# Usage: is_debian_based
is_debian_based() {
    [[ -f /etc/debian_version ]]
}

# Check if current OS is specifically Debian (not derivatives)
# Usage: is_debian
is_debian() {
    [[ -f /etc/os-release ]] || return 1
    # Read file directly into variable
    local content=$(</etc/os-release)
    [[ $content == *"ID=debian"* ]]
}

# Check if current OS is specifically Ubuntu
# Usage: is_ubuntu
is_ubuntu() {
    [[ -f /etc/os-release ]] || return 1
    local content=$(</etc/os-release)
    [[ $content == *"ID=ubuntu"* ]]
}

# Check if current OS is macOS
# Usage: is_macos
is_macos() {
    [[ $OSTYPE == darwin* ]]
}

# Check if current OS is Linux
# Usage: is_linux
is_linux() {
    [[ $OSTYPE == linux* ]]
}

# Check if current OS is Windows (WSL)
# Usage: is_wsl
is_wsl() {
    # Pure Zsh check without grep
    if [[ -r /proc/version ]]; then
        local version=$(</proc/version)
        [[ $version == *[Mm]icrosoft* || $version == *WSL* ]]
    else
        return 1
    fi
}

# --- System Information Retrieval ---

# Get OS name (ID)
# Usage: os_name
# Returns: "macos", "ubuntu", "debian", "fedora", etc.
os_name() {
    case $OSTYPE in
        darwin*)
            print "macos" ;;
        linux*)
            if [[ -f /etc/os-release ]]; then
                # Optimized extraction without subshells/grep
                # (M) keeps matching lines, (f) splits by line
                local line=${${(M)${(f)"$(</etc/os-release)"}:#ID=*}#ID=}
                print -- ${line//\"/}
            else
                print "linux"
            fi ;;
        *)
            print "unknown" ;;
    esac
}

# Get OS code name
# Usage: os_codename
# Returns: "Sequoia", "Noble", "Bookworm", etc.
os_codename() {
    if is_macos; then
        _macos_codename
    else
        _linux_codename
    fi
}

# Helper for Linux codename
_linux_codename() {
    [[ -f /etc/os-release ]] || return 1
    local content="${(f)$(</etc/os-release)}"
    local line=${${(M)content:#VERSION_CODENAME=*}#VERSION_CODENAME=}
    
    # Fallback to PRETTY_NAME if VERSION_CODENAME is missing
    if [[ -z "$line" ]]; then
        line=${${(M)content:#PRETTY_NAME=*}#PRETTY_NAME=}
    fi
    
    print -- "${(C)${line//\"/}}"
}

# Helper for macOS codename
_macos_codename() {
    local product_ver
    # Fast retrieval
    product_ver=$(sw_vers -productVersion)
    
    # Split version by dots
    local -a ver_parts=(${(s:.:)product_ver})
    local major=${ver_parts[1]}
    local minor=${ver_parts[2]}

    # Based on your previous context about Tahoe 26.2
    case $major in
        26) print "Tahoe" ;;
        15) print "Sequoia" ;;
        14) print "Sonoma" ;;
        13) print "Ventura" ;;
        12) print "Monterey" ;;
        11) print "Big Sur" ;;
        10)
            case $minor in
                16|15) print "Catalina" ;;
                14) print "Mojave" ;;
                13) print "High Sierra" ;;
                12) print "Sierra" ;;
                11) print "El Capitan" ;;
                *)  print "macOS $product_ver" ;;
            esac
            ;;
        *)  print "Unknown ($product_ver)" ;;
    esac
}

# Display OS version number
# Usage: os_version
# Returns: "14.2.1" or "22.04"
os_version() {
    if is_macos; then
        sw_vers -productVersion
    elif [[ -f /etc/os-release ]]; then
        local line=${${(M)${(f)"$(</etc/os-release)"}:#VERSION_ID=*}#VERSION_ID=}
        print -- ${line//\"/}
    fi
}

# Get kernel version
# Usage: get_kernel_version
get_kernel_version() {
    uname -r
}

# Get OS icon (Nerd Fonts required)
# Usage: os_icon
os_icon() {
    case $(os_name) in
        macos)      print $'\Uf179' ;; # Apple logo
        ubuntu)     print $'\Uf31b' ;;
        debian)     print $'\Uf306' ;;
        redhat)     print $'\Uf316' ;;
        fedora)     print $'\Uf30a' ;;
        arch)       print $'\Uf303' ;;
        opensuse*)  print $'\Uf314' ;;
        windows)    print $'\Uf17a' ;;
        raspbian)   print $'\Uf315' ;;
        alpine)     print $'\Uf300' ;;
        *)          print $'\Ue712' ;; # Generic Linux penguin
    esac
}

# Get system uptime (human readable)
# Usage: get_uptime
# Returns: "2 days 4h 15m" using format_duration
get_uptime() {
    local uptime_sec boot_time
    
    if is_macos; then
        # sysctl returns: { sec = 1700000000, usec = 0 }
        # We extract the seconds part
        boot_time=${$(sysctl -n kern.boottime)[(w)4]//,}
        uptime_sec=$(( EPOCHSECONDS - boot_time ))
    elif [[ -r /proc/uptime ]]; then
        # First field of /proc/uptime is seconds
        read uptime_sec _ < /proc/uptime
        uptime_sec=${uptime_sec%.*}
    else
        # Fallback without sed, using parameter expansion
        local up_str=$(uptime)
        # Extract part after "up " until first comma
        up_str=${up_str#*up }
        print -- ${up_str%%,*}
        return 0
    fi
    
    # Use helper from date.zsh if available
    if (( ${+functions[format_duration]} )); then
        format_duration "$uptime_sec"
    else
        # Simple fallback
        local d=$(( uptime_sec / 86400 ))
        local h=$(( (uptime_sec % 86400) / 3600 ))
        local m=$(( (uptime_sec % 3600) / 60 ))
        (( d > 0 )) && print -n "${d}d "
        (( h > 0 )) && print -n "${h}h "
        print "${m}m"
    fi
}

# Get CPU Load Average (1 min)
# Usage: get_load_average
# Returns: "1.50"
get_load_average() {
    if is_macos; then
        # sysctl returns "{ 1.50 1.20 1.00 }"
        local load=$(sysctl -n vm.loadavg)
        # Extract second word (the first number inside braces)
        print -- ${load[(w)2]}
    elif [[ -r /proc/loadavg ]]; then
        # First field
        read load _ < /proc/loadavg
        print -- $load
    fi
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}