# zsh-config: Directory Structure

Part of [zsh-config](../README.md) documentation.

```
~/.config/zsh/
├── .zshenv              # Entry point (always sourced first)
├── .zprofile            # Login shell initialization
├── .zshrc               # Interactive shell setup
├── .zlogin              # Post-login actions
├── .zlogout             # Logout cleanup
├── .zsh_history         # Command history
├── .zconfig             # Core configuration variables
│
├── inc/                 # Core configuration modules
│   ├── zfiles.zsh          # File tracking infrastructure
│   ├── modules.zsh         # Zsh module loading (zmodload)
│   ├── functions.zsh       # Zsh autoloaded functions (autoload)
│   ├── bootstrap.zsh       # Bootstrap functions
│   ├── xdg.zsh             # XDG Base Directories
│   ├── folders.zsh         # User folder paths
│   ├── variables.zsh       # Environment variables
│   ├── colors.zsh          # ANSI color codes
│   ├── icons.zsh           # Icon/glyph exports
│   ├── editors.zsh         # Editor configuration
│   ├── history.zsh         # History options
│   ├── prompt.zsh          # Fallback prompt
│   ├── path.zsh            # PATH configuration
│   ├── hashdirs.zsh        # Named directory hashes
│   ├── aliases.zsh         # Aliases
│   └── locales.zsh         # Locale settings
│
├── lib/                 # Helper function library
│   ├── compile.zsh         # Bytecode compilation
│   ├── files.zsh           # File/path tests
│   ├── system.zsh          # OS detection & info
│   ├── strings.zsh         # String manipulation
│   ├── shell.zsh           # Shell info functions
│   ├── plugins.zsh         # Plugin management
│   ├── varia.zsh           # Miscellaneous helpers
│   └── ...                 # Other utility modules
│
├── apps/                # Application integrations
│   ├── brew.zsh            # Homebrew
│   ├── omp.zsh             # Oh My Posh
│   └── ...                 # Other app configs
│
├── functions/           # Autoloaded user functions
│   ├── sysinfo             # System information
│   ├── zfiles              # File tracking report
│   └── ...                 # Other functions
│
├── plugins/             # Zsh plugins
│   ├── <name>.zsh          # Plugin wrapper (versioned)
│   └── <name>/             # Plugin repository (git clone, ignored)
│
└── cache/               # Runtime cache
    └── sessions/           # Zsh sessions
```
