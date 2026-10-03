#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License

# yazi shell wrapper integration
# https://yazi-rs.github.io/docs/quick-start/#shell-wrapper

# Guard: exit immediately if yazi is not installed
is_installed yazi || return

# Shell files tracking - keep at the top (after guards)
zfile_track_start ${0:A}

y() {
   local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
   command yazi "$@" --cwd-file="$tmp"
   IFS= read -r -d '' cwd < "$tmp"
   [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
   command rm -f -- "$tmp"
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}