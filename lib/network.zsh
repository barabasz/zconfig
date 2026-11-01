#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Network functions: connectivity checks, interface and address info,
# validation and small utilities (url_encode/url_decode live in strings.zsh)
# Depends on: system.zsh (is_macos, is_linux), print.zsh (output),
#             fn.zsh (_FN_TYPES regex patterns, single source for validation),
#             zsh/net/tcp (ztcp), zsh/zselect
# TCP checks use a timeout (default ZSH_NET_TIMEOUT=2 seconds), because ztcp
# itself has none and may hang on filtered ports.
##

# Default timeout in seconds for TCP checks
: ${ZSH_NET_TIMEOUT:=2}

## Internal helpers

# Try a TCP connection with a timeout (internal)
# ztcp runs in a background subshell; the parent polls it with zselect.
# Usage: _tcp_probe <host> <port> [timeout_seconds]
# Returns: 0 connected, 1 refused or timed out
_tcp_probe() {
    setopt localoptions nomonitor nonotify
    local host=$1 port=$2
    local -i timeout_cs=$(( ${3:-$ZSH_NET_TIMEOUT} * 100 )) waited=0
    ( ztcp "$host" "$port" 2>/dev/null && ztcp -c $REPLY ) &
    local -i pid=$!
    while (( waited < timeout_cs )); do
        if ! kill -0 $pid 2>/dev/null; then
            wait $pid
            return
        fi
        zselect -t 5
        (( waited += 5 ))
    done
    kill $pid 2>/dev/null
    wait $pid 2>/dev/null
    return 1
}

## Connectivity checks

# Check if network is connected (a default route exists)
# Usage: is_connected
# Returns: 0 true, 1 false, 2 invalid usage
is_connected() {
    (( ARGC == 0 )) || return 2
    get_active_interface >/dev/null
}

# Check if internet is reachable (TCP check to Cloudflare DNS 1.1.1.1:53)
# Usage: is_online [timeout_seconds]
# Returns: 0 true, 1 false, 2 invalid usage
is_online() {
    (( ARGC <= 1 )) || return 2
    [[ -z $1 || $1 == <1-> ]] || return 2
    _tcp_probe 1.1.1.1 53 $1
}

# Check if a TCP port is open
# Usage: is_port_open <host> <port> [timeout_seconds]
# Example: is_port_open localhost 80
# Returns: 0 open, 1 closed or timed out, 2 invalid usage
is_port_open() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2
    [[ $2 == <1-65535> && ( -z $3 || $3 == <1-> ) ]] || return 2
    _tcp_probe "$1" "$2" $3
}

# Wait until a TCP port becomes open
# Usage: wait_for_port <host> <port> [timeout_seconds]   (default: 30)
# Example: wait_for_port localhost 5432 60 && psql ...
# Returns: 0 port open, 1 timed out, 2 invalid usage
wait_for_port() {
    (( ARGC >= 2 && ARGC <= 3 )) || { _lib_usage "wait_for_port <host> <port> [timeout]"; return }
    [[ $2 == <1-65535> && ( -z $3 || $3 == <1-> ) ]] || return 2
    local -i deadline=$(( EPOCHSECONDS + ${3:-30} ))
    while (( EPOCHSECONDS < deadline )); do
        _tcp_probe "$1" "$2" 1 && return 0
        zselect -t 50
    done
    return 1
}

## Host and interface info

# Get hostname (short)
# Usage: get_hostname
# Output: e.g. "macbook" (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
get_hostname() {
    (( ARGC == 0 )) || return 2
    REPLY=${HOST%%.*}
    print -r -- "$REPLY"
}

# Get fully qualified domain name
# Usage: get_fqdn
# Output: e.g. "macbook.local" or "server.example.com" (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
get_fqdn() {
    (( ARGC == 0 )) || return 2
    # macOS/BSD hostname -f may fail; fall back to $HOST
    REPLY=$(command hostname -f 2>/dev/null)
    [[ -n $REPLY ]] || REPLY=$HOST
    print -r -- "$REPLY"
}

