#!/bin/zsh
# Shell files tracking - keep at the top
source "$HOME/.config/zsh/inc/zfiles.zsh"
zfile_track_start ${0:A}

# Zsh core configuration
source "$HOME/.config/zsh/inc/zsh.zsh"

# Zsh module loading
source "$ZSH_INC_DIR/modules.zsh"

# Zsh bootstrap functions
source "$ZSH_INC_DIR/bootstrap.zsh"

# XDG directories
source "$ZSH_INC_DIR/xdg.zsh"

# User folders
source "$ZSH_INC_DIR/folders.zsh"

# Environment variables
source "$ZSH_INC_DIR/variables.zsh"

# Helper library
(( ZSH_LOAD_LIB )) && source_zsh_dir "$ZSH_LIB_DIR"

# PATH
source "$ZSH_INC_DIR/path.zsh"

# Locale
source "$ZSH_INC_DIR/locales.zsh"

# Auto-compile changed files (for next shell startup)
(( ZSH_AUTOCOMPILE )) && compile_zsh_config -q

# Shell files tracking - keep at the end
zfile_track_end ${0:A}