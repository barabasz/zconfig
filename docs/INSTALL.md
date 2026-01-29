# zsh-config: Installation Instructions

This is a part of [zsh-config](../README.md) documentation. 
Instructions for installing and setting up the zsh configuration. 

## Requirements

- Zsh version 5.8 or higher
- Git installed on your system

## Installation

1. **Clone the repository:**

   ```zsh
   git clone https://github.com/barabasz/zsh-config.git ~/.config/zsh
   ```
2. **Link the main configuration file:**

   ```zsh
   ln -s ~/.config/zsh/.zshenv ~/.zshenv
   ```

3. **Set Zsh as your default shell:**

   ```zsh
   chsh -s $(which zsh)
   ```
4. **Restart your terminal** to apply changes.

   ```zsh
   exec zsh
   ```