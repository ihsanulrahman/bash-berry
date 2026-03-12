#!/bin/bash
# ================================================
#   Oh My Zsh Full Setup Script for Termux
#   - Plugins: autosuggestions, syntax highlight,
#              completions, history-substring-search
#   - Themes: powerlevel10k + builtin themes
#   - Fonts: FiraCode, Hack, JetBrains, Meslo
# ================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── 1. Dependencies ──────────────────────────────
info "Installing dependencies..."
pkg update -y
pkg install -y zsh git curl wget unzip gh gnupg || error "Failed to install packages"
success "Dependencies installed (zsh git curl wget unzip gh gnupg)"

# ── 2. Oh My Zsh ────────────────────────────────
info "Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
  warn "Oh My Zsh already installed, skipping..."
else
  rm -rf ~/.oh-my-zsh
  wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O install_omz.sh
  bash install_omz.sh --unattended
  rm -f install_omz.sh
  success "Oh My Zsh installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ── 3. Plugins ───────────────────────────────────
info "Installing plugins..."

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  success "zsh-autosuggestions installed"
else
  warn "zsh-autosuggestions already exists, skipping..."
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  success "zsh-syntax-highlighting installed"
else
  warn "zsh-syntax-highlighting already exists, skipping..."
fi

# zsh-completions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-completions \
    "$ZSH_CUSTOM/plugins/zsh-completions"
  success "zsh-completions installed"
else
  warn "zsh-completions already exists, skipping..."
fi

# zsh-history-substring-search
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search \
    "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
  success "zsh-history-substring-search installed"
else
  warn "zsh-history-substring-search already exists, skipping..."
fi

# ── 4. Powerlevel10k Theme ───────────────────────
info "Installing Powerlevel10k theme..."
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k \
    "$ZSH_CUSTOM/themes/powerlevel10k"
  success "Powerlevel10k installed"
else
  warn "Powerlevel10k already exists, skipping..."
fi

# ── 5. Fonts ─────────────────────────────────────
mkdir -p ~/.termux

echo ""
info "Choose a font to install:"
echo "  1) FiraCode Nerd Font (recommended)"
echo "  2) Hack Nerd Font"
echo "  3) JetBrains Mono Nerd Font"
echo "  4) Meslo Nerd Font (best for Powerlevel10k)"
echo "  5) Skip font installation"
echo ""
read -p "Enter choice [1-5] (default: 4): " font_choice
font_choice=${font_choice:-4}

case $font_choice in
  1)
    info "Downloading FiraCode Nerd Font..."
    curl -fLo ~/.termux/font.ttf \
      "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf"
    success "FiraCode Nerd Font installed"
    ;;
  2)
    info "Downloading Hack Nerd Font..."
    curl -fLo ~/.termux/font.ttf \
      "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Hack/Regular/HackNerdFont-Regular.ttf"
    success "Hack Nerd Font installed"
    ;;
  3)
    info "Downloading JetBrains Mono Nerd Font..."
    curl -fLo ~/.termux/font.ttf \
      "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/JetBrainsMono/Fonts/Regular/JetBrainsMonoNerdFont-Regular.ttf"
    success "JetBrains Mono Nerd Font installed"
    ;;
  4)
    info "Downloading Meslo Nerd Font..."
    curl -fLo ~/.termux/font.ttf \
      "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Meslo/S/Regular/MesloLGSNerdFont-Regular.ttf"
    success "Meslo Nerd Font installed"
    ;;
  5)
    warn "Skipping font installation"
    ;;
  *)
    warn "Invalid choice, skipping font installation"
    ;;
esac

# ── 6. Choose Theme ──────────────────────────────
echo ""
info "Choose a theme:"
echo "  1) powerlevel10k  (feature-rich, highly customizable)"
echo "  2) agnoster       (powerline-style, shows git info)"
echo "  3) bureau         (clean, shows user + git branch)"
echo "  4) half-life      (colorful, compact)"
echo "  5) avit           (minimal with timestamp)"
echo "  6) random         (different theme each launch)"
echo ""
read -p "Enter choice [1-6] (default: 1): " theme_choice
theme_choice=${theme_choice:-1}

case $theme_choice in
  1) THEME="powerlevel10k/powerlevel10k" ;;
  2) THEME="agnoster" ;;
  3) THEME="bureau" ;;
  4) THEME="half-life" ;;
  5) THEME="avit" ;;
  6) THEME="random" ;;
  *) THEME="powerlevel10k/powerlevel10k" ;;
esac
success "Theme set to: $THEME"

# ── 7. Write .zshrc ──────────────────────────────
info "Writing .zshrc config..."

cat > ~/.zshrc << EOF
# Path to Oh My Zsh
export ZSH="\$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="${THEME}"

# Plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-history-substring-search
)

source \$ZSH/oh-my-zsh.sh

# ── Autosuggestions ──────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#888888"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
bindkey '→' autosuggest-accept
bindkey '^]' autosuggest-accept

# ── History ──────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ── History substring search keybinds ────────────
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ── Completions ──────────────────────────────────
autoload -U compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ── Aliases ──────────────────────────────────────
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias cls='clear'
alias zshrc='nano ~/.zshrc'
alias reload='source ~/.zshrc'
alias update='pkg update && pkg upgrade'

EOF

success ".zshrc written"

# ── 8. Set zsh as default shell ──────────────────
info "Setting zsh as default shell..."
chsh -s zsh 2>/dev/null && success "zsh set as default shell" || warn "Could not set default shell, run: chsh -s zsh"

# ── 9. Reload font ───────────────────────────────
termux-reload-settings 2>/dev/null || true

# ── Done ─────────────────────────────────────────
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Setup complete! Restart Termux to apply.    ${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "  Tips:"
echo "  • Press → arrow to accept autosuggestion"
echo "  • Press ↑/↓ to search command history"
echo "  • Type 'reload' to reload config"
echo "  • Type 'update' to update packages"
if [ "$THEME" = "powerlevel10k/powerlevel10k" ]; then
  echo "  • Powerlevel10k will run its setup wizard on first launch"
fi
echo ""
