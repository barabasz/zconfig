# zsh-config: Zsh Idiomatic Coding Guidelines

Part of [zsh-config](README.md) documentation. Guidelines for writing idiomatic zsh code (not bash).

---

## Core Principle

**Write for zsh exclusively** - no bash/POSIX compatibility. Use zsh-native constructs, variables, and builtins.

---

## Script Comments

- `##` = Section header (logical level, not Markdown syntax)
- `#` = Regular comments

## Special Variables

Use zsh-native special variables instead of POSIX equivalents:

```zsh
# ✅ Good - zsh native
ARGC                   # number of arguments (not $#)
argv                   # array of arguments (not $@ or $*)
argv[1]                # first argument (not $1)
argv[-1]               # last argument
status                 # exit code of last command (not $?)

# ❌ Bad - POSIX/bash style
$#                     # use ARGC instead
$@, $*                 # use argv instead
$?                     # use status instead
```

**Note:** `$1`, `$2` etc. are acceptable when clearer (e.g., in simple 2-3 arg functions), but `ARGC` is always preferred over `$#`.

**Elegant arithmetic with `status`:** Inside `(( ))`, variables don't need `$` prefix, making exit code checks particularly clean:

```zsh
# ✅ Elegant - no $ needed in (( ))
command
if (( status != 0 )); then
    print -u2 "Command failed with exit code $status"
fi

# Also valid but less elegant
if (( $? != 0 )); then
    print -u2 "Failed"
fi
```

---

## Conditional Tests: `[[ ]]` vs `(( ))`

### Numeric Operations → `(( ))`

Use `(( ))` for **all** numeric operations - comparisons, arithmetic, counters:

```zsh
# Numeric comparisons - always (( )) with mathematical operators
(( ARGC < 2 ))         # argument count
(( count > 0 ))        # variable comparison
(( exit_code == 0 ))   # exit code check
(( ${#array} >= 5 ))   # array length
(( i++ ))              # increment
(( total += n ))       # arithmetic assignment

# Checking if variable is set (numeric context)
(( ${+var} ))          # 1 if var is set, 0 otherwise
(( ${+functions[fn]} )) # check if function exists
(( ${+commands[cmd]} )) # check if command exists
```

### String and File Tests → `[[ ]]`

Use `[[ ]]` **only** for string and file tests:

```zsh
# File tests - require [[ ]]
[[ -f $file ]]         # is regular file
[[ -d $path ]]         # is directory
[[ -e $path ]]         # exists
[[ -r $file ]]         # is readable

# String tests - require [[ ]]
[[ -n $var ]]          # string is non-empty
[[ -z $var ]]          # string is empty
[[ $str == pattern* ]] # pattern matching
[[ $a == $b ]]         # string equality
[[ $OSTYPE == darwin* ]] # OS detection
```

### FORBIDDEN - POSIX Numeric Operators

**Never use these in `[[ ]]`:**

```zsh
# ❌ WRONG - bashisms, never use these
[[ $# -lt 2 ]]         # use: (( ARGC < 2 ))
[[ $count -gt 0 ]]     # use: (( count > 0 ))
[[ $? -eq 0 ]]         # use: (( status == 0 ))
[[ $x -ne $y ]]        # use: (( x != y ))
[[ $a -le $b ]]        # use: (( a <= b ))
[[ $a -ge $b ]]        # use: (( a >= b ))
```

### Quick Reference

| Operation | Correct | Wrong |
|-----------|---------|-------|
| less than | `(( a < b ))` | `[[ $a -lt $b ]]` |
| greater than | `(( a > b ))` | `[[ $a -gt $b ]]` |
| equal (numeric) | `(( a == b ))` | `[[ $a -eq $b ]]` |
| not equal (numeric) | `(( a != b ))` | `[[ $a -ne $b ]]` |
| less or equal | `(( a <= b ))` | `[[ $a -le $b ]]` |
| greater or equal | `(( a >= b ))` | `[[ $a -ge $b ]]` |

---

## Parameter Expansion Flags

Zsh expansion flags `${(flags)var}` replace external tools like `cut`, `tr`, `sort`, `uniq`.

**Rule:** Before using a pipe (`|`), check if an expansion flag can do it.

```zsh
local str="apple,banana,cherry"
local -a fruits

# (s:x:) - Split by delimiter
fruits=( ${(s:,:)str} )        # → (apple banana cherry)

# (j:x:) - Join with delimiter
print ${(j:--:)fruits}         # → apple--banana--cherry

# (U) / (L) - Uppercase / Lowercase
print ${(U)str}                # → APPLE,BANANA,CHERRY

# (u) - Unique, (o) - sort ascending, (O) - descending
local -a nums=(3 1 2 1 3)
print ${(uo)nums}              # → 1 2 3

# (q) - Quote special characters
local file="File With * Spaces"
print -r -- ${(q)file}         # → File\ With\ \*\ Spaces
```

---

## Path Modifiers

Use modifiers instead of `dirname`, `basename`, `realpath`.

```zsh
local file="./src/main.c"

${file:A}      # Absolute path   → /home/user/project/src/main.c
${file:t}      # Tail (basename) → main.c
${file:r}      # Root (no ext)   → ./src/main
${file:e}      # Extension       → c
${file:h}      # Head (dirname)  → ./src
${file:t:r}    # Combine them    → main
${file:s/src/bin/}  # Substitution → ./bin/main.c

# Works on arrays too
print $argv:A  # Absolute paths of all arguments
```

---

## Globbing Qualifiers

Filter files directly in glob patterns instead of `find` + `grep`.

