#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Zsh-config core environment variables
##

# Configuration version
export ZSH_CONFIG_VERSION="20260130v1"

# Directories configuration
export CONFDIR=$HOME/.config
export ZDOTDIR=$CONFDIR/zsh
export ZCACHEDIR=$ZDOTDIR/cache
export SHELL_SESSION_DIR="$ZCACHEDIR/sessions"
export ZSH_INC_DIR=$ZDOTDIR/inc
export TMP=$HOME/.tmp
export TEMP=$TMP
export TEMPDIR=$TMP
export TMPDIR=$TMP
export BINDIR=$HOME/bin
export LIBDIR=$HOME/lib
export DLDIR=$HOME/Downloads
export DOCDIR=$HOME/Documents
export CACHEDIR=$HOME/.cache
export VENVDIR=$HOME/.venv

# Library files configuration
export ZSH_LIB_DIR=$ZDOTDIR/lib
export ZSH_LOAD_LIB=${ZSH_LOAD_LIB:-1}          # set to 1 to load library files from lib/

# Compilation (zws) configuration
export ZSH_AUTOCOMPILE=${ZSH_AUTOCOMPILE:-1}  # set to 1 to enable auto-compilation of zsh scripts

# Apps configuration
export ZSH_APPS_DIR=$ZDOTDIR/apps
export ZSH_LOAD_APPS=${ZSH_LOAD_APPS:-1}      # set to 1 to load app configurations from apps/

# User functions configuration
export ZSH_FUNCS_DIR=$ZDOTDIR/functions
export ZSH_LOAD_FUNCS=${ZSH_LOAD_FUNCS:-1}  # set to 1 to load functions from functions/

# Plugins configuration
export ZSH_PLUGINS_DIR=$ZDOTDIR/plugins
export ZSH_LOAD_PLUGINS=${ZSH_LOAD_PLUGINS:-1}  # set to 1 to load plugins from plugins/
export ZSH_PLUGINS_AUTOINSTALL=${ZSH_PLUGINS_AUTOINSTALL:-1}  # set to 1 to auto-install missing plugins

## Debug and info messages
export ZSH_DEBUG=${ZSH_DEBUG:-1}              # set to 1 to enable zsh debug messages
export ZSH_ZFILE_DEBUG=${ZSH_ZFILE_DEBUG:-0}  # set to 1 to enable zfile sourcing debug messages
export ZSH_LOGIN_INFO=${ZSH_LOGIN_INFO:-0}    # set to 1 to print login info messages
export ZSH_SYS_INFO=${ZSH_SYS_INFO:-0}        # set to 1 to print system info messages

# Editors and pager
export EDITOR='nvim'
export VISUAL='code'
export PAGER='less'

# Logging configuration
export LOG_SHOW_ICONS=1  # log.sh: 1 for icons, 0 for nothing
export LOG_COLOR_TEXTS=1 # log.sh: 1 for colors, 0 for white
export LOG_EMOJI_ICONS=0 # log.sh: 1 for emoji, 0 for text

# Execs
export EXECS_SPINNER_FRAMES=('⣷' '⣯' '⣟' '⡿' '⢿' '⣻' '⣽' '⣾')
export EXECS_SPINNER_DELAY=0.10

# shell files tracking - keep at the end
zfile_track_end ${0:A}
