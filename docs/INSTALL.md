# zconfig: Installation Instructions

Part of [zconfig](../README.md) documentation.

## Requirements

- [macOS](https://www.apple.com/os/macos/) or Debian-based Linux ([Debian](https://www.debian.org/), [Kali Linux](https://www.kali.org/), [Linux Mint](https://linuxmint.com/), [Ubuntu](https://ubuntu.com/), etc.)
- [curl](https://curl.se/) CLI command available in terminal (see: [How to install curl](#how-to-install-curl))
- [Nerd Font](https://www.nerdfonts.com/) installed and configured in your terminal

To get the most out of zconfig, you’ll want a modern [terminal emulator](https://en.wikipedia.org/wiki/Terminal_emulator). I highly recommend [kitty](https://sw.kovidgoyal.net/kitty/) 😻, [Ghostty](https://ghostty.org/) 👻, [WezTerm](https://wezterm.org/), or [Alacritty](https://alacritty.org/).

## Quick Install (Recommended)

Run this single command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/barabasz/zconfig/HEAD/install.sh)"
```

The installer will:
1. Check system requirements (macOS or Debian-based Linux)
2. Install `sudo` (Linux, if missing)
3. Set the [timezone](#timezone), sync the clock and update system packages (Linux: `apt update && apt upgrade`)
4. Generate English and [regional locales](#locale) and install core utilities (Linux: `unzip`, `coreutils`)
5. Install `git`
6. Install Homebrew (if not present)
7. Install utilities: `bat`, `curl`, `dasel`, `dig`, `eza`, `fzf`, `gh`, `glow`, `grep`, `htop`, `kitty-terminfo`, `lsof`, `man`, `sed`, `tldr`, `tmux`, `tput`, `yazi`, `yq`, `zoxide`, `zsh`
8. Install `oh-my-posh` prompt theme engine
9. Clone the repository to a staging directory
10. Replace any existing installation (backup/remove) with the new clone, keeping `.zsh_history`
11. Create symlink `~/.zshenv` → `~/.config/zsh/.zshenv`
12. Minimize login info (Linux: `.hushlogin`, disable MOTD scripts)
13. Set zsh as your default shell
14. Start zsh with new configuration

Application configuration is a separate, optional step: see [Dotfiles Repository](#dotfiles-repository).

### Timezone

On Linux, the installer sets the timezone to `Europe/Warsaw`. Choose another one with `ZCONFIG_TIMEZONE`, or set it empty to keep the timezone of the system:

```bash
ZCONFIG_TIMEZONE=Asia/Tokyo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/barabasz/zconfig/HEAD/install.sh)"
```

### Locale

Messages are in English, and regional formats (dates, numbers, sorting) use `pl_PL.UTF-8`. Choose another locale with `ZCONFIG_LOCALE`:

```bash
ZCONFIG_LOCALE=de_DE.UTF-8 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/barabasz/zconfig/HEAD/install.sh)"
```

The installer saves a non-default choice as `ZSH_LOCALE` in `~/.config/zsh/local.zsh`, a file for settings of one machine that git ignores. A reinstallation starts without it, so give the variable again. After the installation, edit that file instead; on Linux the shell generates a missing locale when `sudo` needs no password.

## Manual Installation

If you prefer to install manually:

1. **Clone** the repository:

   ```zsh
   git clone https://github.com/barabasz/zconfig.git ~/.config/zsh
   ```

2. **Link** the main configuration file:

   ```zsh
   ln -s ~/.config/zsh/.zshenv ~/.zshenv
   ```

3. **Set** zsh as your default shell (if not already):

   ```zsh
   chsh -s $(which zsh)
   ```

4. **Restart** your terminal or run:

   ```zsh
   exec zsh
   ```

   The first startup may take a moment as zconfig will automatically download plugins and compile files for faster loading.

5. **Explore** with the help command:

   ```zsh
   zhelp
   ```

## Dotfiles Repository

zconfig works on its own. To also use your configuration of other programs, clone your dotfiles repository (one directory per program, as in `~/.config`) after the installation:

```zsh
zdotfiles owner/config
```

It lands in `~/GitHub/config`, and is available as `$GHCONFDIR` at once. A private GitHub repository is handled too: when the plain clone fails, `zdotfiles` runs `gh auth login` if needed, which also works on a server without a browser.

Nothing is linked automatically. Link what you need with `zapp link <app>`, see [ZAPP.md](ZAPP.md).

## Updating

To update zconfig:

```zsh
zupdate
```

Or choose what to update:

```zsh
zupdate -a    # Update everything (zconfig, plugins, system packages)
zupdate -c    # Update only zconfig repository
zupdate -p    # Update only plugins
zupdate -s    # Update system packages (brew/apt)
zupdate -n    # Update zconfig without reloading it in the current shell
```

When the update pulls zconfig changes, `zupdate` reloads `functions/` and `lib/`
in the current shell (via `reload_zconfig`), so new versions work right away.
Changes to startup files (`.zshenv`, `.zshrc`, `inc/`, `apps/`, plugin wrappers)
are listed with a hint to run `reload`.

## Uninstalling

To remove zconfig:

```zsh
rm ~/.zshenv
rm -rf ~/.config/zsh
```

Then set your shell back to bash (if desired):

```zsh
chsh -s /bin/bash
```

## How to install curl

### macOS

`curl` is pre-installed on macOS. You can verify it by running:

```bash
curl --version
```

### Debian-based Linux

It is extremely unlikely that `curl` is not installed on a Debian-based Linux system, but you can check by running:

```bash
curl --version
```

If `curl` is not installed, you can install it using the package manager:

```bash
# Log in as root
su -
# Update package lists
apt update
# Install curl
apt install curl -y
```
