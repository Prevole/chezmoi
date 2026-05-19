# Troubleshooting

> [← Documentation index](./README.md)

Common pitfalls when bootstrapping or maintaining this setup, and how to fix them.

---

## Setup script

### The script does not re-prompt for the profile

The profile is persisted to `~/.config/chezmoi/chezmoi.yaml` and read by `promptChoiceOnce` in `.chezmoi.yaml.tmpl`. To change profile:

```sh
vi ~/.config/chezmoi/chezmoi.yaml
# update data.profile
chezmoi apply
```

### `xcode-select --install` is required

If `git` is not available before running the setup script, install the Command Line Tools first:

```sh
xcode-select --install
```

### macOS security popups during setup

Expected. macOS may ask for your user password, prompt for accessibility permissions (e.g. for `dockutil`), or display Gatekeeper warnings for newly installed casks. Approve them as they appear.

---

## 1Password

### `op` CLI is not signed in

```sh
eval $(op signin)
```

The setup script normally handles sign-in, but the session expires. Re-run the command above before any chezmoi apply that reads from 1Password.

### Templates fail with "no item found"

Symptoms: `chezmoi apply` fails with messages from `onepasswordItemFields` or `onepasswordRead`.

Checks:

- The `chezmoi` vault exists and is unlocked.
- The required items exist with the exact names: `GitHub Configurations`, `Git Repositories - <profile>`.
- The `op` CLI integration is enabled in 1Password **Settings → Developer**.
- You are signed in to the right 1Password account.

See [1Password](./1password.md) for the required item layout.

### The SSH agent does not serve a key

Symptoms: `ssh -T git@github.com` fails with "Permission denied (publickey)".

Checks:

1. 1Password is running and unlocked.
2. **Settings → Developer → Use the SSH Agent** is enabled.
3. Each SSH Key item in the per-machine vault has its `Hosts` field set correctly (e.g. `ssh://git@github.com`).
4. `~/.config/1Password/ssh/agent.toml` references the correct vault (machine hostname).
5. Restart 1Password (the SSH agent picks up changes on startup).

### Commit signing fails

Symptoms: `git commit -S` complains about `op-ssh-sign`.

Checks:

- `op-ssh-sign` is on `$PATH` (installed with the 1Password CLI).
- The SSH key item used for signing is registered on GitHub as a **signing key** (not just an authentication key).
- The Git config (`~/.gitconf/perso.config` or `pro.config`) references the right 1Password item ID.

---

## Homebrew

### `brew bundle` fails on a cask

Frequent causes:

- Xcode Command Line Tools missing → `xcode-select --install`.
- Cask requires Rosetta on an Apple Silicon machine → step `02-machine.sh` installs Rosetta 2; verify it ran.
- Cask name changed upstream → `brew search "<name>"` to find the new name and update the Brewfile.

### Mac App Store apps fail to install

`mas` requires you to be signed in to the App Store on the target machine. On a fresh install, sign in once via the App Store app, then re-run `brew bundle install --global`.

In VMs, MAS sign-in is unreliable — the Brewfiles wrap MAS entries in `{{ if not .is_vm }}` to skip them.

---

## Git repositories

### `repos_clone` does not clone anything

Checks:

- The 1Password item `Git Repositories - <profile>` exists in the `chezmoi` vault.
- The `notesPlain` field starts with `repositories:` and is valid YAML.
- `~/.config/gitrepos/config.yaml` references the right vault and item names.
- SSH cloning works at all: `ssh -T git@github.com`.

### A repo is cloned in the wrong directory

`name` and `category` rules:

- Flat list → `<git.root>/<name>`.
- Categorized list → `<git.root>/<category>/<name>`.
- `name` is inferred from the URL basename when omitted.

To force a specific folder name, set `name` explicitly in the YAML. See [Git repositories](./git-repos.md).

### `repo_track` detects the wrong category

`repo_track` infers the category from the directory layout relative to `git.root`:

- `<git.root>/<repo>` → flat (no category)
- `<git.root>/<category>/<repo>` → categorized

If your repository is nested deeper, `repo_track` will not match. Move the repo or edit the 1Password note manually.

---

## chezmoi

### `chezmoi apply` does not re-run an `osx-*` script

The `run_once_osx-*` scripts run **only once ever**. To force a re-run:

```sh
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

Or, more targeted, delete the specific script hash from the state bucket.

### Dock is not rebuilt

`run_onchange_dockitems-dock.sh.tmpl` re-runs only when the rendered file changes. After editing `dock.yaml`, run `chezmoi apply`. To force:

```sh
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

### `agent.toml` not picked up

Restart 1Password after `chezmoi apply` deploys it. The setup script does this automatically (`08-dotfiles.sh`).

---

## mise

### `mise install` fails to build Python or Ruby

Usually missing system build dependencies. Check the [mise troubleshooting docs](https://mise.jdx.dev/troubleshooting.html). On macOS, ensure Command Line Tools are installed.

### Wrong global version active

```sh
mise current        # show active versions
mise ls             # list installed versions per tool
mise use -g <tool>@<version>
```

For repo-level overrides, drop a `.mise.toml` at the project root (not managed by this repo).

---

## Zsh / Oh My Zsh

### `rep` / `gclone` not found

The `lp` plugin is loaded in `dot_zshrc.tmpl`. Checks:

- `~/.oh-my-zsh/custom/plugins/lp/` exists (deployed by chezmoi).
- The plugin is in the `plugins=(...)` list in `~/.zshrc`.
- Open a new shell or `sprof` to reload.

### `rep` matches the wrong directory

The rootdirs cache may be stale. Either:

```sh
rep_cc          # clear cache (rebuild on next call)
lp_cache_refresh
# or one-off bypass:
repnc <query>
```

### `mega-update` fails midway

`mega-update --preview` runs the same logic in dry-run mode — use it to identify which step would fail without actually executing.

---

## macOS preferences

### Some `defaults write` changes did not apply

Some macOS preferences require a logout/reboot to take effect. The setup script prompts for a reboot at the end (`99-restart.sh`) — accept it.

For changes made later, restart the affected process manually or run `killall Dock Finder SystemUIServer`.

### Safari preferences not applied (Sonoma+)

Safari is sandboxed and most `defaults write com.apple.Safari …` no longer works. The `run_once_osx-11-safari.sh` script is best-effort. Enable developer menu manually in Safari Settings → Advanced.

---

## Still stuck?

- Re-read the relevant section in this documentation.
- Run the offending script with `bash -x` to trace it.
- `chezmoi doctor` for a quick environment check.
- Inspect chezmoi state: `chezmoi state dump`.
