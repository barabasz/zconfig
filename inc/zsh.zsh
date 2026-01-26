#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Zsh core configuration

export CONFDIR=$HOME/.config
export ZDOTDIR=$CONFDIR/zsh
export ZCACHEDIR=$ZDOTDIR/cache
export SHELL_SESSION_DIR="$ZCACHEDIR/sessions"
export ZINCDIR=$ZDOTDIR/inc
export ZLIBDIR=$ZDOTDIR/lib
export ZAPPDIR=$ZDOTDIR/apps
export ZFNCDIR=$ZDOTDIR/functions
export ZPLUGDIR=$ZDOTDIR/plugins

export ZSH_DEBUG=${ZSH_DEBUG:-1}              # set to 1 to enable zsh debug messages
export ZSH_ZFILE_DEBUG=${ZSH_ZFILE_DEBUG:-0}  # set to 1 to enable zfile sourcing debug messages
export ZSH_LOGIN_INFO=${ZSH_LOGIN_INFO:-0}    # set to 1 to print login info messages
export ZSH_SYS_INFO=${ZSH_SYS_INFO:-0}        # set to 1 to print system info messages
export ZSH_AUTOCOMPILE=${ZSH_AUTOCOMPILE:-1}  # set to 1 to enable auto-compilation of zsh scripts
export ZSH_LOAD_APPS=${ZSH_LOAD_APPS:-1}      # set to 1 to load app configurations from apps/
export ZSH_LOAD_PLUGINS=${ZSH_LOAD_PLUGINS:-1}  # set to 1 to load plugins from plugins/
export ZSH_PLUGINS_AUTOINSTALL=${ZSH_PLUGINS_AUTOINSTALL:-1}  # set to 1 to auto-install missing plugins
export ZSH_CONFIG_VERSION="20260126v3"        # configuration version

# Zsh module loading
zmodload zsh/complete
zmodload zsh/datetime
zmodload zsh/main
zmodload zsh/mathfunc
zmodload zsh/net/tcp
zmodload zsh/parameter
zmodload zsh/regex
zmodload zsh/stat
zmodload zsh/system
zmodload zsh/terminfo
zmodload zsh/zle
zmodload zsh/zleparameter
zmodload zsh/zselect
zmodload zsh/zutil

# shell files tracking - keep at the end
zfile_track_end ${0:A}
