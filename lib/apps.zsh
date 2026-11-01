#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Application package-manager helpers used by zapp
# These functions are intentionally non-interactive and do not provide user UX.
# Configuration files and symlinks are outside their scope.
# Supported managers: brew (formula or cask), apt, pipx
# Depends on: path.zsh (path_append, path_prepend, path_remove)
##

## Python environment

# Activate zconfig's main Python virtual environment in the current shell
# Mirrors the runtime integration used by apps/python.zsh, but is also callable
# immediately after zapp creates the environment so no shell reload is needed.
# Usage: app_python_env_activate
# Returns: 0 activated, 1 venv unavailable, 2 invalid usage
app_python_env_activate() {
    (( ARGC == 0 )) || return 2
    local venv_path="${VENVDIR:-$HOME/.local/venv}/python"
    [[ -x $venv_path/bin/python ]] || return 1

    # zconfig owns PATH manipulation through lib/path.zsh. Validate helpers
    # before changing any shell state so activation is all-or-nothing.
    (( ${+functions[path_remove]} && ${+functions[path_prepend]} )) || return 1
    path_remove "$venv_path/bin" || return
    path_prepend "$venv_path/bin" || return

    export VIRTUAL_ENV=$venv_path
    unset PYTHONHOME
    export VIRTUAL_ENV_PROMPT=python
    rehash
}

## Internal helpers

# Resolve pipx executable (internal)
# pipx is installed inside zconfig's main Python virtual environment, so it may
# exist before that venv has been added to PATH in the current shell.
# Usage: _app_pipx_path
# Output: none; sets REPLY to the pipx path
# Returns: 0 found, 1 not found, 2 invalid usage
_app_pipx_path() {
    (( ARGC == 0 )) || return 2
    REPLY=""
    if (( ${+commands[pipx]} )); then
        REPLY=$commands[pipx]
        return 0
    fi
    local candidate="${VENVDIR:-$HOME/.local/venv}/python/bin/pipx"
    [[ -x $candidate ]] || return 1
    REPLY=$candidate
}

# Validate manager/type pair and manager availability (internal)
# Usage: _app_validate <manager> [type]
# Returns: 0 valid and available, 1 manager unavailable, 2 invalid usage
_app_validate() {
    case $1 in
        brew)      [[ -z $2 || $2 == cask ]] || return 2 ;;
        apt|pipx)  [[ -z $2 ]] || return 2 ;;
        *)         return 2 ;;
    esac
    app_manager_available "$1"
}

# Run a brew subcommand non-interactively (internal)
# Usage: _app_brew <install|uninstall|upgrade> <package> [cask]
# Returns: brew exit status
_app_brew() {
    local -a cmd=(brew $1 -q)
    [[ $3 == cask ]] && cmd+=(--cask)
    # Assignment prefix instead of `env`: no extra fork
    HOMEBREW_NO_ASK=1 HOMEBREW_AUTO_UPDATE_QUIET=1 $cmd "$2"
}

## Package manager operations

# Check whether a package manager required by zapp is available
# Usage: app_manager_available <brew|apt|pipx>
# Returns: 0 available, 1 unavailable, 2 invalid usage
app_manager_available() {
    (( ARGC == 1 )) || return 2
    case $1 in
        brew) (( ${+commands[brew]} )) ;;
        apt)  (( ${+commands[apt-get]} && ${+commands[dpkg-query]} )) ;;
        pipx) _app_pipx_path ;;
        *)    return 2 ;;
    esac
}

# Check whether a package is installed by a specific package manager
# Usage: app_is_installed <brew|apt|pipx> <package> [cask]
# Returns: 0 installed, 1 not installed or manager unavailable, 2 invalid usage
app_is_installed() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2
    local manager=$1 package=$2 type=$3
    _app_validate "$manager" "$type" || return

    case $manager in
        brew)
            if [[ $type == cask ]]; then
                brew list --cask --versions "$package" &>/dev/null
            else
                brew list --formula --versions "$package" &>/dev/null
            fi
            ;;
        apt)
            [[ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null) == "install ok installed" ]]
            ;;
        pipx)
            _app_pipx_path || return 1
            local output line
            output=$("$REPLY" list --short 2>/dev/null) || return 1
            for line in "${(@f)output}"; do
                [[ ${line%% *} == "$package" ]] && return 0
            done
            return 1
            ;;
    esac
}

# Install a package non-interactively
# Usage: app_install <brew|apt|pipx> <package> [cask]
# Returns: 0 success or already installed, 1 execution error, 2 invalid usage
app_install() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2
    local manager=$1 package=$2 type=$3
    _app_validate "$manager" "$type" || return
    # pipx: the PATH helper is used only when BINDIR is missing from PATH
    [[ $manager == pipx ]] && { (( ${+functions[path_append]} )) || return 1 }

    app_is_installed "$manager" "$package" "$type" && return 0

    case $manager in
        brew)
            _app_brew install "$package" "$type" || return
            ;;
        apt)
            sudo apt-get install -y -qq "$package" || return
            ;;
        pipx)
            _app_pipx_path || return 1
            local pipx_cmd=$REPLY pipx_bin=${BINDIR:-$HOME/.local/bin}
            command mkdir -p -- "$pipx_bin" || return 1
            PIPX_BIN_DIR=$pipx_bin "$pipx_cmd" install --quiet "$package" || return
            # Expose pipx applications immediately without changing zconfig's
            # established PATH priority. Append BINDIR only when it is absent.
            (( ${path[(Ie)$pipx_bin]} )) || path_append "$pipx_bin" || return
            ;;
    esac
    rehash
}

# Upgrade an installed package non-interactively
# Usage: app_upgrade <brew|apt|pipx> <package> [cask]
# Returns: 0 success, 1 not installed or execution error, 2 invalid usage
app_upgrade() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2
    local manager=$1 package=$2 type=$3
    _app_validate "$manager" "$type" || return
    app_is_installed "$manager" "$package" "$type" || return 1

    case $manager in
        brew)
            _app_brew upgrade "$package" "$type" || return
            ;;
        apt)
            # --only-upgrade: never installs a package that is missing
            sudo apt-get install --only-upgrade -y -qq "$package" || return
            ;;
        pipx)
            _app_pipx_path || return 1
            "$REPLY" upgrade --quiet "$package" || return
            ;;
    esac
    rehash
}

# Remove a package non-interactively
# Usage: app_remove <brew|apt|pipx> <package> [cask]
# Returns: 0 success or already absent, 1 execution error, 2 invalid usage
app_remove() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2
    local manager=$1 package=$2 type=$3
    _app_validate "$manager" "$type" || return

    app_is_installed "$manager" "$package" "$type" || return 0

    case $manager in
        brew)
            _app_brew uninstall "$package" "$type" || return
            ;;
        apt)
            sudo apt-get remove -y -qq "$package" || return
            ;;
        pipx)
            _app_pipx_path || return 1
            PIPX_BIN_DIR=${BINDIR:-$HOME/.local/bin} "$REPLY" uninstall --quiet "$package" || return
            ;;
    esac
    rehash
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
