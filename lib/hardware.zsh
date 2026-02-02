#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Hardware related functions
# Depends on: system.zsh (for is_macos/is_linux)
# Note: These functions return RAW integers (bytes) without formatting.

# --- CPU Information ---

# Get system architecture (Normalized)
# Usage: get_cpu_arch
# Returns: "arm64", "x64", "x86"
# Returns error code 2 on invalid usage
get_cpu_arch() {
    (( ARGC == 0 )) || return 2
    local arch=${CPUTYPE:-$(uname -m)}
    case $arch in
        x86_64|amd64) print "x64" ;;
        arm64|aarch64) print "arm64" ;;
        i386|i686)    print "x86" ;;
        *)            print $arch ;;
    esac
}

# Get CPU Model Name
# Usage: get_cpu_model
# Returns: "Apple M1 Pro", "Intel(R) Core(TM) i7...", etc.
# Returns error code 2 on invalid usage
get_cpu_model() {
    (( ARGC == 0 )) || return 2
    if is_macos; then
        sysctl -n machdep.cpu.brand_string
    elif is_linux; then
        local model
        if [[ -r /proc/cpuinfo ]]; then
             # -m 1: Stop after first match
             if (( ${+commands[grep]} )); then
                model=$(grep -m1 "model name" /proc/cpuinfo)
                print -- ${model#*: }
             fi
        else
            print "Unknown CPU"
        fi
    fi
}

# Get Number of CPU Cores
# Usage: get_cpu_count
# Returns: integer (e.g. 8)
# Returns error code 2 on invalid usage
get_cpu_count() {
    (( ARGC == 0 )) || return 2
    if is_macos; then
        sysctl -n hw.ncpu
    elif is_linux; then
        if (( ${+commands[nproc]} )); then
            nproc
        elif (( ${+commands[grep]} )); then
            grep -c ^processor /proc/cpuinfo
        fi
    fi
}

# --- Memory Information (Raw Bytes) ---

# Get Total RAM in Bytes
# Usage: get_ram_total
# Returns: integer (e.g. 17179869184)
# Returns error code 2 on invalid usage
get_ram_total() {
    (( ARGC == 0 )) || return 2
    local total_bytes=0
    
    if is_macos; then
        total_bytes=$(sysctl -n hw.memsize)
    elif [[ -r /proc/meminfo ]]; then
        local line=${${(M)${(f)"$(</proc/meminfo)"}:#MemTotal*}#MemTotal:}
        local kb=${line//[^0-9]/}
        total_bytes=$(( kb * 1024 ))
    fi

    print -- $total_bytes
}

# Get Used RAM in Bytes (Approximation)
# Usage: get_ram_used
# Returns: integer
# Returns error code 2 on invalid usage
get_ram_used() {
    (( ARGC == 0 )) || return 2
    local used_bytes=0

    if is_macos; then
        local vm_stat=$(vm_stat)
        local page_size=4096
        local sys_page=$(sysctl -n hw.pagesize 2>/dev/null)
        [[ -n "$sys_page" ]] && page_size=$sys_page
        
        local active=${${(M)${(f)vm_stat}:#Pages active:*}#Pages active:}
        local wired=${${(M)${(f)vm_stat}:#Pages wired down:*}#Pages wired down:}
        
        used_bytes=$(( ( ${active//[^0-9]/} + ${wired//[^0-9]/} ) * page_size ))
        
    elif [[ -r /proc/meminfo ]]; then
        local content="$(</proc/meminfo)"
        local total=${${(M)${(f)content}:#MemTotal*}#MemTotal:}
        local avail=${${(M)${(f)content}:#MemAvailable*}#MemAvailable:}
        
        used_bytes=$(( ( ${total//[^0-9]/} - ${avail//[^0-9]/} ) * 1024 ))
    fi

    print -- $used_bytes
}

# Get Available/Free RAM in Bytes
# Usage: get_ram_free
# Returns: integer
# Returns error code 2 on invalid usage
get_ram_free() {
    (( ARGC == 0 )) || return 2
    local free_bytes=0

    if is_macos; then
        local vm_stat=$(vm_stat)
        local page_size=4096
        local sys_page=$(sysctl -n hw.pagesize 2>/dev/null)
        [[ -n "$sys_page" ]] && page_size=$sys_page
        
        local free=${${(M)${(f)vm_stat}:#Pages free:*}#Pages free:}
        local inactive=${${(M)${(f)vm_stat}:#Pages inactive:*}#Pages inactive:}
        local spec=${${(M)${(f)vm_stat}:#Pages speculative:*}#Pages speculative:}
        [[ -z "$spec" ]] && spec=0
        
        free_bytes=$(( ( ${free//[^0-9]/} + ${inactive//[^0-9]/} + ${spec//[^0-9]/} ) * page_size ))

    elif [[ -r /proc/meminfo ]]; then
        local line=${${(M)${(f)"$(</proc/meminfo)"}:#MemAvailable*}#MemAvailable:}
        free_bytes=$(( ${line//[^0-9]/} * 1024 ))
    fi

    print -- $free_bytes
}

# --- Disk Information (Raw Bytes) ---

# Get Total Disk Size
# Usage: get_disk_total [/path/to/mount]
# Returns: integer
# Returns error code 2 on invalid usage
get_disk_total() {
    (( ARGC <= 1 )) || return 2
    local target_path="${1:-.}"

    local output
    output=$(command df -kP "$target_path" 2>/dev/null)
    [[ -z "$output" ]] && return 1

    local last_line="${${(@f)output}[-1]}"
    local -a parts=(${=last_line})
    
    # Column 2 is Total 1024-blocks
    print -- $(( parts[2] * 1024 ))
}

# Get Used Disk Space
# Usage: get_disk_used [/path/to/mount]
# Returns: integer
# Returns error code 2 on invalid usage
get_disk_used() {
    (( ARGC <= 1 )) || return 2
    local target_path="${1:-.}"

    local output
    output=$(command df -kP "$target_path" 2>/dev/null)
    [[ -z "$output" ]] && return 1

    local last_line="${${(@f)output}[-1]}"
    local -a parts=(${=last_line})
    
    # Column 3 is Used
    print -- $(( parts[3] * 1024 ))
}

# Get Free/Available Disk Space
# Usage: get_disk_free [/path/to/mount]
# Returns: integer
# Returns error code 2 on invalid usage
get_disk_free() {
    (( ARGC <= 1 )) || return 2
    local target_path="${1:-.}"

    local output
    output=$(command df -kP "$target_path" 2>/dev/null)
    [[ -z "$output" ]] && return 1

    local last_line="${${(@f)output}[-1]}"
    local -a parts=(${=last_line})
    
    # Column 4 is Available
    print -- $(( parts[4] * 1024 ))
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}