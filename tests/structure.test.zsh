# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Structure checks: lib/ file template, headers, naming; comments, apps/ guards, docs layout

setopt extendedglob

local file name line prev
local -a lines names all_names
for file in $REPO_DIR/lib/*.zsh(N.on); do
    name=${file:t}
    lines=("${(@f)$(<$file)}")
    assert_eq "${lines[1]}" "#!/bin/zsh" "$name: shebang"
    assert_eq "${lines[4]}" "# Shell files tracking - keep at the top" "$name: tracking start comment"
    assert_eq "${lines[5]}" 'zfile_track_start ${0:A}' "$name: tracking start"
    assert_eq "${lines[-2]}" "# Shell files tracking - keep at the end" "$name: tracking end comment"
    assert_eq "${lines[-1]}" 'zfile_track_end ${0:A}' "$name: tracking end"
    assert_eq "${$(tail -c 1 $file | od -An -c)// /}" '\n' "$name: final newline"
    assert_eq "${lines[7]}" "##" "$name: description block"

    # Every function has a comment header with a Usage: line
    prev=""
    for line in $lines; do
        if [[ $line =~ '^([a-zA-Z_][a-zA-Z0-9_]*)\(\) \{' ]]; then
            all_names+=($match[1])
            [[ $prev == "#"* ]] || assert_eq "no header" "header" "$name: ${match[1]} has a comment header"
        fi
        prev=$line
    done
done

## No forbidden constructs in zsh code (docs/ZSH.md); comment lines are skipped
local forbidden='(^|[[:space:]])local[^#]*[[:space:]]path([[:space:]=]|$)'
forbidden+='|[[:space:]]-(eq|ne|lt|gt|le|ge)[[:space:]]'
forbidden+='|^[[:space:]]*echo[[:space:]]'
forbidden+='|\$\?|\$#([^a-zA-Z{]|$)'
forbidden+='|(^[[:space:]]*|if |&& |\|\| |; )\[ '
local -a violations=()
local -i n
for file in $REPO_DIR/{lib,inc,apps,scripts}/*.zsh(N.) $REPO_DIR/functions/^*.zwc(N.) \
            $REPO_DIR/tests/^structure.test.zsh(N.) $REPO_DIR/.z(shenv|shrc|profile|login|logout)(N.); do
    n=0
    for line in "${(@f)$(<$file)}"; do
        (( n++ ))
        [[ $line == [[:space:]]#\#* ]] && continue
        [[ $line =~ $forbidden ]] && violations+=("${file:t}:$n")
    done
done
assert_eq "${violations[*]}" "" "forbidden constructs"

## Each public function has a Usage: line in its header
local -a no_usage=()
for file in $REPO_DIR/lib/*.zsh(N.); do
    lines=("${(@f)$(<$file)}")
    local -i i
    for (( i = 1; i <= ${#lines}; i++ )); do
        [[ ${lines[i]} =~ '^([a-z][a-zA-Z0-9_]*)\(\) \{' ]] || continue
        local -i j=$(( i - 1 ))
        local found=0
        while (( j > 0 )) && [[ ${lines[j]} == "#"* ]]; do
            [[ ${lines[j]} == "# Usage:"* ]] && found=1
            (( j-- ))
        done
        (( found )) || no_usage+=("${file:t}:${match[1]}")
    done
done
assert_eq "${no_usage[*]}" "" "functions without Usage:"

## No function is defined in two lib files
assert_eq "${(j: :)${(@)all_names:#_*}}" "${(j: :)${(@u)${(@)all_names:#_*}}}" "duplicate function names"

## Every code file carries the license header
local -a no_header=()
for file in $REPO_DIR/{lib,inc,apps,tests,scripts}/*.zsh(N.) $REPO_DIR/plugins/*.zsh(N.) $REPO_DIR/functions/^*.zwc(N.); do
    [[ "$(<$file)" == *"# Part of zconfig · https://github.com/barabasz/zconfig · MIT License"* ]] || no_header+=(${file:t})
done
assert_eq "${no_header[*]}" "" "files without license header"

## Section comments use '## Title', not banners (docs/ZSH.md)
local -a banners=()
for file in $REPO_DIR/{lib,inc,apps,scripts}/*.zsh(N.) $REPO_DIR/functions/^*.zwc(N.) $REPO_DIR/install.sh; do
    for line in "${(@f)$(<$file)}"; do
        [[ $line == [[:space:]]#\#[[:space:]]#(---|===)* ]] && banners+=(${file:t})
    done
done
assert_eq "${banners[*]}" "" "files with banner comments"

## In apps/, guards come before tracking: a guard after zfile_track_start
## would leave the file marked as still loading
local -a late_guards=()
local -i tracking
for file in $REPO_DIR/apps/*.zsh(N.); do
    tracking=0
    for line in "${(@f)$(<$file)}"; do
        [[ $line == zfile_track_start* ]] && tracking=1
        (( tracking )) && [[ $line == [^[:space:]\#]*"|| return"* ]] && late_guards+=(${file:t})
    done
done
assert_eq "${late_guards[*]}" "" "apps with a guard after tracking start"

## Only README.md and CLAUDE.md live in the root; all other docs are in docs/
local -a root_docs=($REPO_DIR/*.md(N.:t))
assert_eq "${(oj: :)root_docs}" "CLAUDE.md README.md" "markdown files in root"

## Every file in docs/ is listed in README.md and in zdoc
local readme=$(<$REPO_DIR/README.md) zdoc_src=$(<$REPO_DIR/functions/zdoc)
for file in $REPO_DIR/docs/*.md(N.); do
    [[ $readme == *"(docs/${file:t})"* ]] || assert_eq "missing" "listed" "README.md lists ${file:t}"
    [[ $zdoc_src == *"\"docs/${file:t}:"* ]] || assert_eq "missing" "listed" "zdoc lists ${file:t}"
done
