#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# zsh-history-substring-search
# https://github.com/zsh-users/zsh-history-substring-search

load_plugin zsh-history zsh-users/zsh-history-substring-search

bindkey '^[[A' history-substring-search-up 
bindkey '^[[B' history-substring-search-down 

# Configuration options
HISTORY_SUBSTRING_SEARCH_CASE_SENSITIVE=0
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_TIMEOUT=1

# Highlight found and not found terms
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="fg=green,bold"
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="fg=red,bold"
