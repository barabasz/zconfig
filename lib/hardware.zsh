#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Hardware related functions (CPU, memory, disk, GPU, battery)
# Depends on: system.zsh (is_macos, is_linux)
# Memory and disk functions return RAW integers (bytes) without formatting;
# use format_bytes (math.zsh) for human readable output.
##

## Internal helpers

# Read one value (in kB) from /proc/meminfo (internal)
# Usage: _meminfo_kb <key>   e.g. _meminfo_kb MemTotal
# Output: none; sets REPLY to the value in kB
# Returns: 0 success, 1 key or file not found
_meminfo_kb() {
    REPLY=""
    [[ -r /proc/meminfo ]] || return 1
    local -a lines=("${(@f)$(</proc/meminfo)}")
    lines=(${(M)lines:#$1:*})
    local line=$lines[1]
    [[ -n $line ]] || return 1
    REPLY=${line//[^0-9]/}
}

# Read page counts from vm_stat on macOS (internal)
# Usage: _vm_stat_pages
# Output: none; sets reply to an assoc-style list (key value ...) and REPLY to the page size
# Returns: 0 success, 1 vm_stat not available
_vm_stat_pages() {
    reply=()
    REPLY=4096
    (( ${+commands[vm_stat]} )) || return 1
    local -a lines=("${(@f)$(command vm_stat 2>/dev/null)}")
    local line key
    # First line: "Mach Virtual Memory Statistics: (page size of 16384 bytes)"
    [[ ${lines[1]} =~ 'page size of ([0-9]+)' ]] && REPLY=$match[1]
    for line in ${lines[2,-1]}; do
        key=${line%%:*}
        reply+=("$key" "${${line#*:}//[^0-9]/}")
    done
}

# Run df for a path and split the last line into fields (internal)
# Uses -P (POSIX output), so each file system is on one line and columns are:
# filesystem, 1024-blocks, used, available, capacity, mount point.
# The capacity column ("42%") is located first and the three numbers before it
# are used, so spaces in the file system name or in the mount point
# (e.g. "/Volumes/My Disk") do not shift the columns.
# Usage: _df_fields <path>
# Output: none; sets reply=(total used available) in bytes
# Returns: 0 success, 1 failure
_df_fields() {
    reply=()
    local output
    output=$(command df -kP -- "$1" 2>/dev/null) || return 1
    local -a lines=("${(@f)output}")
    local -a parts=(${=lines[-1]})
    # (I): index of the last word matching <->% (search from the end)
    local -i cap=${parts[(I)<->%]}
    (( cap >= 5 )) || return 1
    local total=${parts[cap-3]} used=${parts[cap-2]} avail=${parts[cap-1]}
    [[ $total == <-> && $used == <-> && $avail == <-> ]] || return 1
    reply=($(( total * 1024 )) $(( used * 1024 )) $(( avail * 1024 )))
}

## CPU

# Get system architecture (normalized)
# Usage: get_cpu_arch
# Output: "arm64", "x64", "x86" or raw machine name (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
get_cpu_arch() {
    (( ARGC == 0 )) || return 2
    local arch=${CPUTYPE:-$(uname -m)}
    case $arch in
        x86_64|amd64)  REPLY=x64 ;;
        arm64|aarch64) REPLY=arm64 ;;
        i386|i686)     REPLY=x86 ;;
        *)             REPLY=$arch ;;
    esac
    print -r -- "$REPLY"
}

