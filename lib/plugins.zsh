#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Zsh plugin management functions
# Plugins are stored in $ZSH_PLUGINS_DIR/<name>/ (git clones, ignored in .gitignore)
# Wrapper files $ZSH_PLUGINS_DIR/<name>.zsh handle loading and configuration
#
# Depends on: compile.zsh (for compile_dir, clean_dir, needs_compile)

# Registry of loaded plugins (associative array: name → main file path)
typeset -gA ZPLUGINS_LOADED

# =============================================================================
# Plugin compilation (wrappers for compile.zsh functions)
# =============================================================================

# Compile all .zsh files in a plugin directory
# Usage: compile_plugin <name>
# Returns: 0 on success, 1 on failure, 2 on invalid usage
compile_plugin() {
    (( ARGC == 1 )) || {
        printe "Usage: compile_plugin <name>"
        return 2
    }
    local name=$1
    local target=$ZSH_PLUGINS_DIR/$name

    [[ -d $target ]] || {
        printe "Plugin '$name' not found"
        return 1
    }

    # Compile recursively (plugins may have subdirectories)
    local file compiled=0 failed=0
    for file in $target/**/*.zsh(N.); do
        if needs_compile "$file"; then
            if compile_file "$file"; then
                (( compiled++ ))
            else
                (( failed++ ))
            fi
        fi
    done

    (( compiled > 0 )) && printd "Compiled $compiled file(s) for plugin '$name'"
    (( failed > 0 )) && printw "$failed file(s) failed to compile"
    (( failed == 0 ))
}

