#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Zsh module loading
# Use `man zshmodules` for reference.
# Use `zmodload` to list loaded modules.
# Note: Some modules are loaded by default by zsh.
##

# Builtins for manipulating extended attributes (xattr).
# zmodload zsh/xattr

# Builtins for manipulating POSIX.1e (POSIX.6) capability (privilege) sets.
# zmodload zsh/cap

# A builtin that can clone a running shell onto another terminal.
# zmodload zsh/clone

# The compctl builtin for controlling completion.
# zmodload zsh/compctl

# The basic completion code.
zmodload zsh/complete

# Completion listing extensions.
zmodload zsh/complist

# A module with utility builtins needed for the shell function based completion system.
zmodload zsh/computil

# curses windowing commands
# zmodload zsh/curses

# Some date/time commands and parameters.
# zmodload zsh/datetime # already loaded by inc/zfiles.zsh


# Some basic file manipulation commands as builtins.
# zmodload zsh/files

# Interface to locale information.
# zmodload zsh/locale

# math functions
zmodload zsh/mathfunc

# Manipulation of Unix domain sockets
# zmodload zsh/net/socket

# native network operations
zmodload zsh/net/tcp

# Access to internal hash tables via special associative arrays.
zmodload zsh/parameter

# Interface to the POSIX regex library.
zmodload zsh/regex

# A builtin command interface to the stat system call.
zmodload -F zsh/stat b:zstat # loaded as 'zstat' to avoid shadowing the system 'stat' command

# A builtin interface to various low-level system features.
zmodload zsh/system

# Interface to the termcap database.
zmodload zsh/termcap

# Interface to the terminfo database.
zmodload zsh/terminfo

# The Zsh Line Editor, including the bindkey and vared builtins.
zmodload zsh/zle

# Access to internals of the Zsh Line Editor via parameters.
zmodload zsh/zleparameter

# Block and return when file descriptors are ready.
# zmodload zsh/zselect

# Some utility builtins, e.g. the one for supporting configuration via styles.
zmodload zsh/zutil


# shell files tracking - keep at the end
zfile_track_end ${0:A}