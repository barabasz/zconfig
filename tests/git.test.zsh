# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Tests for lib/git.zsh (repository discovery, parallel fetch, status parsing)
# Builds throw-away repositories with a local bare "remote" in a temp directory

if ! (( $+commands[git] )); then
    print -r -- "SKIP [$T_FILE] git not installed"
    return 0
fi

local tmp=${TMPDIR:-/tmp}/zconfig-git-test.$$
rm -rf $tmp && mkdir -p $tmp/remotes $tmp/work $tmp/gh
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

# Create a bare remote with one commit on main and clone it to $tmp/gh/<name>
_mkrepo() {
    git init -q --bare -b main $tmp/remotes/$1.git
    git clone -q $tmp/remotes/$1.git $tmp/work/$1 2>/dev/null
    git -C $tmp/work/$1 checkout -q -b main 2>/dev/null
    print a > $tmp/work/$1/file
    git -C $tmp/work/$1 add file
    git -C $tmp/work/$1 commit -qm init
    git -C $tmp/work/$1 push -q origin main 2>/dev/null
    git clone -q $tmp/remotes/$1.git $tmp/gh/$1
}
# Commit in the "other" clone and push, so the tested clone is behind
_remote_commit() {
    print r >> $tmp/work/$1/file
    git -C $tmp/work/$1 commit -qam remote
    git -C $tmp/work/$1 push -q origin main 2>/dev/null
}
# Commit locally in the tested clone (not pushed)
_local_commit() {
    print l > $tmp/gh/$1/local
    git -C $tmp/gh/$1 add local
    git -C $tmp/gh/$1 commit -qm local
}

local name
for name in ahead behind clean diverged dirty noup; do _mkrepo $name; done
_local_commit ahead
_remote_commit behind
_local_commit diverged; _remote_commit diverged
print x >> $tmp/gh/dirty/file
print s > $tmp/gh/dirty/staged && git -C $tmp/gh/dirty add staged
: > $tmp/gh/dirty/.DS_Store
git -C $tmp/gh/noup checkout -q -b feature
# Not repositories: a plain folder, a file, a hidden clone
mkdir $tmp/gh/plain
: > $tmp/gh/.DS_Store
git clone -q $tmp/remotes/clean.git $tmp/gh/.hidden

## is_git_repo
assert_ok is_git_repo $tmp/gh/clean
assert_fail is_git_repo $tmp/gh/plain
assert_fail is_git_repo $tmp/gh/.DS_Store
assert_fail is_git_repo $tmp/missing
assert_rc 2 is_git_repo

## get_git_repos: only real clones, sorted, no hidden dirs or files
get_git_repos $tmp/gh >/dev/null
assert_eq "${(j: :)${(@)reply:t}}" "ahead behind clean dirty diverged noup" "get_git_repos list"
assert_fail get_git_repos $tmp/gh/plain
assert_rc 2 get_git_repos

## get_git_status before fetch: remote changes are not visible yet
get_git_status $tmp/gh/behind >/dev/null
assert_eq "$REPLY" up-to-date "behind (not fetched)"

## fetch_git_repos
get_git_repos $tmp/gh >/dev/null
assert_ok fetch_git_repos $reply
git clone -q $tmp/remotes/clean.git $tmp/gh/broken
git -C $tmp/gh/broken remote set-url origin $tmp/remotes/missing.git
fetch_git_repos $tmp/gh/clean $tmp/gh/broken
assert_eq "$status:${(j: :)${(@)reply:t}}" "1:broken" "fetch_git_repos reports failed repos"
assert_rc 2 fetch_git_repos

## get_git_status after fetch
get_git_status $tmp/gh/clean >/dev/null
assert_eq "$REPLY" up-to-date "clean"
assert_eq "${(j:,:)reply}" "main,origin/main,0,0,0,0,0,0," "clean reply"
get_git_status $tmp/gh/ahead >/dev/null
assert_eq "$REPLY:${reply[3]}:${reply[4]}" "ahead:1:0" "ahead"
get_git_status $tmp/gh/behind >/dev/null
assert_eq "$REPLY:${reply[3]}:${reply[4]}" "behind:0:1" "behind"
get_git_status $tmp/gh/diverged >/dev/null
assert_eq "$REPLY:${reply[3]}:${reply[4]}" "diverged:1:1" "diverged"
get_git_status $tmp/gh/dirty >/dev/null
assert_eq "$REPLY:${reply[5]}:${reply[6]}:${reply[7]}" "up-to-date:1:1:1" "dirty: staged, modified, untracked"
get_git_status $tmp/gh/noup >/dev/null
assert_eq "$REPLY:${reply[1]}" "no-upstream:feature" "no upstream"
assert_eq "$(get_git_status $tmp/gh/clean)" up-to-date "prints the state"

# Upstream branch deleted on the remote
git -C $tmp/gh/clean checkout -q -b tmp
git -C $tmp/gh/clean push -q -u origin tmp 2>/dev/null
git -C $tmp/gh/clean push -q origin --delete tmp 2>/dev/null
git -C $tmp/gh/clean fetch -q --prune
get_git_status $tmp/gh/clean >/dev/null
assert_eq "$REPLY" gone "upstream gone"
git -C $tmp/gh/clean checkout -q main

# Detached HEAD
git -C $tmp/gh/clean checkout -q --detach
get_git_status $tmp/gh/clean >/dev/null
assert_eq "$REPLY" detached "detached HEAD"
git -C $tmp/gh/clean checkout -q main

