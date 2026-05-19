# Homebrew

> [← Documentation index](./README.md)

How CLI tools and macOS applications are managed through Homebrew.

!!! tip "TL;DR"
    - Common packages live in `dot_homebrew/Brewfile.tmpl` (deployed as `~/.homebrew/Brewfile`).
    - Profile-specific packages live in `profiles/<profile>/homebrew/Brewfile.tmpl` and are included at render time.
    - `brew bundle install --file=~/.homebrew/Brewfile` (or `brew install -g`) applies them.

---

## File layout

| File | Role |
|---|---|
| `dot_homebrew/Brewfile.tmpl` | Common brews, casks, fonts. Includes the profile Brewfile at the end. |
| `profiles/work/homebrew/Brewfile.tmpl` | Work-specific (Azure CLI, JetBrains Toolbox, …) |
| `profiles/lp/homebrew/Brewfile.tmpl` | Personal apps + Mac App Store apps |
| `profiles/sp/homebrew/Brewfile.tmpl` | Minimal personal subset |

The deployed file lives at `~/.homebrew/Brewfile`. Running `brew bundle install --global` reads it.

---

## How profile inclusion works

The last line of `dot_homebrew/Brewfile.tmpl`:

```go
{{ includeTemplate (printf "profiles/%s/homebrew/Brewfile.tmpl" .profile) . }}
```

renders the matching profile-specific Brewfile inline, passing the full chezmoi context (notably `.is_vm`).

### VM guard

Mac App Store entries (`mas "…"`) are gated with `{{ if not .is_vm }}` because the Mac App Store cannot sign in inside most VMs.

---

## Common workflows

### Add a package available on every profile

```sh
chezmoi edit ~/.homebrew/Brewfile   # opens dot_homebrew/Brewfile.tmpl
# add: brew "tool"   or   cask "app"
chezmoi apply
brew install -g
```

### Add a package only for one profile

```sh
vi profiles/<profile>/homebrew/Brewfile.tmpl
# add: brew "tool"   or   cask "app"
chezmoi apply
brew install -g
```

### Find the correct formula or cask name

```sh
brew search "tool-name"
```

### Apply the Brewfile manually

```sh
brew bundle install --global       # uses ~/.homebrew/Brewfile
brew bundle cleanup --global       # show what would be removed
```

---

## During bootstrap

`scripts/setup.d/05-chezmoi.sh` pre-renders `dot_homebrew/Brewfile.tmpl` via `chezmoi execute-template` (chezmoi is not yet initialized at this point) and writes the result to `/tmp/Brewfile`. `scripts/setup.d/06-apps.sh` then runs `brew bundle install --file=/tmp/Brewfile`.

This bootstraps the full toolchain before any dotfile is applied.

---

## Related

- [Profiles](./profiles.md) — profile data structure
- [Setup](./setup.md) — bootstrap order
