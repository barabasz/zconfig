# zconfig: Directory Structure

Part of [zconfig](../README.md) documentation.

```
~/.config/zsh/
├── .zshenv              # Entry point (always sourced first)
├── .zprofile            # Login shell initialization
├── .zshrc               # Interactive shell setup
├── .zlogin              # Post-login actions
├── .zlogout             # Logout cleanup
├── .zsh_history         # Command history
│
├── inc/                 # Core configuration modules
│   ├── env.zsh             # Core configuration variables
│   ├── zfiles.zsh          # File tracking infrastructure
│   ├── modules.zsh         # Zsh module loading (zmodload)
│   ├── xdg.zsh             # XDG Base Directories
│   ├── colors.zsh          # ANSI color codes
│   ├── icons.zsh           # Icon/glyph exports
│   ├── history.zsh         # History options
│   ├── prompt.zsh          # Fallback prompt
│   ├── path.zsh            # PATH configuration
│   ├── hashdirs.zsh        # Named directory hashes
│   ├── aliases.zsh         # Aliases
│   ├── keys.zsh            # Key bindings
│   ├── completion.zsh      # Completion configuration
│   ├── locales.zsh         # Locale settings
│   └── plugins.zsh         # Plugin loading
│
├── lib/                 # Helper function library
│   ├── archive.zsh         # Archive extraction/compression
│   ├── arrays.zsh          # Array utilities
│   ├── clipboard.zsh       # Clipboard operations
│   ├── compile.zsh         # Bytecode compilation
│   ├── cwg.zsh             # Random number generator
│   ├── date.zsh            # Date/time functions
│   ├── files.zsh           # File/path tests
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
├── apps/                # Application integrations
│   ├── _brew.zsh           # Homebrew (priority load)
│   ├── omp.zsh             # Oh My Posh
│   ├── fzf.zsh             # Fuzzy finder
│   └── ...                 # Other app configs
│
├── functions/           # Autoloaded user functions
│   ├── zhelp               # Display help and documentation
│   ├── zdoc                # Browse and view docs
│   ├── zman                # List all functions
│   ├── zinfo               # Function help/info
│   ├── zconfig             # Edit config files
│   ├── zfiles              # File tracking report
│   ├── zupdate             # Update zconfig
│   ├── zgit                # Git bulk operations
│   ├── sysinfo             # System information
│   ├── logininfo           # Login information
│   ├── cpuinfo             # CPU information
│   ├── meminfo             # Memory information
│   ├── diskinfo            # Disk information
│   ├── lanip               # Local IP address
│   ├── wanip               # Public IP address
│   ├── mdig                # Multi-DNS query
│   ├── sslinfo             # SSL certificate info
│   ├── urlinfo             # URL information
│   ├── ttfb                # Time To First Byte
│   ├── execs               # Execute with spinner
│   ├── collatz             # Collatz sequences
│   ├── primes              # Prime numbers
│   ├── getrandom           # Random number generator
│   └── ...                 # Other functions
│
├── plugins/             # Zsh plugins
│   ├── <name>.zsh          # Plugin wrapper (versioned)
│   └── <name>/             # Plugin repository (git clone, ignored)
│
└── cache/               # Runtime cache
    └── sessions/           # Zsh sessions
```
