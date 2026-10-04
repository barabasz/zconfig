#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Application package-manager helpers used by zapp.
# These functions are intentionally non-interactive and do not provide user UX.
# Configuration files and symlinks are outside their scope.

# Resolve pipx executable.
# pipx is installed inside zconfig's main Python virtual environment, so it may
# exist before that venv has been added to PATH in the current shell.
# Usage: _app_pipx_path
# Returns: 0 found (REPLY=path), 1 not found, 2 invalid usage
_app_pipx_path() {
    (( ARGC == 0 )) || return 2

    if (( ${+commands[pipx]} )); then
        REPLY="$commands[pipx]"
        return 0
    fi

    local venvdir="${VENVDIR:-$HOME/.local/venv}"
    local candidate="$venvdir/python/bin/pipx"
    if [[ -x "$candidate" ]]; then
        REPLY="$candidate"
        return 0
    fi

    return 1
}

# Check whether a package manager required by zapp is available.
# Usage: app_manager_available <brew|apt|pipx>
# Returns: 0 available, 1 unavailable, 2 invalid usage
app_manager_available() {
    (( ARGC == 1 )) || return 2

    case "$1" in
        brew)
            (( ${+commands[brew]} ))
            ;;
        apt)
            (( ${+commands[apt-get]} && ${+commands[dpkg-query]} ))
            ;;
        pipx)
            _app_pipx_path >/dev/null
            ;;
        *)
            return 2
            ;;
    esac
}

# Check whether a package is installed by a specific package manager.
# Usage: app_is_installed <brew|apt|pipx> <package> [cask]
# Returns: 0 installed, 1 not installed/unavailable, 2 invalid usage
app_is_installed() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2

    local manager="$1"
    local package="$2"
    local type="${3:-}"

    case "$manager" in
        brew)
            app_manager_available brew || return 1
            case "$type" in
                "")   brew list --formula --versions "$package" >/dev/null 2>&1 ;;
                cask) brew list --cask --versions "$package" >/dev/null 2>&1 ;;
                *)    return 2 ;;
            esac
            ;;

        apt)
            [[ -z "$type" ]] || return 2
            app_manager_available apt || return 1
            [[ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null)" == "install ok installed" ]]
            ;;

        pipx)
            [[ -z "$type" ]] || return 2

            local pipx_cmd output line
            _app_pipx_path || return 1
            pipx_cmd="$REPLY"

            output=$("$pipx_cmd" list --short 2>/dev/null) || return 1
            for line in "${(@f)output}"; do
                [[ "${line%% *}" == "$package" ]] && return 0
            done
            return 1
            ;;

        *)
            return 2
            ;;
    esac
}

# Install a package non-interactively.
# Usage: app_install <brew|apt|pipx> <package> [cask]
# Returns: 0 success/already installed, 1 execution error, 2 invalid usage
app_install() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2

    local manager="$1"
    local package="$2"
    local type="${3:-}"

    case "$manager" in
        brew)
            app_manager_available brew || return 1
            [[ -z "$type" || "$type" == cask ]] || return 2
            ;;
        apt)
            app_manager_available apt || return 1
            [[ -z "$type" ]] || return 2
            ;;
        pipx)
            app_manager_available pipx || return 1
            [[ -z "$type" ]] || return 2
            ;;
        *)
            return 2
            ;;
    esac

    app_is_installed "$manager" "$package" "$type" && return 0

    local rc=0
    case "$manager" in
        brew)
            local -a cmd=(brew install -q)
            case "$type" in
                "") ;;
                cask) cmd+=(--cask) ;;
                *) return 2 ;;
            esac
            cmd+=("$package")
            env HOMEBREW_NO_ASK=1 HOMEBREW_AUTO_UPDATE_QUIET=1 "${cmd[@]}"
            rc=$?
            ;;

        apt)
            sudo apt-get install -y -qq "$package"
            rc=$?
            ;;

        pipx)
            local pipx_cmd pipx_bin
            _app_pipx_path || return 1
            pipx_cmd="$REPLY"
            pipx_bin="${BINDIR:-$HOME/.local/bin}"
            mkdir -p "$pipx_bin" || return 1

            PIPX_BIN_DIR="$pipx_bin" "$pipx_cmd" install --quiet "$package"
            rc=$?

            # Make newly exposed pipx applications available immediately in
            # the current shell, even if the bin directory did not exist when
            # the shell started.
            if (( rc == 0 )); then
                if (( ${+functions[path_prepend]} )); then
                    (( ${+functions[path_remove]} )) && path_remove "$pipx_bin"
                    path_prepend "$pipx_bin"
                elif [[ ":$PATH:" != *":$pipx_bin:"* ]]; then
                    export PATH="$pipx_bin:$PATH"
                fi
            fi
            ;;

        *)
            return 2
            ;;
    esac

    (( rc == 0 )) || return $rc
    rehash
    return 0
}

# Remove a package non-interactively.
# Usage: app_remove <brew|apt|pipx> <package> [cask]
# Returns: 0 success/already absent, 1 execution error, 2 invalid usage
app_remove() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2

    local manager="$1"
    local package="$2"
    local type="${3:-}"

    case "$manager" in
        brew)
            app_manager_available brew || return 1
            [[ -z "$type" || "$type" == cask ]] || return 2
            ;;
        apt)
            app_manager_available apt || return 1
            [[ -z "$type" ]] || return 2
            ;;
        pipx)
            app_manager_available pipx || return 1
            [[ -z "$type" ]] || return 2
            ;;
        *)
            return 2
            ;;
    esac

    app_is_installed "$manager" "$package" "$type" || return 0

    local rc=0
    case "$manager" in
        brew)
            local -a cmd=(brew uninstall -q)
            case "$type" in
                "") ;;
                cask) cmd+=(--cask) ;;
                *) return 2 ;;
            esac
            cmd+=("$package")
            env HOMEBREW_NO_ASK=1 HOMEBREW_AUTO_UPDATE_QUIET=1 "${cmd[@]}"
            rc=$?
            ;;

        apt)
            sudo apt-get remove -y -qq "$package"
            rc=$?
            ;;

        pipx)
            local pipx_cmd pipx_bin
            _app_pipx_path || return 1
            pipx_cmd="$REPLY"
            pipx_bin="${BINDIR:-$HOME/.local/bin}"
            PIPX_BIN_DIR="$pipx_bin" "$pipx_cmd" uninstall --quiet "$package"
            rc=$?
            ;;

        *)
            return 2
            ;;
    esac

    (( rc == 0 )) || return $rc
    rehash
    return 0
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
