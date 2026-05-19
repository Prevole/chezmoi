# Architecture

> [← Documentation index](./README.md)

End-to-end view of how this repository is structured and how chezmoi turns it into a configured machine.

!!! tip "TL;DR"
    - `scripts/setup.d/*.sh` is the **bootstrap** pipeline (one-shot, runs from `/tmp/chezmoi`).
    - `.chezmoiscripts/*.sh` is the **steady-state** pipeline (runs on every `chezmoi apply`).
    - `dot_*` files are templates deployed to `$HOME`, `profiles/*` is render-only data, `.chezmoiignore.tmpl` decides what is not deployed.

---

## Key files and directories

| Path | Description |
|---|---|
| `scripts/mac-setup.sh` | Bootstrap orchestrator — sources `setup.d/` scripts in order |
| `scripts/setup.d/` | Individual bootstrap steps |
| `.chezmoi.yaml.tmpl` | chezmoi config template — prompts for `profile` once |
| `.chezmoiignore.tmpl` | Files to exclude from the target state (profile-aware) |
| `.chezmoiexternal.toml` | External resources fetched by chezmoi (p10k, zsh plugins) |
| `.chezmoiscripts/` | Scripts auto-run by chezmoi on apply |
| `profiles/<profile>/` | Per-profile render-only data (Dock, Brewfile) |
| `dot_homebrew/Brewfile.tmpl` | Common Brewfile, includes the profile Brewfile |
| `dot_config/gitrepos/config.yaml.tmpl` | Git root + 1Password vault/item for repos |
| `dot_config/mise/config.toml` | Global runtime tool versions |
| `dot_gitconfig.tmpl` | Git global config — profile-aware |
| `dot_gitconf/` | Git config fragments (`includeIf` targets) |
| `dot_zshrc.tmpl` | Zsh config — profile-aware plugin list |
| `dot_ssh/config.tmpl` | SSH config — profile-aware |
| `dot_oh-my-zsh/custom/plugins/lp/` | Custom Oh My Zsh plugin (see [plugin page](./oh-my-zsh-plugin.md)) |
| `dot_oh-my-zsh/custom/plugins/lppro/` | Work-only Oh My Zsh plugin (Azure, Terragrunt) |

---

## `scripts/setup.d/` — bootstrap pipeline

`mac-setup.sh` sources each `setup.d/NN-*.sh` file in alphabetical order. Scripts are **sourced, not executed** — they share the same shell environment and pass exported variables to each other (`$PROFILE`, `$HOSTNAME`, `$BREWFILE_RENDERED`).

| Script | Role |
|---|---|
| `_utils.sh` | Color helpers: `log_success`, `log_skip`, `log_warn`, `log_info`, `log_title`, `log_box` |
| `00-profile.sh` | Prompt for profile, write `~/.config/chezmoi/chezmoi.yaml` |
| `01-homebrew.sh` | Install Homebrew (or load `brew shellenv`) |
| `02-machine.sh` | Hostname, disable startup chime, install Rosetta 2 |
| `03-1password.sh` | Install 1Password + `op` CLI, login, Developer Settings pause, machine vault creation |
| `04-ssh-keys.sh` | Generate SSH keys in 1Password via `op`, pause for GitHub registration |
| `05-chezmoi.sh` | Install chezmoi, render Brewfile for the selected profile |
| `06-apps.sh` | `brew bundle install` with the rendered Brewfile |
| `07-directories.sh` | Create the `git.root` directory (e.g. `~/Documents/repositories`) |
| `08-dotfiles.sh` | Run `chezmoi init --apply`, restart 1Password |
| `09-mise.sh` | `mise install` — runtimes from `~/.config/mise/config.toml` |
| `10-repos.sh` | Clone Git repositories from 1Password (`Git Repositories - <profile>`) |
| `98-ssh-cleanup.sh` | Remove temporary on-disk SSH key files extracted during setup |
| `99-restart.sh` | Prompt to `sudo shutdown -r now` |

Every step tries to be idempotent — checks whether the action is already done and skips with `log_skip` if so.

---

## `.chezmoiscripts/` — steady-state pipeline

Scripts auto-run by chezmoi based on filename prefix.

### Trigger conventions

| Prefix | Trigger |
|---|---|
| `run_once_before_*` | Once ever, **before** dotfiles are applied |
| `run_once_*` | Once ever, after dotfiles are applied |
| `run_onchange_*` | Re-runs whenever the rendered file hash changes |
| `run_*` (no qualifier) | Every `chezmoi apply` |

### Pre-apply (`run_once_before`)

