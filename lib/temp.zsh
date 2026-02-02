#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Temporary test functions

debug_disk() {
  local -a opts
  zparseopts -D -E f=opts -format=opts
  print "DEBUG: Path arg: '${1:-.}'"
  print "DEBUG: Opts: '${opts}'"

  print "DEBUG: Running: command df -kP \"${1:-.}\""
  local output
  output=$(command df -kP "${1:-.}" 2>&1)
  local ret=$?
  
  print "DEBUG: Exit code: $ret"
  print "DEBUG: Output len: ${#output}"
  print "DEBUG: Output content:\n$output"
  

  local last_line="${${(@f)output}[-1]}"
  print "DEBUG: Last line: '$last_line'"
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}