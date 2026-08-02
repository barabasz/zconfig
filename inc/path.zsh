#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Path configuration (Core / .zshenv stage)
##

# Ensure path arrays maintain unique elements natively in Zsh
typeset -U path fpath manpath cdpath

# Initialize path components array in strict priority order
local -a path_components

# === HIGHEST PRIORITY (Venvs & Language Runtimes) ===
path_components+=(
    $VENVDIR/python/bin(N)                     # 1. Główny venv Pythona
    $HOME/.cargo/bin(N)                        # 2. Rust / Cargo
)

# === PLATFORM-SPECIFIC PATHS ===
if [[ $OSTYPE == darwin* ]]; then
    path_components+=(
        /opt/homebrew/opt/python@3.14/libexec/bin(N) # 3. Fallback dla Pythona z Homebrew (przed /usr/bin)
        /opt/homebrew/bin(N)
        /opt/homebrew/sbin(N)
        $BINDIR(N)
        $HOME/.local/bin(N)
        $HOME/Library/Python/*/bin(N)
        /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin(N)
        /Applications/kitty.app/Contents/MacOS(N)
    )
elif [[ $OSTYPE == linux* ]]; then
    path_components+=(
        /home/linuxbrew/.linuxbrew/bin(N)
        /home/linuxbrew/.linuxbrew/sbin(N)
        $BINDIR(N)
        $HOME/.local/bin(N)
        /snap/bin(N)
    )
fi

# === RE-ORDER PATH STRICTLY ===
# 1. Filter existing $path to remove any occurrences of our target components
for entry in $path_components; do
    path=(${path:#$entry})
done

# 2. Prepend target components cleanly at the very front
path=(
    $path_components
    $path
)

# Native Zsh cleaning: keep only existing directories without external functions
path=($^path(N-/))

# Shell files tracking - keep at the end
zfile_track_end ${0:A}