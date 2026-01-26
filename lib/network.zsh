#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Load Zsh TCP module for native port checking
zmodload zsh/net/tcp

# Check if network is connected (basic interface check)
# Usage: is_connected
# Returns: 0 (true) if connected, 1 (false) otherwise
is_connected() {
    if is_macos; then
        # macOS: Check strictly if we have an IP on primary interfaces
        local ip
        ip=$(ipconfig getifaddr en0 2>/dev/null) || ip=$(ipconfig getifaddr en1 2>/dev/null)
        [[ -n "$ip" ]]
    elif is_linux; then
        # Linux: Check if default route exists
        ip route show default &>/dev/null
    else
        return 1
    fi
}

# Check if internet is reachable (ping reliable DNS)
# Usage: is_online
# Returns: 0 (true) if online, 1 (false) otherwise
is_online() {
    # Try Cloudflare (1.1.1.1) then Google (8.8.8.8)
    # Ping options: -c 1 (count), -W 1 (wait 1s), -q (quiet)
    ping -c 1 -W 1 -q 1.1.1.1 &>/dev/null || \
    ping -c 1 -W 1 -q 8.8.8.8 &>/dev/null
}

# Get default gateway IP address
# Usage: get_gateway
# Returns: gateway IP address
get_gateway() {
    local gateway
    if is_macos; then
        # route -n get default returns a block, we parse "gateway: x.x.x.x"
        local out
        out=$(route -n get default 2>/dev/null)
        # Extract IP using Zsh pattern matching instead of awk
        # Remove everything before "gateway: ", then take the first word
        gateway=${${out##*gateway: }%% *}
    elif is_linux; then
        # ip route show default -> "default via 192.168.1.1 dev eth0 ..."
        local out
        out=$(ip route show default 2>/dev/null)
        gateway=${${out##*via }%% *}
    fi

    if [[ -n "$gateway" ]]; then
        print -- "$gateway"
        return 0
    fi
    return 1
}

# Get local IP address (LAN)
# Usage: get_local_ip
# Returns: local IP address
get_local_ip() {
    local ip
    if is_macos; then
        ip=$(ipconfig getifaddr en0 2>/dev/null)
        [[ -z "$ip" ]] && ip=$(ipconfig getifaddr en1 2>/dev/null)
    elif is_linux; then
        # hostname -I is the most standard Linux way, fallback to ip command
        if is_installed hostname; then
             ip=$(hostname -I 2>/dev/null | cut -d' ' -f1)
        fi
        if [[ -z "$ip" ]]; then
            # Get IP from the interface with default route
            local iface
            local out
            out=$(ip route show default 2>/dev/null)
            iface=${${out##*dev }%% *}
            
            if [[ -n "$iface" ]]; then
                # Parse "inet 192.168.1.10/24"
                local addr_info
                addr_info=$(ip -4 addr show $iface 2>/dev/null)
                ip=${${${addr_info##*inet }%%/*}##* }
            fi
        fi
    fi

    if [[ -n "$ip" ]]; then
        print -- "$ip"
        return 0
    fi
    return 1
}

# Get public/WAN IP address
# Usage: get_public_ip
# Returns: public IP address
get_public_ip() {
    local ip
    # Define providers to rotate
    local urls=(
        "https://api.ipify.org"
        "https://ifconfig.me"
        "https://icanhazip.com"
    )

    if is_installed curl; then
        for url in $urls; do
            ip=$(curl -s --max-time 2 "$url" 2>/dev/null)
            if [[ -n "$ip" ]]; then
                print -- "$ip"
                return 0
            fi
        done
    elif is_installed wget; then
        for url in $urls; do
            ip=$(wget -qO- --timeout=2 "$url" 2>/dev/null)
            if [[ -n "$ip" ]]; then
                print -- "$ip"
                return 0
            fi
        done
    fi
    return 1
}

# Get network interface names
# Usage: get_interfaces
# Returns: list of network interfaces
get_interfaces() {
    if is_macos; then
        # Lists hardware ports (e.g., "Wi-Fi", "Thunderbolt Bridge")
        # networksetup is reliable on macOS
        networksetup -listallhardwareports 2>/dev/null | grep "Device:" | cut -d' ' -f2
    elif is_linux; then
        # /sys/class/net is the cleanest way on Linux (no parsing overhead)
        print -l /sys/class/net/*(:t)
    fi
}

# Get active network interface (primary)
# Usage: get_active_interface
# Returns: name of active network interface (e.g. en0, eth0)
get_active_interface() {
    if is_macos; then
        # Check en0 then en1
        if [[ -n $(ipconfig getifaddr en0 2>/dev/null) ]]; then
            print "en0"
        elif [[ -n $(ipconfig getifaddr en1 2>/dev/null) ]]; then
            print "en1"
        fi
    elif is_linux; then
        # Interface associated with default route
        local out
        out=$(ip route show default 2>/dev/null)
        print -- ${${out##*dev }%% *}
    fi
}

# Get MAC address of interface
# Usage: get_mac_address [interface]
# Returns: MAC address
get_mac_address() {
    local iface="${1:-$(get_active_interface)}"
    [[ -z "$iface" ]] && return 1

    local mac
    if is_macos; then
        local out=$(ifconfig "$iface" 2>/dev/null)
        # Extract after "ether "
        mac=${${out##*ether }%% *}
        # Clean up if extraction failed (e.g. got whole string)
        [[ "$mac" == "$out" ]] && mac=""
    elif is_linux; then
        # Read directly from sysfs - fastest method
        [[ -r "/sys/class/net/$iface/address" ]] && mac=$(<"/sys/class/net/$iface/address")
    fi

    if [[ -n "$mac" ]]; then
        print -- "$mac"
        return 0
    fi
    return 1
}

# Get DNS servers
# Usage: get_dns_servers
# Returns: list of DNS servers
get_dns_servers() {
    if is_macos; then
        scutil --dns 2>/dev/null | grep "nameserver\[[0-9]\]" | awk '{print $3}' | sort -u
    elif is_linux; then
        # resolvectl is modern systemd standard, fallback to resolv.conf
        if is_installed resolvectl; then
            resolvectl dns 2>/dev/null | awk '{print $2}'
        elif [[ -f /etc/resolv.conf ]]; then
            grep "^nameserver" /etc/resolv.conf | awk '{print $2}'
        fi
    fi
}

# Get WiFi SSID (macOS only)
# Usage: get_wifi_ssid
# Returns: WiFi network name
get_wifi_ssid() {
    is_macos || return 1
    
    # Fast CoreWLAN check via airport utility symlink usually found here
    local airport="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
    
    if [[ -x "$airport" ]]; then
        local ssid=$("$airport" -I | awk -F': ' '/ SSID/ {print $2}')
        [[ -n "$ssid" ]] && print -- "$ssid" && return 0
    fi
    
    # Fallback to networksetup
    local out=$(networksetup -getairportnetwork en0 2>/dev/null)
    local ssid=${out#*Current Wi-Fi Network: }
    
    if [[ -n "$ssid" && "$ssid" != "You are not associated with an AirPort network." ]]; then
        print -- "$ssid"
        return 0
    fi
    return 1
}

# Check if IP address is valid
# Usage: is_valid_ip "192.168.1.1"
# Returns: 0 (true) or 1 (false)
is_valid_ip() {
    (( ARGC == 1 )) || return 1
    local ip=$1

    # IPv4 validation
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        # Use Zsh parameter expansion flag (s:.:) to split string by dots
        local -a octets=(${(s:.:)ip})
        
        for octet in $octets; do
            (( octet >= 0 && octet <= 255 )) || return 1
        done
        return 0
    fi
    return 1
}

# Check if URL is valid
# Usage: is_url_valid "https://example.com/path?query=1"
# Returns: 0 (true) or 1 (false)
# Validates: scheme, host (domain or IP), optional port, path, query, fragment
is_url_valid() {
    (( ARGC == 1 )) || return 1
    local url=$1

    # URL regex pattern:
    # ^(https?|ftp)://                     - scheme (http, https, ftp)
    # ([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}  - domain
    # |((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}...        - or IPv4
    # (:[0-9]{1,5})?                       - optional port
    # (/[^\s]*)?$                          - optional path/query/fragment

    local domain_pattern='([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}'
    local ipv4_pattern='((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'
    local port_pattern='(:[0-9]{1,5})?'
    local path_pattern='(/[^[:space:]]*)?'

    local full_pattern="^(https?|ftp)://(${domain_pattern}|${ipv4_pattern}|localhost)${port_pattern}${path_pattern}$"

    [[ $url =~ $full_pattern ]]
}

# Check if email address is valid
# Usage: is_email_valid "user@example.com"
# Returns: 0 (true) or 1 (false)
# Validates: local part, @ symbol, domain with TLD
is_email_valid() {
    (( ARGC == 1 )) || return 1
    local email=$1

    # Email regex pattern (RFC 5321 simplified):
    # ^[a-zA-Z0-9._%+-]+     - local part (letters, digits, special chars)
    # @                       - at symbol
    # [a-zA-Z0-9.-]+         - domain (letters, digits, dots, hyphens)
    # \.[a-zA-Z]{2,}$        - TLD (dot + 2+ letters)

    local pattern='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

    [[ $email =~ $pattern ]]
}

# Check if domain name is valid
# Usage: is_domain_valid "example.com"
# Returns: 0 (true) or 1 (false)
is_domain_valid() {
    (( ARGC == 1 )) || return 1
    local domain=$1

    # Domain pattern:
    # - Labels separated by dots
    # - Each label: starts/ends with alphanumeric, can contain hyphens
    # - TLD: 2+ letters
    local pattern='^([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'

    [[ $domain =~ $pattern ]]
}

# Check if port is open
# Usage: is_port_open "localhost" 80
# Returns: 0 (true) if open, 1 (false) otherwise
is_port_open() {
    (( ARGC == 2 )) || return 1
    local host=$1
    local port=$2

    # Use native Zsh TCP module - much faster than spawning nc/telnet
    ztcp "$host" "$port" 2>/dev/null
    local fd=$REPLY
    
    if (( fd > 0 )); then
        ztcp -c $fd # Close the connection immediately
        return 0
    fi
    return 1
}

# Get hostname
# Usage: get_hostname
# Returns: system hostname
get_hostname() {
    # $HOST is a standard Zsh parameter
    print -- "${HOST%%.*}"
}

# Get fully qualified domain name
# Usage: get_fqdn
# Returns: fully qualified domain name
get_fqdn() {
    # Try hostname -f first
    local fqdn
    fqdn=$(hostname -f 2>/dev/null)
    
    if [[ -z "$fqdn" ]]; then
         # Fallback to Zsh param
         print -- "$HOST"
    else
         print -- "$fqdn"
    fi
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}