#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# --- Connectivity Checks ---

# Check if network is connected (interface check)
# Usage: is_connected
# Returns: 0 (true) if connected, 1 (false) otherwise
is_connected() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    
    if is_macos; then
        # Check specific interfaces on macOS
        local ip
        # ipconfig getifaddr returns 0 (success) if IP is found
        command ipconfig getifaddr en0 >/dev/null 2>&1 || \
        command ipconfig getifaddr en1 >/dev/null 2>&1
    elif is_linux; then
        # Check for default route presence using ip route
        [[ -n "$(command ip route show default 2>/dev/null)" ]]
    else
        return 1
    fi
}

# Check if internet is reachable (TCP check to Cloudflare DNS)
# Usage: is_online
# Returns: 0 (true) if online, 1 (false) otherwise
is_online() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    # Optimization: Use ztcp instead of ping (no fork, instant timeout control via system)
    # 1.1.1.1 is Cloudflare DNS, port 53 is almost always open
    if ztcp 1.1.1.1 53 2>/dev/null; then
        local fd=$REPLY
        ztcp -c $fd
        return 0
    fi
    return 1
}

# Check if port is open
# Usage: is_port_open "localhost" 80
# Returns: 0 (true) if open, 1 (false) otherwise
is_port_open() {
    (( ARGC == 2 )) || return 2 # Invalid usage
    local host=$1
    local port=$2

    # Use native Zsh TCP module
    if ztcp "$host" "$port" 2>/dev/null; then
        local fd=$REPLY
        ztcp -c $fd
        return 0
    fi
    return 1
}

# --- Network Info (Getters) ---

# Get hostname (short)
# Usage: get_hostname
# Returns: "macbook"
get_hostname() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    print -- $HOST
}

# Get Fully Qualified Domain Name
# Usage: get_fqdn
# Returns: "macbook.local" or "server.example.com"
get_fqdn() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    if is_linux; then
        command hostname -f
    else
        # macOS/BSD often fails with -f, fallback to HOST
        command hostname -f 2>/dev/null || print -- $HOST
    fi
}

# Get active network interface (primary)
# Usage: get_active_interface
# Returns: "en0" or "eth0"
get_active_interface() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    if is_macos; then
        # Route get default returns interface name
        local route_info
        route_info=$(command route -n get default 2>/dev/null)
        # Extract value after "interface: "
        local iface=${route_info#*interface: }
        print -- ${iface%%$'\n'*}
    elif is_linux; then
        # Parse ip route default line
        local -a parts
        parts=( $(command ip -4 route show default 2>/dev/null) )
        # "default via X dev Y ..." -> Y is usually at index 5 (1-based)
        local idx
        idx=${parts[(i)dev]}
        print -- $parts[idx+1]
    fi
}

