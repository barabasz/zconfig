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
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/barabasz/zconfig/main/install.sh)"
```

The installer will:
- Check system requirements (macOS or Debian-based Linux)
- Update system packages (Linux: `apt update && apt upgrade`)
- Install core utilities (Linux: `curl`, `unzip`, `coreutils`)
- Install Homebrew (if not present)
- Install extra utilities: `bat`, `eza`, `htop`, `ncurses`, `gh`, `fzf`, `zoxide`, `yazi`
- Install `git` and `zsh`
- Install `oh-my-posh` prompt theme engine
- Install `kitty-terminfo` (Linux only)
- Check for uncommitted local changes (prompts before overwriting)
- Back up or remove existing zsh configuration
- Clone the repository to `~/.config/zsh`
- Create symlink `~/.zshenv` → `~/.config/zsh/.zshenv`
- Minimize login info (Linux: `.hushlogin`, disable MOTD scripts)
- Set zsh as your default shell

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

## Updating

To update zconfig and all plugins:

```zsh
zupdate
```

Or update only specific components:

```zsh
zupdate -c    # Update only zconfig repository
zupdate -p    # Update only plugins
zupdate -s    # Update system packages (brew/apt)
```

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
