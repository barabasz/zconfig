#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Locales configuration
##

# English language
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en:C
export LC_MESSAGES=en_US.UTF-8

# Polish locale
export LC_ADDRESS=pl_PL.UTF-8
export LC_COLLATE=pl_PL.UTF-8
export LC_CTYPE=pl_PL.UTF-8
export LC_IDENTIFICATION=pl_PL.UTF-8
export LC_MEASUREMENT=pl_PL.UTF-8
export LC_MONETARY=pl_PL.UTF-8
export LC_NAME=pl_PL.UTF-8
export LC_NUMERIC=pl_PL.UTF-8
export LC_PAPER=pl_PL.UTF-8
export LC_TELEPHONE=pl_PL.UTF-8
export LC_TIME=pl_PL.UTF-8

# Do not set LC_ALL, it overrides all other LC_* settings
export LC_ALL=

# Ensure required locales are generated (Linux/Debian-based only)
__ensure_locales() {
    [[ "$OSTYPE" != linux* ]] && return 0
    [[ ! -f /etc/debian_version ]] && return 0

    # Check if sudo is available without password (non-interactive)
    sudo -n true 2>/dev/null || return 0

    local needs_generation=false
    local locales_to_check=("en_US.UTF-8" "pl_PL.UTF-8")

    # Install locales package if missing
    if ! dpkg -s locales &>/dev/null; then
        sudo -n apt-get install -qq -y locales &>/dev/null || return 1
    fi

    # Check and uncomment locales in /etc/locale.gen
    for loc in "${locales_to_check[@]}"; do
        if ! locale -a 2>/dev/null | grep -qFx "${loc/UTF-8/utf8}"; then
            needs_generation=true
            # Uncomment the locale line if it exists commented
            if grep -qE "^#\s*${loc}" /etc/locale.gen 2>/dev/null; then
                sudo -n sed -i "s/^#\s*\(${loc}\)/\1/" /etc/locale.gen 2>/dev/null
            # Or add the line if it doesn't exist at all
            elif ! grep -qE "^\s*${loc}" /etc/locale.gen 2>/dev/null; then
                print "${loc} UTF-8" | sudo -n tee -a /etc/locale.gen &>/dev/null
            fi
        fi
    done

    # Generate locales if needed
    if $needs_generation; then
        sudo -n locale-gen &>/dev/null
    fi
}

if [[ "$OSTYPE" != darwin* ]]; then
    __ensure_locales
    unset -f __ensure_locales
fi

# shell files tracking - keep at the end
zfile_track_end ${0:A}
