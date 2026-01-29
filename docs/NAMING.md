# zsh-config: Naming Conventions

Part of [zsh-config](../README.md) documentation. Conventions for naming functions, variables, and files.

## Functions

**Test/Check Functions:**
- Prefix: `is_`
- Return: 0 (true) or 1 (false)
- Examples: `is_file`, `is_macos`, `is_installed`

**Info Functions:**
- Suffix: `_name`, `_version`, `_icon`
- Return: string via `print`
- Examples: `os_name`, `shell_ver`, `os_icon`

**Action Functions:**
- Verb prefix: `get_`, `compile_`, `clean_`
- Examples: `get_version`, `compile_dir`, `clean_dir`

**Utility Functions:**
- Short, descriptive names
- Examples: `etime`, `trim`, `confirm`

## Variables

**Environment Variables:**
- Uppercase, descriptive
- Examples: `ZDOTDIR`, `ZSH_INC_DIR`, `HOMEBREW_PREFIX`

**Local Variables:**
- Lowercase, snake_case
- Examples: `filepath`, `file_name`, `start_time`

**Color Variables:**
- Single letter for basic: `r`, `g`, `y`, `b`, `p`, `c`, `w`
- Prefix `b` for bright: `br`, `bg`, `by`, `bb`, `bp`, `bc`, `bw`
- Reset: `x`

**Icon Variables:**
- Prefix: `ICO_`, uppercase
- Examples: `ICO_OK`, `ICO_ERROR`, `ICO_WARN`

## Files

**Library Files:** `{category}.zsh`
- Examples: `files.zsh`, `system.zsh`, `strings.zsh`

**App Files:** `{tool}.zsh` or `_{tool}.zsh` (priority loading)
- Examples: `brew.zsh`, `fzf.zsh`, `_brew.zsh`

**Plugin Wrappers:** `{plugin-name}.zsh`
- Examples: `f-sy-h.zsh`, `zsh-autosuggestions.zsh`

**Include Files:** `{purpose}.zsh`
- Examples: `modules.zsh`, `colors.zsh`, `history.zsh`

**Root Config Files:** `.z{name}` or `.zsh{name}`
- Examples: `.zconfig`, `.zshenv`, `.zshrc`

**User Functions:** No extension, lowercase
- Examples: `sysinfo`, `logininfo`, `zfiles`
