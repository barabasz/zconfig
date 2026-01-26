#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Helper functions for zsh plugins
# Plugins are stored in $ZPLUGDIR/<name>/ (git clones, ignored in .gitignore)
# Wrapper files $ZPLUGDIR/<name>.zsh handle loading and configuration

# Registry of loaded plugins (associative array: name → main file path)
typeset -gA ZPLUGINS_LOADED

# =============================================================================
# Compilation - low level
# =============================================================================

# Check if a .zsh file needs (re)compilation
# Usage: needs_compile <file.zsh>
# Returns: 0 if needs compile, 1 if up-to-date
needs_compile() {
    (( ARGC == 1 )) || return 1
    local src=$1 zwc=$1.zwc
    local src_mtime zwc_mtime

    # No .zwc exists → needs compile
    [[ -f $zwc ]] || return 0

    # Compare modification times using zstat
    zstat -A src_mtime +mtime "$src" 2>/dev/null || return 1
    zstat -A zwc_mtime +mtime "$zwc" 2>/dev/null || return 0

    # Source newer than compiled → needs recompile
    (( src_mtime > zwc_mtime ))
}

# Compile a single .zsh file
# Usage: compile_file <file.zsh>
# Returns: 0 on success, 1 on failure
compile_file() {
    (( ARGC == 1 )) || return 1
    [[ -f $1 && $1 == *.zsh ]] || return 1
    zcompile "$1" 2>/dev/null
}

# =============================================================================
# Compilation - high level
# =============================================================================

# Compile all .zsh files in a plugin directory
# Usage: compile_plugin <name>
# Returns: 0 on success (or nothing to compile), 1 on failure
compile_plugin() {
    (( ARGC == 1 )) || {
        printe "Usage: compile_plugin <name>"
        return 1
    }
    local name=$1
    local target=$ZPLUGDIR/$name
    local file compiled=0 failed=0

    [[ -d $target ]] || {
        printe "Plugin '$name' not found"
        return 1
    }

    # Find all .zsh files recursively
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
# Returns: 0 if all succeeded, 1 if any failed
compile_plugins() {
    local name failed=0
    local -a dirs=($ZPLUGDIR/*(N/:t))

    (( ${#dirs} == 0 )) && {
        printi "No plugins installed"
        return
    }

    for name in $dirs; do
        compile_plugin "$name" || (( failed++ ))
    done

    (( failed == 0 ))
}

# =============================================================================
# Cleaning
# =============================================================================

# Remove all .zwc files from a plugin directory
# Usage: clean_plugin <name>
# Returns: 0 on success, 1 on failure
clean_plugin() {
    (( ARGC == 1 )) || {
        printe "Usage: clean_plugin <name>"
        return 1
    }
    local name=$1
    local target=$ZPLUGDIR/$name
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
# Returns: 0 on success, 1 if any failed
clean_plugins() {
    local name failed=0
    local -a dirs=($ZPLUGDIR/*(N/:t))

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
# Examples:
#   install_plugin f-sy-h z-shell/F-Sy-H
#   install_plugin f-sy-h https://github.com/z-shell/F-Sy-H
# Returns: 0 on success, 1 on failure
install_plugin() {
    (( ARGC == 2 )) || {
        printe "Usage: install_plugin <name> <repo>"
        return 1
    }
    local name=$1 repo=$2 url
    local target=$ZPLUGDIR/$name

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

# Update a plugin (git pull)
# Recompiles after update (clean + compile)
# Usage: update_plugin <name>
# Returns: 0 on success, 1 on failure
update_plugin() {
    (( ARGC == 1 )) || {
        printe "Usage: update_plugin <name>"
        return 1
    }
    local name=$1
    local target=$ZPLUGDIR/$name

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
# Returns: 0 if all succeeded, 1 if any failed
update_plugins() {
    local name failed=0
    local -a dirs=($ZPLUGDIR/*(N/:t))

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
# Returns: 0 on success, 1 on failure
remove_plugin() {
    (( ARGC == 1 )) || {
        printe "Usage: remove_plugin <name>"
        return 1
    }
    local name=$1
    local target=$ZPLUGDIR/$name

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
# Common patterns: *.plugin.zsh, init.zsh, <name>.zsh
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

# Load a plugin by name
# Automatically compiles .zsh files if needed for faster loading
# Usage: load_plugin <name>
# Returns: 0 on success, 1 on failure
load_plugin() {
    (( ARGC == 1 )) || {
        printe "Usage: load_plugin <name>"
        return 1
    }
    local name=$1
    local target=$ZPLUGDIR/$name

    # Already loaded?
    (( ${+ZPLUGINS_LOADED[$name]} )) && return 0

    [[ -d $target ]] || {
        printe "Plugin '$name' not installed"
        return 1
    }

    find_plugin_file "$target" || {
        printe "Cannot find main file for plugin '$name'"
        return 1
    }

    # Compile if needed (lazy compilation for speed)
    compile_plugin "$name"

    source "$REPLY" || {
        printe "Failed to source $REPLY"
        return 1
    }

    ZPLUGINS_LOADED[$name]=$REPLY
}

# =============================================================================
# Status checks
# =============================================================================

# Check if a plugin is loaded
# Usage: is_plugin_loaded <name>
# Returns: 0 if loaded, 1 otherwise
is_plugin_loaded() {
    (( ARGC == 1 )) && (( ${+ZPLUGINS_LOADED[$1]} ))
}

# Check if a plugin is installed (directory exists)
# Usage: is_plugin_installed <name>
# Returns: 0 if installed, 1 otherwise
is_plugin_installed() {
    (( ARGC == 1 )) && [[ -d $ZPLUGDIR/$1 ]]
}

# List installed plugins
# Usage: list_plugins
# Prints list of installed plugins with status
list_plugins() {
    local name state
    local -a dirs=($ZPLUGDIR/*(N/:t))

    (( ${#dirs} == 0 )) && {
        printi "No plugins installed"
        return
    }

    print "Installed plugins:"
    for name in $dirs; do
        if is_plugin_loaded $name; then
            state="loaded"
        else
            state="not loaded"
        fi
        print "  $name ($state)"
    done
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}
