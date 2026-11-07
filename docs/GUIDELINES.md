# zconfig: Development Guidelines

Part of [zconfig](../README.md) documentation. Project rules: how files are organized and how to add components.

See also:
- [ZSH.md](ZSH.md) - Zsh coding style and comments
- [FN.md](FN.md) - Function library for user-facing functions
- [NAMING.md](NAMING.md) - Naming conventions
- [EXAMPLES.md](EXAMPLES.md) - Code examples and common patterns

## Rules

- Write zsh only; `install.sh` is the only exception (see [ZSH.md](ZSH.md))
- Keep zconfig self-contained: it must work without any other repository, so handle unset `$GHDIR` and `$GHCONFDIR`
- Before writing a helper, check `lib/` (`zman`, [FUNCTIONS.md](FUNCTIONS.md)); put a new helper in `lib/` if other code can use it
- Follow the file type rules and templates below
- Use the `fn.zsh` library for all user-facing functions in `functions/`
- Keep only native zsh commands in `functions/`, not wrappers for scripts in other languages or repositories
- Use `zparseopts` for options of `lib/` functions (not `case`/`getopts`)
- Guard every integration with an availability check; never assume a tool is installed
- Use lazy loading for slow tools (see [EXAMPLES.md](EXAMPLES.md#lazy-loading-pattern))
- Use the plugin loaders for plugins; never commit plugin directories, only wrapper files
- Don't put heavy operations in `.zshenv` (it runs for every shell, including scripts)
- Keep documentation in `docs/`; only `README.md` and `CLAUDE.md` stay in the root
- Describe each fact in one place and link to it from others
- After a change, update the documentation and consider adding tests

## File Types and Their Rules

| Location | Tracking | `fn.zsh` | First line | Purpose |
|----------|----------|----------|------------|---------|
| `lib/*.zsh` | Yes | No | `#!/bin/zsh` | Helper functions (sourced) |
| `inc/*.zsh` | Yes | No | `#!/bin/zsh` | Config modules (sourced) |
| `apps/*.zsh` | Yes, after guards | No | `#!/bin/zsh` | App integrations (sourced) |
| `plugins/*.zsh` | By the plugin loader | No | `#!/bin/zsh` | Plugin wrappers (sourced) |
| `functions/*` | No | Yes | License header | User commands (autoloaded) |
| `tests/*.test.zsh` | No | No | License header | Test files |
| `scripts/*.zsh` | No | No | `#!/usr/bin/env zsh` | Maintenance scripts |

Files in `functions/` are autoloaded, not sourced, so they must not use file tracking. For the tracking system, see [ZFILES.md](ZFILES.md).

## Adding Components

### Helper Functions (`lib/`)

1. **Choose appropriate file:**
   - File tests → `files.zsh`
   - OS detection → `system.zsh`
   - String operations → `strings.zsh`
   - Shell info → `shell.zsh`
   - General utilities → `varia.zsh`

2. **Follow naming conventions** (see [NAMING.md](NAMING.md))

3. **Use the file template** (checked by `tests/structure.test.zsh`):
   ```zsh
   #!/bin/zsh
   # Part of zconfig · https://github.com/barabasz/zconfig · MIT License
   #
   # Shell files tracking - keep at the top
   zfile_track_start ${0:A}

   ##
   # Short description of the file
   # Depends on: other lib files or zsh modules
   ##

   ## Section name

   # Shell files tracking - keep at the end
   zfile_track_end ${0:A}
   ```

4. **Use the function header template:**
   ```zsh
   # One-line description (shown by zman and in docs/FUNCTIONS.md)
   # Usage: name <required> [optional]
   # Example: name foo -> bar            (optional)
   # Output: what is printed; also sets REPLY
   # Returns: 0 success, 1 failure, 2 invalid usage
   name() {
       (( ARGC == 1 )) || return 2
       ...
   }
   ```
   Getters set `REPLY` (or `reply`) **and** print the value, so both
   `name x; v=$REPLY` (no subshell) and `v=$(name x)` work.

5. **Add tests** in `tests/*.test.zsh` and run `zsh tests/run.zsh`.

6. **Regenerate the function list:** `zsh scripts/functions-md.zsh`
   (CI fails when `docs/FUNCTIONS.md` is out of date).

### App Integrations (`apps/`)

1. Create `apps/{tool}.zsh`
2. Use the template. The guard comes **before** tracking; a guard after `zfile_track_start` would leave the file marked as still loading:
   ```zsh
   #!/bin/zsh
   # Part of zconfig · https://github.com/barabasz/zconfig · MIT License

   # Short description of the integration

   # Guard: exit immediately if {tool} is not installed
   is_installed {tool} || return

   # Shell files tracking - keep at the top (after guards)
   zfile_track_start ${0:A}

   # Configuration here

   # Shell files tracking - keep at the end
   zfile_track_end ${0:A}
   ```

To install a tool and link its configuration, add a recipe instead (see [ZAPP.md](ZAPP.md)).

### Plugins (`plugins/`)

`inc/plugins.zsh` lists all plugins and loads each one in one of three ways:

| Function | Use for |
|----------|---------|
| `load_plugin_directly <name> <repo>` | Plugin without configuration |
| `load_plugin_wrapper <name>` | Plugin with configuration in `plugins/<name>.zsh` |
| `source_plugin <name>` | Standalone single-file plugin `plugins/<name>.zsh` |

Missing plugins are installed automatically when `ZSH_PLUGINS_AUTOINSTALL=1`. For manual management, see the plugin functions in [FUNCTIONS.md](FUNCTIONS.md) (`install_plugin`, `update_plugins`, `list_plugins`, ...).

Wrapper template (no tracking calls: the loader tracks the file):

```zsh
#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Plugin name
# Plugin URL

# Pre-load configuration (optional)
# export PLUGIN_OPTION=value

load_plugin <name> <github-user/repo>

# Post-load configuration (optional)
# plugin_command --setup
```

Plugin directories (`plugins/<name>/`) are git clones and must be in `.gitignore`.

### User Functions (`functions/`)

1. Create `functions/{name}` (no extension, no shebang, no tracking)
2. Start with the header, then write the function body directly (no function declaration):
   ```zsh
   # Part of zconfig · https://github.com/barabasz/zconfig · MIT License
   #
   # One-line description
   # Use '{name} --help' for more information.
   ```
3. Use `fn.zsh` library for metadata, options, and args (see [FN.md](FN.md))

### Include Files (`inc/`)

1. Create `inc/{purpose}.zsh`, using the `lib/` file template above
2. Source it in `.zshenv` or `.zshrc`

## Performance

- Measure startup: `zspeed`, `zfiles`
- Files taking > 10ms are suspicious — investigate
- Use lazy loading for slow app initializations
- Prefer zsh builtins over external commands, and avoid unnecessary forks and subshells (see [ZSH.md](ZSH.md))

## Bytecode Compilation

Files in `lib/`, `inc/`, `apps/` and the startup files (`.zshrc`, `.zshenv`, ...) are automatically compiled to `.zwc` bytecode on shell startup (when `ZSH_AUTOCOMPILE=1`). All `functions/` are compiled into one digest, `functions.zwc`, which zsh uses for autoloading.

Only changed files are recompiled (timestamps are compared), and zsh uses a `.zwc` file only when it is newer than its source.

**No manual action needed** - after editing any `.zsh` file:
1. First shell startup uses the source file (newer) and recompiles
2. Subsequent startups use the compiled `.zwc` (faster)

**Manual commands** (in `lib/compile.zsh`):
```zsh
compile_zsh_config      # Compile lib/, inc/, apps/ with output
compile_zsh_config -q   # Compile quietly
clean_zsh_config        # Remove all .zwc files
compile_dir <dir>       # Compile single directory
compile_functions_dir <dir>  # Compile functions into <dir>.zwc digest
clean_dir <dir>         # Clean single directory
needs_compile <file>    # Check if a file needs recompilation
```

## Debugging

Configuration variables can disable parts of the shell, which helps to isolate a problem (see [README.md](../README.md#configuration-variables)).

```zsh
# Show the load time of each file
ZSH_ZFILE_DEBUG=1 zsh -lic "exit"

# Syntax check
zsh -n lib/files.zsh

# Unit tests (all, or only files matching a pattern)
zsh tests/run.zsh
zsh tests/run.zsh math
```

`tests/structure.test.zsh` also acts as the lint: it checks file templates, comments, the forbidden constructs from [ZSH.md](ZSH.md) in all zsh code, and the documentation layout.