# Get active (default route) network interface
# Usage: get_active_interface
# Output: e.g. "en0" or "eth0" (stdout); also sets REPLY
# Returns: 0 success, 1 no default route, 2 invalid usage
get_active_interface() {
    (( ARGC == 0 )) || return 2
    REPLY=""
    if is_macos; then
        local route_info
        route_info=$(command route -n get default 2>/dev/null)
        [[ $route_info =~ 'interface: ([^[:space:]]+)' ]] && REPLY=$match[1]
    elif (( ${+commands[ip]} )); then
        # "default via X dev Y ..." -> word after "dev"
        local -a parts=($(command ip -4 route show default 2>/dev/null))
        local -i idx=${parts[(i)dev]}
        (( idx < ${#parts} )) && REPLY=$parts[idx+1]
    elif [[ -r /proc/net/route ]]; then
        # Destination 00000000 marks the default route
        local line
        for line in "${(@f)$(</proc/net/route)}"; do
            [[ ${line[(w)2]} == 00000000 ]] && { REPLY=${line[(w)1]}; break }
        done
    fi
    [[ -n $REPLY ]] || return 1
    print -r -- "$REPLY"
}

# Get list of network interfaces
# Usage: get_interfaces
# Output: interface names, one per line (stdout); also sets reply
# Returns: 0 success, 2 invalid usage
get_interfaces() {
    (( ARGC == 0 )) || return 2
    if [[ -d /sys/class/net ]]; then
        reply=(/sys/class/net/*(N:t))
    else
        reply=(${(s: :)"$(command ifconfig -l 2>/dev/null)"})
    fi
    print -rl -- $reply
}

# Get MAC address of an interface
# Usage: get_mac_address <interface>
# Output: e.g. "aa:bb:cc:dd:ee:ff" (stdout); also sets REPLY
# Returns: 0 success, 1 unknown interface, 2 invalid usage
get_mac_address() {
    (( ARGC == 1 )) || return 2
    REPLY=""
    if [[ -r /sys/class/net/$1/address ]]; then
        # Linux: read sysfs directly (no fork)
        REPLY=$(</sys/class/net/$1/address)
    elif is_macos; then
        local -a words=(${=$(command ifconfig "$1" 2>/dev/null)})
        local -i idx=${words[(i)ether]}
        (( idx < ${#words} )) && REPLY=$words[idx+1]
    fi
    [[ -n $REPLY ]] || return 1
    print -r -- "$REPLY"
}

# Get local IPv4 address (LAN)
# Usage: get_local_ip [interface]
# Output: IP address (stdout); also sets REPLY
# Returns: 0 success, 1 not found, 2 invalid usage
get_local_ip() {
    (( ARGC <= 1 )) || return 2
    local iface=$1
    REPLY=""
    if is_macos; then
        [[ -n $iface ]] || iface=$(get_active_interface) || iface=en0
        REPLY=$(command ipconfig getifaddr "$iface" 2>/dev/null)
    elif [[ -z $iface ]] && (( ${+commands[hostname]} )); then
        # hostname -I lists all addresses; take the first one
        local ips=$(command hostname -I 2>/dev/null)
        REPLY=${ips%% *}
    fi
    if [[ -z $REPLY ]] && (( ${+commands[ip]} )); then
        [[ -n $iface ]] || iface=$(get_active_interface)
        local -a parts=($(command ip -4 -o addr show ${iface:+dev "$iface"} scope global 2>/dev/null))
        local -i idx=${parts[(i)inet]}
        (( idx < ${#parts} )) && REPLY=${parts[idx+1]%%/*}
    fi
    [[ -n $REPLY ]] || return 1
    print -r -- "$REPLY"
}

# Get local global-scope IPv6 address
# Usage: get_local_ip6 [interface]
# Output: IPv6 address (stdout); also sets REPLY
# Returns: 0 success, 1 not found, 2 invalid usage
get_local_ip6() {
    (( ARGC <= 1 )) || return 2
    local iface=$1
    REPLY=""
    if is_macos; then
        [[ -n $iface ]] || iface=$(get_active_interface) || iface=en0
        local line
        for line in "${(@f)$(command ifconfig "$iface" 2>/dev/null)}"; do
            # Skip link-local (fe80::) and temporary addresses
            if [[ $line == *inet6* && $line != *fe80:* && $line != *temporary* ]]; then
                REPLY=${line[(w)2]}
                break
            fi
        done
    elif (( ${+commands[ip]} )); then
        local -a parts=($(command ip -6 -o addr show ${iface:+dev "$iface"} scope global 2>/dev/null))
        local -i idx=${parts[(i)inet6]}
        (( idx < ${#parts} )) && REPLY=${parts[idx+1]%%/*}
    fi
    [[ -n $REPLY ]] || return 1
    print -r -- "$REPLY"
}

# Get public IPv4 address (WAN)
# DNS (dig) first for speed, then HTTP services as fallback
# Usage: get_public_ip
# Output: IP address (stdout); also sets REPLY
# Returns: 0 success, 1 failure, 2 invalid usage
get_public_ip() {
    (( ARGC == 0 )) || return 2
    REPLY=""
    if (( ${+commands[dig]} )); then
        REPLY=$(command dig +short +time=2 +tries=1 -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null)
        [[ -z $REPLY ]] && REPLY=$(command dig +short +time=2 +tries=1 -4 TXT o-o.myaddr.l.google.com @ns1.google.com 2>/dev/null)
        REPLY=${REPLY//\"/}
    fi
    if [[ -z $REPLY ]]; then
        if (( ${+commands[curl]} )); then
            REPLY=$(command curl -4 -fsS -m 2 https://api.ipify.org 2>/dev/null) ||
                REPLY=$(command curl -4 -fsS -m 2 https://ifconfig.me/ip 2>/dev/null)
        elif (( ${+commands[wget]} )); then
            REPLY=$(command wget -qO- --timeout=2 https://api.ipify.org 2>/dev/null)
        fi
    fi
    is_valid_ip "$REPLY" || { REPLY=""; return 1 }
    print -r -- "$REPLY"
}

# Get default gateway IP
# Usage: get_gateway
# Output: gateway IP (stdout); also sets REPLY
# Returns: 0 success, 1 no default route, 2 invalid usage
get_gateway() {
    (( ARGC == 0 )) || return 2
    REPLY=""
    if is_macos; then
        local out
        out=$(command route -n get default 2>/dev/null)
        [[ $out =~ 'gateway: ([^[:space:]]+)' ]] && REPLY=$match[1]
    elif (( ${+commands[ip]} )); then
        local -a parts=($(command ip -4 route show default 2>/dev/null))
        local -i idx=${parts[(i)via]}
        (( idx < ${#parts} )) && REPLY=$parts[idx+1]
    elif [[ -r /proc/net/route ]]; then
        # Gateway is a little-endian hex number, e.g. 0101A8C0 = 192.168.1.1
        local line hex
        for line in "${(@f)$(</proc/net/route)}"; do
            [[ ${line[(w)2]} == 00000000 ]] || continue
            hex=${line[(w)3]}
            (( 16#$hex )) && REPLY="$(( 16#${hex[7,8]} )).$(( 16#${hex[5,6]} )).$(( 16#${hex[3,4]} )).$(( 16#${hex[1,2]} ))"
            break
        done
    fi
    [[ -n $REPLY ]] || return 1
    print -r -- "$REPLY"
}

# Get DNS servers
# With systemd-resolved, /etc/resolv.conf points to the 127.0.0.53 stub,
# so resolvectl is asked for the real upstream servers.
# Usage: get_dns_servers
# Output: DNS server IPs, one per line (stdout); also sets reply
# Returns: 0 success, 1 none found, 2 invalid usage
get_dns_servers() {
    (( ARGC == 0 )) || return 2
    reply=()
    local line key value
    if is_macos; then
        for line in "${(@f)$(command scutil --dns 2>/dev/null)}"; do
            [[ $line == *nameserver\[* ]] && reply+=("${line##* : }")
        done
    else
        if [[ -r /etc/resolv.conf ]]; then
            while read -r key value; do
                [[ $key == nameserver ]] && reply+=("$value")
            done < /etc/resolv.conf
        fi
        if [[ ${reply[*]} == 127.0.0.53 ]] && (( ${+commands[resolvectl]} )); then
            reply=()
            for line in "${(@f)$(command resolvectl dns 2>/dev/null)}"; do
                # "Global: 1.1.1.1" or "Link 2 (eth0): 192.168.1.1 1.1.1.1"
                [[ $line == *": "* ]] && reply+=(${=line#*: })
            done
        fi
    fi
    reply=(${(u)reply})
    (( ${#reply} )) || return 1
    print -rl -- $reply
}

# Get current Wi-Fi SSID
# Usage: get_wifi_ssid [interface]
# Output: SSID (stdout); also sets REPLY
# Returns: 0 success, 1 not available, 2 invalid usage
get_wifi_ssid() {
    (( ARGC <= 1 )) || return 2
    local iface=$1
    REPLY=""
    if is_macos; then
        [[ -n $iface ]] || iface=$(get_active_interface) || iface=en0
        local line
        for line in "${(@f)$(command ipconfig getsummary "$iface" 2>/dev/null)}"; do
            [[ $line == *" SSID : "* ]] && { REPLY=${line#* : }; break }
        done
        if [[ -z $REPLY || $REPLY == *[Rr]edacted* ]]; then
            REPLY=""
            printe "Could not retrieve SSID (result empty or redacted)."
            printi "Try running: sudo ipconfig sethidewifiinfo 0"
            return 1
        fi
    elif (( ${+commands[iwgetid]} )); then
        REPLY=$(command iwgetid -r 2>/dev/null)
    elif (( ${+commands[nmcli]} )); then
        local line
        for line in "${(@f)$(command nmcli -t -f active,ssid dev wifi 2>/dev/null)}"; do
            [[ $line == yes:* ]] && { REPLY=${line#yes:}; break }
        done
    fi
    [[ -n $REPLY ]] || return 1
    print -r -- "$REPLY"
}

# List TCP ports listening on this system
# Runs without sudo, so process names of other users' sockets may be missing.
# Usage: get_open_ports
# Output: "PORT: COMMAND (PID)" lines, sorted by port (stdout); also sets reply
# Returns: 0 success, 1 no tool available, 2 invalid usage
get_open_ports() {
    (( ARGC == 0 )) || return 2
    reply=()
    local line addr port proc pid
    local -a fields
    if (( ${+commands[ss]} )); then
        # ss -ltnpH: State Recv-Q Send-Q Local:Port Peer:Port Process
        for line in "${(@f)$(command ss -ltnpH 2>/dev/null)}"; do
            fields=(${=line})
            addr=${fields[4]}
            port=${addr##*:}          # works for [::1]:8080 and 0.0.0.0:22
            proc="?" pid="?"
            [[ $line =~ 'users:\(\("([^"]+)",pid=([0-9]+)' ]] && { proc=$match[1]; pid=$match[2] }
            reply+=("$port: $proc ($pid)")
        done
    elif (( ${+commands[lsof]} )); then
        # lsof: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME (LISTEN)
        local -a lines=("${(@f)$(command lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null)}")
        for line in "${(@)lines[2,-1]}"; do
            fields=(${=line})
            addr=${fields[-2]}
            reply+=("${addr##*:}: ${fields[1]} (${fields[2]})")
        done
    else
        return 1
    fi
    # (n) numeric sort, (u) unique
    reply=(${(nu)reply})
    print -rl -- $reply
}

## Validation

# Check if string is a valid IPv4 address
# Usage: is_valid_ip <string>
# Returns: 0 valid, 1 invalid, 2 invalid usage
is_valid_ip() {
    (( ARGC == 1 )) || return 2
    [[ $1 =~ ${_FN_TYPES[ipv4]} ]]
}

# Check if string is a valid IPv6 address
# Usage: is_valid_ipv6 <string>
# Returns: 0 valid, 1 invalid, 2 invalid usage
is_valid_ipv6() {
    (( ARGC == 1 )) || return 2
    [[ $1 =~ ${_FN_TYPES[ipv6]} ]]
}

# Check if string is a valid domain name
# Usage: is_valid_domain <string>
# Returns: 0 valid, 1 invalid, 2 invalid usage
is_valid_domain() {
    (( ARGC == 1 )) || return 2
    [[ $1 =~ ${_FN_TYPES[domain]} ]]
}
# Alias: is_domain_valid (old name)
functions[is_domain_valid]=$functions[is_valid_domain]

# Check if string is a valid URL (http, https, ftp, ftps)
# Usage: is_valid_url <string>
# Example: is_valid_url "https://example.com:8080/path"
# Returns: 0 valid, 1 invalid, 2 invalid usage
is_valid_url() {
    (( ARGC == 1 )) || return 2
    local scheme='(https?|ftps?)'
    local host='[-a-zA-Z0-9@:%._+~#=]+'
    local port='(:[0-9]+)?'
    local resource='([/?#][-a-zA-Z0-9@:%_+.~#?&/=]*)?'
    [[ $1 =~ ^$scheme://$host$port$resource$ ]]
}
# Alias: is_url_valid (old name)
functions[is_url_valid]=$functions[is_valid_url]

## Utilities

# Get HTTP status code of a URL (GET request, follows redirects)
# Usage: http_status <url> [timeout_seconds]   (default: 10)
# Output: status code, e.g. 200 (stdout); also sets REPLY
# Returns: 0 success, 1 request failed, 2 invalid usage, 127 curl not found
http_status() {
    (( ARGC >= 1 && ARGC <= 2 )) || return 2
    (( ${+commands[curl]} )) || return 127
    REPLY=$(command curl -sL -o /dev/null -m ${2:-10} -w '%{http_code}' -- "$1" 2>/dev/null)
    [[ $REPLY == <1-> ]] || { REPLY=""; return 1 }
    print -r -- "$REPLY"
}

# Download a file with a progress bar
# Usage: download <url> <output_file>
# Returns: 0 success, 1 failure, 2 invalid usage, 127 no download tool
download() {
    (( ARGC == 2 )) || { _lib_usage "download <url> <output_file>"; return }
    if (( ${+commands[curl]} )); then
        command curl -fL -# -o "$2" -- "$1"
    elif (( ${+commands[wget]} )); then
        command wget -q --show-progress -O "$2" -- "$1"
    else
        printe "No download tool found (curl or wget)."
        return 127
    fi
}

# Scan common TCP ports on a host (each probe uses ZSH_NET_TIMEOUT)
# Usage: scan_ports <host>
# Output: open ports (stdout)
# Returns: 0 at least one port open, 1 none open, 2 invalid usage
scan_ports() {
    (( ARGC == 1 )) || { _lib_usage "scan_ports <host>"; return }
    local host=$1 port
    local -i found=0
    local -a common_ports=(21 22 23 25 53 80 443 3000 3306 5432 8000 8080)
    printi "Scanning $host..."
    for port in $common_ports; do
        if _tcp_probe "$host" $port 1; then
            print -r -- "Port $port: ${g}OPEN${x}"
            (( found++ ))
        fi
    done
    (( found ))
}

# Flush the DNS cache (requires sudo)
# Usage: flush_dns
# Returns: 0 success, 1 failure, 2 invalid usage
flush_dns() {
    (( ARGC == 0 )) || return 2
    if is_macos; then
        sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder || {
            printe "Failed to flush macOS DNS cache."
            return 1
        }
        prints "macOS DNS cache flushed."
    elif (( ${+commands[resolvectl]} )); then
        sudo resolvectl flush-caches || return 1
        prints "systemd-resolved cache flushed."
    else
        printe "No known DNS flush method found for this system."
        return 1
    fi
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
