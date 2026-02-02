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
    # Hardcoded variables for macOS (Apple Silicon default)
    # eval "$($brew_mac_path shellenv)" <- this was very slow
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    export HOMEBREW_REPOSITORY="/opt/homebrew"
    
    # Prepend site-functions to fpath
    fpath[1,0]="/opt/homebrew/share/zsh/site-functions"
    
    # Manually prepend PATH instead of using path_helper
    # This matches the logic you used in the Linux block below
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"
    
    # Manpages and Info setup
    [ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

elif [[ -f $brew_linux_path ]]; then
    # Hardcoded variables for Linux
    # eval "$($brew_linux_path shellenv)" <- this was very slow
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
    export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
    
    fpath[1,0]="/home/linuxbrew/.linuxbrew/share/zsh/site-functions"
    export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin${PATH+:$PATH}"
    
    [ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
    export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH:-}"
fi

# homebrew environment variables
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_EMOJI=1
export HOMEBREW_LOADED=1

# shell files tracking - keep at the end
zfile_track_end ${0:A}