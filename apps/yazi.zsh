#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# yazi shell wrapper
# https://yazi-rs.github.io/docs/quick-start/#shell-wrapper

# Guard: check if yazi is installed
if ! is_installed yazi; then
    zfile_track_end ${0:A}
    return
fi

y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}