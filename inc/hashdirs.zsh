#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Directories shortcuts (named directories)
##

hash -d bin=$BINDIR
hash -d conf=$CONFDIR
hash -d dl=$DLDIR
hash -d doc=$DOCDIR
is_folder "$HOME/GitHub" && hash -d gh=$GHDIR
hash -d lib=$LIBDIR
hash -d tmp=$TMP
hash -d venv=$VENVDIR
hash -d zsh=$ZDOTDIR

# shell files tracking - keep at the end
zfile_track_end ${0:A}