#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start "$ZDOTDIR/.zlogin"

# Interactive cleanup
unset d # set by zsh

# Show login info
(( ZSH_SYS_INFO ))   && sysinfo
(( ZSH_LOGIN_INFO )) && logininfo

# Shell files tracking - keep at the end
zfile_track_end "$ZDOTDIR/.zlogin"
ZFILES_TIME[total]=$(( ${(j:+:)ZFILES_TIME} ))
unset this_file # ZFILES_START