#!/usr/bin/env bash

if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install)"
else
  echo "Homebrew already installed. Skip."
fi

brew upgrade

if [ ! -d ~/.ssh ]; then
  echo "SSH directory not found. Creating SSH directory..."
  mkdir ~/.ssh
else
  echo "SSH directory already exists. Skip."
fi

if [ ! -f ~/.ssh/id_rsa ]; then
  echo "SSH key not found. Generating SSH key..."
  ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_rsa -N ""

  echo "SSH key generated. Please add the following public key to your GitHub account:"
  cat ~/.ssh/id_rsa.pub

  pause "Press Enter after adding the SSH key to GitHub..."
else
  echo "SSH key already exists. Skip."
fi

if [ ! -d ~/Documents/repositories ]; then
  echo "Repositories directory not found. Creating repositories directory..."
  mkdir -p ~/Documents/repositories
else
  echo "Repositories directory already exists. Skip."
fi

echo "Installing applications and tools from Brewfile..."
brew bundle install -g --file=../dot_homebrew/Brewfile

pause "Please log in to 1Password and set up your vaults before proceeding. Press Enter to continue after you're done..."

if [ ! -d ~/.local/share/chezmoi ]; then
  echo "Chezmoi not found. Initializing chezmoi with your dotfiles repository..."
  chezmoi init --apply 'git@github.com:REDACTED_REDACTED/env.git'
else
  echo "Chezmoi already initialized. Skip."
fi

#if [ ! -d "$HOME/.oh-my-zsh" ]; then
#  echo "Installing Oh My Zsh..."
#  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#
#  [ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ] || \
#    git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
#
#  [ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] || \
#    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
#
#  [ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] || \
#    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
#
#  FONT_URLS=(
#    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
#    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
#    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
#    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
#  )
#
#  for url in "${FONT_URLS[@]}"; do
#    file_name="$(basename "$url" | sed 's/%20/ /g')"
#    target="$FONT_DIR/$file_name"
#
#    if [ ! -f "$target" ]; then
#      echo "Downloading font: $file_name"
#      curl -fL "$url" -o "$target"
#    else
#      echo "Font already present: $file_name"
#    fi
#  done
#else
#  echo "Oh My Zsh already installed. Skip."
#fi
