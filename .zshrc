#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start "$ZDOTDIR/.zshrc"

# Options configuration
(( ZSH_LOAD_OPTIONS )) && source "$ZSH_INC_DIR/options.zsh"

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

# Helper library
(( ZSH_LOAD_LIB )) && source_zsh_dir "$ZSH_LIB_DIR"

# User functions
if (( ZSH_LOAD_USER_FUNCS )); then
    fpath=($ZSH_FUNCS_DIR $fpath)
    autoload -Uz $ZSH_FUNCS_DIR/[^_.]*(N.:t)
fi

# Aliases
(( ZSH_LOAD_ALIASES )) && source $ZSH_INC_DIR/aliases.zsh

# Key bindings
(( ZSH_LOAD_KEYS )) && source "$ZSH_INC_DIR/keys.zsh"

# App configurations
(( ZSH_LOAD_APPS )) && source_zsh_dir "$ZSH_APPS_DIR"

# Directory hashes
(( ZSH_LOAD_HASHDIRS )) && source "$ZSH_INC_DIR/hashdirs.zsh"

# Plugin configurations
(( ZSH_LOAD_PLUGINS )) && source "$ZSH_INC_DIR/plugins.zsh"

# Auto-compile changed files (for next shell startup)
(( ZSH_AUTOCOMPILE )) && compile_zsh_config -q

# shell files tracking - keep at the end
zfile_track_end "$ZDOTDIR/.zshrc"

# Ensure successful sourcing
true