# Get list of network interfaces
# Usage: get_interfaces
# Returns: list of interfaces (one per line)
get_interfaces() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    if is_linux; then
        # Pure Zsh: glob /sys/class/net files
        print -l /sys/class/net/*(N:t)
    else
        # macOS: parsing ifconfig -l (space separated) to newlines
        print -l ${(s: :)"$(command ifconfig -l)"}
    fi
}

# Get MAC address of an interface
# Usage: get_mac_address "eth0"
# Returns: "aa:bb:cc:dd:ee:ff"
get_mac_address() {
    (( ARGC == 1 )) || return 2 # Invalid usage
    local iface=$1

    if is_linux; then
        # Pure Zsh file read (fastest method on Linux, no external commands)
        [[ -r "/sys/class/net/$iface/address" ]] && cat "/sys/class/net/$iface/address"
    elif is_macos; then
        # Parse ifconfig output safely using Zsh word splitting
        local out
        out=$(command ifconfig "$iface" 2>/dev/null)
        
        # ${=out} splits the string into an array of words (handling newlines/spaces)
        local -a words=( ${=out} )
        
        # Find the index of the 'ether' keyword using (i) subscript flag
        local idx=${words[(i)ether]}
        
        # If 'ether' was found (idx <= length) and is not the last word
        if (( idx < ${#words} )); then
            print -- $words[idx+1]
        fi
    fi
}

# Get local IP address (LAN)
# Usage: get_local_ip [interface]
# Returns: IP address
get_local_ip() {
    (( ARGC <= 1 )) || return 2 # Invalid usage
    local iface=$1

    if is_macos; then
        # Optimization from your lanip script
        if [[ -z "$iface" ]]; then
            # Try to guess active interface if none provided
            iface=$(get_active_interface)
            [[ -z "$iface" ]] && iface="en0"
        fi
        
        # Using ipconfig is faster and cleaner than parsing ifconfig
        command ipconfig getifaddr "$iface" 2>/dev/null
        
    elif is_linux; then
        # Optimization: hostname -I is the fastest standard method on Linux
        if [[ -z "$iface" ]]; then
            local ip
            ip=$(command hostname -I 2>/dev/null)
            print -- ${ip%% *} # Return first IP
        else
            # If interface specific, use ip command
            local -a parts
            parts=( $(command ip -4 -o addr show dev "$iface" 2>/dev/null) )
            # Format: ... inet 192.168.1.5/24 ...
            # We want the 4th field (usually) or look for inet
            local idx=${parts[(i)inet]}
            if (( idx <= ${#parts} )); then
                local ip_cidr=$parts[idx+1]
                print -- ${ip_cidr%%/*}
            fi
        fi
    fi
}

# Get public IP address (WAN)
# Usage: get_public_ip
# Returns: IP address
# Optimization: Uses DNS (dig) first as per 'wanip' script for max speed
get_public_ip() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    local ip
    
    # Method 1: DNS (Ultra fast, ~20-50ms)
    if (( ${+commands[dig]} )); then
        # Try OpenDNS
        ip=$(command dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null)
        if [[ -n "$ip" ]]; then
            print -- ${ip//\"/} # Remove quotes if any
            return 0
        fi
        
        # Try Google DNS
        ip=$(command dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com 2>/dev/null)
        if [[ -n "$ip" ]]; then
            print -- ${ip//\"/}
            return 0
        fi
    fi
    
    # Method 2: HTTP (Fallback, slower)
    if (( ${+commands[curl]} )); then
        command curl -4 -s -m 2 https://api.ipify.org || \
        command curl -4 -s -m 2 https://ifconfig.me/ip
    elif (( ${+commands[wget]} )); then
        command wget -qO- --timeout=2 https://api.ipify.org
    else
        return 1
    fi
}

# Get default gateway IP
# Usage: get_gateway
# Returns: Gateway IP
get_gateway() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    if is_macos; then
        local out
        out=$(command route -n get default 2>/dev/null)
        local gw=${out#*gateway: }
        print -- ${gw%%$'\n'*}
    elif is_linux; then
        local -a parts
        parts=( $(command ip -4 route show default 2>/dev/null) )
        print -- $parts[3]
    fi
}

# Get DNS servers
# Usage: get_dns_servers
# Returns: list of DNS IPs
get_dns_servers() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    if is_macos; then
        # Parse scutil output for cleaner results than resolv.conf
        command scutil --dns | while read -r line; do
            if [[ $line == *nameserver\[* ]]; then
                print -- ${line##* : }
            fi
        done | sort -u
    else
        # Linux: read /etc/resolv.conf
        while read -r key value; do
            [[ $key == "nameserver" ]] && print -- $value
        done < /etc/resolv.conf
    fi
}

# Get current Wi-Fi SSID
# Usage: get_wifi_ssid [interface]
# Returns: "MyWiFiNetwork"
get_wifi_ssid() {
    (( ARGC <= 1 )) || return 2 # Invalid usage
    local iface=$1

    if is_macos; then
        # 1. Resolve interface if not provided
        if [[ -z "$iface" ]]; then
            if (( ${+functions[get_active_interface]} )); then
                iface=$(get_active_interface)
            fi
            # Default fallback if detection fails
            [[ -z "$iface" ]] && iface="en0"
        fi

        # 2. Get SSID using ipconfig getsummary (User preferred method)
        local out
        out=$(command ipconfig getsummary "$iface" 2>/dev/null | grep " SSID :")

        # 3. Parse output: "  SSID : Name"
        local ssid=""
        if [[ -n "$out" ]]; then
            ssid=${out#* : }
        fi

        # 4. Validate and Return
        if [[ -n "$ssid" && "$ssid" != *"<redacted>"* && "$ssid" != *"<SSID Redacted>"* ]]; then
            print -- "$ssid"
            return 0
        else
            # Instruction for the user as requested
            printe "Could not retrieve SSID (result empty or redacted)."
            printe "Try running: sudo ipconfig sethidewifiinfo 0"
            return 1
        fi

    elif is_linux; then
        # Linux implementation remains unchanged
        if (( ${+commands[iwgetid]} )); then
            command iwgetid -r
        elif (( ${+commands[nmcli]} )); then
            command nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2
        fi
    fi
}

# List all TCP ports currently listening on the system
# Usage: get_open_ports
# Returns: List of "PORT: COMMAND (PID)"
get_open_ports() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    
    if is_macos; then
        # macOS: lsof is the most reliable standard tool
        # -iTCP -sTCP:LISTEN -n (no host names) -P (no port names)
        # awk parses output to format: "8080: python3.9 (1234)"
        command lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | \
        awk 'NR>1 {print $9 ": " $1 " (" $2 ")"}' | \
        cut -d: -f2- | sort -n -u
        
    elif is_linux; then
        # Method 1: ss (Socket Statistics) - fastest modern Linux tool
        if (( ${+commands[ss]} )); then
            # -l (listening), -t (tcp), -n (numeric), -p (processes), -H (no header)
            # Output format manipulation to match requested style
            command sudo ss -ltnpH 2>/dev/null | \
            awk '{print $4 ": " $6}' | \
            sed 's/users:(("//g; s/",/, /g; s/pid=//g; s/))//g' | \
            awk -F':' '{print $NF ": " $0}' | cut -d: -f1,3- | sort -n -u
            
        # Method 2: netstat (legacy fallback)
        elif (( ${+commands[netstat]} )); then
            command sudo netstat -tlnp 2>/dev/null | \
            awk '/^tcp/ {print $4 "/" $7}' | \
            awk -F'/' '{print $1 ": " $2}' | \
            awk -F':' '{print $NF ": " $0}' | cut -d: -f1,3- | sort -n -u
            
        # Method 3: lsof (if installed)
        elif (( ${+commands[lsof]} )); then
             command sudo lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | \
             awk 'NR>1 {print $9 ": " $1 " (" $2 ")"}' | \
             cut -d: -f2- | sort -n -u
        fi
    fi
}

# --- Validation ---

# Check if string is a valid IPv4 address
# Usage: is_valid_ip "192.168.1.1"
is_valid_ip() {
    (( ARGC == 1 )) || return 2 # Invalid usage
    local octet='(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
    # Compose the full pattern: octet.octet.octet.octet
    [[ $1 =~ ^$octet\.$octet\.$octet\.$octet$ ]]
}

# Check if domain name is valid format
# Usage: is_domain_valid "example.com"
is_domain_valid() {
    (( ARGC == 1 )) || return 2 # Invalid usage
    local domain=$1
    # Basic regex: alphanumeric parts separated by dots, min 2 chars TLD
    local pattern='^([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'
    [[ $domain =~ $pattern ]]
}

# Check if string is a valid URL (supports http, https, ftp, ftps)
# Usage: is_url_valid "https://example.com:8080/path"
is_url_valid() {
    (( ARGC == 1 )) || return 2 # Invalid usage

    # Scheme: http, https, ftp, ftps
    local scheme='(https?|ftps?)'

    # Host: Alphanumeric, dots, hyphens, and common special chars.
    # Changed {1,256} to + to avoid "invalid repetition count" errors on some BSD systems.
    local host='[-a-zA-Z0-9@:%._+~#=]+'

    # Port (optional): e.g. :80 or :8080
    local port='(:[0-9]+)?'

    # Resource path/query (optional)
    local resource='([/?#][-a-zA-Z0-9@:%_+.~#?&//=]*)?'

    # Compose and match
    [[ $1 =~ ^$scheme://$host$port$resource$ ]]
}

# --- Utilities ---

# Check HTTP status code
# Usage: http_status "https://google.com"
# Returns: 200
http_status() {
    (( ARGC == 1 )) || return 2 # Invalid usage
    if (( ${+commands[curl]} )); then
        command curl -I -s -o /dev/null -w "%{http_code}" "$1"
    else
        return 1
    fi
}

# Download file with progress
# Usage: download "url" "output"
download() {
    (( ARGC == 2 )) || return 2 # Invalid usage
    local url=$1
    local out=$2
    
    if (( ${+commands[curl]} )); then
        command curl -L -# -o "$out" "$url"
    elif (( ${+commands[wget]} )); then
        command wget -q --show-progress -O "$out" "$url"
    else
        printe "No download tool found"
        return 1
    fi
}

# Scan common ports on a host
# Usage: scan_ports "192.168.1.1"
scan_ports() {
    (( ARGC == 1 )) || return 2 # Invalid usage
    local host=$1
    local port
    local -a common_ports=(21 22 23 25 53 80 443 3000 3306 5432 8000 8080)
    
    prints "Scanning $host..."
    
    for port in $common_ports; do
        if is_port_open "$host" "$port"; then
            print "Port $port: \e[32mOPEN\e[0m"
        fi
    done
}

# Flush DNS cache
# Usage: flush_dns
flush_dns() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    if is_macos; then
        sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
        prints "macOS DNS cache flushed"
    elif is_linux; then
        if (( ${+commands[resolvectl]} )); then
            sudo resolvectl flush-caches
            prints "systemd-resolved cache flushed"
        elif (( ${+commands[systemd-resolve]} )); then
            sudo systemd-resolve --flush-caches
            prints "systemd-resolved cache flushed"
        else
            printe "No known DNS flush method found for this Linux"
            return 1
        fi
    fi
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}