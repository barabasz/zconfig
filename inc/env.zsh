#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Zsh-config core environment variables
##

# Configuration version 
export ZSH_CONFIG_VERSION="20260206v1"

# zconfig directories
export CONFDIR=$HOME/.config
export ZDOTDIR=$CONFDIR/zsh
export ZSH_CACHE_DIR=$ZDOTDIR/cache
export ZSH_INC_DIR=$ZDOTDIR/inc
export ZSH_LIB_DIR=$ZDOTDIR/lib
export ZSH_APPS_DIR=$ZDOTDIR/apps
export ZSH_FUNCS_DIR=$ZDOTDIR/functions
export ZSH_PLUGINS_DIR=$ZDOTDIR/plugins

# System directories
export LOCALDIR=$HOME/.local
export TMPDIR=$LOCALDIR/tmp
export TMP=$TMPDIR
export TEMP=$TMPDIR
export VENVDIR=$LOCALDIR/venv
export BINDIR=$LOCALDIR/bin
export LIBDIR=$LOCALDIR/lib
export CACHEDIR=$LOCALDIR/cache
export DATADIR=$LOCALDIR/share
export STATEDIR=$LOCALDIR/state

# User directories
# See also inc/xdg.zsh for XDG variables
export DLDIR=$HOME/Downloads
export DOCDIR=$HOME/Documents

# Ensure all *DIR directories exist
local _var                                                                                                                                                                     
for _var in ${(Mk)parameters:#*DIR}; do                                                                                                                                        
    [[ -d ${(P)_var} ]] || mkdir -p "${(P)_var}"                                                                                                                               
done

# Don't consider certain characters part of the word
WORDCHARS='_-'

# Hide EOL sign ('%')
PROMPT_EOL_MARK=""

# Time format for the 'time' command
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

# Zsh options
setopt autocd              # change directory just by typing its name
#setopt correct            # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
#setopt nonomatch          # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

# Library files configuration
export ZSH_LOAD_LIB=${ZSH_LOAD_LIB:-1}           # set to 1 to load library files from lib/
export ZSH_AUTOCOMPILE=${ZSH_AUTOCOMPILE:-1}     # set to 1 to enable auto-compilation of zsh scripts
export ZSH_LOAD_APPS=${ZSH_LOAD_APPS:-1}         # set to 1 to load app configurations from apps/
export ZSH_LOAD_USER_FUNCS=${ZSH_LOAD_USER_FUNCS:-1} # set to 1 to load functions from functions/
export ZSH_LOAD_SHELL_FUNCS=${ZSH_LOAD_SHELL_FUNCS:-1} # set to 1 to autoload shell functions like zargs and zmv
export ZSH_LOAD_PLUGINS=${ZSH_LOAD_PLUGINS:-1}   # set to 1 to load plugins from plugins/
export ZSH_PLUGINS_AUTOINSTALL=${ZSH_PLUGINS_AUTOINSTALL:-1}  # set to 1 to auto-install missing plugins
export ZSH_LOAD_KEYS=${ZSH_LOAD_KEYS:-1}         # set to 1 to load key bindings from keys.zsh
export ZSH_LOAD_ALIASES=${ZSH_LOAD_ALIASES:-1}   # set to 1 to load aliases from aliases.zsh
export ZSH_LOAD_COLORS=${ZSH_LOAD_COLORS:-1}     # set to 1 to load colors from colors.zsh
export ZSH_LOAD_COMPLETION=${ZSH_LOAD_COMPLETION:-1} # set to 1 to load completion configuration from completion.zsh
export ZSH_LOAD_HASHDIRS=${ZSH_LOAD_HASHDIRS:-1} # set to 1 to load directory hashes from hashdirs.zsh
## Debug and info messages
export ZSH_DEBUG=${ZSH_DEBUG:-1}              # set to 1 to enable zsh debug messages
export ZSH_ZFILE_DEBUG=${ZSH_ZFILE_DEBUG:-0}  # set to 1 to enable zfile sourcing debug messages
export ZSH_LOGIN_INFO=${ZSH_LOGIN_INFO:-0}    # set to 1 to print login info messages
export ZSH_SYS_INFO=${ZSH_SYS_INFO:-0}        # set to 1 to print system info messages

# Editors and pager
export EDITOR='nvim'
export VISUAL='code'
export PAGER='less -r'

# Logging configuration
export LOG_SHOW_ICONS=1  # log.sh: 1 for icons, 0 for nothing
export LOG_COLOR_TEXTS=1 # log.sh: 1 for colors, 0 for white
export LOG_EMOJI_ICONS=0 # log.sh: 1 for emoji, 0 for text

# zdoc configuration
export ZDOC_MAX_WIDTH=120  # max line width for zdoc viewer
export ZDOC_MIN_WIDTH=60   # min line width for zdoc viewer

# Execs
export EXECS_SPINNER_FRAMES=('⣷' '⣯' '⣟' '⡿' '⢿' '⣻' '⣽' '⣾')
export EXECS_SPINNER_DELAY=0.10

# shell files tracking - keep at the end
zfile_track_end ${0:A}
