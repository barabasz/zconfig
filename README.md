# zsh-config

This is a modular, performance-optimized zsh configuration focused on maintainability, tracking, and fast startup times. The configuration is split across multiple specialized directories with a clear separation of concerns.

## Table of Contents

- [Overview](#overview)
- [Philosophy & Principles](#philosophy--principles)
- [Directory Structure](#directory-structure)
- [Core Components](#core-components)
- [Naming Conventions](#naming-conventions)
- [File Tracking System](#file-tracking-system)
- [Development Guidelines](#development-guidelines)
- [Examples & Use Cases](#examples--use-cases)
- [ZSH.md](ZSH.md) - guidelines for writing idiomatic zsh code.

## Key Features

- File tracking system with performance monitoring
- Modular library of helper functions
- Lightweight plugin system (no Oh-My-Zsh dependency)
- Automatic plugin compilation for faster loading
- Lazy loading for heavy applications
- Dynamic loading of all library and app files
- Autoloaded user functions
- Comprehensive aliasing system

## Instructions for changes and improvements

When working on changes to this zsh configuration:

1. **Before adding or modifying functions**, always read:
   - `lib/*.zsh` - to see existing helper functions
   - `functions/*` - to see existing autoloaded functions

   This prevents duplicating existing functionality and ensures consistency with established patterns.

2. **Before modifying app integrations**, read:
   - `apps/*.zsh` - to understand existing configurations

3. **Before adding plugins**, read:
   - `lib/plugins.zsh` - plugin management functions
   - `plugins/*.zsh` - existing plugin wrappers

4. **For any changes**, familiarize yourself with:
   - The naming conventions (see [Naming Conventions](#naming-conventions))
   - The file tracking pattern (see [File Tracking System](#file-tracking-system))

5. **For coding style**, follow the zsh idioms in **[ZSH.md](ZSH.md)** - this is critical for writing proper zsh code (not bash)

## Philosophy & Principles

### Core Values

1. **Performance First**
   - Track loading times of all sourced files
   - Lazy load heavy applications
   - Minimize startup time
   - Dynamic loading (no compilation)

2. **Modularity**
   - Each component in separate file
   - Clear single responsibility
   - Easy to enable/disable features

3. **Zsh-Native**
   - Write for zsh exclusively (no bash compatibility)
   - Use zsh-specific features: `[[ ]]`, `print`, `whence`, parameter expansion
   - Leverage zsh builtins whenever possible

4. **Explicit Over Implicit**
   - Function names clearly describe purpose
   - Consistent naming conventions
   - Documented behavior

5. **Maintainability**
   - Self-documenting code
   - Clear structure
   - Easy debugging with `ZSH_DEBUG=1`

### Design Decisions

- **No compatibility layers** - zsh only, no sh/bash/ksh support
- **Separation of concerns** - Each file has a single, clear responsibility
  - Core configuration in `inc/zsh.zsh`
  - Colors separated to `inc/colors.zsh`
  - History configuration in `inc/history.zsh`
  - Editor settings in `inc/editors.zsh`
  - User folders in `inc/folders.zsh`
  - Icons in `inc/icons.zsh`
- **Helper library** - Small, fast functions loaded first in `.zshenv`
- **Application configs** - Loaded last, can depend on helpers
- **Tracking everywhere** - Every file reports loading time
- **Dynamic loading** - All files in `lib/` and `apps/` are sourced dynamically at shell startup
- **Explicit module loading** - All zsh modules loaded upfront in `inc/zsh.zsh`

## Directory Structure

```
~/.config/zsh/
├── .zshenv           # Main entry point (always sourced)
├── .zprofile         # Login shell initialization
├── .zshrc            # Interactive shell setup
├── .zlogin           # Post-login actions
├── .zlogout          # Logout cleanup
├── .zsh_history      # Command history
├── inc/              # Core includes
│   ├── zfiles.zsh       # Shell files tracking infrastructure
│   ├── zsh.zsh          # Core zsh configuration and modules
│   ├── bootstrap.zsh    # Bootstrap functions
│   ├── xdg.zsh          # XDG Base Directories
│   ├── folders.zsh      # User folder paths
│   ├── variables.zsh    # Environment variables
│   ├── colors.zsh       # ANSI color codes
│   ├── icons.zsh        # Icon/glyph exports
│   ├── editors.zsh      # Editor and pager configuration
│   ├── history.zsh      # History configuration and options
│   ├── prompt.zsh       # Fallback prompt
│   ├── path.zsh         # PATH configuration
│   ├── hashdirs.zsh     # Named directory hashes
│   ├── aliases.zsh      # Aliases
│   └── locales.zsh      # Locale settings
├── lib/              # Helper library (fast utilities)
│   ├── files.zsh        # File/path test functions
│   ├── system.zsh       # OS detection & info
│   ├── strings.zsh      # String manipulation
│   ├── shell.zsh        # Shell info functions
│   ├── plugins.zsh      # Plugin management functions
│   └── varia.zsh        # Miscellaneous helpers
├── apps/             # Application integrations
│   ├── brew.zsh         # Homebrew
│   ├── omp.zsh          # Oh My Posh (prompt engine)
│   └── ...              # Other apps
├── functions/        # Autoloaded user functions
│   ├── sysinfo          # System information display
│   ├── logininfo        # Login details
│   ├── zfiles           # Show tracked files (with -b flag for bar viz)
│   └── ...              # Other functions
├── plugins/          # Zsh plugins
│   ├── f-sy-h.zsh       # Plugin wrapper (configuration)
│   ├── f-sy-h/          # Plugin repository (git clone, in .gitignore)
│   └── ...              # Other plugins
└── cache/            # Runtime cache
    └── sessions/     # Zsh sessions
```

## Core Components

### 1. `.zshenv` - Entry Point

**Purpose:** Always sourced first, sets up tracking and loads critical components.

**Responsibilities:**
- Load file tracking system (`zfiles.zsh`)
- Load core zsh configuration (`zsh.zsh`)
- Load bootstrap functions
- Load XDG directories, folders, and environment variables
- Source entire `lib/` directory (helper functions)
- Configure PATH and locale

**Key Variables** (defined in `inc/zsh.zsh`):
```zsh
CONFDIR=$HOME/.config
ZDOTDIR=$CONFDIR/zsh
ZCACHEDIR=$ZDOTDIR/cache
ZINCDIR=$ZDOTDIR/inc
ZLIBDIR=$ZDOTDIR/lib
ZAPPDIR=$ZDOTDIR/apps
ZFNCDIR=$ZDOTDIR/functions
ZSH_CONFIG_VERSION="20260111v3"
ZSH_DEBUG=1              # Set to 1 for verbose output
ZSH_ZFILE_DEBUG=0        # Set to 1 for file tracking debug
ZSH_LOGIN_INFO=0         # Show login info
ZSH_SYS_INFO=0           # Show system info
```

**Flow:**
```
.zshenv
  → inc/zfiles.zsh (file tracking setup)
  → inc/zsh.zsh (core config, variables, zmodload)
  → inc/bootstrap.zsh (helper functions)
  → inc/xdg.zsh (XDG directories)
  → inc/folders.zsh (user folder paths)
  → inc/variables.zsh (environment exports)
  → lib/*.zsh (all helper functions)
  → inc/path.zsh (PATH configuration)
  → inc/locales.zsh (locale settings)
```

### 2. `inc/zfiles.zsh` - File Tracking Infrastructure

**Purpose:** Provides tracking functions for measuring load times of sourced files.

**Exports:**
- `ZFILES` - associative array: filepath → status (0=loading, 1=loaded)
- `ZFILES_TIME` - associative array: filepath → load time in ms
- `ZFILES_START` - associative array: filepath → start time
- `ZFILES_ORDER` - array of filepaths in load order
- `zfile_track_start()` - Start tracking a file
- `zfile_track_end()` - End tracking and calculate time

### 3. `inc/zsh.zsh` - Core Zsh Configuration

**Purpose:** Set core zsh configuration variables and load zsh modules.

**Exports:**
```zsh
# Directory structure
CONFDIR, ZDOTDIR, ZCACHEDIR, SHELL_SESSION_DIR
ZINCDIR, ZLIBDIR, ZAPPDIR, ZFNCDIR

# Debug/info flags
ZSH_DEBUG, ZSH_ZFILE_DEBUG, ZSH_LOGIN_INFO, ZSH_SYS_INFO

# Version
ZSH_CONFIG_VERSION
```

**Zsh Modules Loaded:**
- `zsh/complete` - Completion system
- `zsh/datetime` - Date/time functions (EPOCHREALTIME)
- `zsh/main` - Main module
- `zsh/mathfunc` - Math functions
- `zsh/net/tcp` - TCP socket support
- `zsh/parameter` - Parameter manipulation
- `zsh/regex` - Regex support
- `zsh/stat` - File stat builtin
- `zsh/system` - System interface
- `zsh/terminfo` - Terminal info
- `zsh/zle` - Zsh Line Editor
- `zsh/zleparameter` - ZLE parameter access
- `zsh/zselect` - Select system call
- `zsh/zutil` - Utility builtins

### 4. `inc/bootstrap.zsh` - Bootstrap Functions

**Purpose:** Provide essential functions needed during initialization.

**Exports:**
- `is_debug()` - Check if debug mode enabled (ZSH_DEBUG=1 or DEBUG=1)
- `source_zsh_dir()` - Source all .zsh files in directory

**Usage:**
```zsh
source_zsh_dir "$ZAPPDIR"  # Load all app configs
if is_debug; then
    print "Debug mode active"
fi
```

### 5. `inc/xdg.zsh` - XDG Base Directories

**Purpose:** Set XDG Base Directory Specification variables.

**Exports:**
```zsh
XDG_CONFIG_HOME=$HOME/.config
XDG_CACHE_HOME=$HOME/.local/cache
XDG_BIN_HOME=$HOME/.local/bin
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state
XDG_RUNTIME_DIR=$HOME/.xdg
# User directories
XDG_DESKTOP_DIR, XDG_DOCUMENTS_DIR, XDG_DOWNLOAD_DIR, etc.
```

### 6. `inc/folders.zsh` - User Folder Paths

**Purpose:** Set user folder path variables.

**Exports:**
```zsh
TMP, TEMP, TEMPDIR, TMPDIR  # Temporary directories
BINDIR                      # ~/bin
LIBDIR                      # ~/lib
DLDIR                       # ~/Downloads
DOCDIR                      # ~/Documents
CACHEDIR                    # ~/.cache
VENVDIR                     # ~/.venv
```

### 7. `inc/variables.zsh` - Environment Variables

**Purpose:** Set general environment variables.

**Exports:**
```zsh
# Editors
EDITOR='nvim', VISUAL='code', PAGER='less'

# Logging (for custom scripts)
LOG_SHOW_ICONS=1   # Show icons in log output
LOG_COLOR_TEXTS=1  # Colorize log text
LOG_EMOJI_ICONS=0  # Use emoji (0) or text (1) icons
```

### 8. `inc/colors.zsh` - ANSI Color Codes

**Purpose:** Define ANSI color code variables for terminal output.

**Exports:**
```zsh
# Basic colors
r, g, y, b, p, c, w  # red, green, yellow, blue, purple, cyan, white

# Bright colors
br, bg, by, bb, bp, bc, bw

# Reset
x  # Reset to default
```

**Usage:**
```zsh
print "${g}Success${x}"  # Green text
print "${r}Error${x}"    # Red text
```

### 9. `inc/icons.zsh` - Icon/Glyph Exports

**Purpose:** Define icon/glyph variables for consistent visual output.

**Exports:**
```zsh
ICO_BELL   # 🔔
ICO_DEBUG  # 👉
ICO_ERROR  # ⛔
ICO_INFO   # 👍
ICO_MSG    # 💬
ICO_OK     # ✅
ICO_UL     # •
ICO_WARN   # ⚠️
```

### 10. `inc/editors.zsh` - Editor Configuration

**Purpose:** Set editor and pager variables.

**Exports:**
```zsh
EDITOR='nvim'
VISUAL='code'
PAGER='less'
```

**Note:** Variables are exported unconditionally for performance. If the tool is missing, commands using it will error, which is expected behavior.

### 11. `inc/history.zsh` - History Configuration

**Purpose:** Configure command history settings and options.

**Exports:**
```zsh
HISTFILE=$ZDOTDIR/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
```

**Options Set:**
- `append_history` - Append to history file
- `extended_history` - Save timestamps
- `hist_expire_dups_first` - Delete duplicates first when HISTSIZE exceeded
- `hist_ignore_dups` - Ignore consecutive duplicates
- `hist_ignore_all_dups` - Delete old entry if new is duplicate
- `hist_find_no_dups` - Don't display previously found lines
- `hist_ignore_space` - Don't record lines starting with space
- `hist_save_no_dups` - Don't write duplicates to history file
- `hist_verify` - Show command before running history expansion
- `share_history` - Share history between all sessions

### 12. `inc/prompt.zsh` - Fallback Prompt

**Purpose:** Set fallback prompt (will be overridden by Oh My Posh if configured).

**Exports:**
```zsh
PS1="[%F{cyan}%n%f@%F{green}%m%f:%F{yellow}%~%f]$ "
```

### 13. `inc/path.zsh` - PATH Configuration

**Purpose:** Build PATH with platform-specific directories.

**Features:**
- Adds common paths: `$BINDIR`, `~/.local/bin`, `/usr/local/bin`
- macOS-specific: `/opt/homebrew/bin`, VSCode path
- Linux-specific: linuxbrew paths, `/snap/bin`
- Removes duplicates and non-existent directories

### 14. `inc/hashdirs.zsh` - Named Directories

**Purpose:** Create directory shortcuts using zsh hash feature.

**Exports:**
```zsh
hash -d bin=$BINDIR
hash -d conf=$CONFDIR
hash -d gh=$GHDIR
hash -d zsh=$ZDOTDIR
# Usage: cd ~zsh, ls ~gh
```

### 15. `inc/aliases.zsh` - Aliases

**Purpose:** Define command aliases with dependency checks.

**Categories:**
- Global aliases: `alias -g G='| grep'`
- Common aliases: `cls`, `reload`, `myip`, `ds`
- Application-specific (only if installed): bat, brew, eza, git, nvim, zoxide, etc.

### 16. `inc/locales.zsh` - Locale Settings

**Purpose:** Configure language and locale settings.

**Features:**
- English language (`LANG=en_US.UTF-8`)
- Polish locale for formatting (`LC_*=pl_PL.UTF-8`)
- Auto-generation of locales on Debian-based systems

### 17. `lib/` - Helper Library

**Purpose:** Fast, frequently-used utility functions loaded in `.zshenv`.

**Categories:**

#### `lib/files.zsh` - File System Tests
```zsh
is_file PATH        # True if regular file
is_dir PATH         # True if directory
is_link PATH        # True if symbolic link
is_exists PATH      # True if path exists (any type)
is_hardlink PATH    # True if hard link (link count > 1)
is_block_device PATH
is_char_device PATH
is_pipe PATH
is_socket PATH
```

#### `lib/system.zsh` - OS Detection & Info
```zsh
is_debian           # True if pure Debian
is_debian_based     # True if Debian-based (Ubuntu, Mint, etc.)
is_ubuntu           # True if Ubuntu
is_macos            # True if macOS
is_linux            # True if Linux
os_name             # Return OS name string
os_version          # Return OS version
os_codename         # Return codename (Sequoia, Bookworm, etc.)
os_icon             # Return Nerd Font icon
```

#### `lib/strings.zsh` - String Manipulation
```zsh
get_version STRING  # Extract version number from string
                    # Example: get_version "zsh 5.9" → "5.9"
```

#### `lib/shell.zsh` - Shell Info
```zsh
shell_ver           # Get zsh version number
```

#### `lib/varia.zsh` - Miscellaneous Utilities
```zsh
is_debug            # True if ZSH_DEBUG=1 or DEBUG=1
etime CMD [ARGS]    # Measure command execution time
is_installed CMD... # True if all commands exist
try_source FILE [CALLER] # Source file with error handling
```

#### `lib/plugins.zsh` - Plugin Management

Lightweight plugin system without Oh-My-Zsh dependency. Plugins are git repositories cloned to `$ZPLUGDIR/<name>/` with wrapper files for configuration.

**Architecture:**
```
plugins/
├── f-sy-h.zsh       ← Wrapper file (versioned, your config)
└── f-sy-h/          ← Git clone (in .gitignore)
    ├── *.zsh
    └── *.zsh.zwc    ← Compiled for speed
```

**Functions:**

| Function | Description |
|----------|-------------|
| `install_plugin <name> <repo>` | Clone plugin from GitHub or URL |
| `update_plugin <name>` | Update plugin (git pull + recompile) |
| `update_plugins` | Update all installed plugins |
| `remove_plugin <name>` | Remove plugin |
| `load_plugin <name>` | Load plugin (compile if needed + source) |
| `compile_plugin <name>` | Compile all .zsh files in plugin |
| `compile_plugins` | Compile all installed plugins |
| `clean_plugin <name>` | Remove .zwc files from plugin |
| `clean_plugins` | Remove .zwc files from all plugins |
| `is_plugin_loaded <name>` | Check if plugin is loaded |
| `is_plugin_installed <name>` | Check if plugin is installed |
| `list_plugins` | List installed plugins with status |

**Usage:**
```zsh
# Install a plugin (GitHub shorthand or full URL)
install_plugin f-sy-h z-shell/F-Sy-H
install_plugin f-sy-h https://github.com/z-shell/F-Sy-H

# Update all plugins
update_plugins

# Check status
list_plugins
```

**Plugin wrapper example (`plugins/f-sy-h.zsh`):**
```zsh
#!/bin/zsh
zfile_track_start ${0:A}

# Configuration BEFORE loading (plugin reads these)
typeset -gA FAST_HIGHLIGHT
FAST_HIGHLIGHT[git-hierarchical]=1

# Load plugin
load_plugin f-sy-h

# Configuration AFTER loading (uses plugin functions)
fast-theme XDG:catppuccin-mocha 2>/dev/null

zfile_track_end ${0:A}
```

**Compilation:**
- Plugins are automatically compiled to `.zwc` bytecode for ~30-40% faster loading
- Compilation happens automatically on `install_plugin`, `update_plugin`, and `load_plugin`
- `.zwc` files are stored alongside `.zsh` files (inside plugin directories)
- Plugin directories are in `.gitignore`, so `.zwc` files are not versioned

### 18. `apps/` - Application Integrations

**Purpose:** Configure external tools and applications. Loaded last in `.zshrc`.

**Naming Convention:**
- `apps/{tool}.zsh` - regular app config
- `apps/_{tool}.zsh` - prefixed with `_` to load first (alphabetical order)

**Current Apps:**
| File | Purpose |
|------|---------|
| `acme.zsh` | ACME.sh SSL certificates |
| `bat.zsh` | bat (cat replacement) |
| `brew.zsh` | Homebrew |
| `fzf.zsh` | fzf fuzzy finder |
| `git.zsh` | GitHub directories |
| `omp.zsh` | Oh My Posh prompt |
| `python.zsh` | Python virtual environment |
| `rust.zsh` | Rust/Cargo environment |
| `ssh.zsh` | SSH configuration |
| `thefuck.zsh` | thefuck (lazy loaded) |
| `yazi.zsh` | yazi file manager |
| `zoxide.zsh` | zoxide (z command) |

**Template Structure:**
```zsh
#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# {Tool Name} configuration

if is_installed {tool}; then
    # Configuration here
fi

# shell files tracking - keep at the end
zfile_track_end ${0:A}
```

### 19. `plugins/` - Zsh Plugins

**Purpose:** Zsh plugins managed without Oh-My-Zsh. Each plugin has a wrapper file for configuration.

**Structure:**
- `plugins/<name>.zsh` - Wrapper file (versioned in git)
- `plugins/<name>/` - Plugin repository (git clone, in `.gitignore`)

**Current Plugins:**
| Wrapper | Plugin | Description |
|---------|--------|-------------|
| `f-sy-h.zsh` | [F-Sy-H](https://github.com/z-shell/F-Sy-H) | Feature-rich syntax highlighting |

**Why no Oh-My-Zsh?**
- Faster startup (OMZ loads many unused features)
- Simpler dependencies
- Full control over what gets loaded
- Automatic `.zwc` compilation for speed

**Adding a new plugin:**

1. Install: `install_plugin <name> <github-user/repo>`
2. Create wrapper: `plugins/<name>.zsh`
3. In wrapper, call `load_plugin <name>` and add any configuration

**Wrapper template:**
```zsh
#!/bin/zsh
zfile_track_start ${0:A}

# Plugin Name - short description
# https://github.com/user/repo

# Pre-load configuration (optional)
# export PLUGIN_VAR=value

load_plugin <name>

# Post-load configuration (optional)
# plugin_command --setup

zfile_track_end ${0:A}
```

### 20. `functions/` - Autoloaded Functions

**Purpose:** Complex user functions that are autoloaded on demand.

**Current Functions:**
| Function | Purpose |
|----------|---------|
| `htime` | Convert seconds to human-readable time |
| `lanip` | Get local IP address |
| `wanip` | Get public IP address |
| `logininfo` | Display login information |
| `sysinfo` | Display system information |
| `uptimeh` | Get uptime in human format |
| `zfiles` | Show loaded files report (supports -b flag for bar visualization) |

### 21. `.zshrc` - Interactive Shell

**Purpose:** Set up interactive shell features.

**Flow:**
```
.zshrc
  → inc/history.zsh (history configuration)
  → inc/colors.zsh (color codes)
  → inc/icons.zsh (icons/glyphs)
  → inc/prompt.zsh (fallback prompt)
  → inc/editors.zsh (editor variables)
  → autoload zmv, colors
  → autoload functions/*
  → inc/aliases.zsh
  → apps/*.zsh (all apps)
  → plugins/*.zsh (all plugin wrappers)
  → inc/hashdirs.zsh
```

### 22. `.zlogin` - Post-Login

**Purpose:** Actions after login shell initialization.

**Responsibilities:**
- Clean up temporary variables
- Display system info (if `ZSH_SYS_INFO=1`)
- Display login info (if `ZSH_LOGIN_INFO=1`)
- Calculate total load time
- Cleanup tracking variables

## Naming Conventions

### Function Names

**Test/Check Functions:**
- Prefix: `is_`
- Return: 0 (true) or 1 (false)
- Examples: `is_file`, `is_macos`, `is_installed`

**Info Functions:**
- Suffix: `_name`, `_version`, `_icon`, etc.
- Return: string via `print`
- Examples: `os_name`, `shell_ver`, `os_icon`

**Action Functions:**
- Verb prefix: `get_`, `try_`
- Examples: `get_version`, `try_source`

**Utility Functions:**
- Short, descriptive names
- Examples: `etime`, `sysinfo`

### Variable Names

**Environment Variables:**
- Uppercase
- Descriptive
- Examples: `ZDOTDIR`, `ZINCDIR`, `HOMEBREW_PREFIX`, `OMP_THEME`

**Local Variables:**
- Lowercase
- Snake_case for multi-word
- Examples: `filepath`, `file_name`, `start_time`

**Color Variables:**
- Single letter for basic colors: `r`, `g`, `y`, `b`, `p`, `c`, `w`
- Prefix `b` for bright: `br`, `bg`, `by`, `bb`, `bp`, `bc`, `bw`
- Reset: `x`

**Icon Variables:**
- Prefix: `ICO_`
- Uppercase
- Examples: `ICO_OK`, `ICO_ERROR`, `ICO_WARN`

### File Names

**Library Files:** `{category}.zsh`
- Examples: `files.zsh`, `system.zsh`, `strings.zsh`

**App Files:** `{tool}.zsh` or `_{tool}.zsh` (for priority loading)
- Examples: `brew.zsh`, `fzf.zsh`, `omp.zsh`

**Plugin Wrappers:** `{plugin-name}.zsh`
- Examples: `f-sy-h.zsh`, `zsh-autosuggestions.zsh`

**Include Files:** `{purpose}.zsh`
- Examples: `zsh.zsh`, `bootstrap.zsh`, `colors.zsh`, `folders.zsh`, `history.zsh`, `path.zsh`, `aliases.zsh`

**Functions:** No extension, lowercase
- Examples: `sysinfo`, `logininfo`, `zfiles`

## File Tracking System

### Purpose

Track which files are loaded and measure their loading time for performance optimization.

### Global Variables

```zsh
typeset -A ZFILES          # filepath → status (0=loading, 1=loaded)
typeset -A ZFILES_TIME     # filepath → load time in ms
typeset -A ZFILES_START    # filepath → start time (EPOCHREALTIME)
typeset -a ZFILES_ORDER    # array of filepaths in load order
```

### Tracking Functions

```zsh
zfile_track_start ${0:A}   # Start tracking (top of file)
zfile_track_end ${0:A}     # End tracking (bottom of file)
```

### Debug Output

When `ZSH_DEBUG=1`:
```
✅ bootstrap.zsh sourced in 1.89ms
✅ xdg.zsh sourced in 0.45ms
✅ files.zsh sourced in 0.67ms
...
```

### Usage Pattern

**Every sourced file must have:**
```zsh
#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# ... file content ...

# shell files tracking - keep at the end
zfile_track_end ${0:A}
```

**Special case - main files:**
```zsh
# In .zshrc, .zlogin, etc:
zfile_track_start "$ZDOTDIR/.zshrc"
# ... content ...
zfile_track_end "$ZDOTDIR/.zshrc"
```

### Reporting

Use `zfiles` function to see full report:
```zsh
❯ zfiles
   err file                     time     dir
 1. ✓ .zshenv               12.45 ms  zsh
 2. ✓   zfiles.zsh           0.23 ms  inc
 3. ✓   zsh.zsh              1.12 ms  inc
 4. ✓   bootstrap.zsh        0.34 ms  inc
 5. ✓   xdg.zsh              0.45 ms  inc
 6. ✓   folders.zsh          0.21 ms  inc
 7. ✓   variables.zsh        0.32 ms  inc
 8. ✓   files.zsh            0.67 ms  lib
 9. ✓   system.zsh           1.23 ms  lib
10. ✓   strings.zsh          0.45 ms  lib
11. ✓   shell.zsh            0.34 ms  lib
12. ✓   varia.zsh            0.78 ms  lib
13. ✓   path.zsh             0.56 ms  inc
14. ✓   locales.zsh          0.89 ms  inc
15. ✓ .zshrc                 8.91 ms  zsh
16. ✓   history.zsh          0.43 ms  inc
17. ✓   colors.zsh           0.19 ms  inc
18. ✓   icons.zsh            0.15 ms  inc
19. ✓   prompt.zsh           0.11 ms  inc
20. ✓   editors.zsh          0.13 ms  inc
21. ✓   aliases.zsh          2.45 ms  inc
22. ✓   brew.zsh             3.21 ms  apps
23. ✓   omp.zsh             45.67 ms  apps
24. ✓   hashdirs.zsh         0.12 ms  inc
                            80.39 ms  total
```

**With bar visualization (`zfiles -b`):**
```zsh
❯ zfiles -b
Zsh Shell Configuration Load Time Report
 1. ✓ .zshenv               12.45 ms  zsh   ┝━━
 2. ✓   zfiles.zsh           0.23 ms  inc   │
 3. ✓   zsh.zsh              1.12 ms  inc   ┝━
...
```

**Color coding:**
- Green: < 1ms
- White: 1-5ms
- Yellow: 5-10ms
- Red: > 10ms

## Development Guidelines

### Adding New Helper Functions

1. **Choose appropriate file:**
   - File tests → `lib/files.zsh`
   - OS detection → `lib/system.zsh`
   - String operations → `lib/strings.zsh`
   - Shell info → `lib/shell.zsh`
   - General utilities → `lib/varia.zsh`

2. **Follow naming conventions:**
   - Tests: `is_*` → return 0/1
   - Info: `*_name`, `*_version` → print string
   - Actions: `get_*`, `try_*`

3. **Follow zsh coding style** - see [ZSH.md](ZSH.md)

4. **Add tracking:**
   ```zsh
   #!/bin/zsh
   # Shell files tracking - keep at the top
   zfile_track_start ${0:A}
   
   # Your functions here
   
   # shell files tracking - keep at the end
   zfile_track_end ${0:A}
   ```

5. **Test thoroughly:**
   ```zsh
   is_file /etc/hosts     # should return 0
   is_file /etc           # should return 1
   is_file /nonexistent   # should return 1
   ```

### Adding New App Integration

1. **Create file:** `apps/{tool}.zsh`

2. **Use template:**
   ```zsh
   #!/bin/zsh
   # Shell files tracking - keep at the top
   zfile_track_start ${0:A}
   
   # {Tool Name} configuration
   
   if is_installed {tool}; then
       # Configuration here
   fi
   
   # shell files tracking - keep at the end
   zfile_track_end ${0:A}
   ```

3. **For priority loading:** Use `_` prefix (e.g., `_brew.zsh` loads before `fzf.zsh`)

4. **Check installation:**
   ```zsh
   if is_installed mytool; then
       # Only configure if available
   fi
   ```

5. **Use lazy loading for slow tools:**
   ```zsh
   # Instead of:
   eval "$(slowtool init zsh)"
   
   # Use:
   slowtool() {
       unfunction slowtool
       eval "$(command slowtool init zsh)"
       slowtool "$@"
   }
   ```

### Adding New Plugin

1. **Install the plugin:**
   ```zsh
   install_plugin <name> <github-user/repo>
   # Example:
   install_plugin zsh-autosuggestions zsh-users/zsh-autosuggestions
   ```

2. **Create wrapper file:** `plugins/<name>.zsh`
   ```zsh
   #!/bin/zsh
   zfile_track_start ${0:A}

   # Plugin Name - short description
   # https://github.com/user/repo

   # Pre-load configuration (if plugin reads env vars at load time)
   # export PLUGIN_OPTION=value

   load_plugin <name>

   # Post-load configuration (if plugin provides setup commands)
   # plugin_setup_command

   zfile_track_end ${0:A}
   ```

3. **Test:**
   ```zsh
   source ~/.zshrc
   list_plugins  # should show new plugin as "loaded"
   ```

4. **Update `.gitignore`** (if not already):
   ```gitignore
   /plugins/*/
   ```

**Notes:**
- Plugin directories (`plugins/<name>/`) are git clones and should be in `.gitignore`
- Only wrapper files (`plugins/<name>.zsh`) are versioned
- Plugins are automatically compiled to `.zwc` for faster loading
- Use `update_plugins` to update all plugins at once

### Adding New User Function

1. **Create file:** `functions/{name}` (no extension)

2. **Write function body directly** (no function declaration needed):
   ```zsh
   # functions/myinfo
   local hostname=$(hostname)
   local os=$(os_name)
   
   print "Host: $hostname"
   print "OS: $os"
   ```

3. **Available in autoloaded functions:**
   - All `lib/*` functions
   - All environment variables
   - Color variables (if interactive)

4. **Test:**
   ```zsh
   # In new shell
   myinfo  # should work automatically
   ```

### Adding New Include File

1. **Choose appropriate category:**
   - Core config → `inc/zsh.zsh`
   - Colors → `inc/colors.zsh`
   - Icons → `inc/icons.zsh`
   - User folders → `inc/folders.zsh`
   - History → `inc/history.zsh`
   - Editors → `inc/editors.zsh`
   - General env vars → `inc/variables.zsh`
   - New category → create new `inc/{purpose}.zsh`

2. **Create file:** `inc/{purpose}.zsh`

3. **Add tracking:**
   ```zsh
   #!/bin/zsh
   # Shell files tracking - keep at the top
   zfile_track_start ${0:A}

   # Content here

   # shell files tracking - keep at the end
   zfile_track_end ${0:A}
   ```

4. **Source it** in appropriate location (`.zshenv` or `.zshrc`)

**Note:** The configuration follows a separation of concerns principle:
- Each file handles a single responsibility
- Related variables are grouped together
- Files are kept small and focused
- This makes it easier to find, modify, and maintain configuration

### Performance Optimization

1. **Measure first:**
   ```zsh
   ZSH_DEBUG=1 zsh -lic "exit"
   # or
   zfiles
   ```

2. **Identify slow files:**
   - Look for times > 10ms
   - Check heavy initialization (eval, external commands)

3. **Optimize strategies:**
   - Lazy load heavy apps
   - Cache results
   - Avoid unnecessary forks
   - Use zsh builtins

4. **Lazy loading example:**
   ```zsh
   # See apps/thefuck.zsh for example
   fuck() {
       unfunction fuck
       eval $(thefuck --alias)
       fuck "$@"
   }
   ```

### Debugging

1. **Enable debug mode:**
   ```zsh
   export ZSH_DEBUG=1         # Enable general debug output
   export ZSH_ZFILE_DEBUG=1   # Enable file tracking debug messages
   source ~/.zshenv
   ```

2. **Check specific file:**
   ```zsh
   zsh -n lib/files.zsh  # syntax check
   source lib/files.zsh  # test loading
   ```

3. **Test functions:**
   ```zsh
   is_file /etc/hosts && print "OK" || print "FAIL"
   print $(os_name)
   ```

4. **Common issues:**
   - Missing tracking calls
   - Wrong variable scope (local vs global)
   - PATH not set correctly
   - Function name conflicts

## Examples & Use Cases

### Example 1: OS-Specific Configuration

```zsh
# apps/mytool.zsh
#!/bin/zsh
zfile_track_start ${0:A}

if is_installed mytool; then
    if is_macos; then
        export MYTOOL_PATH=/opt/homebrew/opt/mytool
    elif is_debian_based; then
        export MYTOOL_PATH=/usr/local/mytool
    fi
    
    export PATH=$MYTOOL_PATH/bin:$PATH
fi

zfile_track_end ${0:A}
```

### Example 2: Conditional Feature Loading

```zsh
# Using try_source for optional files
try_source "$HOME/.secrets" "${0:t}"
try_source "$HOME/.local.zsh" "${0:t}"
```

### Example 3: Custom Info Function

```zsh
# functions/devinfo
local python_ver node_ver git_ver

python_ver=$(python3 --version 2>&1 | get_version)
node_ver=$(node --version 2>&1 | get_version)
git_ver=$(git --version 2>&1 | get_version)

print "Development Environment:"
print "  Python: ${y}${python_ver}${x}"
print "  Node.js: ${y}${node_ver}${x}"
print "  Git: ${y}${git_ver}${x}"
```

### Example 4: Performance Measurement

```zsh
# Measure startup time
$ time zsh -lic "exit"
zsh -lic "exit"  0.08s user 0.04s system 93% cpu 0.134 total

# Detailed breakdown
$ ZSH_DEBUG=1 zsh -lic "exit"
✅ bootstrap.zsh sourced in 1.89ms
✅ xdg.zsh sourced in 0.45ms
...

# View full report
$ zfiles
```

### Example 5: Lazy Loading Pattern

```zsh
# apps/heavytool.zsh
if is_installed heavytool; then
    heavytool() {
        unfunction heavytool
        eval "$(command heavytool init zsh)"
        heavytool "$@"
    }
fi
```

### Example 6: Plugin with Configuration

```zsh
# plugins/zsh-autosuggestions.zsh
#!/bin/zsh
zfile_track_start ${0:A}

# zsh-autosuggestions - Fish-like autosuggestions
# https://github.com/zsh-users/zsh-autosuggestions

# Configuration before loading
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

load_plugin zsh-autosuggestions

# Keybinding after loading
bindkey '^[[Z' autosuggest-accept  # Shift+Tab to accept

zfile_track_end ${0:A}
```

## Best Practices Summary

### Do's ✅

- **Always** use tracking in sourced files
- **Always** check installation before configuring
- **Always** follow zsh coding style (see [ZSH.md](ZSH.md))
- **Always** test functions before committing
- Use `is_installed` before configuring tools
- Use `is_debug` for conditional logging
- Use named directories (`~zsh`, `~gh`, etc.)
- Keep functions small and focused
- Prefer builtins over external commands
- Use lazy loading for slow tools
- Use `load_plugin` for loading plugins (handles compilation)
- Keep plugin directories in `.gitignore`

### Don'ts ❌

- **Never** skip tracking in sourced files
- **Never** assume tools are installed
- Don't use global variables in functions unnecessarily
- Don't create dependencies between lib files
- Don't put heavy operations in `.zshenv`
- Don't use subshells when not needed
- Don't commit plugin directories (only wrappers)

*For zsh coding do's and don'ts, see [ZSH.md](ZSH.md)*

## Troubleshooting

### Shell Starts Slowly

1. Check load times: `zfiles`
2. Identify slow files (> 10ms)
3. Consider lazy loading heavy apps
4. Check for unnecessary external commands

### Function Not Found

1. Check if in `lib/` or `functions/`
2. For `functions/`: check `$fpath`
3. Verify file permissions (functions should be readable)
4. Start new shell: `exec zsh`

### Changes Not Applied

1. For `lib/` or `inc/`: `source ~/.zshenv`
2. For `apps/`: `source ~/.zshrc`
3. Or start new shell: `exec zsh`

### Syntax Errors

1. Check syntax: `zsh -n file.zsh`
2. Enable debug: `ZSH_DEBUG=1 source file.zsh`
3. Test in isolation: `source file.zsh`

---

## Future Enhancements

### Performance Goals

- Total startup time < 50ms
- Library load time < 10ms
- Individual file load < 5ms

### Maintenance Tasks

- Periodic review of `zfiles` output
- Remove unused app configurations
- Archive old functions
- Update documentation

## References

### Related Files

- User script library: `~/lib/`
- User binaries: `~/bin/`
- GitHub repositories: `~/GitHub/`
- Project configurations: `~/.config/`

### External Documentation

- Zsh manual: `man zshall`
- Parameter expansion: `man zshexpn`
- Builtin commands: `man zshbuiltins`
- Oh My Posh: https://ohmyposh.dev/

### Useful Commands

```zsh
# Show current configuration version
print $ZSH_CONFIG_VERSION

# Show all loaded files
zfiles

# Show all loaded files with bar visualization
zfiles -b

# Show system info
sysinfo

# Show login info
logininfo

# Debug mode
ZSH_DEBUG=1 zsh -lic "exit"

# File tracking debug mode
ZSH_ZFILE_DEBUG=1 zsh -lic "exit"

# Measure startup
time zsh -lic "exit"
```

