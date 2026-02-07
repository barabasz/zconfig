#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Colors and ANSI color codes 
##

# Load zsh's color definitions
autoload -Uz colors && colors

# basic colors
export b=$'\033[0;34m'      # blue
export c=$'\033[0;36m'      # cyan
export g=$'\033[0;32m'      # green
export p=$'\033[0;35m'      # purple
export r=$'\033[0;31m'      # red
export w=$'\033[0;37m'      # white
export y=$'\033[0;33m'      # yellow
# reset
export x=$'\033[0m'

# shell files tracking - keep at the end
zfile_track_end ${0:A}