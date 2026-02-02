#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Path configuration
##

# Initialize path components array
local -a path_components

# === COMMON PATHS (all platforms) ===
path_components+=(
  $BINDIR
  $BINDIR/{common,install,test,thisos}
  $HOME/.local/bin
  /usr/local/bin
)

# === PLATFORM-SPECIFIC PATHS ===
if is_macos; then
  path_components+=(
    /opt/homebrew/bin
    /opt/homebrew/sbin
    /usr/local/opt/python/libexec/bin
    /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin
    $HOME/Library/Python/*/bin(N)  # Python user packages
  )
elif is_linux; then
  path_components+=(
    /home/linuxbrew/.linuxbrew/bin
    /home/linuxbrew/.linuxbrew/sbin
    /snap/bin
    /usr/sbin
    /sbin
  )
fi

# === BUILD FINAL PATH ===
# Prepend our paths to existing PATH
path=(
  $path_components
  $path  # existing PATH entries
)

# Remove duplicates and non-existent directories
typeset -U path              # unique values only
path=($^path(N-/))           # keep only existing directories

export PATH

# shell files tracking - keep at the end
zfile_track_end ${0:A}