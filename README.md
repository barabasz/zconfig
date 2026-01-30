# zsh-config

A modular, performance-optimized zsh configuration focused on maintainability and fast startup times. The configuration is split across specialized directories with clear separation of concerns.

For installation instructions, see [INSTALL.md](docs/INSTALL.md).

## Documentation

| File | Description |
|------|-------------|
| [STRUCTURE.md](docs/STRUCTURE.md) | Directory structure |
| [GUIDELINES.md](docs/GUIDELINES.md) | Development guidelines |
| [NAMING.md](docs/NAMING.md) | Naming conventions |
| [ZSH.md](docs/ZSH.md) | Zsh coding style |
| [ZFILES.md](docs/ZFILES.md) | File tracking system |
| [EXAMPLES.md](docs/EXAMPLES.md) | Examples & use cases |
| [FUNCTIONS.md](docs/FUNCTIONS.md) | List of functions |

## Key Features

- File tracking system with performance monitoring (`zfiles` command)
- Modular library of helper functions (`lib/`)
- Lightweight plugin system (no Oh-My-Zsh dependency)
- Automatic bytecode compilation (`.zwc`) for faster loading
- Lazy loading for heavy applications
- Dynamic loading of all library and app files
- Autoloaded user functions (`functions/`)

## Philosophy

1. **Performance First** - Track loading times, lazy load heavy apps, minimize startup
2. **Modularity** - Each component in separate file with single responsibility
3. **Zsh-Native** - No bash compatibility, use zsh-specific features exclusively
4. **Explicit Over Implicit** - Clear naming conventions, documented behavior

## Directory Overview

```
~/.config/zsh/
├── .zshenv           # Entry point (always sourced first)
├── .zshrc            # Interactive shell setup
├── .zprofile         # Login shell initialization
├── .zlogin           # Post-login actions
├── zsh.env           # Core configuration variables
├── inc/              # Core configuration modules
├── lib/              # Helper function library
├── apps/             # Application integrations
├── functions/        # Autoloaded user functions
├── plugins/          # Zsh plugins (wrappers + git clones)
└── cache/            # Runtime cache
```

See [STRUCTURE.md](docs/STRUCTURE.md) for detailed structure.

## Core Components

### Entry Points

| File | Purpose |
|------|---------|
| `.zshenv` | Always sourced first; loads tracking, core config, lib/, PATH |
| `.zshrc` | Interactive shell; loads history, colors, aliases, apps, plugins |
| `.zprofile` | Login shell initialization |
| `.zlogin` | Post-login actions (cleanup, display system info) |

### Configuration Modules (`inc/`)

Core configuration split by responsibility. Each file handles one concern.

| File | Purpose |
|------|---------|
| `zfiles.zsh` | File tracking infrastructure |
| `modules.zsh` | Zsh module loading (`zmodload`) |
| `functions.zsh` | Zsh autoloaded functions (`autoload`) |
| `xdg.zsh` | XDG Base Directory variables |
| `folders.zsh` | User folder path variables |
| `colors.zsh` | ANSI color code variables |
| `icons.zsh` | Icon/glyph variables |
| `history.zsh` | History configuration and options |
| `prompt.zsh` | Fallback prompt |
| `path.zsh` | PATH configuration |
| `hashdirs.zsh` | Named directory hashes (`~zsh`, `~gh`, etc.) |
| `aliases.zsh` | Command aliases |
| `locales.zsh` | Locale settings |

### Helper Library (`lib/`)

Fast utility functions loaded in `.zshenv`. See individual files for available functions.

| File | Category |
|------|----------|
| `compile.zsh` | Bytecode compilation (`compile_zsh_config`, `compile_dir`, etc.) |
| `files.zsh` | File system tests (`is_file`, `is_dir`, `is_link`, etc.) |
| `system.zsh` | OS detection (`is_macos`, `is_linux`, `os_name`, etc.) |
| `strings.zsh` | String manipulation (`trim`, `lowercase`, `str_contains`, etc.) |
| `shell.zsh` | Shell info (`shell_ver`, `is_interactive`, `reload_shell`, etc.) |
| `plugins.zsh` | Plugin management (`install_plugin`, `load_plugin`, etc.) |
| `varia.zsh` | Miscellaneous (`is_debug`, `etime`, `is_installed`, `confirm`) |
| `print.zsh` | Print functions for formatted output |
| `path.zsh` | PATH manipulation |
| `arrays.zsh` | Array utilities |
| `date.zsh` | Date/time functions |
| `network.zsh` | Network utilities |

### Application Integrations (`apps/`)

