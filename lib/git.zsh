#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Git repository helpers: discovery, parallel fetch and status parsing (used by zgit)
# Depends on: git
##

## Discovery

# Check if a directory is the top level of a git working tree
# A .git directory, or a .git file (worktrees, submodules), must be present
# Usage: is_git_repo <dir>
# Returns: 0 true, 1 false, 2 invalid usage
is_git_repo() {
    (( ARGC == 1 )) || return 2
    [[ -n $1 && -d $1 && ( -d $1/.git || -f $1/.git ) ]]
}

# List git repositories that are direct subdirectories of a directory
# Hidden directories, plain files (e.g. .DS_Store) and directories that are
# not git clones are skipped; symlinks to repositories are included
# Usage: get_git_repos <dir>
# Output: one repository path per line
# Sets: reply to array of repository paths (sorted by name)
# Returns: 0 at least one repository found, 1 none found, 2 invalid usage
get_git_repos() {
    (( ARGC == 1 )) || return 2
    reply=()
    local dir
    for dir in $1/*(N-/on); do
        is_git_repo $dir && reply+=($dir)
    done
    (( ${#reply} )) || return 1
    print -rl -- $reply
}

## Remote

# Fetch all remotes of many repositories in parallel (quietly, with --prune)
# Password, askpass and ssh prompts are disabled (credential helpers and
# ssh-agent still work), so a fetch that needs a password fails instead of
# blocking the shell
# Usage: fetch_git_repos <repo>...
# Output: nothing
# Sets: reply to array of repositories whose fetch failed
# Returns: 0 all fetched, 1 at least one fetch failed, 2 invalid usage
fetch_git_repos() {
    (( ARGC )) || return 2
    # No job control messages ([1] 12345, done ...) in interactive shells
    setopt local_options no_monitor no_notify
    local repo
    local -a pids=()
    for repo in "$@"; do
        {
            # Keep the user's ssh command (env or core.sshCommand), only add BatchMode
            local ssh_cmd=${GIT_SSH_COMMAND:-$(git -C $repo config --get core.sshCommand 2>/dev/null)}
            if [[ -n $GIT_SSH ]]; then
                # Custom ssh wrapper program: leave it untouched
                GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true \
                    git -C $repo fetch --all --prune --quiet
            else
                GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true \
                GIT_SSH_COMMAND="${ssh_cmd:-ssh} -o BatchMode=yes" \
                    git -C $repo fetch --all --prune --quiet
            fi
        } </dev/null >/dev/null 2>&1 &
        pids+=($!)
    done
    reply=()
    local -i i
    for (( i = 1; i <= ARGC; i++ )); do
        wait $pids[i] || reply+=(${argv[i]})
    done
    (( ${#reply} == 0 ))
}

## Status

# Read the state of a repository relative to its upstream, plus local changes
# Uses only local data: run fetch_git_repos (or git fetch) first to compare
# with the current state of the remote
# Usage: get_git_status <repo>
# Output: the sync state (same as REPLY)
# Sets: REPLY to sync state, one of: up-to-date ahead behind diverged
#       no-upstream gone (upstream branch deleted) detached
# Sets: reply=(branch upstream ahead behind staged modified untracked conflicts operation)
#       operation is one of: merge rebase cherry-pick revert bisect (or empty)
# Returns: 0 success, 1 not a git repository or git failed, 2 invalid usage
get_git_status() {
    (( ARGC == 1 )) || return 2
    REPLY="" reply=()
    is_git_repo $1 || return 1
    local -a lines
    lines=("${(@f)$(git -C $1 status --porcelain=v2 --branch 2>/dev/null)}") || return 1

    local branch="" upstream="" line
    local -i ahead=0 behind=0 staged=0 modified=0 untracked=0 conflicts=0 has_ab=0
    local -a words
    for line in $lines; do
        case $line in
            ('# branch.head '*)     branch=${line#\# branch.head } ;;
            ('# branch.upstream '*) upstream=${line#\# branch.upstream } ;;
            ('# branch.ab '*)
                words=(${=line})
                ahead=${words[3]#+} behind=${words[4]#-} has_ab=1
                ;;
            ([12]' '*)
                # XY: X = index (staged), Y = worktree (not staged); '.' = unchanged
                [[ ${line[3]} != . ]] && (( staged++ ))
                [[ ${line[4]} != . ]] && (( modified++ ))
                ;;
            ('u '*) (( conflicts++ )) ;;
            ('? '*) (( untracked++ )) ;;
        esac
    done

    # An operation in progress (git dir is .git, or read from a .git file)
    local git_dir=$1/.git operation=""
    [[ -f $git_dir ]] && git_dir=$(git -C $1 rev-parse --absolute-git-dir 2>/dev/null)
    if [[ -d $git_dir/rebase-merge || -d $git_dir/rebase-apply ]]; then operation=rebase
    elif [[ -f $git_dir/MERGE_HEAD ]]; then operation=merge
    elif [[ -f $git_dir/CHERRY_PICK_HEAD ]]; then operation=cherry-pick
    elif [[ -f $git_dir/REVERT_HEAD ]]; then operation=revert
    elif [[ -f $git_dir/BISECT_LOG ]]; then operation=bisect
    fi

    if [[ $branch == "(detached)" ]]; then
        REPLY=detached
    elif [[ -z $upstream ]]; then
        REPLY=no-upstream
    elif (( ! has_ab )); then
        # Upstream is configured but its remote branch no longer exists
        REPLY=gone
    elif (( ahead && behind )); then
        REPLY=diverged
    elif (( ahead )); then
        REPLY=ahead
    elif (( behind )); then
        REPLY=behind
    else
        REPLY=up-to-date
    fi
    reply=("$branch" "$upstream" $ahead $behind $staged $modified $untracked $conflicts "$operation")
    print -r -- $REPLY
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
