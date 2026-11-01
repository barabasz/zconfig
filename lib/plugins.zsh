#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Zsh plugin management functions
# Plugins are stored in $ZSH_PLUGINS_DIR/<name>/ (git clones, ignored in .gitignore).
# Wrapper files $ZSH_PLUGINS_DIR/<name>.zsh handle loading and configuration.
# Depends on: compile.zsh (compile_file, needs_compile), print.zsh (output)
##

# Registry of loaded plugins (associative array: name → main file path)
typeset -gA ZPLUGINS_LOADED

## Internal helpers

# Validate a plugin name, so it can never point outside $ZSH_PLUGINS_DIR (internal)
# Allowed: letters, digits, ".", "_", "-"; must start with a letter or digit.
# Usage: _plugin_name_ok <name>
# Returns: 0 valid, 2 invalid name or ZSH_PLUGINS_DIR not set
_plugin_name_ok() {
    if [[ -z $ZSH_PLUGINS_DIR ]]; then
        printe "ZSH_PLUGINS_DIR is not set."
        return 2
    fi
    if [[ ! $1 =~ '^[[:alnum:]][[:alnum:]._-]*$' ]]; then
        printe "Invalid plugin name: '$1'"
        return 2
    fi
}

# Source a file with zfile tracking; tracking is closed also on failure (internal)
# Usage: _plugin_source <file>
# Returns: 0 success, 1 failure
_plugin_source() {
    local file=$1
    zfile_track_start $file
    source "$file"
    local -i rc=$?
    zfile_track_end $file
    if (( rc )); then
        printe "Failed to source $file"
        return 1
    fi
}

