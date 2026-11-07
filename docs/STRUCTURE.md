# zconfig: Directory Structure

Part of [zconfig](../README.md) documentation.

```
~/.config/zsh/
├── .zshenv              # Entry point (always sourced first)
├── .zprofile            # Login shell initialization
├── .zshrc               # Interactive shell setup
├── .zlogin              # Post-login actions
├── .zlogout             # Logout cleanup
├── .zsh_history         # Command history (ignored)
├── .zsh_sessions/       # Zsh sessions (ignored)
├── install.sh           # Installer (bash, the only non-zsh code)
├── README.md            # Project overview
├── CLAUDE.md            # Project context for Claude Code
│
├── docs/                # All other documentation
│
├── inc/                 # Core configuration modules
│   ├── env.zsh             # Core configuration variables
│   ├── zfiles.zsh          # File tracking infrastructure
│   ├── modules.zsh         # Zsh module loading (zmodload)
│   ├── xdg.zsh             # XDG Base Directories
│   ├── colors.zsh          # ANSI color codes
│   ├── icons.zsh           # Icon/glyph exports
│   ├── options.zsh         # Shell options (setopt/unsetopt)
│   ├── prompt.zsh          # Fallback prompt
│   ├── path.zsh            # PATH configuration
│   ├── hashdirs.zsh        # Named directory hashes
│   ├── aliases.zsh         # Aliases
│   ├── keys.zsh            # Key bindings
│   ├── completion.zsh      # Completion configuration
│   ├── locales.zsh         # Locale settings
│   └── plugins.zsh         # Plugin loading
│
├── lib/                 # Helper function library (interactive shells only)
│   ├── apps.zsh            # Package-manager helpers for zapp
│   ├── archive.zsh         # Archive extraction/compression
│   ├── arrays.zsh          # Array utilities
│   ├── clipboard.zsh       # Clipboard operations
│   ├── cmdinfo.zsh         # Command information (zinfo, zwhere, zver)
│   ├── compile.zsh         # Bytecode compilation
│   ├── cwg.zsh             # Random number generator
│   ├── date.zsh            # Date/time functions
│   ├── files.zsh           # File/path tests
│   ├── fn.zsh              # Option/argument parsing for functions/
│   ├── git.zsh             # Git repository helpers (zgit)
│   ├── hardware.zsh        # Hardware info
│   ├── math.zsh            # Math utilities
│   ├── network.zsh         # Network utilities
│   ├── path.zsh            # PATH manipulation
│   ├── plugins.zsh         # Plugin management
│   ├── print.zsh           # Formatted output
│   ├── shell.zsh           # Shell info functions
│   ├── strings.zsh         # String manipulation
│   ├── system.zsh          # OS detection & info
│   └── varia.zsh           # Miscellaneous helpers
│
├── apps/                # Application integrations, one file per tool
│
├── functions/           # Autoloaded user commands (see docs/FUNCTIONS.md)
│
├── recipes/             # Application recipes for zapp (see docs/ZAPP.md)
│
├── plugins/             # Zsh plugins
│   ├── <name>.zsh          # Plugin wrapper or standalone plugin (versioned)
│   └── <name>/             # Plugin repository (git clone, ignored)
│
├── tests/               # Unit tests (zsh tests/run.zsh)
│   ├── run.zsh             # Test runner and assertions
│   └── *.test.zsh          # Test files
│
├── scripts/             # Maintenance scripts
│   └── functions-md.zsh    # Generate docs/FUNCTIONS.md
│
├── .github/workflows/   # CI: syntax, tests, FUNCTIONS.md check
│
└── cache/               # Runtime cache (ignored)
```

## Installation Layout

The only zconfig file in the home directory is the symlink `~/.zshenv` → `~/.config/zsh/.zshenv`. All other files must be in the installation directory, `~/.config/zsh`.

Zsh always reads `~/.zshenv` first. `inc/env.zsh` then sets `ZDOTDIR` to the installation directory, so zsh reads the remaining startup files from there.

## Startup Order

| Step | File | Loaded for | What it does |
|------|------|------------|--------------|
| 1 | `.zshenv` | Every shell | Sources `inc/`: `zfiles`, `env`, `modules`, `xdg`, `path`, `locales` |
| 2 | `.zprofile` | Login shells | Placeholder for login initialization |
| 3 | `.zshrc` | Interactive shells | See below |
| 4 | `.zlogin` | Login shells | Cleanup, optional system and login info |
| 5 | `.zlogout` | Login shells, on exit | Placeholder for logout cleanup |

`.zshrc` runs these steps in order:

1. `inc/`: `options`, `colors`, `completion`, `icons`, `prompt`
2. Zsh shell functions (`zargs`, `zmv`)
3. `lib/`
4. `functions/`
5. `inc/`: `aliases`, `keys`
6. `apps/`
7. `inc/`: `hashdirs`, `plugins`
8. Auto-compilation of changed files

Most steps can be turned off with `ZSH_LOAD_*` variables (see [README.md](../README.md#configuration-variables)).

## Loading Mechanisms

| Location | Mechanism | A new file is |
|----------|-----------|---------------|
| `inc/` | Explicit `source` in `.zshenv` or `.zshrc` | Loaded after adding it there |
| `lib/` | `source_zsh_dir`: every `*.zsh`, in alphabetical order | Loaded automatically |
| `apps/` | `source_zsh_dir`: every `*.zsh`, in alphabetical order | Loaded automatically |
| `functions/` | `autoload -Uz`: every file not starting with `_` or `.` | Loaded automatically, on first use |
| `plugins/` | Explicit loader call in `inc/plugins.zsh` | Loaded after adding it there |

`apps/` files are per-application configuration, and each one exits at once if its application is not installed. An app must not depend on another app: `PATH`, including Homebrew, is already set by `inc/path.zsh`.

`source_zsh_dir` is first defined in `inc/zfiles.zsh`, because it is needed before `lib/` exists in the shell; `lib/varia.zsh` then replaces it with the full version.
