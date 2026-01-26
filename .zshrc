#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start "$ZDOTDIR/.zshrc"

# History configuration
source "$ZINCDIR/history.zsh"

# Colors variables
source "$ZINCDIR/colors.zsh"

# Icons and glyphs
source "$ZINCDIR/icons.zsh"

# PROMPT fallback
source "$ZINCDIR/prompt.zsh"

# Editors and pager
source "$ZINCDIR/editors.zsh"

# Autoloaded functions
## Zsh functions
autoload -Uz zmv
autoload -Uz colors && colors
## User functions
fpath=($ZFNCDIR $fpath)
autoload -Uz $ZFNCDIR/[^_.]*(N.:t)

# Aliases
source $ZINCDIR/aliases.zsh

# Directory hashes
source "$ZINCDIR/hashdirs.zsh"

# App configurations
source_zsh_dir "$ZAPPDIR"

# Plugin configurations
source_zsh_dir "$ZPLUGDIR"

# shell files tracking - keep at the end
zfile_track_end "$ZDOTDIR/.zshrc"

# Ensure successful sourcing
true