# Run a function for every installed plugin (internal)
# Usage: _plugin_each <function>
# Returns: 0 all succeeded or no plugins, 1 at least one failed
_plugin_each() {
    local name
    local -i failed=0
    local -a dirs=($ZSH_PLUGINS_DIR/*(N/:t))
    if (( ! ${#dirs} )); then
        printi "No plugins installed."
        return 0
    fi
    for name in $dirs; do
        $1 "$name" || (( failed++ ))
    done
    (( failed )) && printw "$failed plugin(s) failed: $1"
    (( failed == 0 ))
}

# Build a git URL from GitHub shorthand or return a full URL unchanged (internal)
# Usage: _plugin_url <repo>
# Output: none; sets REPLY to the URL
_plugin_url() {
    if [[ $1 == (https://*|git@*|ssh://*|file://*) ]]; then
        REPLY=$1
    else
        REPLY="https://github.com/$1.git"
    fi
}

## Compilation

# Compile all .zsh files in a plugin directory (recursively)
# Usage: compile_plugin <name>
# Returns: 0 success, 1 failure, 2 invalid usage
compile_plugin() {
    (( ARGC == 1 )) || { _lib_usage "compile_plugin <name>"; return }
    _plugin_name_ok "$1" || return
    local name=$1 file
    local target=$ZSH_PLUGINS_DIR/$name
    local -i compiled=0 failed=0

    [[ -d $target ]] || { printe "Plugin '$name' not found."; return 1 }

    for file in $target/**/*.zsh(N.); do
        needs_compile "$file" || continue
        if compile_file "$file"; then
            (( compiled++ ))
        else
            (( failed++ ))
        fi
    done

    (( compiled )) && printd "Compiled $compiled file(s) for plugin '$name'"
    (( failed )) && printw "$failed file(s) failed to compile for plugin '$name'"
    (( failed == 0 ))
}

# Compile all installed plugins
# Usage: compile_plugins
# Returns: 0 success, 1 at least one plugin failed, 2 invalid usage
compile_plugins() {
    (( ARGC == 0 )) || return 2
    _plugin_each compile_plugin
}

# Remove all .zwc files from a plugin directory
# Usage: clean_plugin <name>
# Returns: 0 success, 1 failure, 2 invalid usage
clean_plugin() {
    (( ARGC == 1 )) || { _lib_usage "clean_plugin <name>"; return }
    _plugin_name_ok "$1" || return
    local name=$1
    local target=$ZSH_PLUGINS_DIR/$name

    [[ -d $target ]] || { printe "Plugin '$name' not found."; return 1 }

    local -a zwc_files=($target/**/*.zwc(N.))
    (( ${#zwc_files} )) || return 0
    command rm -f -- $zwc_files || return 1
    printd "Cleaned ${#zwc_files} compiled file(s) from '$name'"
}

# Remove all .zwc files from all plugins
# Usage: clean_plugins
# Returns: 0 success, 1 at least one plugin failed, 2 invalid usage
clean_plugins() {
    (( ARGC == 0 )) || return 2
    _plugin_each clean_plugin
}

## Installation

# Install a plugin from a git repository
# Usage: install_plugin [-b|--branch <tag_or_branch>] <name> <repo>
# Repo can be "user/repo" (GitHub shorthand) or a full URL.
# Example: install_plugin -b v0.7.1 zsh-autosuggestions zsh-users/zsh-autosuggestions
# Returns: 0 success, 1 failure, 2 invalid usage, 127 git not found
install_plugin() {
    local -a branch_opt
    zparseopts -D b:=branch_opt -branch:=branch_opt
    (( ARGC == 2 )) || { _lib_usage "install_plugin [-b <tag>] <name> <repo>"; return }
    _plugin_name_ok "$1" || return
    (( ${+commands[git]} )) || { printe "git is not installed."; return 127 }
    local name=$1 repo=$2
    local target=$ZSH_PLUGINS_DIR/$name

    if [[ -e $target ]]; then
        printe "Plugin '$name' already installed at $target"
        return 1
    fi

    _plugin_url "$repo"
    local url=$REPLY
    local -a clone_args=(--depth 1)
    (( ${#branch_opt} )) && clone_args+=(--branch "${branch_opt[-1]}")

    printi "Installing plugin '$name' from $url..."
    if ! git clone -q $clone_args -- "$url" "$target"; then
        printe "Failed to clone $url"
        return 1
    fi

    # Compile immediately for faster first load
    compile_plugin "$name"
    prints "Plugin '$name' installed."
}

# Reinstall a plugin (remove and clone again from its origin URL)
# A tag or branch selected with install_plugin --branch is kept.
# Usage: reinstall_plugin <name>
# Returns: 0 success, 1 failure, 2 invalid usage
reinstall_plugin() {
    (( ARGC == 1 )) || { _lib_usage "reinstall_plugin <name>"; return }
    _plugin_name_ok "$1" || return
    local name=$1
    local target=$ZSH_PLUGINS_DIR/$name
    local url
    url=$(git -C "$target" remote get-url origin 2>/dev/null)
    if [[ -z $url ]]; then
        printe "Plugin '$name' not found or has no git origin."
        return 1
    fi
    # Pinned selection: a branch other than the remote default when HEAD is
    # attached; an exact tag only when HEAD is detached (a branch tip may also
    # carry a tag, and pinning it would stop update_plugin from following the branch)
    local ref default_ref
    if ref=$(git -C "$target" symbolic-ref -q --short HEAD 2>/dev/null); then
        default_ref=$(git -C "$target" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
        [[ $ref == ${default_ref#origin/} ]] && ref=""
    else
        ref=$(git -C "$target" describe --tags --exact-match HEAD 2>/dev/null)
    fi
    remove_plugin "$name" || return 1
    if [[ -n $ref ]]; then
        install_plugin --branch "$ref" "$name" "$url"
    else
        install_plugin "$name" "$url"
    fi
}

## Updating

# Update a plugin (git pull, then recompile)
# Usage: update_plugin <name>
# Returns: 0 success, 1 failure, 2 invalid usage
update_plugin() {
    (( ARGC == 1 )) || { _lib_usage "update_plugin <name>"; return }
    _plugin_name_ok "$1" || return
    local name=$1
    local target=$ZSH_PLUGINS_DIR/$name

    if [[ ! -d $target/.git ]]; then
        printe "Plugin '$name' not found or not a git repo."
        return 1
    fi

    printi "Updating plugin '$name'..."
    if ! git -C "$target" pull -q --ff-only; then
        printe "Failed to update $name"
        return 1
    fi
    clean_plugin "$name"
    compile_plugin "$name"
}

# Update all installed plugins
# Usage: update_plugins
# Returns: 0 success, 1 at least one plugin failed, 2 invalid usage
update_plugins() {
    (( ARGC == 0 )) || return 2
    _plugin_each update_plugin
}

# List plugins that have updates available (git fetch, no changes to files)
# Usage: outdated_plugins
# Output: names of outdated plugins with commit counts (stdout); also sets reply
# Returns: 0 at least one outdated, 1 all up to date, 2 invalid usage
outdated_plugins() {
    (( ARGC == 0 )) || return 2
    reply=()
    local dir name
    local -i behind
    for dir in $ZSH_PLUGINS_DIR/*/.git(N/:h); do
        name=${dir:t}
        git -C "$dir" fetch -q 2>/dev/null || { printw "Cannot fetch '$name'"; continue }
        behind=$(git -C "$dir" rev-list --count HEAD..@{upstream} 2>/dev/null)
        if (( behind )); then
            reply+=("$name")
            print -r -- "$name ($behind new commit(s))"
        fi
    done
    (( ${#reply} ))
}

## Removal

# Remove a plugin (deletes its directory)
# Usage: remove_plugin <name>
# Returns: 0 success, 1 failure, 2 invalid usage
remove_plugin() {
    (( ARGC == 1 )) || { _lib_usage "remove_plugin <name>"; return }
    _plugin_name_ok "$1" || return
    local name=$1
    local target=$ZSH_PLUGINS_DIR/$name

    if [[ ! -d $target ]]; then
        printe "Plugin '$name' not found."
        return 1
    fi

    printi "Removing plugin '$name'..."
    if ! command rm -rf -- "$target"; then
        printe "Failed to remove $name"
        return 1
    fi
    unset "ZPLUGINS_LOADED[$name]"
    prints "Plugin '$name' removed."
}

## Loading

# Find the main plugin file
# Usage: find_plugin_file <plugin_dir>
# Output: none; sets REPLY to the main file path (empty if not found)
# Returns: 0 found, 1 not found, 2 invalid usage
find_plugin_file() {
    (( ARGC == 1 )) || return 2
    local dir=$1 name=${1:t}
    # Priority order for main file detection
    local -a candidates=(
        $dir/*.plugin.zsh(N[1])
        $dir/init.zsh(N)
        $dir/$name.zsh(N)
        $dir/${name:l}.zsh(N)
    )
    REPLY=${candidates[1]:-}
    [[ -n $REPLY ]]
}

# Ensure a plugin is installed, auto-installing when allowed (internal)
# Usage: _plugin_ensure <name> [repo]
# Returns: 0 installed, 1 not installed
_plugin_ensure() {
    [[ -d $ZSH_PLUGINS_DIR/$1 ]] && return 0
    if [[ -n $2 && ${ZSH_PLUGINS_AUTOINSTALL:-0} == 1 ]]; then
        install_plugin "$1" "$2"
        return
    fi
    printe "Plugin '$1' not installed."
    [[ -n $2 ]] && printi "Run: install_plugin $1 $2"
    return 1
}

# Load a plugin by name (used by wrapper files)
# Compiles the plugin only when its main file has no up-to-date .zwc,
# so a normal shell start costs one file test per plugin.
# Usage: load_plugin <name> [repo]
# Returns: 0 success, 1 failure, 2 invalid usage
load_plugin() {
    (( ARGC >= 1 && ARGC <= 2 )) || { _lib_usage "load_plugin <name> [repo]"; return }
    _plugin_name_ok "$1" || return
    local name=$1 repo=$2

    (( ${+ZPLUGINS_LOADED[$name]} )) && return 0
    _plugin_ensure "$name" "$repo" || return 1

    if ! find_plugin_file "$ZSH_PLUGINS_DIR/$name"; then
        printe "Cannot find main file for plugin '$name'."
        return 1
    fi
    local main_file=$REPLY

    needs_compile "$main_file" && compile_plugin "$name"
    _plugin_source "$main_file" || return 1
    ZPLUGINS_LOADED[$name]=$main_file
}

# Load a plugin by name directly (without a wrapper file)
# Usage: load_plugin_directly <name> <repo>
# Returns: 0 success, 1 failure, 2 invalid usage
load_plugin_directly() {
    (( ARGC == 2 )) || { _lib_usage "load_plugin_directly <name> <repo>"; return }
    load_plugin "$1" "$2"
}

# Load a plugin wrapper file ($ZSH_PLUGINS_DIR/<name>.zsh)
# Usage: load_plugin_wrapper <name>
# Returns: 0 success, 1 failure, 2 invalid usage
load_plugin_wrapper() {
    (( ARGC == 1 )) || { _lib_usage "load_plugin_wrapper <name>"; return }
    _plugin_name_ok "$1" || return
    local wrapper_file=$ZSH_PLUGINS_DIR/$1.zsh
    if [[ ! -f $wrapper_file ]]; then
        printe "Wrapper file '$wrapper_file' not found."
        return 1
    fi
    _plugin_source "$wrapper_file"
}

# Source a standalone plugin file ($ZSH_PLUGINS_DIR/<name>.zsh) and register it
# Usage: source_plugin <name>
# Returns: 0 success, 1 failure, 2 invalid usage
source_plugin() {
    (( ARGC == 1 )) || { _lib_usage "source_plugin <name>"; return }
    _plugin_name_ok "$1" || return
    local file=$ZSH_PLUGINS_DIR/$1.zsh
    if [[ ! -f $file ]]; then
        printe "Plugin file '$file' not found."
        return 1
    fi
    _plugin_source "$file" || return 1
    register_plugin "$1" "$file"
}

## Status

# Register a standalone plugin (single file, no repo)
# Without a path, the file that called register_plugin is recorded.
# Usage: register_plugin <name> [file]
# Returns: 0 success, 2 invalid usage
register_plugin() {
    (( ARGC >= 1 && ARGC <= 2 )) || { _lib_usage "register_plugin <name> [file]"; return }
    ZPLUGINS_LOADED[$1]=${2:-${funcfiletrace[1]%:*}}
}

# Check if a plugin is loaded
# Usage: is_plugin_loaded <name>
# Returns: 0 true, 1 false, 2 invalid usage
is_plugin_loaded() {
    (( ARGC == 1 )) || return 2
    (( ${+ZPLUGINS_LOADED[$1]} ))
}

# Check if a plugin is installed (its directory exists)
# Usage: is_plugin_installed <name>
# Returns: 0 true, 1 false, 2 invalid usage
is_plugin_installed() {
    (( ARGC == 1 )) || return 2
    _plugin_name_ok "$1" 2>/dev/null || return 1
    [[ -d $ZSH_PLUGINS_DIR/$1 ]]
}

# List all plugins (installed repositories and loaded standalone files)
# Usage: list_plugins
# Output: table of plugins (stdout)
# Returns: 0 success, 2 invalid usage
list_plugins() {
    (( ARGC == 0 )) || return 2
    local name kind state
    local -A plugin_kinds

    for name in $ZSH_PLUGINS_DIR/*(N/:t); do
        plugin_kinds[$name]=repo
    done
    # Standalone plugins are known only from the registry
    for name in ${(k)ZPLUGINS_LOADED}; do
        [[ -d $ZSH_PLUGINS_DIR/$name ]] || plugin_kinds[$name]=file
    done

    if (( ! ${#plugin_kinds} )); then
        printi "No plugins found."
        return 0
    fi

    print "Plugins:"
    for name in ${(ko)plugin_kinds}; do
        kind=$plugin_kinds[$name]
        if is_plugin_loaded "$name"; then
            state=loaded
        else
            state="not loaded"
        fi
        printf '  %-20s [%s] (%s)\n' "$name" "$kind" "$state"
    done
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
