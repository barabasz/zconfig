# zconfig: Application Recipes (zapp)

Part of [zconfig](../README.md) documentation.
`zapp` installs applications and connects them to their configuration, using one declarative recipe per application. It is how a new machine goes from "zconfig installed" to "all my tools work the way I expect".

A recipe can manage a package, dependencies, configuration symlinks, setup actions, or any combination of them. Bundles group recipes.

## Components

| Component | Role |
|-----------|------|
| `functions/zapp` | User command: parses and validates recipes, runs actions |
| `recipes/<id>.kdl` | Recipes and bundles ([KDL 2](https://kdl.dev/) files) |
| `lib/apps.zsh` | Non-interactive package-manager layer (`app_install`, `app_remove`, ...); no user output, no config handling |
| `functions/lns` | Creates symlinks, backing up an existing target to `<target>.bak` |
| `$GHCONFDIR` | Dotfiles repository, the source of linked configuration: one directory per program, as in `~/.config` |

## Requirements

- [dasel](https://github.com/TomWright/dasel) reads the KDL files. It is required for every action, and `install.sh` installs it.
- `$GHCONFDIR` is optional. Any dotfiles repository works; [`zdotfiles`](INSTALL.md#dotfiles-repository) clones it, and `apps/git.zsh` sets the variable when `~/GitHub/config` exists. Without it, `install` and `remove` still handle packages, and `link`/`unlink` fail with an error.
- `$ZSH_RECIPES_DIR` overrides the recipe directory (default: `$ZDOTDIR/recipes`).

## Usage

```zsh
zapp [options] <action> <app>
```

See `zapp --help` for options and examples.

| Action | Dependencies | Package | Extras | Config links | Setup |
|--------|--------------|---------|--------|--------------|-------|
| `install` | installed first | installed | installed | created | run |
| `remove` | preserved | removed | preserved | removed | - |
| `link` | - | - | - | created | - |
| `unlink` | - | - | - | removed | - |

`show` prints the parsed recipe or bundle, and `verify` validates KDL syntax and the schema. Neither changes anything.

`install` runs the steps in the column order above. `remove` removes the package first, then the links.

`--test` shows what would be done and changes nothing. It does not apply to `show` and `verify`.

`--quiet` hides routine output; the output of a failed child command is still shown. Nested recipes always run quietly.

## Recipe Format (schema 1)

The file name must match the `id`: `recipes/example.kdl` contains `recipe id="example"`. This recipe shows all nodes; real recipes are usually much shorter.

```kdl
/- kdl-version 2

recipe id="example" schema=1 {
    name "Example"
    description "Short description"
    homepage "https://example.com/"
    command "example"

    dependencies {
        install id="python"
    }

    install package="example-package"

    extras {
        install id="ripgrep"
    }

    config {
        link source="example/themes" target="$XDG_DATA_HOME/example/themes"
    }

    setup {
        mkdir path="$XDG_STATE_HOME/example"
        run label="First run setup" when="new" command="example --init"
    }
}
```

| Node | Required | Description |
|------|----------|-------------|
| `recipe id schema` | Yes | `id` must match the file name; `schema` must be `1` |
| `name` | Yes | Display name |
| `description`, `homepage` | No | Shown by `show` |
| `command` | No | Executable checked after installation; a missing command is an error |
| `install package` | No | Package to manage. A recipe without it manages configuration or setup only |
| `install method` | No | `brew` (default), `apt` or `pipx` |
| `install type` | No | `cask`; Homebrew recipes only |
| `dependencies { install id }` | No | Recipes or bundles installed before the package; each must exist |
| `extras { install id }` | No | Installed after the package: as a recipe if `recipes/<id>.kdl` exists, otherwise as a package of that name |
| `config dir` | No | Directory for the automatic link (default: `id`) |
| `config auto` | No | `false` disables the automatic link (default: `true`) |
| `config { link source target }` | No | Additional link; `target` defaults to `$CONFDIR/<source>` |
| `setup { mkdir path when }` | No | Directory to create |
| `setup { run command label when }` | No | Command run with `eval` in the current shell |

`when` is `always` (default) or `new`. `new` runs the item only if the package was installed during this run.

### Package Manager Selection

- The default method is `brew` on every platform; it is not derived from the operating system.
- `--brew` and `--apt` override the method of system-package recipes and are passed on to nested recipes.
- `pipx` recipes are not overridden; they still pass the option on to their dependencies.
- A `cask` recipe cannot be forced to `--apt`.

### Configuration Links

The automatic link is `$CONFDIR/<dir>` → `$GHCONFDIR/<dir>`. If the source does not exist, the application keeps its default configuration.

`source` of an additional link is relative to `$GHCONFDIR`.

These variables are expanded in `target` and `mkdir path`, as `$NAME` or `${NAME}`: `HOME`, `CONFDIR`, `GHCONFDIR`, `VENVDIR`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`, `XDG_STATE_HOME`.

## Bundle Format (schema 1)

```kdl
/- kdl-version 2

bundle id="terminal" schema=1 {
    name "Terminal tools"
    description "Terminal utilities and file managers"

    include id="cli"
    include id="mc"
    include id="yazi"
}
```

At least one `include` is required. Includes may be recipes or other bundles, and the action is applied to each of them.

Within one run, every recipe is processed once. Circular dependencies are detected and reported as an error.

## Safety Rules

These rules protect the dotfiles repository. Any change to `zapp` must keep them.

- `remove` and `unlink` never remove or modify real files.
- Only a symlink verified to point at its expected source in `$GHCONFDIR` is removed. Anything else is preserved.
- `rm` is never recursive, and it never receives a source path.
- A source must be inside `$GHCONFDIR`, and a link path must be outside it.
- All managed paths are checked before any action that changes state.
- `install` and `link` back up an existing file or directory to `<path>.bak` before linking.

## Adding a Recipe

1. Create `recipes/<id>.kdl`; use the simplest existing recipe with the same features as a starting point.
2. Use `config auto=false` when the application has no configuration in `$GHCONFDIR`.
3. Run `zapp verify <id>`, `zapp show <id>` and `zapp -t install <id>`.

## Known Gaps

- There are no automated tests for `functions/zapp` or `recipes/`.
- The `zapp link karabiner` example in `zapp --help` has no matching recipe.
- `app_upgrade` exists in `lib/apps.zsh`, but `zapp` has no `upgrade` action.
