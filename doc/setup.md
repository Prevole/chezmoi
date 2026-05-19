# Computer setup

> [← Documentation index](./README.md)

End-to-end procedure to bootstrap a fresh macOS machine from this repository.

!!! tip "TL;DR"
    1. Install Xcode Command Line Tools
    2. Prepare 1Password items (see [1Password](./1password.md))
    3. `git clone` this repo into `/tmp/chezmoi`
    4. Run `/tmp/chezmoi/scripts/mac-setup.sh`
    5. Follow the interactive prompts (profile, 1Password Developer Settings, GitHub SSH key upload)
    6. Reboot

---

## 1. Install developer tools

This makes `git` available in the terminal.

```sh
xcode-select --install
```

## 2. Set up 1Password

Prepare the required vault and items in 1Password **before** cloning the repo. See the dedicated [1Password page](./1password.md) for full details.

In short:

- Create a vault named `chezmoi`
- Create a Login item `GitHub Configurations` (fields: `username`, `email`, `name`, optional `org`)
- Create one Secure Note per profile: `Git Repositories - work`, `Git Repositories - lp`, `Git Repositories - sp` (see YAML format in [Git repositories](./git-repos.md))

## 3. Clone this repository

Clone over HTTPS into `/tmp` — SSH is not yet set up at this point. `/tmp` is cleaned up on next restart.

```sh
git clone https://github.com/<your-username>/<this-repo>.git /tmp/chezmoi
```

## 4. Run the setup script

```sh
/tmp/chezmoi/scripts/mac-setup.sh
```

The script sources each file in `scripts/setup.d/` in order. See [Architecture](./architecture.md) for the full step list.

!!! warning "Interactive pauses"
    The script pauses at several points to wait for manual actions (adding SSH keys to GitHub, confirming 1Password settings). macOS may also display security popups or prompt for your user password — these are expected and required.

The high-level flow is:

1. Prompt for the **profile**:
    - `work` — work machine (work-specific tools, pro Git config, work Brewfile)
    - `lp` — personal machine
    - `sp` — secondary personal machine
2. Install Homebrew
3. Configure machine hostname, disable startup chime, install Rosetta 2
4. Install 1Password + `op` CLI, sign in, **pause for Developer Settings** (see step 5 below)
5. Generate SSH keys directly in 1Password, **pause for GitHub registration**
6. Install chezmoi and render the Brewfile for the selected profile
7. Run `brew bundle` (brews, casks, MAS apps)
8. Create standard user directories (e.g. `~/Documents/repositories`)
9. Apply dotfiles via `chezmoi init --apply`, then restart 1Password
10. Install global runtimes via `mise install`
11. Clone Git repositories listed in 1Password (`Git Repositories - <profile>`)
12. Remove temporary SSH key files from disk (1Password SSH agent serves them from now on)

!!! note
    The profile choice is persisted in `~/.config/chezmoi/chezmoi.yaml` and remembered by `promptChoiceOnce`. It is not asked again on subsequent `chezmoi apply` runs.

## 5. Configure 1Password (interactive)

### Developer Settings

When 1Password opens, sign in and configure **Settings → Developer** as shown:

![1Password Developer Settings](./images/1password-devsettings.png)

| Setting | Value |
|---|---|
| Use the SSH Agent | enabled |
| Ask approval for each new | `application and terminal session` |
| Remember key approval | `until 1Password quits` |
| Display key names when authorizing connections | enabled |
| Generate SSH config file with bookmarked hosts | enabled |
| Integrate with 1Password CLI | enabled |

Press Enter in the terminal to continue.

### Machine vault (automatic)

The script signs in to the `op` CLI and creates a vault named after the machine hostname. This vault is referenced by `agent.toml` (deployed to `~/.config/1Password/ssh/agent.toml`) to serve SSH keys.

### SSH key generation (automatic)

SSH keys are generated directly inside 1Password using `op item create --ssh-generate-key Ed25519` — **no private key file is written to disk** at this stage.

For each key, the script displays a `log_box` with instructions. Open the 1Password item and use the built-in autofill integration to add the public key directly to GitHub — no copy/paste needed. Press Enter in the terminal to continue.

The script also reminds you to set the **Hosts** field on each 1Password SSH Key item — this is required for the SSH agent to select the correct key per GitHub account:

| Key | Hosts value |
|---|---|
| Primary (work/personal) | `ssh://git@github.com` |
| Personal (work profile only) | `ssh://git@github-perso` |

References:

- [Autofill public keys on GitHub](https://developer.1password.com/docs/ssh/public-key-autofill#github)
- [Register a key for commit signing](https://developer.1password.com/docs/ssh/git-commit-signing#step-2-register-your-public-key)

On a **work** profile, the script optionally generates a second key for a personal GitHub account.

1Password is then restarted so the SSH agent picks up the new keys. Once it is back up and the agent shows as running, press Enter to continue.

## 6. Restart

```sh
sudo reboot
```

This is required to apply all macOS system preferences set by the `run_once_osx-*` chezmoi scripts.

---

## What's next

- [Profiles](./profiles.md) — change profile-specific data
- [Homebrew](./homebrew.md) — add tools and apps
- [Git repositories](./git-repos.md) — clone, track, import repos
- [Troubleshooting](./troubleshooting.md) — if something went wrong
