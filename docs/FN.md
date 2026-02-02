# zsh-config: Function Library (fn.zsh)

Part of [zsh-config](../README.md) documentation.
A comprehensive library for building standardized Zsh functions with automatic help generation, option parsing, argument validation, and type checking.

## Overview

The `fn.zsh` library provides a declarative way to define function metadata, arguments, and options. It automatically generates help messages, parses command-line arguments, validates types, and handles errors consistently.

**Dependencies:** `printe` (from print.zsh), color variables (`$r`, `$g`, `$y`, `$c`, `$p`, `$x`)

## Quick Start

```zsh
# Minimal function using fn.zsh
local -A _fn=(
    [version]="1.0.0"
    [info]="Brief description of what this function does"
)

local -A opts=() args=()
_fn_init "$@" || return $REPLY

# Your code here - opts and args are now populated
```

## Function Metadata (_fn)

The `_fn` associative array defines function metadata:

```zsh
local -A _fn=(
    [version]="1.0.0"           # Enables -v/--version option
    [info]="Short description"  # One-liner shown in help header
    [desc]="Full description"   # Shown in Description section
    [notes]="Additional notes"  # Shown in Notes section (after Examples)
    [author]="Author Name"      # Shown in footer with ©
    [created]="2025-01-15"      # Creation date (year used in © range)
    [modified]="2026-02-02"     # Last modified date (shown after version)
    [license]="MIT"             # License name (shown in footer)
    # [name] is auto-detected from function name (via $funcstack)
)
```

| Key        | Description                              | Auto-enables |
|------------|------------------------------------------|--------------|
| `version`  | Version string                           | `-v/--version` |
| `info`     | One-line description (help header)       | `-h/--help` |
| `desc`     | Multi-line description                   | `-h/--help` |
| `notes`    | Additional notes (after Examples)        | `-h/--help` |
| `author`   | Author name (shown in footer with ©)     | - |
| `created`  | Creation date YYYY-MM-DD (year for ©)    | - |
| `modified` | Modified date YYYY-MM-DD (shown in footer) | - |
| `license`  | License name (shown in footer)           | - |
| `name`     | Function name (auto-detected if omitted) | - |

### Footer Format

The footer is built from version, dates, author, and license:

```
myfunc ver. 1.0.0 (2026-02-02) © 2025-2026 Author Name (license: MIT)
```

- Date after version: `modified` date, or `created` if no `modified`
- Year range: from `created` to `modified` year (single year if same)
- If no dates: `myfunc ver. 1.0.0 © Author Name (license: MIT)`
- If only version: `myfunc ver. 1.0.0`
- If nothing defined: no footer

## Arguments (_fn_args)

Positional arguments are defined in `_fn_args` array:

```zsh
local -a _fn_args=(
    "input|Input file path"                 # name|description (required, string)
    "output|Output file|o"                  # name|description|o (optional)
    "count|Number of items|r|integer"       # name|description|r|type (required, typed)
)
```

### Argument Format

```
name|description|required_marker|type
```

| Field    | Required | Description                              |
|----------|----------|------------------------------------------|
| name     | Yes      | Argument name (letters, numbers, underscore) |
| description | No    | Help text for the argument               |
| required | No       | `r` = required (default), `o` = optional |
| type     | No       | Validation type (default: `string`)      |

### Rules

- Required arguments must come before optional arguments
- Arguments are matched by position
- Access values via `${args[name]}`

## Options (_fn_opts)

Command-line options are defined in `_fn_opts` array:

```zsh
local -a _fn_opts=(
    "force|f|Force overwrite"               # flag (no value)
    "cycles|c|Number of cycles|n"           # option with value
    "count|n|Count|n|integer"               # option with typed value
    "test||Test mode"                       # long-only option (no short form)
)
```

### Option Format

```
long_name|short_name|description|arg_name|type
```

| Field      | Required | Description                                |
|------------|----------|--------------------------------------------|
| long_name  | Yes      | Long option name (e.g., `force` for `--force`) |
| short_name | No       | Single letter (e.g., `f` for `-f`)         |
| description| No       | Help text for the option                   |
| arg_name   | No       | If present, option takes a value (shown as `<arg_name>`) |
| type       | No       | Validation type for the value (default: `string`) |

### Auto-added Options

These options are automatically added unless already defined:

