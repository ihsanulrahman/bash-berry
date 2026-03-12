# BASH-BERRY 🚀

A simple set of shell scripts for cloning my device repositories, setting up Git configs, installing GPG keys, and configuring Oh My Zsh on Termux.

## Quick start

### Clone device repositories

```bash
wget -q https://raw.githubusercontent.com/ihsanulrahman/bash-berry/main/repo_clone.sh -O - | bash
```

### Set up Git configs and GPG keys

```bash
wget -q https://raw.githubusercontent.com/ihsanulrahman/bash-berry/main/git-gpg.sh -O - | bash
```

### Set up Oh My Zsh (Termux)

Installs and configures Oh My Zsh on Termux with plugins, themes, and Nerd Fonts:

```bash
wget -q https://raw.githubusercontent.com/ihsanulrahman/bash-berry/main/termux_zsh.sh -O - | bash
```

**What it installs:**

| Component | Details |
|---|---|
| Oh My Zsh | Shell framework |
| zsh-autosuggestions | Suggests commands as you type |
| zsh-syntax-highlighting | Colors valid/invalid commands in real time |
| zsh-completions | Extra tab-completion definitions |
| zsh-history-substring-search | Search history by prefix with ↑/↓ |
| Powerlevel10k | Feature-rich customizable theme |
| Nerd Font | FiraCode / Hack / JetBrains / Meslo (your choice) |
| gh | GitHub CLI |
| gnupg | GPG key management |

**Key bindings after setup:**

| Key | Action |
|---|---|
| `→` | Accept autosuggestion |
| `↑` / `↓` | Search history by what you've typed |
| `Tab` | Autocomplete with menu |

## Notes
- These are convenience one-liners that download and execute remote scripts. Review the scripts before running them.
- Ensure you have `wget` and `bash` installed on your system.
- Oh My Zsh setup requires Termux (F-Droid version recommended).
- Powerlevel10k runs its config wizard on first zsh launch.
- Type `reload` to reload zsh config, `update` to update packages.
