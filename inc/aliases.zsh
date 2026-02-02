#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Aliases
##

# Global
alias -g G='| grep'

# Common
alias info='sysinfo && logininfo'
alias reload="reload_shell"
alias cls='clear'
alias myip='curl icanhazip.com'
alias ds='du -sh ./*/'

# Internal functions

alias help='zhelp'

# Applications - Unconditional Aliases
# (Defining these is virtually free. If the tool is missing, the alias just fails when run)

# 7zip
alias 7z='7zz'

# Brew
alias brewu='brew update && brew upgrade && brew missing && brew autoremove && brew cleanup && brew doctor'

# Code
alias vsc='code'

# Git (Always define these, huge performance win skipping the check)
alias gaa='git add --all'
alias gcm='git commit -m "update"'
alias glog='git log --oneline -n 10'
alias gpu='git add --all && git commit -m "update" && git push'
alias grb='git pull --rebase'
alias gup='git pull --rebase'
alias gsb='git status -sb'
alias gst='git status -s'

# HTTP Server
alias serve='http-server -c-1 -o'

# MC
alias mc='mc --nosubshell'

# Node/JS
alias js='node'
alias ts='npx tsx'

# Oh My Posh
alias omp='oh-my-posh'

# Python (Assume python3 is standard these days)
alias python='python3'
alias py='python3'

# Trippy
alias trip='sudo trip'

# Youtube-DL
alias youtube-dl='yt-dlp'
alias ytdl='yt-dlp'


# --- Shadowing Aliases (Require checks) ---
# We use direct hash lookup (( ${+commands[cmd]} )) which is faster than calling is_installed function

# bat -> cat
(( ${+commands[bat]} )) && alias bat='bat -n' cat='bat'

# cal (BSD style)
(( ${+commands[cal]} )) && alias cal='cal -m3'

# eza -> ls
if (( ${+commands[eza]} )); then
    alias eza='eza --icons'
    alias exa='eza --icons'
    alias ls='eza --group-directories-first'
    alias ll='ls --long'
    alias la='ll --all'
    alias tree='eza --tree  --icons'
    alias tree2='eza --tree --level=2 --icons'
    alias tree3='eza --tree --level=3 --icons'
fi

# gdate -> date
(( ${+commands[gdate]} )) && alias date='gdate'

# gsed -> sed (macOS)
if is_macos && (( ${+commands[gsed]} )); then
    alias sed='gsed'
fi

# nvim -> vim/vi
if (( ${+commands[nvim]} )); then
    alias vi='nvim'
    alias view='nvim -R'
    alias vim='nvim'
    alias neovim='nvim'
    alias vimdiff='nvim -d'
fi

# pip3 -> pip
(( ${+commands[pip3]} )) && alias pip='pip3' pipi='pip install' pipu='pip uninstall' pipf='pip freeze'

# zoxide -> cd
if (( ${+commands[zoxide]} )); then
    alias cd='z'
    alias cd..='z ..'
    alias zz='z -'
fi

# shell files tracking - keep at the end
zfile_track_end ${0:A}