# Get CPU model name
# On ARM Linux /proc/cpuinfo has no "model name", so "Model" or
# the device-tree model (e.g. Raspberry Pi) is used instead.
# Usage: get_cpu_model
# Output: e.g. "Apple M1 Pro", "Intel(R) Core(TM) i7-..." (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
get_cpu_model() {
    (( ARGC == 0 )) || return 2
    REPLY=""
    if is_macos; then
        REPLY=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
    elif [[ -r /proc/cpuinfo ]]; then
        local -a lines=("${(@f)$(</proc/cpuinfo)}")
        local line=${${(M)lines:#model name*:*}[1]}
        [[ -z $line ]] && line=${${(M)lines:#Model*:*}[1]}
        [[ -z $line ]] && line=${${(M)lines:#Hardware*:*}[1]}
        [[ -n $line ]] && REPLY=${${line#*:}## }
        if [[ -z $REPLY && -r /proc/device-tree/model ]]; then
            REPLY=${"$(</proc/device-tree/model)"//$'\0'/}
        fi
    fi
    [[ -n $REPLY ]] || return 1
    print -r -- "$REPLY"
}

# Get number of logical CPU cores
# Usage: get_cpu_count
# Output: integer, e.g. 8 (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
get_cpu_count() {
    (( ARGC == 0 )) || return 2
    REPLY=""
    if is_macos; then
        REPLY=$(sysctl -n hw.ncpu 2>/dev/null)
    elif (( ${+commands[nproc]} )); then
        REPLY=$(nproc 2>/dev/null)
    elif [[ -r /proc/cpuinfo ]]; then
        local -a lines=("${(@f)$(</proc/cpuinfo)}")
        lines=(${(M)lines:#processor*})
        REPLY=${#lines}
    fi
    [[ $REPLY == <1-> ]] || { REPLY=""; return 1 }
    print -r -- "$REPLY"
}

# Check if running on Apple Silicon (also true under Rosetta 2)
# Usage: is_apple_silicon
# Returns: 0 true, 1 false, 2 invalid usage
is_apple_silicon() {
    (( ARGC == 0 )) || return 2
    is_macos || return 1
    [[ $(sysctl -n hw.optional.arm64 2>/dev/null) == 1 ]]
}

# Get GPU model name
# macOS: system_profiler (slow, about 0.5 s); Linux: lspci
# Usage: get_gpu_model
# Output: GPU name(s), one per line (stdout); also sets REPLY (first GPU) and reply (all)
# Returns: 0 success, 1 unknown, 2 invalid usage
get_gpu_model() {
    (( ARGC == 0 )) || return 2
    reply=()
    local line
    if is_macos; then
        for line in "${(@f)$(system_profiler SPDisplaysDataType 2>/dev/null)}"; do
            [[ $line == *"Chipset Model:"* ]] && reply+=("${${line#*: }## }")
        done
    elif (( ${+commands[lspci]} )); then
        for line in "${(@f)$(command lspci 2>/dev/null)}"; do
            [[ $line == *(VGA|3D|Display)* ]] && reply+=("${line#*: }")
        done
    fi
    (( ${#reply} )) || { REPLY=""; return 1 }
    REPLY=${reply[1]}
    print -rl -- $reply
}

## Memory (raw bytes)

# Get total RAM in bytes
# Usage: get_ram_total
# Output: integer, e.g. 17179869184 (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
get_ram_total() {
    (( ARGC == 0 )) || return 2
    if is_macos; then
        REPLY=$(sysctl -n hw.memsize 2>/dev/null)
    else
        _meminfo_kb MemTotal && REPLY=$(( REPLY * 1024 ))
    fi
    [[ $REPLY == <-> ]] || { REPLY=""; return 1 }
    print -r -- "$REPLY"
}

# Get used RAM in bytes (approximation)
# macOS: active + wired + compressed pages (close to Activity Monitor "Memory Used")
# Linux: MemTotal - MemAvailable
# Usage: get_ram_used
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
get_ram_used() {
    (( ARGC == 0 )) || return 2
    if is_macos; then
        _vm_stat_pages || return 1
        local -A pages=("${(@)reply}")
        local -i page_size=$REPLY
        REPLY=$(( ( ${pages[Pages active]:-0} + ${pages[Pages wired down]:-0} \
                  + ${pages[Pages occupied by compressor]:-0} ) * page_size ))
    else
        _meminfo_kb MemTotal || return 1
        local -i total=$REPLY
        _meminfo_kb MemAvailable || return 1
        REPLY=$(( ( total - REPLY ) * 1024 ))
    fi
    print -r -- "$REPLY"
}

# Get available (free) RAM in bytes
# macOS: free + inactive + speculative pages; Linux: MemAvailable
# Usage: get_ram_free
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
get_ram_free() {
    (( ARGC == 0 )) || return 2
    if is_macos; then
        _vm_stat_pages || return 1
        local -A pages=("${(@)reply}")
        local -i page_size=$REPLY
        REPLY=$(( ( ${pages[Pages free]:-0} + ${pages[Pages inactive]:-0} \
                  + ${pages[Pages speculative]:-0} ) * page_size ))
    else
        _meminfo_kb MemAvailable || return 1
        REPLY=$(( REPLY * 1024 ))
    fi
    print -r -- "$REPLY"
}

# Get total swap in bytes
# Usage: get_swap_total
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
get_swap_total() {
    (( ARGC == 0 )) || return 2
    if is_macos; then
        _swap_macos || return 1
        REPLY=${reply[1]}
    else
        _meminfo_kb SwapTotal || return 1
        REPLY=$(( REPLY * 1024 ))
    fi
    print -r -- "$REPLY"
}

# Get used swap in bytes
# Usage: get_swap_used
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
get_swap_used() {
    (( ARGC == 0 )) || return 2
    if is_macos; then
        _swap_macos || return 1
        REPLY=${reply[2]}
    else
        _meminfo_kb SwapTotal || return 1
        local -i total=$REPLY
        _meminfo_kb SwapFree || return 1
        REPLY=$(( ( total - REPLY ) * 1024 ))
    fi
    print -r -- "$REPLY"
}

# Read swap usage on macOS (internal)
# sysctl vm.swapusage: "total = 2048.00M  used = 1024.50M  free = 1023.50M  (encrypted)"
# Usage: _swap_macos
# Output: none; sets reply=(total used) in bytes
# Returns: 0 success, 1 failure
_swap_macos() {
    reply=()
    local raw
    raw=$(sysctl -n vm.swapusage 2>/dev/null) || return 1
    [[ $raw =~ 'total = ([0-9.]+)M.*used = ([0-9.]+)M' ]] || return 1
    reply=($(( int(match[1] * 1048576) )) $(( int(match[2] * 1048576) )))
}

## Disk (raw bytes)

# Get total size of the file system containing a path
# Usage: get_disk_total [path]   (default: current directory)
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 1 failure, 2 invalid usage
get_disk_total() {
    (( ARGC <= 1 )) || return 2
    _df_fields "${1:-.}" || return 1
    REPLY=${reply[1]}
    print -r -- "$REPLY"
}

# Get used space on the file system containing a path
# Usage: get_disk_used [path]   (default: current directory)
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 1 failure, 2 invalid usage
get_disk_used() {
    (( ARGC <= 1 )) || return 2
    _df_fields "${1:-.}" || return 1
    REPLY=${reply[2]}
    print -r -- "$REPLY"
}

# Get available space on the file system containing a path
# Usage: get_disk_free [path]   (default: current directory)
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 1 failure, 2 invalid usage
get_disk_free() {
    (( ARGC <= 1 )) || return 2
    _df_fields "${1:-.}" || return 1
    REPLY=${reply[3]}
    print -r -- "$REPLY"
}

## Battery

# Get battery charge level in percent
# macOS: pmset; Linux: /sys/class/power_supply/BAT*/capacity
# Usage: get_battery_level
# Output: integer 0-100 (stdout); also sets REPLY
# Returns: 0 success, 1 no battery, 2 invalid usage
get_battery_level() {
    (( ARGC == 0 )) || return 2
    REPLY=""
    if is_macos; then
        local raw
        raw=$(pmset -g batt 2>/dev/null)
        [[ $raw =~ '([0-9]+)%' ]] && REPLY=$match[1]
    else
        local -a bats=(/sys/class/power_supply/BAT*/capacity(N))
        (( ${#bats} )) && REPLY=$(<$bats[1])
    fi
    [[ $REPLY == <-> ]] || { REPLY=""; return 1 }
    print -r -- "$REPLY"
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