| File | Action |
|---|---|
| `run_once_before_01-setup-zsh.sh` | Add `zsh` to `/etc/shells`, `chsh` to zsh |
| `run_once_before_02-setup-oh-my-zsh.sh` | Install Oh My Zsh if missing |

### macOS defaults (`run_once_osx-*`)

A series of scripts setting `defaults write` for Finder, keyboard, trackpad, display, Dock, Mission Control, security, screenshots, Desktop, hot corners, Safari, Activity Monitor, TextEdit, Control Center, printing, software update, miscellaneous. They flag affected processes for restart in `$MACOS_RESTART_FLAG_DIR`.

### Dock (`run_onchange`)

`run_onchange_dockitems-dock.sh.tmpl` rebuilds the Dock when `profiles/<profile>/.chezmoidata/dock.yaml` changes. See [Dock](./dock.md).

### Restart (`run` every apply)

`run_osx-99-always-macosx-restart-processes-if-required.sh` reads the flag dir and restarts the corresponding processes (Dock, Finder, SystemUIServer, …).

---

## `profiles/` — render-only data

```
profiles/
├── work/
│   ├── .chezmoidata/dock.yaml
│   └── homebrew/Brewfile.tmpl
├── lp/
│   ├── .chezmoidata/dock.yaml
│   └── homebrew/Brewfile.tmpl
└── sp/
    ├── .chezmoidata/dock.yaml
    └── homebrew/Brewfile.tmpl
```

The active profile is selected once during setup (stored in `~/.config/chezmoi/chezmoi.yaml`) and referenced in templates as `.profile`.

!!! note
    `profiles/` is excluded from the target state via `.chezmoiignore.tmpl`. Its content is loaded only when explicitly referenced by other templates (e.g. `dot_homebrew/Brewfile.tmpl` includes `profiles/<profile>/homebrew/Brewfile.tmpl`).

See [Profiles](./profiles.md) for details.

---

## `dot_config/` — XDG configuration

Deployed to `~/.config/`. Highlights:

| Entry | Purpose |
|---|---|
| `atuin/` | Shell history (atuin) |
| `direnv/` | direnv helpers |
| `gh-copilot/` | GitHub Copilot CLI |
| `ghostty/` | Ghostty terminal |
| `gitrepos/` | Git root + 1Password coords (used by `lp` plugin) |
| `mise/` | Global runtime versions |
| `nvim/` | LazyVim configuration |
| `opencode/` | OpenCode CLI config + agents/skills/plugins |
| `private_1Password/private_ssh/agent.toml` | 1Password SSH agent config (private mode) |
| `zellij/` | Zellij multiplexer |
| `media-archiver/` | media-archiver config |

---

## `.chezmoiignore.tmpl`

Files excluded from the target state. Some exclusions are conditional on profile:

```go
chezmoi.iml
README.md
.workstation
.shellcheckrc
.tool-versions
scripts
doc
profiles

{{- if ne .profile "work" }}
.gitconf/pro.config
.m2/settings.xml
.oh-my-zsh/custom/plugins/lppro
{{- end }}
```

- `doc/`, `scripts/`, `profiles/` stay in the repo but are never deployed.
- The `lppro` plugin is installed only on the `work` profile.

---

## `.chezmoiexternal.toml`

Fetches external resources at apply time:

- powerlevel10k theme (git repo)
- zsh-autosuggestions (git repo)
- zsh-syntax-highlighting (git repo)
- powerlevel10k fonts archive

Each entry has `refreshPeriod = "168h"` (one week).

---

## Bootstrap data flow

```
mac-setup.sh
  └─ sources setup.d/00..99
      ├─ 00 profile prompt           → ~/.config/chezmoi/chezmoi.yaml
      ├─ 01 Homebrew
      ├─ 02 Hostname / chime / Rosetta
      ├─ 03 1Password CLI + Developer Settings + machine vault
      ├─ 04 SSH keys in 1Password (+ temp extract to ~/.ssh)
      ├─ 05 chezmoi install + render Brewfile via execute-template
      ├─ 06 brew bundle
      ├─ 07 mkdir ~/Documents/repositories
      ├─ 08 chezmoi init --apply         → deploys dot_*, runs .chezmoiscripts
      │     └─ restart 1Password (agent picks up agent.toml)
      ├─ 09 mise install
      ├─ 10 repos_clone (from 1Password)
      ├─ 98 ssh cleanup (delete temp keys)
      └─ 99 reboot prompt
```

---

## Related

- [Setup](./setup.md) — user-facing bootstrap procedure
- [Profiles](./profiles.md) — profile selection mechanics
- [Oh My Zsh plugin](./oh-my-zsh-plugin.md) — the `lp` plugin internals
