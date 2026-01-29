# zsh-config: File Tracking System

Part of [zsh-config](../README.md) documentation. A system to monitor sourced files and their load times for performance optimization.

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

## Usage Pattern

Every sourced file must include tracking calls:

```zsh
#!/bin/zsh
zfile_track_start ${0:A}

# ... file content ...

zfile_track_end ${0:A}
```

## Debug Output

When `ZSH_DEBUG=1`:

```
✅ bootstrap.zsh sourced in 1.89ms
✅ xdg.zsh sourced in 0.45ms
✅ files.zsh sourced in 0.67ms
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
 3. ✓   .zconfig             1.12 ms  zsh
...
                            80.39 ms  total
```

**Color coding:**
- Green: < 1ms
- White: 1-5ms
- Yellow: 5-10ms
- Red: > 10ms
