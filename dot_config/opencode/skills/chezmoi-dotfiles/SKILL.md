---
name: chezmoi-dotfiles
description: When modifying a home directory config or dotfile, check if it is managed by chezmoi and prompt to add it if not
---

## What I do

When I create or modify a file under `~` (home directory):

1. Run `chezmoi managed` and check if the file is listed
2. If **already managed**: edit via `chezmoi edit <file>` or apply changes with `chezmoi add <file>` after editing in place, then remind the user to commit in the chezmoi source repo
3. If **not managed**: ask the user whether to add it with `chezmoi add <file>`

## When to use me

Use this automatically whenever a task involves creating or editing a dotfile or config file under `~/` — including `~/.config/`, `~/.local/`, `~/.bashrc`, `~/.zshrc`, etc.