```zsh
# Type qualifiers
*(/)           # directories only
*(.)           # regular files only
*(^/)          # NOT directories
*(.x)          # executable files

# Size and time
*(Lm+5)        # files > 5MB
*(om[1,3])     # 3 newest files (ordered by mtime)

# Example: find vs zsh
# BASH: find . -maxdepth 1 -type d -not -name '.*'
# ZSH:
echo *(/)
```

---

## Tied Parameters (PATH arrays)

Operate on arrays (`path`, `fpath`, `cdpath`) instead of colon-separated strings.

```zsh
# ❌ Bash style
export PATH=$PATH:/opt/new/bin

# ✅ Zsh style
path+=(/opt/new/bin)

# Remove duplicates automatically
typeset -U path
```

---

## Print Command

Use `print` instead of `echo`. More predictable, more options.

```zsh
# Errors to stderr
print -u2 "Error message"
print -u2 -- "Error: $msg"     # Safe with variables starting with -

# Safe printing (prevents -flags interpretation)
local input="-v"
print -r -- $input             # Works correctly, prints "-v"

# Formatted output
print -f "Name: %s, Count: %d\n" "$name" "$count"
```

---

## Associative Arrays

```zsh
local -A config
config[host]="localhost"
config[port]="8080"

# Access
print "Connect to $config[host]:$config[port]"

# Check if key exists
(( ${+config[user]} )) && print "User is set"

# Iterate (k=keys, v=values)
for key val in ${(kv)config}; do
    print "$key → $val"
done
```

---

## Short Loop Syntax

```zsh
# Standard
for f in *.txt; do
    print -r -- $f
done

# Short form (single command)
for f (*.txt) print -r -- $f

# With modifiers
for f in *.txt; do
    mv -- $f $f:r.md    # rename .txt → .md
done
```

---

## Useful Special Variables

```zsh
$funcstack     # Array of function names on call stack (debugging)
$pipestatus    # Array of exit codes from pipeline commands
$status        # Exit code of last command (same as $?)
$match         # Regex match results (with =~ operator)
```

---

## Returning Values (`$REPLY` / `$reply`)

Avoid slow subshells `$(...)` for capturing function output. Use reference variables instead.

```zsh
# ❌ Slow - subshell
get_data() {
    print "result"
}
result=$(get_data)

# ✅ Fast - reference variable
get_data() {
    REPLY="result"           # scalar
    reply=(apple banana)     # array
}

get_data
print $REPLY      # → result
print $reply[2]   # → banana
```

---

## Reading Files (`zsh/mapfile`)

For reasonable-sized files, `mapfile` is cleaner and faster than `cat` in subshell.

```zsh
zmodload zsh/mapfile

# Read file
local content=$mapfile[file.txt]

# Write file
mapfile[log.txt]="New log entry"
```

---

## Parsing Options (`zparseopts`)

Built-in option parser. Replaces `getopt` and manual `case` loops.

```zsh
zmodload zsh/zutil
local -A opts

# -D removes parsed flags from $@
# -A stores flags in associative array
zparseopts -D -A opts v=verbose -verbose=v h=help

(( ${+opts[-v]} )) && print "Verbose mode"
(( ${+opts[-h]} )) && print "Help requested"
```

---

## Code Examples

### Good - Zsh Native

```zsh
is_file() {
    (( ARGC == 1 )) && [[ -f $1 ]]
}

process_args() {
    (( ARGC < 2 )) && { print -u2 "Usage: $0 arg1 arg2"; return 1 }
    local first=$1
    local last=${argv[-1]}
    # ...
}
```

### Bad - Bash-Compatible

```zsh
is_file() {
    if [ $# -eq 1 ] && [ -f "$1" ]; then
        return 0
    else
        return 1
    fi
}
```

---

## Do's and Don'ts

### Do's ✅

- Use `(( ))` for all numeric comparisons
- Use `[[ ]]` for file and string tests
- Use `ARGC` for argument count, `argv` for argument array
- Use `print` for output, `print -u2` for errors
- Use expansion flags instead of pipes (`${(s:,:)str}` not `echo $str | cut`)
- Use path modifiers (`${file:t}` not `basename $file`)
- Use glob qualifiers (`*(/)` not `find -type d`)
- Use `path+=()` not `PATH=$PATH:...`
- Keep functions small and focused

### Don'ts ❌

- **Never** use `$#` for argument count (use `ARGC`)
- **Never** use `$?` for exit status (use `status`)
- **Never** use `-lt`, `-gt`, `-eq`, `-ne`, `-le`, `-ge`
- **Never** use `[ ]` (use `[[ ]]`)
- **Never** use `echo` (use `print`)
- **Never** call `dirname`, `basename`, `realpath` (use `:h`, `:t`, `:A`)
- **Never** write bash-compatible code

---

## Code Style Checklist

```zsh
#!/bin/zsh
# ✅ Shebang present
# ✅ Tracking calls at top and bottom
zfile_track_start ${0:A}

# ✅ Check tool availability
if is_installed tool; then

    # ✅ Use [[ ]] for file/string tests
    [[ -f $file ]] && source "$file"

    # ✅ Use (( )) for numeric comparisons - NEVER -lt/-gt/-eq etc.
    (( ARGC < 2 )) && return 1
    (( count > 0 )) && process

    # ✅ Use (( )) for arithmetic
    (( count++ ))
    (( total += n ))

    # ✅ Use print for output
    print "Message"

    # ✅ Local variables in functions
    local var="value"

fi

# ✅ Tracking at end
zfile_track_end ${0:A}
```

