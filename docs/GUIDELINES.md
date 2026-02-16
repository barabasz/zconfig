# zconfig: Development Guidelines

Part of [zconfig](../README.md) documentation.

See also:
- [ZSH.md](ZSH.md) - Zsh coding style
- [FN.md](FN.md) - Function library for user-facing functions
- [NAMING.md](NAMING.md) - Naming conventions
- [EXAMPLES.md](EXAMPLES.md) - Code examples and common patterns

## Do's

- Always use file tracking in sourced files (`zfile_track_start`/`zfile_track_end` in `lib/`, `inc/`, `apps/`, `plugins/`)
- Do NOT use file tracking in autoloaded functions (`functions/`) — they are not sourced
- Check tool availability before configuring (`is_installed`)
- Follow zsh coding style (see [ZSH.md](ZSH.md))
- Use `fn.zsh` library for all user-facing functions in `functions/` (metadata, options, args, examples)
- Use `zparseopts` for parsing command-line options (not `case`/`getopts`)
- Use lazy loading for slow tools (see [EXAMPLES.md](EXAMPLES.md#lazy-loading-pattern))
- Use `load_plugin` for plugins (handles compilation)
- Keep plugin directories in `.gitignore`
- Use `REPLY`/`reply` for returning values from functions (no subshells)
- Use zsh path modifiers (`:t`, `:h`, `:e`, `:r`, `:A`) instead of `basename`/`dirname`
- Use expansion flags instead of piping to external commands
- Use correct exit codes: `0` = success, `1` = error, `2` = invalid usage, `127` = not found

## Don'ts

- Never skip file tracking in sourced files (`lib/`, `inc/`, `apps/`, `plugins/`)
- Never add file tracking to autoloaded functions (`functions/`)
- Never assume tools are installed — always guard with `is_installed`
- Don't use `case $1` or `getopts` for option parsing (use `zparseopts`)
- Don't put heavy operations in `.zshenv` (runs for every shell, including scripts)
- Don't use subshells when `REPLY`/`reply` can be used instead
- Don't commit plugin directories (only wrapper files)
- Don't shadow zsh reserved variable names: `path`, `fpath`, `cdpath`, `mailpath`, `manpath`
- Don't use bash constructs: `echo` (use `print`), `$#` (use `ARGC`), `$?` (use `status`), `$1` (use `argv[1]`)
- Don't use external commands where zsh builtins exist (`stat` → `zstat`, `basename` → `:t`, `dirname` → `:h`)
- Don't use `return $?` — it's redundant (functions return last command's exit code by default)
- Don't use `exit` in functions — use `return`

## File Types and Their Rules

| Location | Tracking | `fn.zsh` | Shebang | Purpose |
|----------|----------|----------|---------|---------|
| `lib/*.zsh` | Yes | No | `#!/bin/zsh` | Helper functions (sourced) |
| `inc/*.zsh` | Yes | No | `#!/bin/zsh` | Config modules (sourced) |
| `apps/*.zsh` | Yes | No | `#!/bin/zsh` | App integrations (sourced) |
| `plugins/*.zsh` | Yes | No | `#!/bin/zsh` | Plugin wrappers (sourced) |
| `functions/*` | No | Yes | None | User commands (autoloaded) |

## Adding Components

### Helper Functions (`lib/`)

1. **Choose appropriate file:**
   - File tests → `files.zsh`
   - OS detection → `system.zsh`
   - String operations → `strings.zsh`
   - Shell info → `shell.zsh`
   - General utilities → `varia.zsh`

2. **Follow naming conventions** (see [NAMING.md](NAMING.md))

3. **Use tracking:**
   ```zsh
   #!/bin/zsh
   zfile_track_start ${0:A}

   # Your code here

   zfile_track_end ${0:A}
   ```

### App Integrations (`apps/`)

1. Create `apps/{tool}.zsh`
2. Use template:
   ```zsh
   #!/bin/zsh
   zfile_track_start ${0:A}

   is_installed {tool} || return

   # Configuration here

   zfile_track_end ${0:A}
   ```
3. For priority loading, use `_` prefix (e.g., `_brew.zsh`)

### Plugins (`plugins/`)

1. Install: `install_plugin <name> <github-user/repo>`
2. Create wrapper `plugins/<name>.zsh`:
   ```zsh
   #!/bin/zsh
   zfile_track_start ${0:A}

   # Pre-load configuration (optional)
   # export PLUGIN_OPTION=value

   load_plugin <name>

   # Post-load configuration (optional)
   # plugin_command --setup

   zfile_track_end ${0:A}
   ```

Plugin directories (`plugins/<name>/`) are git clones and must be in `.gitignore`.

### User Functions (`functions/`)

1. Create `functions/{name}` (no extension, no shebang, no tracking)
2. Write function body directly (no function declaration)
3. Use `fn.zsh` library for metadata, options, and args (see [FN.md](FN.md))

### Include Files (`inc/`)

1. Create `inc/{purpose}.zsh`
2. Add tracking calls
3. Source it in `.zshenv` or `.zshrc`

## Common Patterns

### Guard for optional tools

```zsh
# apps/tool.zsh
is_installed tool || return
```

### Conditional config by OS

```zsh
if is_macos; then
    export TOOL_PATH=/opt/homebrew/opt/tool
elif is_debian_based; then
    export TOOL_PATH=/usr/local/tool
fi
```

### Returning values without subshells

```zsh
# Bad - subshell overhead
result=$(my_func "$input")

# Good - REPLY protocol
my_func "$input"
result="$REPLY"
```

### Lazy loading

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

## Performance

- Measure startup: `zfiles` or `time zsh -lic "exit"`
- Files taking > 10ms are suspicious — investigate
- Use lazy loading for slow app initializations
- Prefer zsh builtins over external commands (`(( ))` over `expr`, `[[ ]]` over `test`)
- Use `${+var}` instead of `[[ -n "$var" ]]` to check if variable is set
- Avoid unnecessary forks/subshells — use parameter expansion and `REPLY`

## Bytecode Compilation

Files in `lib/`, `inc/`, `apps/` are automatically compiled to `.zwc` bytecode on shell startup (when `ZSH_AUTOCOMPILE=1`).

**No manual action needed** - after editing any `.zsh` file:
1. First shell startup uses the source file (newer) and recompiles
2. Subsequent startups use the compiled `.zwc` (faster)

**Manual commands** (in `lib/compile.zsh`):
```zsh
compile_zsh_config      # Compile lib/, inc/, apps/ with output
compile_zsh_config -q   # Compile quietly
clean_zsh_config        # Remove all .zwc files
compile_dir <dir>       # Compile single directory
clean_dir <dir>         # Clean single directory
```

## Configuration Variables

Configuration variables in `inc/env.zsh` control shell behavior. Useful for debugging:

```zsh
# Start shell without apps (debug app issues)
ZSH_LOAD_APPS=0 zsh

# Start shell without plugins (debug plugin issues)
ZSH_LOAD_PLUGINS=0 zsh

# Minimal shell
ZSH_LOAD_APPS=0 ZSH_LOAD_PLUGINS=0 ZSH_AUTOCOMPILE=0 zsh
```

See [README.md](../README.md#configuration-variables) for the full list.

## Debugging

```zsh
# Enable debug output
export ZSH_DEBUG=1
source ~/.zshenv

# Syntax check
zsh -n lib/files.zsh

# Test function
is_file /etc/hosts && print "OK" || print "FAIL"
```
