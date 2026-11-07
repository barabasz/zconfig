# zconfig: File Tracking System

Part of [zconfig](../README.md) documentation. A system to monitor sourced files and their load times for performance optimization.

## Global Variables

```zsh
typeset -A ZFILES          # filepath → status (0=loading, 1=loaded)
typeset -A ZFILES_TIME     # filepath → load time in ms
typeset -A ZFILES_START    # filepath → start time (EPOCHREALTIME)
typeset -a ZFILES_ORDER    # array of filepaths in load order
```

## Tracking Functions

```zsh
zfile_track_start ${0:A}   # Start tracking (top of file)
zfile_track_end ${0:A}     # End tracking (bottom of file)
```

Tracking works in interactive shells only. Which files use it, and the file templates, are described in [GUIDELINES.md](GUIDELINES.md#file-types-and-their-rules).

## Debug Output

When `ZSH_ZFILE_DEBUG=1`, each tracked file prints its load time:

```
modules.zsh     —     0.45 ms
xdg.zsh         —     0.32 ms
files.zsh       —     0.67 ms
```

## Reporting

```zsh
# Show full report
zfiles

# With bar visualization
zfiles -b
```

Example output:

```
   err file                     time     dir
 1. ✓ .zshenv               12.45 ms  zsh
 2. ✓   zfiles.zsh           0.23 ms  inc
 3. ✓   env.zsh              1.12 ms  inc
...
                            80.39 ms  total
```

**Color coding:**
- Green: < 1ms
- White: 1-5ms
- Yellow: 5-10ms
- Red: > 10ms
