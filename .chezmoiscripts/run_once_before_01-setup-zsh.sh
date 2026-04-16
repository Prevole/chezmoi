#!/usr/bin/env bash

ZSH_PATH="$(which zsh)"

if ! grep -qx "$ZSH_PATH" /etc/shells; then
  echo "Adding zsh to /etc/shells..."
  echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
else
  echo "zsh is already in /etc/shells. Skip."
fi

CURRENT_SHELL="$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')"

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
  echo "Changing default shell to zsh..."
  chsh -s "$ZSH_PATH" "$(id -un)"
else
  echo "Default shell is already zsh. Skip."
fi
