# zconfig: List of Functions

Part of [zconfig](../README.md) documentation. 
List of available functions and helper functions with descriptions. 

| function | location | description |
| -------- | -------- | ----------- |
| abs | math.zsh | Get absolute value |
| add_days | date.zsh | Add days to current date |
| age_from_date | date.zsh | Get age from birthdate |
| array_concat | arrays.zsh | Concatenate multiple arrays |
| array_contains | arrays.zsh | Check if array contains element (exact match) |
| array_diff | arrays.zsh | Get array difference (elements in arr1 but not in arr2) |
| array_every | arrays.zsh | Check if all elements match predicate |
| array_filter | arrays.zsh | Filter array by pattern |
| array_first | arrays.zsh | Get first element of an array |
| array_flatten | arrays.zsh | Flatten nested arrays (split string elements by space) |
| array_index_of | arrays.zsh | Get index of element in array |
| array_intersect | arrays.zsh | Get array intersection (common elements) |
| array_is_empty | arrays.zsh | Check if array is empty |
| array_join | arrays.zsh | Join array with separator |
| array_last | arrays.zsh | Get last element of array |
| array_length | arrays.zsh | Get array length |
| array_map | arrays.zsh | Map array through function |
| array_pop | arrays.zsh | Remove and return last element from array |
| array_print | arrays.zsh | Print array elements (for debugging) |
| array_push | arrays.zsh | Append element(s) to array |
| array_remove_at | arrays.zsh | Remove element from array by index |
| array_remove | arrays.zsh | Remove element from array by value |
| array_reverse | arrays.zsh | Reverse array |
| array_shift | arrays.zsh | Remove and return first element from array |
| array_slice | arrays.zsh | Slice array |
| array_some | arrays.zsh | Check if any element matches predicate |
| array_sort_reverse | arrays.zsh | Sort array in reverse order |
| array_sort | arrays.zsh | Sort array |
| array_unique | arrays.zsh | Get unique elements from array |
| array_unshift | arrays.zsh | Add element(s) to beginning of array |
| avg | math.zsh | Calculate average (mean) of numbers (integer) |
| avgf | math.zsh | Calculate average with floating point |
| backup_file | varia.zsh | Create a backup of a file with timestamp |
| capitalize | strings.zsh | Capitalize first letter of string (Sentence case) |
| cdpath_append | path.zsh | Add directory to $cdpath |
| ceil | math.zsh | Round number up (ceiling) |
| clamp | math.zsh | Clamp number to range |
| clean_dir | compile.zsh | Remove all .zwc files from a directory |
| clean_plugin | plugins.zsh | Remove all .zwc files from a plugin directory |
| clean_plugins | plugins.zsh | Remove all .zwc files from all plugins |
| clean_zsh_config | compile.zsh | Clean .zwc files from entire zsh configuration |
| clip_copy | clipboard.zsh | Copy input to system clipboard |
| clip_paste | clipboard.zsh | Paste from system clipboard to stdout |
| collatz | functions | Calculate Collatz sequences or analyze ranges statistics |
| compile_dir | compile.zsh | Compile all .zsh files in a directory |
| compile_file | compile.zsh | Compile a single .zsh file |
| compile_plugin | plugins.zsh | Compile all .zsh files in a plugin directory |
| compile_plugins | plugins.zsh | Compile all installed plugins |
| compile_zsh_config | compile.zsh | Compile entire zsh configuration (lib/, inc/, apps/) |
| compress | archive.zsh | Compress a file or directory into a .tar.gz (uses pigz if available) |
| confirm | varia.zsh | Ask for confirmation (Y/n) |
| copyfile | clipboard.zsh | Copy the contents of a file to clipboard |
| copypath | clipboard.zsh | Copy the absolute path of a file or directory to clipboard |
| count_dirs | files.zsh | Count directories in directory (non-recursive) |
| count_files | files.zsh | Count files in directory (non-recursive) |
| cpuinfo | functions | Display CPU hardware information and current load statistics |
| current_day | date.zsh | Get current day |
| current_hour | date.zsh | Get current hour (24h format) |
| current_minute | date.zsh | Get current minute |
| current_month_name | date.zsh | Get current month (name) |
| current_month | date.zsh | Get current month (numeric) |
| current_second | date.zsh | Get current second |
| current_weekday | date.zsh | Get current day of week (name) |
| current_year | date.zsh | Get current year |
| cwg_next | cwg.zsh | Core function returning a raw random number |
| cwg_seed | cwg.zsh | Function to initialize the generator with a custom seed |
| date_to_timestamp | date.zsh | Get timestamp for specific date |
| days_between | date.zsh | Get difference between two timestamps in days |
| days_in_month | date.zsh | Get number of days in month |
| dec2bin | math.zsh | Convert Decimal to Binary |
| dec2hex | math.zsh | Convert Decimal to Hexadecimal |
| deg2rad | math.zsh | Convert degrees to radians |
| diskinfo | functions | Display disk usage statistics for a specific directory or mount point |
| download | network.zsh | Download file with progress |
| end_of_day | date.zsh | Get end of day timestamp (23:59:59) |
| etime | varia.zsh | Measure execution time of a command |
| execs | functions | Execute command with animated spinner |
| extract | archive.zsh | Extract any archive format based on extension |
| factorial | math.zsh | Calculate factorial |
| fibonacci | math.zsh | Calculate fibonacci number at position n |
| find_plugin_file | plugins.zsh | Find the main plugin file |
| floor | math.zsh | Round number down (floor) |
| flush_dns | network.zsh | Flush DNS cache |
| format_bytes | math.zsh | Format bytes into human readable size (IEC) |
| format_duration | date.zsh | Format seconds into human readable duration |
| format_metric | math.zsh | Format number with SI metric prefixes (k, M, G, T) - Base 1000 |
| format_size | files.zsh | Format bytes into human readable size |
| format_time | date.zsh | Format seconds (with sub-second precision) into human readable time |
| format_timestamp | date.zsh | Format timestamp to date string |
| fpath_append | path.zsh | Add directory to the END of $fpath |
| fpath_prepend | path.zsh | Add directory to the BEGINNING of $fpath |
| fpath_remove | path.zsh | Remove directory from $fpath |
| gcd | math.zsh | Calculate GCD (Greatest Common Divisor) |
| get_active_interface | network.zsh | Get active network interface (primary) |
| get_available_shells | shell.zsh | Get available shells from /etc/shells |
| get_cpu_arch | hardware.zsh | Get system architecture (Normalized) |
| get_cpu_count | hardware.zsh | Get Number of CPU Cores |
| get_cpu_model | hardware.zsh | Get CPU Model Name |
| get_day_of_year | date.zsh | Get day of year |
| get_default_shell | shell.zsh | Get default shell for current user |
| get_dirname | files.zsh | Get directory from path (dirname equivalent) |
| get_disk_free | hardware.zsh | Get Free/Available Disk Space |
| get_disk_total | hardware.zsh | Get Total Disk Size |
| get_disk_used | hardware.zsh | Get Used Disk Space |
| get_dns_servers | network.zsh | Get DNS servers |
| get_extension | files.zsh | Get file extension (without dot) |
| get_file_mode | files.zsh | Get file permissions in octal format |
| get_file_mtime | files.zsh | Get modification time (epoch) |
| get_file_owner | files.zsh | Get file owner name |
| get_file_size | files.zsh | Get file size in bytes |
| get_filename_no_ext | files.zsh | Get filename without extension |
| get_filename | files.zsh | Get filename from path (basename equivalent) |
| get_fqdn | network.zsh | Get Fully Qualified Domain Name |
| get_gateway | network.zsh | Get default gateway IP |
| get_hostname | network.zsh | Get hostname (short) |
| get_interfaces | network.zsh | Get list of network interfaces |
| get_kernel_version | system.zsh | Get kernel version |
| get_load_average | system.zsh | Get CPU Load Average (1 min) |
| get_local_ip | network.zsh | Get local IP address (LAN) |
| get_mac_address | network.zsh | Get MAC address of an interface |
| get_open_ports | network.zsh | List all TCP ports currently listening on the system |
| get_public_ip | network.zsh | Get public IP address (WAN) |
| get_quarter | date.zsh | Get quarter of year (1-4) |
| get_ram_free | hardware.zsh | Get Available/Free RAM in Bytes |
| get_ram_total | hardware.zsh | Get Total RAM in Bytes |
| get_ram_used | hardware.zsh | Get Used RAM in Bytes (Approximation) |
| get_uptime | system.zsh | Get system uptime (human readable) |
| get_version | strings.zsh | Extract version number from a string |
| get_week_number | date.zsh | Get week number of year |
| get_wifi_ssid | network.zsh | Get current Wi-Fi SSID |
| getrandom | functions | Unified function to get random numbers with optional formatting |
| hex2dec | math.zsh | Convert Hexadecimal to Decimal |
| hours_between | date.zsh | Get difference between two timestamps in hours |
| http_status | network.zsh | Check HTTP status code |
| in_range | math.zsh | Check if number is in range (inclusive) |
| install_plugin | plugins.zsh | Install a plugin from git repository |
| is_alphanumeric | strings.zsh | Check if string is alphanumeric |
| is_array_initialized | arrays.zsh | Check if array/variable is initialized |
| is_color_terminal | shell.zsh | Check if terminal supports colors |
| is_connected | network.zsh | Check if network is connected (interface check) |
| is_debian_based | system.zsh | Check if current OS is Debian-based (includes Ubuntu, Mint, etc.) |
| is_debian | system.zsh | Check if current OS is specifically Debian (not derivatives) |
| is_debug | varia.zsh | Check if debug mode is enabled |
| is_dir | files.zsh | Check if path exists and is a directory |
| is_domain_valid | network.zsh | Check if domain name is valid format |
| is_empty_dir | files.zsh | Check if directory is empty |
| is_empty | strings.zsh | Check if string is empty |
| is_even | math.zsh | Check if number is even |
| is_executable | files.zsh | Check if file is executable |
| is_file | files.zsh | Check if path exists and is a regular file |
| is_future | date.zsh | Check if date is in the future |
| is_hardlink | files.zsh | Check if file is a hard link (has link count > 1) |
| is_installed | varia.zsh | Check if command(s) are installed/available |
| is_integer | strings.zsh | Check if string is strictly an integer |
| is_interactive | shell.zsh | Check if running in interactive shell |
| is_leap_year | date.zsh | Check if year is leap year |
| is_link | files.zsh | Check if path exists and is a symbolic link |
| is_linux | system.zsh | Check if current OS is Linux |
| is_login_shell | shell.zsh | Check if running in login shell |
| is_macos | system.zsh | Check if current OS is macOS |
| is_negative | math.zsh | Check if number is negative |
| is_number | math.zsh | Check if argument is a valid number (integer or float) |
| is_numeric | strings.zsh | Check if string is numeric (Integer or Float, +/-) |
| is_odd | math.zsh | Check if number is odd |
| is_online | network.zsh | Check if internet is reachable (TCP check to Cloudflare DNS) |
| is_past | date.zsh | Check if date is in the past |
| is_plugin_installed | plugins.zsh | Check if a plugin is installed (directory exists) |
| is_plugin_loaded | plugins.zsh | Check if a plugin is loaded |
| is_port_open | network.zsh | Check if port is open |
| is_positive | math.zsh | Check if number is positive |
| is_readable | files.zsh | Check if file/dir is readable |
| is_root | shell.zsh | Check if running as root |
| is_screen | shell.zsh | Check if running under screen |
| is_sourced | shell.zsh | Check if script is being sourced (not executed directly) |
| is_ssh | shell.zsh | Check if running via SSH |
| is_subshell | shell.zsh | Check if running inside a subshell |
| is_tmux | shell.zsh | Check if running under tmux |
| is_today | date.zsh | Check if date is today |
| is_ubuntu | system.zsh | Check if current OS is specifically Ubuntu |
| is_url_valid | network.zsh | Check if string is a valid URL (supports http, https, ftp, ftps) |
| is_valid_ip | network.zsh | Check if string is a valid IPv4 address |
| is_writable | files.zsh | Check if file/dir is writable |
| is_wsl | system.zsh | Check if current OS is Windows (WSL) |
| is_zero | math.zsh | Check if number is zero |
| j2y | functions | Convert JSON to YAML using yq |
| lanip | functions | Retrieve the local IP address (interactive tool) |
| lcm | math.zsh | Calculate LCM (Least Common Multiple) |
| list_plugins | plugins.zsh | List all plugins |
| load_plugin_directly | plugins.zsh | Load a plugin by name directly (without wrapper) |
| load_plugin_wrapper | plugins.zsh | Load a plugin wrapper file |
| load_plugin | plugins.zsh | Load a plugin by name (from wrapper) |
| logininfo | functions | Display login information with user, host, IP, TTY and remote connection |
| lowercase | strings.zsh | Convert string to lowercase |
| ltrim | strings.zsh | Trim whitespace from left side of string |
| manpath_append | path.zsh | Add directory to $manpath |
| max | math.zsh | Get maximum of two or more numbers |
| mdig | functions | Multi-DNS query tool |
| meminfo | functions | Display system memory (RAM) usage statistics |
| min | math.zsh | Get minimum of two or more numbers |
| minutes_between | date.zsh | Get difference between two timestamps in minutes |
| mkfile | files.zsh | Create a file and its parent directories if they don't exist |
| needrestart | functions | Manage needrestart interactive prompts on Ubuntu |
| needs_compile | compile.zsh | Check if a .zsh file needs (re)compilation |
| now_format | date.zsh | Get current date in custom format |
| now_iso_full | date.zsh | Get current date and time in ISO 8601 format |
| now_iso | date.zsh | Get current date in ISO 8601 format |
| now_timestamp | date.zsh | Get current timestamp (Unix epoch) |
| os_codename | system.zsh | Get OS code name |
| os_icon | system.zsh | Get OS icon (Nerd Fonts required) |
| os_name | system.zsh | Get OS name (ID) |
| os_version | system.zsh | Display OS version number |
| parent_process | shell.zsh | Get parent process name |
| path_append | path.zsh | Add directory to the END of $PATH |
| path_clean | path.zsh | Remove non-existing directories from all path arrays |
| path_prepend | path.zsh | Add directory to the BEGINNING of $PATH |
| path_print | path.zsh | Pretty print path variables |
| path_remove | path.zsh | Remove directory from $PATH |
| percent | math.zsh | Calculate percentage |
| pow | math.zsh | Calculate power |
| primes | functions | Prime number generator and tester |
| printa | print.zsh | Print all elements of an array (associative or indexed) |
| printb | print.zsh | Print bell message to stdout (with sound) |
| printc | print.zsh | Print colored text (simple wrapper) |
| printcol | print.zsh | Print arguments in columns (like ls) |
| printd | print.zsh | Print debug message (only if debug mode is on) |
| printdemo | print.zsh | Print available print functions (for demo purposes) |
| printe | print.zsh | Print error message to stderr |
| printh | print.zsh | Print a header with an underline |
| printi | print.zsh | Print info message to stdout |
| printkv | print.zsh | Print a key-value pair |
| printl | print.zsh | Print a separator line |
| printq | print.zsh | Ask user for input with default value |
| prints | print.zsh | Print success message to stdout |
| printt | print.zsh | Print text surrounded by a border |
| printul | print.zsh | Print unordered list |
| printw | print.zsh | Print warning message to stderr |
| rad2deg | math.zsh | Convert radians to degrees |
| random | math.zsh | Generate random number between min and max (inclusive) |
| register_plugin | plugins.zsh | Register a standalone plugin (single file, no repo) |
| relative_time | date.zsh | Get relative time description |
| reload_shell | shell.zsh | Reload current shell configuration |
| remove_plugin | plugins.zsh | Remove a plugin |
| rename-fonts | functions | Rename font files in the current directory based on their internal font names. |
| resolve_link | files.zsh | Resolve symbolic link target (readlink equivalent) |
| round | math.zsh | Round number to nearest integer |
| rtrim | strings.zsh | Trim whitespace from right side of string |
| scan_ports | network.zsh | Scan common ports on a host |
| seconds_between | date.zsh | Get difference between two timestamps in seconds |
| set_default_shell | shell.zsh | Set default shell for current user |
| shell_level | shell.zsh | Get shell level (nesting depth) |
| shell_name | shell.zsh | Get current shell name |
| shell_path | shell.zsh | Get full shell path (environment variable) |
| shell_speed | shell.zsh | Measure shell startup times |
| shell_ver | shell.zsh | Get Zsh version |
| sleepme | functions | Put the computer to sleep |
| slugify | strings.zsh | Convert string to slug (URL-friendly) |
| source_plugin | plugins.zsh | Source a standalone plugin file directly |
| sqrt | math.zsh | Calculate square root |
| sslinfo | functions | Wrapper around openssl to inspect certificates |
| start_of_day | date.zsh | Get start of day timestamp (00:00:00) |
| start_of_month | date.zsh | Get start of month timestamp |
| start_of_week | date.zsh | Get start of week timestamp (Monday 00:00:00) |
| start_of_year | date.zsh | Get start of year timestamp |
| str_contains | strings.zsh | Check if string contains substring |
| str_count | strings.zsh | Count occurrences of substring |
| str_ends_with | strings.zsh | Check if string ends with suffix |
| str_join | strings.zsh | Join array elements with delimiter |
| str_length | strings.zsh | Get string length |
| str_pad | strings.zsh | Pad string to length |
| str_repeat | strings.zsh | Repeat string N times |
| str_replace_all | strings.zsh | Replace all occurrences of pattern with replacement |
| str_replace | strings.zsh | Replace first occurrence of pattern with replacement |
| str_reverse | strings.zsh | Reverse string |
| str_split | strings.zsh | Split string by delimiter into array |
| str_starts_with | strings.zsh | Check if string starts with prefix |
| str_to_unicode | strings.zsh | Convert string to JSON-ready Unicode escape sequences |
| sub_days | date.zsh | Subtract days from current date |
| substring | strings.zsh | Get substring |
| sum | math.zsh | Calculate sum of numbers |
| sysinfo | functions | Display system information summary |
| terminal_columns | shell.zsh | Get number of terminal columns |
| terminal_lines | shell.zsh | Get number of terminal lines |
| terminal_type | shell.zsh | Get terminal type |
| titlecase | strings.zsh | Convert string to title case (AP/Chicago style logic) |
| trim | strings.zsh | Trim whitespace from both ends of string |
| ttfb | functions | Measure Time To First Byte (TTFB) for a given URL |
| update_plugin | plugins.zsh | Update a plugin (git pull + recompile) |
| update_plugins | plugins.zsh | Update all installed plugins |
| uppercase | strings.zsh | Convert string to uppercase |
| urlinfo | functions | uURL information tool (zsh port of PHP version) |
| wanip | functions | Retrieve the public IP address (IPv4 or IPv6) |
| y2j | functions | Convert YAML to JSON using yq |
| yesno | print.zsh | Ask user a yes/no question |
| zcalc | math.zsh | Evaluate mathematical expression and print result |
| zconfig | functions | Open the file defined in $ZCONFIG using the default editor |
| zfiles | functions | Show loaded shell files in order |
| zgit | functions | Git wrapper for bulk operations on repositories defined in $GHDIR |
| zinfo | functions | Display help information for a function from lib/ or functions/ |
| zip_folder | archive.zsh | Create a zip archive of a folder (ignoring common junk) |
| zman | functions | List all user functions from lib/ and functions/ directories |
| zupdate | functions | Update zconfig and all plugins |