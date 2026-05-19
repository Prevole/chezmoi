# Git repositories

> [← Documentation index](./README.md)

How Git repositories are tracked, cloned, and imported using 1Password as the source of truth.

!!! tip "TL;DR"
    - The list of repositories is stored as YAML inside the `notesPlain` field of `Git Repositories - <profile>` (1Password vault `chezmoi`).
    - `repos_clone` clones missing repos. `repo_track` adds the current repo to the list. `repos_track_import <file.yaml>` replaces the list with a local file.
    - The root directory and 1Password coordinates are defined in `~/.config/gitrepos/config.yaml`.

---

## Configuration file

Rendered from `dot_config/gitrepos/config.yaml.tmpl` to `~/.config/gitrepos/config.yaml`. It defines:

- `git.root` — base directory where repositories are cloned (default `~/Documents/repositories`)
- 1Password vault and item names per profile

---

## YAML schema

The `notesPlain` field of the 1Password Secure Note must start with a `repositories:` key.

### Categorized form

```yaml
repositories:
  work:
    - url: git@github.com:org/repo.git           # folder name inferred from URL
    - name: custom-folder                         # explicit folder name (optional)
      url: git@github.com:org/repo.git
  perso:
    - url: git@github-perso:user/repo.git
```

Repositories are cloned into `<root>/<category>/<name>`.

### Flat form (no categories)

```yaml
repositories:
  - url: git@github.com:org/repo.git
```

Repositories are cloned into `<root>/<name>`.

!!! note
    The `name` field is optional. When omitted, the folder name is inferred from the URL basename (e.g. `foo` from `git@github.com:org/foo.git`). Use `name` only when your local folder differs from the repository name.

---

## Commands

All commands are exposed by the custom Oh My Zsh plugin `lp`. See [the plugin page](./oh-my-zsh-plugin.md) for the full reference.

### Clone missing repositories

```sh
repos_clone
```

Reads `Git Repositories - <profile>` from 1Password and clones any repository not already present on disk. Skips existing clones.

### Track the current repository

From inside a Git repository:

```sh
repo_track
```

Detects the category automatically from the directory layout:

- `<root>/<repo>` → flat list (no category)
- `<root>/<category>/<repo>` → categorized

The `name` field is omitted from the stored entry when the folder name matches the repository name in the URL. If the folder name differs, `name` is stored explicitly.

### Import a YAML file

```sh
repos_track_import <file.yaml>
```

Replaces the `Git Repositories - <profile>` item in 1Password with the contents of a local YAML file. The file must follow the same schema as `notesPlain`.

Useful for bulk-import or restoring a list from a backup.

---

## SSH host selection

The plugin function `gclone <org>/<repo>` and the underlying clone logic select the SSH alias (`github.com` vs `github-perso`) based on:

- the current directory (under `<root>/work/` vs `<root>/perso/`)
- the active chezmoi profile

See `_lp_git_host()` in `dot_oh-my-zsh/custom/plugins/lp/lp.plugin.zsh`.

---

## Related

- [1Password](./1password.md) — vault and item creation
- [Oh My Zsh plugin](./oh-my-zsh-plugin.md) — `rep`, `gclone`, navigation commands
- [Profiles](./profiles.md) — which item is read per profile
