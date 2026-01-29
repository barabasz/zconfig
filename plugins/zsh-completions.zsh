#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# zsh-completions
# https://github.com/zsh-users/zsh-completions

load_plugin zsh-completions zsh-users/zsh-completions
fpath_append "${ZSH_PLUGINS_DIR}/zsh-completions/src"

# shell files tracking - keep at the end
zfile_track_end ${0:A}