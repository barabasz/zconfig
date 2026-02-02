#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# rust (programming language)

# Guard
is_file "$HOME/.cargo/env" || return

# Rust environment
source "$HOME/.cargo/env"

# Cargo and Rustup directories
export CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
export RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.rustup}

# shell files tracking - keep at the end
zfile_track_end ${0:A}