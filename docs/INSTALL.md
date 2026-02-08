# zconfig: Installation Instructions

Part of [zconfig](../README.md) documentation.

## Requirements

- **Operating system:** macOS or Debian-based Linux (Debian, Ubuntu, Mint, etc.)
- **[Nerd Font](https://www.nerdfonts.com/):** installed and configured in your terminal emulator

## Quick Install (Recommended)

Run this single command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/barabasz/zconfig/main/install.sh)"
```

The installer will:
- Check system requirements
- Install zsh if needed (Linux only)
- Clone the repository to `~/.config/zsh`
- Create symlink `~/.zshenv`
- Optionally install Homebrew
- Set zsh as your default shell

If you have an existing zsh configuration, the installer will offer to back it up.

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
