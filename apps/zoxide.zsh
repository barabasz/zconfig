#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License

# zoxide shell integration

# Guard: exit immediately if zoxide is not installed
is_installed zoxide || return

# Shell files tracking - keep at the top (after guards)
zfile_track_start ${0:A}

eval "$(zoxide init zsh)"

# Shell files tracking - keep at the end
zfile_track_end ${0:A}