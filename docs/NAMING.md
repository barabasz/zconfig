# zconfig: Naming Conventions

Part of [zconfig](../README.md) documentation. Conventions for naming functions, variables, and files.

## Functions

**Test/Check Functions:**
- Prefix: `is_`
- Return: 0 (true), 1 (false), 2 (invalid usage)
- Validators: `is_valid_<thing>` (e.g. `is_valid_ip`, `is_valid_url`)
- Examples: `is_file`, `is_macos`, `is_installed`

**Info Functions:**
- Suffix: `_name`, `_version`, `_icon`
- Return: string via `print`, also stored in `REPLY` (or `reply` for lists)
- Examples: `os_name`, `shell_version`, `os_icon`

**Action Functions:**
- Verb prefix: `get_`, `compile_`, `clean_`
- Examples: `get_version`, `compile_dir`, `clean_dir`

**Aliases:**
- Old or short names are kept as copies: `functions[new]=$functions[old]`
- `zman` lists them as "Alias for ..."
- Examples: `shell_ver`, `is_url_valid`, `extract_version`

**Private Functions:**
- Prefix `_` (e.g. `_patharr_add`); not listed by `zman`

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
- Single letter: `r`, `g`, `y`, `b`, `p`, `c`, `w` (defined in `inc/colors.zsh`)
- Reset: `x`
- There are no bright variants; use the basic colors

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
- Examples: `modules.zsh`, `colors.zsh`, `options.zsh`

**Root Config Files:** `.z{name}` or `.zsh{name}`
- Examples: `.zshenv`, `.zshrc`, `.zprofile`

**User Functions:** No extension, lowercase
- Examples: `sysinfo`, `logininfo`, `zfiles`