| Option           | Added when                                                    |
|------------------|---------------------------------------------------------------|
| `-v/--version`   | `_fn[version]` is set                                         |
| `-h/--help`      | Any of: version, info, desc, notes, opts, args, or examples exist |

**Conflict resolution:** If `-v` or `-h` is already used by another option, only the long form (`--version` or `--help`) is added. For example, if you have `"verbose|v|..."`, then `-v` triggers verbose, but `--version` still shows version.

### Accessing Options

```zsh
# Get option value
${opts[cycles]}

# Check if flag is set
if (( ${+opts[force]} )); then
    echo "Force mode enabled"
fi
```

## Examples (_fn_examples)

Usage examples shown in help:

```zsh
local -a _fn_examples=(
    "myfunc input.txt"                          # Example only
    "myfunc -c 8 input.txt|Process with 8 cycles"  # Example with description
)
```

Format: `command|description` (description is optional)

## Commands (_fn_commands)

For functions that have subcommands (like `git pull`, `git push`), use `_fn_commands`:

```zsh
local -a _fn_commands=(
    "pull|Pull --rebase all repos"
    "push|Commit and push all repos"
    "status|Show status for all repos"
    "list|List all repositories"
    "reset|Hard reset all repos to origin/main"
)
```

Format: `command_name|description`

Commands are displayed in help between the Arguments and Options sections. Useful when your function accepts a command/action as its first argument.

### Example: Function with Subcommands

```zsh
local -A _fn=(
    [info]="Git wrapper for bulk operations"
    [version]="1.0.0"
)

local -a _fn_args=(
    "command|Command to execute|o"
)

local -a _fn_commands=(
    "pull|Pull all repositories"
    "push|Push all repositories"
    "status|Show status"
)

local -A opts=() args=()
_fn_init "$@" || return $REPLY

case "${args[command]:-help}" in
    pull)   # handle pull ;;
    push)   # handle push ;;
    status) # handle status ;;
    help)   _fn_usage >&2 ;;
    *)      printe "Unknown command: ${args[command]}" ;;
esac
```

## Supported Types

### Basic Types

| Type       | Description                    | Pattern/Validation           |
|------------|--------------------------------|------------------------------|
| `string`   | Any text                       | `^.*$`                       |
| `char`     | Single character               | `^.$`                        |
| `digit`    | Single digit (0-9)             | `^[0-9]$`                    |
| `integer`  | Integer number                 | `^-?[0-9]+$`                 |
| `float`    | Decimal number                 | `^-?[0-9]+(\.[0-9]+)?$`      |
| `bool`     | Boolean value                  | `true/false/yes/no/1/0`      |

### Date/Time Types

| Type       | Description                    | Format                       |
|------------|--------------------------------|------------------------------|
| `date`     | ISO date                       | `YYYY-MM-DD`                 |
| `time`     | 24-hour time                   | `HH:MM:SS`                   |
| `datetime` | ISO datetime                   | `YYYY-MM-DDTHH:MM:SS`        |

### Network Types

| Type       | Description                    | Example                      |
|------------|--------------------------------|------------------------------|
| `ipv4`     | IPv4 address                   | `192.168.1.1`                |
| `ipv6`     | IPv6 address                   | `2001:db8::1`                |
| `email`    | Email address                  | `user@example.com`           |
| `domain`   | Domain name                    | `example.com`                |
| `url`      | URL (any schema)               | `https://example.com`        |

## Ranged Types

Use interval notation to constrain numeric values or string lengths:

### Interval Notation

| Notation   | Meaning                        |
|------------|--------------------------------|
| `[a;b]`    | Inclusive: `a <= x <= b`       |
| `(a;b)`    | Exclusive: `a < x < b`         |
| `[a;b)`    | Left-inclusive: `a <= x < b`   |
| `(a;b]`    | Right-inclusive: `a < x <= b`  |
| `[a;]`     | Minimum only: `x >= a`         |
| `(;b]`     | Maximum only: `x <= b`         |
| `(;b)`     | Maximum exclusive: `x < b`     |

### Examples

```zsh
# Integer in range 1-10 (inclusive)
"cycles|c|Number of cycles|n|integer[1;10]"

# Float greater than 0
"speed|s|Speed value|v|float(0;]"

# String length 1-255 characters
"name|n|User name|name|string[1;255]"

# Non-empty string up to 100 chars
"title|t|Title|title|string(;100]"
```

For `string` type, the range applies to string **length**, not the value itself.

