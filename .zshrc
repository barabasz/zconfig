#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start "$ZDOTDIR/.zshrc"

# History configuration
source "$ZSH_INC_DIR/history.zsh"

# Colors variables
(( ZSH_LOAD_COLORS )) && source "$ZSH_INC_DIR/colors.zsh"

# Completion configuration
(( ZSH_LOAD_COMPLETION )) && source "$ZSH_INC_DIR/completion.zsh"

# Icons and glyphs
source "$ZSH_INC_DIR/icons.zsh"

# PROMPT fallback
source "$ZSH_INC_DIR/prompt.zsh"

# Autoloadable Shell Functions
if (( ZSH_LOAD_SHELL_FUNCS )); then
    autoload -Uz zargs
    autoload -Uz zmv
fi


# User functions
if (( ZSH_LOAD_USER_FUNCS )); then
    fpath=($ZSH_FUNCS_DIR $fpath)
    autoload -Uz $ZSH_FUNCS_DIR/[^_.]*(N.:t)
fi

# Aliases
(( ZSH_LOAD_ALIASES )) && source $ZSH_INC_DIR/aliases.zsh

# Key bindings
(( ZSH_LOAD_KEYS )) && source "$ZSH_INC_DIR/keys.zsh"

# Directory hashes
(( ZSH_LOAD_HASHDIRS )) && source "$ZSH_INC_DIR/hashdirs.zsh"

# App configurations
(( ZSH_LOAD_APPS )) && source_zsh_dir "$ZSH_APPS_DIR"

# Plugin configurations
(( ZSH_LOAD_PLUGINS )) && source "$ZSH_INC_DIR/plugins.zsh"

# shell files tracking - keep at the end
zfile_track_end "$ZDOTDIR/.zshrc"

# Ensure successful sourcing
true
