#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Application package-manager helpers used by zapp.
# These functions are intentionally non-interactive and do not provide user UX.
# Configuration files and symlinks are outside their scope.

# Check whether a package manager required by zapp is available.
# Usage: app_manager_available <brew|apt>
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
        *)
            return 2
            ;;
    esac
}

# Check whether a package is installed by a specific package manager.
# Usage: app_is_installed <brew|apt> <package> [cask]
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

        *)
            return 2
            ;;
    esac
}

# Install a package non-interactively.
# Usage: app_install <brew|apt> <package> [cask]
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

        *)
            return 2
            ;;
    esac

    (( rc == 0 )) || return $rc
    rehash
    return 0
}

# Remove a package non-interactively.
# Usage: app_remove <brew|apt> <package> [cask]
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