## URL Schema Restrictions

Restrict allowed URL schemas:

```zsh
# Only http and https
"website|w|Website URL|url|url[http,https]"

# Force https only
"secure|s|Secure URL|url|url[https]"

# Allow multiple schemas
"link|l|Link URL|url|url[http,https,ftp]"
```

## Initialization

Call `_fn_init` to parse arguments and options:

```zsh
local -A opts=() args=()
_fn_init "$@" || return $REPLY
```

### Return Values

| Code | Meaning                                              |
|------|------------------------------------------------------|
| 0    | Success - opts and args are populated                |
| 1    | Help or version shown (REPLY=0) or parsing error (REPLY=1) |
| 2    | Validation error (REPLY=2)                           |
| 3    | Definition error in _fn_args or _fn_opts (REPLY=3)   |

**Important:** Always use `return $REPLY` after `_fn_init` fails to propagate the correct exit code.

## Complete Example

```zsh
# backup - Create timestamped backup of a file
# Usage: backup [options] <source> [destination]

local -A _fn=(
    [info]="Create timestamped backup of a file"
    [desc]="Creates a backup copy of the specified file with a timestamp suffix.
            If no destination is provided, the backup is created in the same directory."
    [version]="1.0.0"
    [author]="Your Name"
    [notes]="Timestamps use ISO 8601 format (YYYY-MM-DD_HH-MM-SS).
             Existing backups are not overwritten."
)

local -a _fn_args=(
    "source|Source file to backup|r"
    "destination|Destination directory|o"
)

local -a _fn_opts=(
    "compress|c|Compress backup with gzip"
    "keep|k|Number of backups to keep|n|integer[1;100]"
    "quiet|q|Suppress output messages"
)

local -a _fn_examples=(
    "backup important.txt|Backup to same directory"
    "backup -c data.db /backups|Compressed backup to /backups"
    "backup --keep 5 config.yml|Keep only 5 most recent backups"
)

local -A opts=() args=()
_fn_init "$@" || return $REPLY

# Main logic
local src="${args[source]}"
local dst="${args[destination]:-.}"
local timestamp=$(date +%Y-%m-%d_%H-%M-%S)
local backup_name="${src:t}_${timestamp}"

if (( ${+opts[compress]} )); then
    backup_name+=".gz"
    gzip -c "$src" > "${dst}/${backup_name}"
else
    cp "$src" "${dst}/${backup_name}"
fi

(( ${+opts[quiet]} )) || print "Backup created: ${dst}/${backup_name}"
```

## Help Output Structure

When `-h/--help` is invoked, the output follows this structure:

```
function_name - Short info from _fn[info]

Usage: function_name [options] <required_arg> [optional_arg]

Description
  Full description from _fn[desc]

Arguments
  <source>       Source file to backup  [required, string]
  [destination]  Destination directory  [string]

Commands                                 # Only shown if _fn_commands defined
  pull           Pull all repositories
  push           Push all repositories
  status         Show status

Options
  -h, --help     Show this help message
  -v, --version  Show version
  -c, --compress Compress backup with gzip
  -k, --keep <n> Number of backups to keep  [integer]
  -q, --quiet    Suppress output messages

Examples
  backup important.txt - Backup to same directory
  backup -c data.db /backups - Compressed backup to /backups

Notes
  Timestamps use ISO 8601 format...

function_name ver. 1.0.0 (2026-02-02) © 2025-2026 Your Name (license: MIT)
This function is defined in /path/to/function
```

## Extending Types

Add custom types by extending the global arrays:

```zsh
# Add custom type pattern
_FN_TYPES[uuid]='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

# Add human-readable description for error messages
_FN_TYPE_DESC[uuid]="UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
```

## Error Handling

The library collects all validation errors and displays them together:

```
Invalid value for option --cycles: 'abc' is not integer.
Invalid value for argument <count>: '999' is not integer >= 1 and <= 100.
Usage: myfunc [options] <source> [destination]
For more information use `myfunc --help`
```

## Best Practices

1. **Always include `[info]`** - provides context in help header
2. **Use descriptive argument/option names** - they appear in help and error messages
3. **Prefer typed validation** - catches errors early with clear messages
4. **Add examples** - helps users understand common usage patterns
5. **Use `[notes]`** - for important caveats or additional information
6. **Check flag presence with `${+opts[flag]}`** - not `${opts[flag]}`
