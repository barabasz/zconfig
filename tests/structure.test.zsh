setopt extendedglob
# Structure checks for lib/*.zsh (file template, headers, naming)

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
    # No forbidden constructs (docs/ZSH.md)
    local -a hits
    hits=(${(M)lines:#*local*[[:space:]]path([[:space:]=]*|)})
    assert_eq "${#hits}" 0 "$name: no 'local path' (would clear \$PATH)"
    hits=(${(M)lines:#*[[:space:]]-eq[[:space:]]*})
    assert_eq "${#hits}" 0 "$name: no -eq"
    hits=(${(M)lines:#[[:space:]]#echo[[:space:]]*})
    assert_eq "${#hits}" 0 "$name: no echo"
done

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
