# My Machine Setup

Personal macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/).

This repository centralizes the configuration of a macOS development environment and automates the setup of a new machine from scratch: shell, tools, applications, macOS system preferences, Git repositories, and Dock layout.

Sensitive data (SSH keys, tokens, secrets) is never stored here. It lives in 1Password and is fetched at runtime via the `op` CLI.

## Main tools

| Tool | Role |
|---|---|
| [chezmoi](https://www.chezmoi.io/) | Dotfile manager — templates, profiles, scripts |
| [1Password](https://1password.com/) | Secret storage — SSH keys, Git identity, repository lists |
| [Homebrew](https://brew.sh/) | Package manager — CLI tools and macOS applications |
| [mise](https://mise.jdx.dev/) | Runtime version manager — Java, Node, Python, etc. |
| [Oh My Zsh](https://ohmyz.sh/) | Zsh framework — plugins, themes, custom functions |

## Quickstart

1. **Install developer tools** — `xcode-select --install`
2. **Prepare 1Password** — create the `chezmoi` vault and the required items (see [1Password setup](doc/1password.md))
3. **Clone over HTTPS** — `git clone https://github.com/<user>/<repo>.git /tmp/chezmoi`
4. **Run the setup script** — `/tmp/chezmoi/scripts/mac-setup.sh`
5. **Follow the interactive prompts** — profile choice, 1Password Developer Settings, GitHub SSH key upload
6. **Reboot** — `sudo reboot`

See [doc/setup.md](doc/setup.md) for the full step-by-step procedure.

## Documentation

| Page | Description |
|---|---|
| [Setup](doc/setup.md) | Step-by-step machine bootstrap |
| [1Password](doc/1password.md) | Vault layout, items, SSH keys, secret model |
| [Profiles](doc/profiles.md) | `work` / `lp` / `sp` — how profile-aware rendering works |
| [Homebrew](doc/homebrew.md) | Common vs profile-specific Brewfiles |
| [Git repositories](doc/git-repos.md) | `repos_clone`, `repo_track`, YAML import |
| [mise](doc/mise.md) | Global runtime version management |
| [Dock](doc/dock.md) | dockutil-driven Dock layout per profile |
| [Architecture](doc/architecture.md) | `setup.d`, `.chezmoiscripts`, templates, ignore rules |
| [Oh My Zsh plugin (`lp`)](doc/oh-my-zsh-plugin.md) | Custom plugin: navigation, cloning, mega-update |
| [Troubleshooting](doc/troubleshooting.md) | Common pitfalls and fixes |

## Architecture in one paragraph

`scripts/mac-setup.sh` sources `scripts/setup.d/NN-*.sh` in order to bootstrap a fresh machine (Homebrew, 1Password CLI, SSH keys, chezmoi, apps, mise, repos). `chezmoi apply` then deploys `dot_*` templates to `$HOME`, runs the `.chezmoiscripts/run_once_osx-*` macOS defaults, and rebuilds the Dock on-change. Per-profile data lives in `profiles/<profile>/` and is loaded by templates at render time. See [Architecture](doc/architecture.md) for the full picture.
