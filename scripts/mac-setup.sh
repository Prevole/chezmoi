#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed. Skip."
fi

if ! command -v brew &> /dev/null; then
  echo "Homebrew not in PATH. Setting up brew environment..."
  eval "$(/opt/homebrew/bin/brew shellenv)"
  echo "Homebrew environment ready."
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

  echo ""
  echo "IMPORTANT: If your GitHub account is managed by your organization (EMU/SSO),"
  echo "you must also authorize this SSH key for SSO on each required organization:"
  echo "  GitHub -> Settings -> SSH and GPG keys -> find this key -> Configure SSO"
  echo ""

  read -r -p "Press Enter after adding the SSH key to GitHub..."
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
brew bundle install -g --file="$(dirname "$0")/../dot_homebrew/Brewfile"

read -r -p "Please log in to 1Password and set up your vaults before proceeding. Press Enter to continue after you're done..."

if [ ! -d ~/.local/share/chezmoi ]; then
  echo "Chezmoi not found. Initializing chezmoi with your dotfiles repository..."
  chezmoi init --apply 'git@github.com:REDACTED_REDACTED/env.git'
else
  echo "Chezmoi already initialized. Skip."
fi

