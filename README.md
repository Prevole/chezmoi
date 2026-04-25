# My Machine Setup

Personal macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/).

---

## Introduction

This repository centralizes the configuration of a macOS development environment. It automates the setup of a new machine from scratch: shell, tools, applications, macOS system preferences, Git repositories, and Dock layout.

Sensitive data (SSH keys, tokens, secrets) is never stored in this repository. It lives in 1Password and is fetched at runtime via the `op` CLI.

---

## Main tools

| Tool | Role |
|---|---|
| [chezmoi](https://www.chezmoi.io/) | Dotfile manager — templates, profiles, scripts |
| [1Password](https://1password.com/) | Secret storage — SSH keys, Git repository list |
| [Homebrew](https://brew.sh/) | Package manager — CLI tools and macOS applications |
| [mise](https://mise.jdx.dev/) | Runtime version manager — Java, Node, Python, etc. |
| [Oh My Zsh](https://ohmyz.sh/) | Zsh framework — plugins, themes, custom functions |

---

## Computer setup

### 1. Install developer tools

```sh
xcode-select --install
```

### 2. Set up 1Password

Before cloning this repository, prepare the following items in 1Password.

#### Vault: `chezmoi`

Create a vault named `chezmoi`. This is the central vault for all data used by this setup.

#### Item: `GitHub Configurations`

> **Warning**: The configuration of GitHub stored in 1Password is subject to specific and personal setup.
> 
> In my case, I have two different setups: One for work with two GitHub Accounts, and one for personal use with only
> one main GitHub Account.

Create a **Login** item named `GitHub Configurations` in the `chezmoi` vault with the following fields (as an example):

| Field | Description |
|---|---|
| `username` | Your GitHub username |
| `email` | Your commit email address |
| `name` | Your display name (used in Git commits) |
| `org` | Your GitHub organization (work profile only) |

These values are used to populate `~/.gitconfig` and profile-specific Git configs via chezmoi templates.

#### Item: `Git Repositories - <profile>`

Create one note per profile (`Git Repositories - work`, `Git Repositories - lp`, `Git Repositories - sp`) in the `chezmoi` vault.

Each note contains the single note field holding a YAML document with your list of repositories. Two formats are supported:

**With categories:**
```yaml
repositories:
   my-category: # Will be a root folder where the repositories are cloned
     - name: my-repo
       url: git@github.com:username/my-repo.git
   
   another-category: # Will be another root folder where the repositories are cloned
     - name: other-repo
       url: git@github.com:username/other-repo.git
```

**Flat list (no categories):**
```yaml
repositories:
   - name: my-repo
     url: git@github.com:username/my-repo.git
```

> Repositories are cloned into `<root>/<category>/<name>` when categories are defined, or `<root>/<name>` for flat lists.
> 
> The root directory is defined in `~/.config/gitrepos/config.yaml` (rendered from `dot_config/gitrepos/config.yaml.tmpl`).

### 3. Clone this repository

Clone over HTTPS into `/tmp` — SSH is not yet set up at this point. The directory is cleaned up automatically on next restart.

```sh
git clone https://github.com/<your-username>/<this-repo>.git /tmp/chezmoi
```

### 4. Run the setup script

```sh
/tmp/chezmoi/scripts/mac-setup.sh
```

The script sources each file in `setup.d/` in order. It will:

1. Install Homebrew
2. Configure the machine hostname
3. Generate an SSH key — pause to let you add the public key to GitHub
4. Prompt for the **profile** — enter one of:
   - `work` — work machine (work-specific tools, pro Git config, work Brewfile)
   - `lp` — personal machine
   - `sp` — secondary personal machine
5. Render the Brewfile for the chosen profile and install all tools and applications
6. Open 1Password — pause to let you configure it (see step 5)
7. Initialize chezmoi and apply dotfiles

The profile choice is written to `~/.config/chezmoi/chezmoi.yaml` and remembered by `promptChoiceOnce`. It will not be 
asked again on subsequent `chezmoi apply` runs.

### 5. Configure 1Password

The setup script opens 1Password and pauses at several points.

#### Developer Settings

When 1Password opens, sign in and configure **Settings → Developer** as shown below:

![1Password Developer Settings](doc/images/1password-devsettings.png)

| Setting | Value |
|---|---|
| Use the SSH Agent | enabled |
| Ask approval for each new | `application and terminal session` |
| Remember key approval | `until 1Password quits` |
| Display key names when authorizing connections | enabled |
| Generate SSH config file with bookmarked hosts | enabled |
| Integrate with 1Password CLI | enabled |

Press Enter in the terminal to continue.

#### Machine vault (automatic)

The script signs in to the `op` CLI and creates a vault named after your machine hostname. This vault is used by 
`agent.toml` to serve SSH keys.

#### SSH key import (manual)

The script opens `~/.ssh` in Finder and displays the exact title and vault to use:

1. In 1Password, select the `<hostname>` vault created in the previous step.
2. Clic on `New Item`
3. Select `SSH Key`
4. Title the item exactly as shown in the terminal: `<username> - <hostname> - <algirthm>`
5. Drag and drop the private key (e.g. `~/.ssh/id_ed25519`)
6. Repeat the process from 1 for key you want to use with GitHub
7. Save, then press Enter in the terminal.

The script will then restart 1Password so the SSH agent picks up the imported key. Once it is back up and the agent 
shows as running, press Enter to continue.

### 6. Restart

```sh
sudo reboot
```

---

## How tos

### Clone your Git repositories

```sh
repos_clone
```

Reads the `Git Repositories - <profile>` item from 1Password (vault `chezmoi`) and clones any repository not already 
present on the filesystem. The root directory is read from `~/.config/gitrepos/config.yaml`.

Repositories are cloned into `<root>/<category>/<name>` when categories are defined, or `<root>/<name>` for flat lists.

### Track a new Git repository

From inside any Git repository:

```sh
repo_track
```

Infers the category from the directory path, asks you to confirm or override, then adds the repository to the 
`Git Repositories - <profile>` item in 1Password via `op item edit`.

### Change global runtime tool versions (mise)

Language runtimes (Java, Node.js, Python, Maven, Terraform, Terragrunt, etc.) are managed by [mise](https://mise.jdx.dev/).

Global versions are defined in `dot_config/mise/config.toml` → `~/.config/mise/config.toml`:

```toml
[tools]
java = "temurin"
maven = "latest"
node = "latest"
python = "latest"
terraform = "latest"
terragrunt = "latest"
```

To add or change a version:

```sh
chezmoi edit ~/.config/mise/config.toml  # add or update the tool entry
chezmoi apply                            # Apply the configuration change
mise install                             # install the new version(s)
```

To browse available versions: `mise ls-remote <tool>`.

Per-project overrides can be added with a `.mise.toml` file at the project root — these are not managed by this 
repository.

### Add or change CLI tools and applications (Homebrew)

Specific tools and applications are declared in `profiles/<profile>/homebrew/Brewfile`, included at render time 
into `dot_homebrew/Brewfile.tmpl`. For common tools and applications, see `dot_homebrew/Brewfile.tmpl`.

To find the correct name: `brew search "tool-name"`.

```sh
# For specific profile
vi /profiles/<profile>/Brewfile  # add brew "tool" or cask "app"
chezmoi apply                    # install the new tool or app

# For common tools and applications 
chezmoi edit ~/.homebrew/Brewfile  # add brew "tool" or cask "app"
chezmoi apply                      # install the new tool or app

# Once applied, run brew
brew install -g
```

### Add items to the Dock (dockutil)

Dock contents are declared in `profiles/<profile>/.chezmoidata/dock.yaml`:

```yaml
dock:
  apps:
    - /Applications/MyApp.app
```

Edit the file for your profile, then run `chezmoi apply` — the Dock script re-runs automatically when the file has changed.

---

## Architecture

### Key files and directories

| Path | Description |
|---|---|
| `scripts/mac-setup.sh` | Bootstrap orchestrator — sources `setup.d/` scripts in order |
| `scripts/setup.d/` | Individual setup steps (see below) |
| `.chezmoi.yaml.tmpl` | chezmoi config template — prompts for `profile` |
| `profiles/<profile>/` | Per-profile data (Dock, Brewfile) |
| `dot_homebrew/Brewfile.tmpl` | Homebrew packages — includes the profile Brewfile |
| `dot_config/gitrepos/config.yaml.tmpl` | Git root and 1Password vault/item for repos |
| `dot_config/mise/config.toml` | Global runtime tool versions |
| `dot_gitconfig.tmpl` | Git global config — profile-aware |
| `dot_zshrc.tmpl` | Zsh config — profile-aware plugin list |
| `dot_ssh/config.tmpl` | SSH config — profile-aware |
| `dot_oh-my-zsh/custom/plugins/lp/` | Custom Oh My Zsh plugin (see below) |
| `.chezmoiscripts/` | Scripts auto-run by chezmoi on apply |


### setup.d — how it works

`mac-setup.sh` sources each `setup.d/NN-*.sh` file in alphabetical order. Scripts are **sourced, not executed** — they 
all share the same shell environment and can pass exported variables to each other.

| Script | Role |
|---|---|
| `_utils.sh` | Color helpers: `log_success`, `log_skip`, `log_warn`, `log_info`, `log_box` |
| `01-homebrew.sh` | Install Homebrew |
| `02-machine.sh` | Set machine hostname |
| `03-ssh.sh` | Generate SSH key |
| `04-chezmoi.sh` | Install chezmoi, prompt for profile, render and write Brewfile |
| `05-apps.sh` | Run `brew bundle` with the rendered Brewfile |
| `06-1password.sh` | 1Password login, vault creation, SSH key import |
| `07-dotfiles.sh` | Initialize and apply chezmoi |
| `99-restart.sh` | Prompt to restart |

Every step tries to be idempotent — Checks whether the action is already done and skips with `log_skip` if so.

### profiles — how it works

`profiles/` contains per-profile data that is **not deployed to the target machine** — it is only read by chezmoi templates at render time. It is excluded from the chezmoi target state via `.chezmoiignore.tmpl`.

```
profiles/
  work/
    .chezmoidata/dock.yaml    ← Dock apps for the work profile
    homebrew/Brewfile         ← Homebrew packages for the work profile
  lp/
    ...
  sp/
    ...
```

The active profile is selected once during setup (stored in `~/.config/chezmoi/chezmoi.yaml`) and referenced in templates as `.profile`.

### Personal data in 1Password

No personal data is stored in this repository. The following items must exist in the `chezmoi` vault before running chezmoi:

| Item | Used by |
|---|---|
| `GitHub Configurations` | `dot_gitconfig.tmpl`, `dot_gitconf/*.config.tmpl` |
| `Git Repositories - <profile>` | `repos_clone`, `repo_track` (via `~/.config/gitrepos/config.yaml`) |

SSH keys are stored in the machine vault (named after the hostname) and served by the 1Password SSH agent — no private key files live on disk after the initial setup.
