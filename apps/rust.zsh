#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License

# Rust (programming language) integration

# Assign path to a local variable (without exporting to the environment)
local _cargo_dir="${CARGO_HOME:-$HOME/.cargo}"

# Guard: exit immediately if cargo bin directory does not exist
[[ -d "$_cargo_dir/bin" ]] || return

# Shell files tracking - keep at the top (after guards)
zfile_track_start ${0:A}

# Rust environment detected. Safe to export global variables.
export CARGO_HOME="$_cargo_dir"
export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"

# Safely add Cargo bin to PATH
path_remove "$CARGO_HOME/bin"
path_prepend "$CARGO_HOME/bin"

# Re-apply python venv on top if active (so Python venv always wins!)
local venv_bin="$VENVDIR/python/bin"
if [[ -d "$venv_bin" ]]; then
    path_remove "$venv_bin"
    path_prepend "$venv_bin"
fi

# Shell files tracking - keep at the end
zfile_track_end ${0:A}