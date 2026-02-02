#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

## SSH configuration

# Guard
is_installed ssh || return

export SSH_HOME="$CONFDIR/ssh"
export SSH_AUTH_SOCK="$SSH_HOME/ssh_auth.sock"

# shell files tracking - keep at the end
zfile_track_end ${0:A}