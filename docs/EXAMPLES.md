# zconfig: Examples & Use Cases

This is a part of [zconfig](../README.md) documentation. 
Code examples and common patterns.

## OS-Specific Configuration

```zsh
#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License

# mytool integration

# Guard: exit immediately if mytool is not installed
is_installed mytool || return

# Shell files tracking - keep at the top (after guards)
zfile_track_start ${0:A}

if is_macos; then
    export MYTOOL_PATH=/opt/homebrew/opt/mytool
elif is_debian_based; then
    export MYTOOL_PATH=/usr/local/mytool
fi
path_prepend $MYTOOL_PATH/bin

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
```

## Optional File Loading

```zsh
# Source file only if it exists
[[ -f "$HOME/.secrets" ]] && source "$HOME/.secrets"
[[ -f "$HOME/.local.zsh" ]] && source "$HOME/.local.zsh"
```

## Custom Autoloaded Function

```zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Display versions of development tools
# Use 'devinfo --help' for more information.

local -A _fn=(
    [info]="Display versions of development tools"
    [version]="1.0.0"
    [required]="python3 node git"
)

local -a _fn_args=()
local -a _fn_opts=()
local -a _fn_commands=()
local -a _fn_examples=()

local -A opts=() args=()
_fn_init "$@" || return $REPLY

local tool
print "Development Environment:"
for tool in python3 node git; do
    printkv "  $tool" "$(zver $tool)"
done
```

## Performance Measurement

```zsh
# Benchmark startup time
$ zspeed

# Load time of each file, while the shell starts
$ ZSH_ZFILE_DEBUG=1 zsh -lic "exit"

# Full report
$ zfiles
```

## Lazy Loading Pattern

```zsh
# apps/heavytool.zsh, between the tracking calls
heavytool() {
    unfunction heavytool
    eval "$(command heavytool init zsh)"
    heavytool "$@"
}
```

## Plugin with Configuration

```zsh
#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# zsh-autosuggestions
# https://github.com/zsh-users/zsh-autosuggestions

# Configuration before loading
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

load_plugin zsh-autosuggestions zsh-users/zsh-autosuggestions

# Keybinding after loading
bindkey '^[[Z' autosuggest-accept
```
