#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# ANSI color codes 
##

# basic colors
export b=$'\033[0;34m'      # blue
export c=$'\033[0;36m'      # cyan
export g=$'\033[0;32m'      # green
export p=$'\033[0;35m'      # purple
export r=$'\033[0;31m'      # red
export w=$'\033[0;37m'      # white
export y=$'\033[0;33m'      # yellow
# bright colors
export br=$'\033[0;91m'     # bright red
export bg=$'\033[0;92m'     # bright green
export by=$'\033[0;93m'     # bright yellow
export bb=$'\033[0;94m'     # bright blue
export bp=$'\033[0;95m'     # bright purple
export bc=$'\033[0;96m'     # bright cyan
export bw=$'\033[0;97m'     # bright white
# reset
export x=$'\033[0m'

# shell files tracking - keep at the end
zfile_track_end ${0:A}