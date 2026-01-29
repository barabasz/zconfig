#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start "$ZDOTDIR/.zshrc"

# History configuration
source "$ZSH_INC_DIR/history.zsh"

# Colors variables
source "$ZSH_INC_DIR/colors.zsh"

# Icons and glyphs
source "$ZSH_INC_DIR/icons.zsh"

# PROMPT fallback
source "$ZSH_INC_DIR/prompt.zsh"

# Editors and pager
source "$ZSH_INC_DIR/editors.zsh"

# Zsh functions
source "$ZSH_INC_DIR/functions.zsh"

# User functions
if (( ZSH_LOAD_FUNCS )); then
    fpath=($ZSH_FUNCS_DIR $fpath)
    autoload -Uz $ZSH_FUNCS_DIR/[^_.]*(N.:t)
fi

# Aliases
source $ZSH_INC_DIR/aliases.zsh

# Directory hashes
source "$ZSH_INC_DIR/hashdirs.zsh"

# App configurations
(( ZSH_LOAD_APPS )) && source_zsh_dir "$ZSH_APPS_DIR"

# Plugin configurations
(( ZSH_LOAD_PLUGINS )) && source_zsh_dir "$ZSH_PLUGINS_DIR"

# shell files tracking - keep at the end
zfile_track_end "$ZDOTDIR/.zshrc"

# Ensure successful sourcing
true
