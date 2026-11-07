# zconfig

Project context for Claude Code and other AI assistants, readable for humans too. It summarizes what matters and links to the details. `docs/` is the single source of truth, so this file should not repeat it.

## What This Is

**zconfig** is a modular, fast Zsh framework by Andrzej Barabasz (public repo `barabasz/zconfig`). It has two goals:

1. **Instant setup:** a new machine gets a complete working Zsh environment in minutes.
2. **Consistency:** the same commands and the same way of working on every machine.

Targets: current macOS and Debian-based Linux (mainly Ubuntu Server).

**zconfig is self-contained.** Once installed, it needs no other repository.

**Dotfiles repository (optional):** configuration of other programs lives in a separate repo of the "dotfiles" kind, with one directory per program, as in `~/.config`. Any such repo works. It is available as `$GHCONFDIR`, and `zapp` symlinks configuration from it. The author's own one is private, so never copy its content into this public repo.

## Working Agreement

- **When unsure, ask.** The user always prefers to talk it through over a blind decision.
- **Zsh only, using 100% of its features.** Compatibility with bash or other shells does not matter. The only exception is `install.sh` (bash, because it runs before zsh exists).
- **Reuse before writing.** Before building a helper, check whether `lib/` already has it (`docs/FUNCTIONS.md`). If it doesn't, and other code could use it, consider adding it to `lib/`.
- **DRY and single source of truth,** in code and in docs. Never describe the same thing in two places, link instead. Contradictions in the docs are the worst outcome.
- **Update `docs/` with every change.** Only `README.md` and `CLAUDE.md` belong in the root; all other docs go to `docs/`.
- **Always consider tests** in `tests/` after a change or a new function.
- **`functions/` holds only native zsh commands, all built on `fn.zsh`,** so every command behaves the same way. No wrappers for scripts in other languages or repos.
- **All code comments are in English** and follow one style (see below).
- **Work directly on `main`.** One person works on zconfig, in one place, so branches and PRs are not needed. Commit or push only when asked.

## How It Loads

`~/.zshenv` is a symlink to `~/.config/zsh/.zshenv`, and it is the only zconfig file in the home directory. Everything else must stay in the installation directory, `~/.config/zsh` (`$ZDOTDIR`).

1. **`.zshenv`** (every shell) sources `inc/`: `zfiles`, `env`, `modules`, `xdg`, `path`, `locales`.
2. **`.zprofile`** (login shells) is a placeholder.
3. **`.zshrc`** (interactive shells) loads, in order: `inc/` basics, `lib/`, `functions/`, aliases, keys, `apps/`, hashes, plugins, then compiles changed files.
4. **`.zlogin`** (login shells) does cleanup and optional info.

A new file in `lib/`, `apps/` or `functions/` loads automatically: `source_zsh_dir` sources every `*.zsh` in the first two, and `functions/` is autoloaded. Files in `inc/` and `plugins/` must be added by hand to a startup file or to `inc/plugins.zsh`. Details are in [docs/STRUCTURE.md](docs/STRUCTURE.md#startup-order).

## Code at a Glance

| Location | What it holds | Key rules |
|----------|---------------|-----------|
| `inc/` | Core configuration, one concern per file | Sourced, tracked |
| `lib/` | Helper functions | Sourced, tracked; header with `Usage:`; getters set `REPLY` and print |
| `apps/` | Extra configuration per application, applied only if that application is installed | Sourced; guard first, then tracking |
| `functions/` | User commands | Autoloaded: no shebang, tracking or function declaration; `fn.zsh` |
| `plugins/` | Plugin wrappers (`plugins/*/` are ignored git clones) | Sourced; tracked by the loader |
| `recipes/` | `zapp` recipes: install an application and link its configuration | KDL, see [docs/ZAPP.md](docs/ZAPP.md) |

- **Style in one line:** `ARGC`, `status`, `(( ))` for numbers, `[[ ]]` for strings and files, `print` instead of `echo`, path modifiers and expansion flags instead of external tools, `REPLY`/`reply` instead of subshells.
- **Comments:** `## Section name` for sections, `# Text` for comments, explaining why rather than what. No `# ---` or `# ===` banners. Details are in [docs/ZSH.md](docs/ZSH.md#comments).

## Where To Look

| Topic | Source |
|-------|--------|
| Directory layout, startup, loading | [docs/STRUCTURE.md](docs/STRUCTURE.md) |
| Project rules, file templates, adding components | [docs/GUIDELINES.md](docs/GUIDELINES.md) |
| Zsh coding style, comments, exit codes | [docs/ZSH.md](docs/ZSH.md) |
| Naming | [docs/NAMING.md](docs/NAMING.md) |
| Writing commands with `fn.zsh` | [docs/FN.md](docs/FN.md) |
| `zapp` and recipes | [docs/ZAPP.md](docs/ZAPP.md) |
| All functions (generated, do not edit) | [docs/FUNCTIONS.md](docs/FUNCTIONS.md) |
| File tracking | [docs/ZFILES.md](docs/ZFILES.md) |
| Examples | [docs/EXAMPLES.md](docs/EXAMPLES.md) |
| Installation, updating | [docs/INSTALL.md](docs/INSTALL.md) |
| Configuration variables | [README.md](README.md#configuration-variables) |

Read the relevant file before working in that area, especially `ZSH.md` and `GUIDELINES.md` before writing code.

## Commands

```zsh
zsh tests/run.zsh                    # All tests, including the style lint
zsh tests/run.zsh math               # Test files matching a pattern
zsh -n lib/files.zsh                 # Syntax check
zsh scripts/functions-md.zsh         # Regenerate docs/FUNCTIONS.md
zsh scripts/functions-md.zsh --check # Check it is up to date
```

CI (`.github/workflows/ci.yml`) runs the syntax check and tests on Ubuntu and macOS, and the `FUNCTIONS.md` check.

## Traps

- **Never `local path`** or other tied names (`fpath`, `cdpath`, `manpath`, `mailpath`). It silently empties `PATH`, so every external command in that function fails.
- **`lib/` is not available in `.zshenv`:** it loads only in interactive shells, from `.zshrc`. `inc/` files loaded by `.zshenv` run for every shell, so they must stay fast.
- **`$GHDIR` and `$GHCONFDIR` may be unset.** They exist only if `~/GitHub` and `~/GitHub/config` do, so code must handle their absence.
- **zconfig exports single-letter color variables** (`r g y b p c w x`). Don't use these names for anything else, and remember they leak into child shells.
- **Global aliases** such as `G` can break code that is parsed at runtime; that is why `compile_file` and `reload_zconfig` set `noaliases`.
- **The running shell keeps old code.** After a change, test in a new `zsh`, or use `reload_zconfig` (`lib/`, `functions/`) or `reload` (everything).
- **`tests/structure.test.zsh` is the lint.** It enforces file templates, comments, forbidden constructs and the docs layout. Fix the code rather than weakening a check.
- **`*.zwc` files are generated** and ignored by git. Never edit them.

## Definition of Done

1. Code follows `ZSH.md` and `GUIDELINES.md`.
2. Tests are added or consciously skipped, and `zsh tests/run.zsh` passes.
3. `docs/` is updated, and `zsh scripts/functions-md.zsh` is run if any function changed.
4. Nothing is described twice, and nothing contradicts the docs.

## To Do

- **Installation:** decide how the dotfiles repository reaches a new machine. `install.sh` doesn't handle it; for now it is cloned by hand to `$GHDIR/config`.
- **`zapp`:** see Known Gaps in [docs/ZAPP.md](docs/ZAPP.md#known-gaps).
