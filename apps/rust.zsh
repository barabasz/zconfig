#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# rust (programming language)

# Cargo and Rustup directories
export CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
export RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.rustup}

# Guard: check if cargo bin directory actually exists
[[ -d "$CARGO_HOME/bin" ]] || return

# Safely add Cargo bin to PATH
path_remove "$CARGO_HOME/bin"
path_prepend "$CARGO_HOME/bin"

# Re-apply python venv on top if active (so Python venv always wins!)
local venv_bin="$VENVDIR/python/bin"
if [[ -d "$venv_bin" ]]; then
    path_remove "$venv_bin"
    path_prepend "$venv_bin"
fi

# shell files tracking - keep at the end
zfile_track_end ${0:A}