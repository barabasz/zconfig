#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License

# SSH integration

# Guard: exit immediately if ssh is not installed
is_installed ssh || return

# Shell files tracking - keep at the top (after guards)
zfile_track_start ${0:A}

export SSH_HOME="$CONFDIR/ssh"
export SSH_AUTH_SOCK="$SSH_HOME/ssh_auth.sock"

# Shell files tracking - keep at the end
zfile_track_end ${0:A}