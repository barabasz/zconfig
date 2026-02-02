#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Plugins loading
#
# Plugins are stored in $ZSH_PLUGINS_DIR
# There are three ways to load them:
# 
# to use plugin wrapper (with specific config) use
#    load_plugin_wrapper <name>
# to load a plugin directly use
#    load_plugin_directly <name> <repo>
# to source a plugin file directly use
#    source_plugin <name>
##

# sudo-esc
# adds 'sudo' before the last command after pressing 'Esc Esc' in Zsh.
source_plugin sudo-esc

# fzf-tab
# Replace zsh's default completion selection menu with fzf
# https://github.com/Aloxaf/fzf-tab
# fzf-tab needs to be loaded before plugins which will wrap widgets
# such as zsh-autosuggestions or fast-syntax-highlighting
load_plugin_directly fzf-tab Aloxaf/fzf-tab

# zsh-autosuggestions
# Fish-like fast/unobtrusive autosuggestions for Zsh
load_plugin_wrapper zsh-autosuggestions

# zsh-history-substring-search
# Type in any part of any command from history
load_plugin_wrapper zsh-history

# F-Sy-H - Feature-rich Syntax Highlighting for Zsh
# https://github.com/z-shell/F-Sy-H
load_plugin_directly f-sy-h z-shell/F-Sy-H

# shell files tracking - keep at the end
zfile_track_end ${0:A}