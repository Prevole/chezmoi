# Oh My Zsh custom plugins

> [← Documentation index](./README.md)

Custom Oh My Zsh plugins shipped by this repository: `lp` (always loaded) and `lppro` (work profile only).

!!! tip "TL;DR"
    - `lp` exposes commands for repository navigation, cloning via 1Password, environment scaffolding, and an `mega-update` command.
    - `lppro` is a minimal helper for Azure CLI and Terraform/Terragrunt cleanup. Loaded only on the `work` profile.

---

## `lp` plugin

### Location

`dot_oh-my-zsh/custom/plugins/lp/` → `~/.oh-my-zsh/custom/plugins/lp/`

### File map

| File | Purpose |
|---|---|
| `lp.plugin.zsh` | Entry point. Defines all user-facing functions, aliases, completion bindings. |
| `_lp.zsh` | Zsh completion script (`#compdef rep orep repnc repd lrep`). Tab-completes navigation commands by scanning rootdirs from the shared cache. |
| `lp_1password.rb` | Ruby helpers for reading/writing the `Git Repositories` 1Password note. |
| `repos_clone.rb` | Clones all repos listed in the 1Password note that are missing on disk. Supports flat and categorized YAML. |
| `repo_track.rb` | Adds the current git repository to the 1Password note. |
| `repos_track_import.rb` | Replaces the 1Password note with a local YAML file. |

### User-facing commands

#### Repository navigation

| Command | Description |
|---|---|
| `rep <query>` | `cd` into a repo matching `<query>`. Uses `fzf` on multi-match. |
| `orep <query>` | Same as `rep` but `open` the directory (Finder). |
| `repd [query]` | `cd` to a known repo **rootdir** (uses `fzf` when multiple match). |
| `lrep <query>` | Same as `rep`, scoped to the deepest known rootdir containing `$PWD`. |
| `repnc <query>` | Alias for `REP_NO_CACHE=1 rep` — bypasses the rootdir cache (debug). |

Rootdirs are derived from `~/.gitconfig` `includeIf "gitdir:..."` entries and cached at `$XDG_CACHE_HOME/lp/rootdirs`. Matching is case-insensitive prefix match at level 1 (`rootdir/repo`) and level 2 (`rootdir/category/repo`).

#### Cache management

| Command | Description |
|---|---|
| `lp_cache_refresh` | Clear and rebuild the rootdirs cache immediately. |
| `rep_cc` | Clear the rootdirs cache (rebuilt on next call). |

#### Cloning

| Command | Description |
|---|---|
| `gclone <org>/<repo> [target]` | `git clone` using the correct SSH host (`github.com` vs `github-perso`) based on CWD + profile, then `cd` into the clone. |
| `repos_clone` | Clone every repo listed in `Git Repositories - <profile>` (1Password) that is missing on disk. |

#### Repository tracking (1Password-backed)

| Command | Description |
|---|---|
| `repo_track` | From inside a git repo: add it to the 1Password note. Auto-detects flat vs categorized layout. |
| `repos_track_import <file.yaml>` | Replace the 1Password note with a local YAML file. |

See [Git repositories](./git-repos.md) for the YAML schema.

#### Editing chezmoi sources

| Command | Description |
|---|---|
| `cedit <file>` | Edit a chezmoi source file via `$EDITOR`. Tab-completion lists chezmoi source files with their applied names. |

#### Bulk repo operations

| Command | Description |
|---|---|
| `repos_pull` | `git pull` in every direct subdirectory that is a git repo. |
| `repos_stat` | `git s` (status) in every direct subdirectory that is a git repo. |

#### Profile / shell helpers

| Command | Description |
|---|---|
| `eprof` | Open `~/.zshrc` in nvim. |
| `sprof` | `source ~/.zshrc`. |
| `envsetup` | Scaffold `.envrc`, `.envrc.sample`, `.oprc` for direnv + 1Password in the current directory. |

#### Search

| Command | Description |
|---|---|
| `fgg <pattern> <glob>` | ripgrep with a glob filter. |

#### Mega update

| Command | Description |
|---|---|
| `mega-update [--preview]` | Orchestrated update of chezmoi, Homebrew (+ Brewfile delta), Oh My Zsh, mise, gh extensions. Colored framed output. `--preview` runs in dry-run mode. |

### Internal helpers

These are not meant to be called directly but are useful to know when reading the plugin code:

- `_lp_build_rootdirs_cache` — parses `~/.gitconfig` and caches rootdirs. Invalidated when gitconfig is newer than the cache or when `REP_NO_CACHE=1`.
- `_lp_git_root` — reads `git.root` from `~/.config/gitrepos/config.yaml`.
- `_lp_chezmoi_profile` — extracts `.data.profile` from `~/.config/chezmoi/chezmoi.yaml`.
- `_lp_git_host` — chooses `github.com` vs `github-perso` based on CWD + active profile.
- `_lp_find_repos` — case-insensitive prefix match at levels 1 and 2.
- `_internal_rep` — shared implementation behind `rep` / `orep`.

### Completion bindings

The plugin registers:

- `compdef _cedit cedit` — completes chezmoi source files for `cedit`.
- `compdef repnc=rep` — `repnc` shares the same completion as `rep`.
- `_lp.zsh` (`#compdef rep orep repnc repd lrep`) — completes repo names by scanning the rootdirs cache.

---

## `lppro` plugin (work profile only)

### Location

`dot_oh-my-zsh/custom/plugins/lppro/` → `~/.oh-my-zsh/custom/plugins/lppro/`

Loaded only when `.profile == "work"`. On other profiles, it is excluded from the target state via `.chezmoiignore.tmpl`:

```go
{{- if ne .profile "work" }}
.oh-my-zsh/custom/plugins/lppro
{{- end }}
```

### Commands

| Command | Description |
|---|---|
| `azl` | `az logout` then `az login` — re-auth Azure CLI shortcut. |
| `tgclean` | Recursively removes `.terraform/`, `.terragrunt-cache/` directories and `.terraform.lock.hcl` files under the current directory. |

---

## Adding a new function

1. Open the plugin entry point: `chezmoi edit ~/.oh-my-zsh/custom/plugins/lp/lp.plugin.zsh` (or `lppro.plugin.zsh`).
2. Add the function. Prefix internal helpers with `_lp_` / `_lppro_`.
3. If the function takes a repo or chezmoi source as argument, add a completion entry in `_lp.zsh` or via `compdef`.
4. `chezmoi apply` to deploy.
5. `sprof` (or open a new shell) to reload.

---

## Related

- [Git repositories](./git-repos.md) — the cloning / tracking commands
- [1Password](./1password.md) — secret storage backing the plugin
- [Profiles](./profiles.md) — why `lppro` is loaded only on `work`
