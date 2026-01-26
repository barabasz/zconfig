#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Temporary test functions

test1() {
    print -- "This is test2"
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}