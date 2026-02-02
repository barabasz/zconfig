#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Zsh functions loading
##

# Anonymous function scope ensures variables don't leak to global scope
() {
    local mod mods

    # Autoload tools (lazy loading - ready to use when called)
    mods=(zargs zmv)
    for mod in $mods; do
        autoload -Uz "$mod" || printe "Cannot load zsh $mod function"
    done

    # Autoload AND initialize subsystems (load and run immediately)
    mods=(colors compinit)
    for mod in $mods; do
        autoload -Uz "$mod" && "$mod" || printe "Cannot load zsh $mod function"
    done
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}