External tool configurations. Loaded dynamically in `.zshrc`. Each file follows the pattern:

```zsh
#!/bin/zsh
zfile_track_start ${0:A}

if is_installed <tool>; then
    # Configuration here
fi

zfile_track_end ${0:A}
```

Use `_` prefix for priority loading (e.g., `_brew.zsh` loads before `fzf.zsh`).

### Plugins (`plugins/`)

Lightweight plugin system without Oh-My-Zsh. Each plugin has:
- `<name>.zsh` - Wrapper file (versioned, your configuration)
- `<name>/` - Git clone (in `.gitignore`, auto-compiled)

```zsh
# Install a plugin
install_plugin <name> <github-user/repo>

# Update all plugins
update_plugins

# List plugins
list_plugins
```

See `lib/plugins.zsh` for all available functions.

### User Functions (`functions/`)

Autoloaded functions available on-demand. No function declaration needed in files - just write the function body directly.

## Configuration Variables

All configuration variables are defined in `zsh.env` with sensible defaults. Override them by setting before shell startup (e.g., `ZSH_DEBUG=0 zsh`).

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_DEBUG` | 1 | Enable debug messages |
| `ZSH_ZFILE_DEBUG` | 0 | Enable file tracking debug messages |
| `ZSH_LOGIN_INFO` | 0 | Show login info on startup |
| `ZSH_SYS_INFO` | 0 | Show system info on startup |
| `ZSH_AUTOCOMPILE` | 1 | Auto-compile `.zsh` to `.zwc` bytecode |
| `ZSH_LOAD_LIB` | 1 | Load library files from `lib/` |
| `ZSH_LOAD_FUNCS` | 1 | Load functions from `functions/` |
| `ZSH_LOAD_APPS` | 1 | Load app configurations from `apps/` |
| `ZSH_LOAD_PLUGINS` | 1 | Load plugins from `plugins/` |
| `ZSH_PLUGINS_AUTOINSTALL` | 1 | Auto-install missing plugins |

**Examples:**
```zsh
# Minimal shell (no apps, no plugins)
ZSH_LOAD_APPS=0 ZSH_LOAD_PLUGINS=0 zsh

# Debug a plugin issue
ZSH_LOAD_PLUGINS=0 zsh

# Quiet mode (no debug output)
ZSH_DEBUG=0 zsh
```

## Bytecode Compilation

Zsh files are automatically compiled to `.zwc` bytecode for faster loading (~10% speedup).

**How it works:**
- On shell startup, `compile_zsh_config -q` checks all files in `lib/`, `inc/`, `apps/`
- Only changed files are recompiled (compares timestamps)
- Overhead: ~0.3ms (negligible)
- Zsh automatically uses `.zwc` when newer than `.zsh`
- Controlled by `ZSH_AUTOCOMPILE` variable

**After editing a file:**
1. First shell startup → uses `.zsh` (newer), then recompiles
2. Next shell startup → uses `.zwc` (faster)

**Manual commands:**
```zsh
compile_zsh_config      # Compile with output
compile_zsh_config -q   # Compile quietly
clean_zsh_config        # Remove all .zwc files
```

See `lib/compile.zsh` for all compilation functions.

## Best Practices

### Do's

- Always use tracking in sourced files (`zfile_track_start`/`zfile_track_end`)
- Check installation before configuring (`is_installed`)
- Follow zsh coding style (see [ZSH.md](docs/ZSH.md))
- Use `zparseopts` for parsing command-line options (not `case`/`getopts`)
- Use lazy loading for slow tools
- Use `load_plugin` for plugins (handles compilation)
- Keep plugin directories in `.gitignore`

### Don'ts

- Never skip tracking in sourced files
- Never assume tools are installed
- Don't use `case $1` or `getopts` for option parsing (use `zparseopts`)
- Don't put heavy operations in `.zshenv`
- Don't use subshells when not needed
- Don't commit plugin directories (only wrappers)

## Troubleshooting

### Shell Starts Slowly

1. Run `zfiles` to identify slow files (> 10ms)
2. Consider lazy loading heavy apps
3. Check for unnecessary external commands

### Function Not Found

1. Check if in `lib/` or `functions/`
2. For `functions/`: verify `$fpath` and file permissions
3. Start new shell: `exec zsh`

### Changes Not Applied

1. For `lib/` or `inc/`: `source ~/.zshenv`
2. For `apps/`: `source ~/.zshrc`
3. Or start new shell: `exec zsh`

## References

- Zsh manual: `man zshall`
- Parameter expansion: `man zshexpn`
- Builtin commands: `man zshbuiltins`