# Merge conflict in progress (both sides changed the same line)
_mkrepo conflict
_remote_commit conflict
print local > $tmp/gh/conflict/file
git -C $tmp/gh/conflict commit -qam local
git -C $tmp/gh/conflict pull -q --no-rebase --no-edit >/dev/null 2>&1
get_git_status $tmp/gh/conflict >/dev/null
assert_eq "$REPLY:${reply[8]}:${reply[9]}" "diverged:1:merge" "merge conflict"

assert_fail get_git_status $tmp/gh/plain
assert_rc 2 get_git_status

## zgit status (functions/zgit): one line per real repository, with its state
fpath=($REPO_DIR/functions $fpath)
autoload -Uz zgit
local out
out=$(GHDIR=$tmp/gh zgit status -n 2>&1)
assert_eq "$status" 0 "zgit status -n rc"
local -a out_lines=("${(@f)out}")
assert_eq "${#${(@M)out_lines:#*/8  *}}" 8 "zgit status: 8 repositories (no plain/hidden/.DS_Store)"
assert_eq "${#${(@M)out_lines:#*behind*"1 behind (pull needed)"}}" 1 "zgit status: behind"
assert_eq "${#${(@M)out_lines:#*ahead*"1 ahead (push needed)"}}" 1 "zgit status: ahead"
assert_eq "${#${(@M)out_lines:#*dirty*up to date · 1 staged · 1 modified · 1 untracked}}" 1 "zgit status: local changes"
assert_eq "${#${(@M)out_lines:#*conflict*merge in progress · 1 conflicted*}}" 1 "zgit status: conflict"
assert_eq "${#${(@M)out_lines:#*noup*feature*no upstream branch}}" 1 "zgit status: no upstream"
assert_eq "${#${(@M)out_lines:#*broken*}}" 1 "zgit status: broken remote listed"
out=$(GHDIR=$tmp/gh zgit status 2>&1)
assert_eq "$status" 1 "zgit status rc when a fetch fails"
assert_eq "${#${(@M)${(@f)out}:#*broken*fetch failed*}}" 1 "zgit status: fetch failure shown"

## zgit pull: fast-forwards repos that are behind, one line per repository
# A local commit that conflicts with the remote: the rebase must be aborted
_mkrepo rbconf
_remote_commit rbconf
print local > $tmp/gh/rbconf/file
git -C $tmp/gh/rbconf commit -qam local
local rbconf_head=$(git -C $tmp/gh/rbconf rev-parse HEAD)
# Uncommitted change that conflicts with the remote: autostash cannot be restored
_mkrepo stashconf
_remote_commit stashconf
print uncommitted > $tmp/gh/stashconf/file
# A changed file whose name contains "changed" must be listed by -f
_mkrepo fileview
print new > $tmp/work/fileview/changed.txt
git -C $tmp/work/fileview add changed.txt
git -C $tmp/work/fileview commit -qm "add changed.txt"
git -C $tmp/work/fileview push -q origin main 2>/dev/null

out=$(GHDIR=$tmp/gh zgit pull -f 2>&1)
assert_eq "$status" 1 "zgit pull rc when a repository fails"
out_lines=("${(@f)out}")
assert_eq "${#${(@M)out_lines:#*/11  *}}" 11 "zgit pull: one line per repository"
assert_eq "${#${(@M)out_lines:#*behind*updated*"1 commit · 1 file +1 -0"}}" 1 "zgit pull: behind updated"
assert_eq "${#${(@M)out_lines:#*clean*up to date}}" 1 "zgit pull: clean"
assert_eq "${#${(@M)out_lines:#*noup*skipped: no upstream branch}}" 1 "zgit pull: no upstream skipped"
assert_eq "${#${(@M)out_lines:#*broken*fetch failed, skipped}}" 1 "zgit pull: fetch failure"
assert_eq "${#${(@M)out_lines:#*\\n*}}" 0 "zgit pull: no literal \\n"
assert_eq "${#${(@M)out_lines:#*changed.txt*}}" 1 "zgit pull -f: lists changed.txt"

# Rebase conflict: aborted, repository unchanged
assert_eq "${#${(@M)out_lines:#*rbconf*pull failed*rebase aborted*}}" 1 "zgit pull: rebase conflict reported"
assert_eq "$(git -C $tmp/gh/rbconf rev-parse HEAD)" "$rbconf_head" "rebase conflict: HEAD unchanged"
assert_eq "$(git -C $tmp/gh/rbconf status --porcelain)" "" "rebase conflict: clean index and worktree"
get_git_status $tmp/gh/rbconf >/dev/null
assert_eq "$REPLY:${reply[9]}" "diverged:" "rebase conflict: no rebase in progress"

# Autostash conflict: reported as a failure, stash kept
assert_eq "${#${(@M)out_lines:#*stashconf*after autostash*}}" 1 "zgit pull: autostash conflict reported"
assert_eq "$(git -C $tmp/gh/stashconf stash list | wc -l | tr -d ' ')" 1 "autostash conflict: stash kept"

get_git_status $tmp/gh/behind >/dev/null
assert_eq "$REPLY" up-to-date "behind is up to date after zgit pull"

assert_rc 1 env GHDIR=$tmp/gh/plain zsh -fc "source $REPO_DIR/tests/run.zsh --lib-only; fpath=($REPO_DIR/functions \$fpath); autoload -Uz zgit; zgit status -n"

rm -rf $tmp
unfunction _mkrepo _remote_commit _local_commit
