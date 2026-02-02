#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Python virtual environment configuration

# Guard: Fast check if python is even installed
(( ${+commands[python3]} )) || return

# Define venv path once
local venv_path="$VENVDIR/python"

# Check for activate script existence (proof of valid venv)
if [[ -f "$venv_path/bin/activate" ]]; then
    # Manual activation - avoids 'source' overhead (~3ms -> ~0.1ms)
    
    # 1. Set VIRTUAL_ENV (Critical for tools like pip, starship, oh-my-posh)
    export VIRTUAL_ENV="$venv_path"

    # 2. Prepend to PATH (Only once!)
    export PATH="$VIRTUAL_ENV/bin:$PATH"

    # 3. Unset PYTHONHOME (Safety measure)
    unset PYTHONHOME

    # 4. Optional: Set Prompt hint
    export VIRTUAL_ENV_PROMPT="python"
fi

# shell files tracking - keep at the end
zfile_track_end ${0:A}