# Compile all installed plugins
# Usage: compile_plugins
compile_plugins() {
    local name failed=0
    local -a dirs=($ZSH_PLUGINS_DIR/*(N/:t))

    (( ${#dirs} == 0 )) && {
        printi "No plugins installed"
        return
    }

    for name in $dirs; do
        compile_plugin "$name" || (( failed++ ))
    done

    (( failed == 0 ))
}

# Remove all .zwc files from a plugin directory
# Usage: clean_plugin <name>
clean_plugin() {
    (( ARGC == 1 )) || {
        printe "Usage: clean_plugin <name>"
        return 1
    }
    local name=$1
    local target=$ZSH_PLUGINS_DIR/$name
    local -a zwc_files

    [[ -d $target ]] || {
        printe "Plugin '$name' not found"
        return 1
    }

    zwc_files=($target/**/*.zwc(N.))
    (( ${#zwc_files} > 0 )) && {
        rm -f $zwc_files
        printd "Cleaned ${#zwc_files} compiled file(s) from '$name'"
    }
}

# Remove all .zwc files from all plugins
# Usage: clean_plugins
clean_plugins() {
    local name failed=0
    local -a dirs=($ZSH_PLUGINS_DIR/*(N/:t))

    (( ${#dirs} == 0 )) && {
        printi "No plugins installed"
        return
    }

    for name in $dirs; do
        clean_plugin "$name" || (( failed++ ))
    done

    (( failed == 0 ))
}

# =============================================================================
# Installation
# =============================================================================

# Install a plugin from git repository
# Usage: install_plugin <name> <repo>
# Repo can be: user/repo (GitHub shorthand) or full URL
install_plugin() {
    (( ARGC == 2 )) || {
        printe "Usage: install_plugin <name> <repo>"
        return 1
    }
    local name=$1 repo=$2 url
    local target=$ZSH_PLUGINS_DIR/$name

    [[ -d $target ]] && {
        printe "Plugin '$name' already installed at $target"
        return 1
    }

    # Detect if repo is full URL or GitHub shorthand
    if [[ $repo == https://* || $repo == git@* ]]; then
        url=$repo
    else
        url="https://github.com/$repo.git"
    fi

    printi "Installing plugin '$name' from $url..."
    git clone --depth 1 "$url" "$target" || {
        printe "Failed to clone $url"
        return 1
    }

    # Compile immediately for faster first load
    compile_plugin "$name"

    prints "Plugin '$name' installed successfully"
}

# =============================================================================
# Updating
# =============================================================================

# Update a plugin (git pull + recompile)
# Usage: update_plugin <name>
update_plugin() {
    (( ARGC == 1 )) || {
        printe "Usage: update_plugin <name>"
        return 1
    }
    local name=$1
    local target=$ZSH_PLUGINS_DIR/$name

    [[ -d $target/.git ]] || {
        printe "Plugin '$name' not found or not a git repo"
        return 1
    }

    printi "Updating plugin '$name'..."
    git -C "$target" pull --ff-only || {
        printe "Failed to update $name"
        return 1
    }

    # Recompile (clean + compile)
    clean_plugin "$name"
    compile_plugin "$name"
}

# Update all installed plugins
# Usage: update_plugins
update_plugins() {
    local name failed=0
    local -a dirs=($ZSH_PLUGINS_DIR/*(N/:t))

    (( ${#dirs} == 0 )) && {
        printi "No plugins installed"
        return
    }

    for name in $dirs; do
        update_plugin "$name" || (( failed++ ))
    done

    (( failed > 0 )) && printw "$failed plugin(s) failed to update"
    (( failed == 0 ))
}

# =============================================================================
# Removal
# =============================================================================

# Remove a plugin
# Usage: remove_plugin <name>
remove_plugin() {
    (( ARGC == 1 )) || {
        printe "Usage: remove_plugin <name>"
        return 1
    }
    local name=$1
    local target=$ZSH_PLUGINS_DIR/$name

    [[ -d $target ]] || {
        printe "Plugin '$name' not found"
        return 1
    }

    printi "Removing plugin '$name'..."
    rm -rf "$target" || {
        printe "Failed to remove $name"
        return 1
    }
    unset "ZPLUGINS_LOADED[$name]"
    prints "Plugin '$name' removed"
}

# =============================================================================
# Loading
# =============================================================================

# Find the main plugin file
# Usage: find_plugin_file <plugin-dir>
# Sets REPLY to the path of the main file, or empty if not found
find_plugin_file() {
    (( ARGC == 1 )) || return 1
    local dir=$1 name=${1:t}
    local -a candidates

    # Priority order for main file detection
    candidates=(
        $dir/*.plugin.zsh(N[1])
        $dir/init.zsh(N)
        $dir/$name.zsh(N)
        $dir/${name:l}.zsh(N)
    )

    REPLY=${candidates[1]:-}
    [[ -n $REPLY ]]
}

# Load a plugin by name (from wrapper)
# Automatically compiles .zsh files if needed
# Usage: load_plugin <name> [repo]
load_plugin() {
    (( ARGC >= 1 && ARGC <= 2 )) || {
        printe "Usage: load_plugin <name> [repo]"
        return 1
    }
    local name=$1
    local repo=${2:-}
    local target=$ZSH_PLUGINS_DIR/$name

    # Already loaded?
    (( ${+ZPLUGINS_LOADED[$name]} )) && return 0

    # Not installed - try auto-install if repo provided and enabled
    if [[ ! -d $target ]]; then
        if [[ -n $repo && ${ZSH_PLUGINS_AUTOINSTALL:-0} == 1 ]]; then
            install_plugin "$name" "$repo" || return 1
        else
            printe "Plugin '$name' not installed"
            [[ -n $repo ]] && printi "Run: install_plugin $name $repo"
            return 1
        fi
    fi

    find_plugin_file "$target" || {
        printe "Cannot find main file for plugin '$name'"
        return 1
    }

    # Compile if needed
    compile_plugin "$name"

    source "$REPLY" || {
        printe "Failed to source $REPLY"
        return 1
    }

    ZPLUGINS_LOADED[$name]=$REPLY
}

# Load a plugin by name directly (without wrapper)
# Usage: load_plugin_directly <name> <repo>
load_plugin_directly() {
    (( ARGC == 2 )) || {
        printe "Usage: load_plugin_directly <name> <repo>"
        return 1
    }
    local name=$1
    local repo=$2
    local target=$ZSH_PLUGINS_DIR/$name

    # Already loaded?
    (( ${+ZPLUGINS_LOADED[$name]} )) && return 0

    # Not installed - try auto-install if enabled
    if [[ ! -d $target ]]; then
        if [[ ${ZSH_PLUGINS_AUTOINSTALL:-0} == 1 ]]; then
            install_plugin "$name" "$repo" || return 1
        else
            printe "Plugin '$name' not installed"
            printi "Run: install_plugin $name $repo"
            return 1
        fi
    fi

    find_plugin_file "$target" || {
        printe "Cannot find main file for plugin '$name'"
        return 1
    }

    local main_file=$REPLY

    # Compile if needed
    compile_plugin "$name"

    # zfile tracking start
    zfile_track_start $main_file

    # Source the plugin
    source "$main_file" || {
        printe "Failed to source $main_file"
        zfile_track_end $main_file
        return 1
    }

    ZPLUGINS_LOADED[$name]=$main_file

    # zfile tracking end
    zfile_track_end $main_file
}

# Load a plugin wrapper file
# Usage: load_plugin_wrapper <name>
load_plugin_wrapper() {
    (( ARGC == 1 )) || {
        printe "Usage: load_plugin_wrapper <name>"
        return 1
    }
    local name=$1
    local wrapper_file=$ZSH_PLUGINS_DIR/$name.zsh
    [[ -f $wrapper_file ]] || {
        printe "Wrapper file '$wrapper_file' not found"
        return 1
    }
    # zfile tracking start
    zfile_track_start $wrapper_file
    # actual sourcing
    source "$wrapper_file" || {
        printe "Failed to source $wrapper_file"
        return 1
    }
    # zfile tracking end
    zfile_track_end $wrapper_file
}

# Source a standalone plugin file directly
# Usage: source_plugin <name>
source_plugin() {
    (( ARGC == 1 )) || {
        printe "Usage: source_plugin <name>"
        return 1
    }
    local name=$1
    local file=$ZSH_PLUGINS_DIR/$name.zsh
    [[ -f $file ]] || {
        printe "Plugin file '$file' not found"
        return 1
    }
    # zfile tracking start
    zfile_track_start $file
    # actual sourcing
    source "$file" || {
        printe "Failed to source $file"
        return 1
    }
    # zfile tracking end
    zfile_track_end $file

    register_plugin $name
}

# =============================================================================
# Status checks
# =============================================================================

# Register a standalone plugin (single file, no repo)
# Usage: register_plugin <name>
register_plugin() {
    (( ARGC == 1 )) || {
        printe "Usage: register_plugin <name>"
        return 1
    }
    local name=$1
    local caller=${funcfiletrace[1]%:*}
    ZPLUGINS_LOADED[$name]=$caller
}

# Check if a plugin is loaded
# Usage: is_plugin_loaded <name>
is_plugin_loaded() {
    (( ARGC == 1 )) && (( ${+ZPLUGINS_LOADED[$1]} ))
}

# Check if a plugin is installed (directory exists)
# Usage: is_plugin_installed <name>
is_plugin_installed() {
    (( ARGC == 1 )) && [[ -d $ZSH_PLUGINS_DIR/$1 ]]
}

# List all plugins
# Usage: list_plugins
list_plugins() {
    local name state type path
    local -a repo_plugins all_plugins
    local -A plugin_types

    # Find repo-based plugins (directories)
    repo_plugins=($ZSH_PLUGINS_DIR/*(N/:t))
    for name in $repo_plugins; do
        plugin_types[$name]="repo"
    done

    # Find standalone plugins from ZPLUGINS_LOADED
    for name path in ${(kv)ZPLUGINS_LOADED}; do
        if [[ ! -d $ZSH_PLUGINS_DIR/$name ]]; then
            plugin_types[$name]="file"
        fi
    done

    # Combine and sort
    all_plugins=(${(ko)plugin_types})

    (( ${#all_plugins} == 0 )) && {
        printi "No plugins found"
        return
    }

    print "Plugins:"
    for name in $all_plugins; do
        type=$plugin_types[$name]
        if is_plugin_loaded $name; then
            state="loaded"
        else
            state="not loaded"
        fi
        printf "  %-20s [%s] %s\n" "$name" "$type" "($state)"
    done
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}
