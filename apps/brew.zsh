#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Homebrew configuration

brew_mac_path="/opt/homebrew/bin/brew"
brew_linux_path="/home/linuxbrew/.linuxbrew/bin/brew"

# Guard
is_file "$brew_mac_path" || is_file "$brew_linux_path" || return

# homebrew shellenv integration
if [[ -f $brew_mac_path ]]; then
    # Hardcoded variables for macOS (Apple Silicon default - fast startup)
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    export HOMEBREW_REPOSITORY="/opt/homebrew"
    
    # Prepend site-functions to fpath
    fpath_prepend "/opt/homebrew/share/zsh/site-functions"
    
    # Safe path prepending using zconfig library
    path_remove "/opt/homebrew/sbin"
    path_prepend "/opt/homebrew/sbin"
    path_remove "/opt/homebrew/bin"
    path_prepend "/opt/homebrew/bin"
    
    # Manpages and Info setup
    [ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

elif [[ -f $brew_linux_path ]]; then
    # Hardcoded variables for Linux
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
    export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
    
    fpath_prepend "/home/linuxbrew/.linuxbrew/share/zsh/site-functions"

    path_remove "/home/linuxbrew/.linuxbrew/sbin"
    path_prepend "/home/linuxbrew/.linuxbrew/sbin"
    path_remove "/home/linuxbrew/.linuxbrew/bin"
    path_prepend "/home/linuxbrew/.linuxbrew/bin"
    
    [ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
    export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH:-}"
fi

# homebrew environment variables
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_EMOJI=1
export HOMEBREW_LOADED=1

# shell files tracking - keep at the end
zfile_track_end ${0:A}