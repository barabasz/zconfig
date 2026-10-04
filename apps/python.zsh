#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License

# Python virtual environment integration

# Guard: exit immediately using hash table if python3 is not installed
(( ${+commands[python3]} )) || return

# Shell files tracking - keep at the top (after guards)
zfile_track_start ${0:A}

# Ensure Homebrew Python libexec is prepended as base fallback (before /usr/bin)
local brew_python_bin="/opt/homebrew/opt/python@3.14/libexec/bin"
if [[ -d "$brew_python_bin" ]]; then
    path_remove "$brew_python_bin"
    path_prepend "$brew_python_bin"
fi

# Activate zconfig's standard Python venv when available.
# Shared helper is also used by zapp immediately after creating the venv.
app_python_env_activate 2>/dev/null || true

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
