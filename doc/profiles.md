# Profiles

> [← Documentation index](./README.md)

How profile-aware rendering works: `work`, `lp`, `sp`.

!!! tip "TL;DR"
    - The profile is chosen once during setup and stored in `~/.config/chezmoi/chezmoi.yaml`.
    - `profiles/<profile>/` holds per-profile data (Brewfile, Dock). It is **read by templates** but **not deployed**.
    - Templates branch on `.profile` (e.g. `{{ if eq .profile "work" }}…{{ end }}`).

---

## Available profiles

| Profile | Target | Notes |
|---|---|---|
| `work` | Work laptop | Work tools (Azure CLI, Microsoft Office, JetBrains), pro Git config, optional second GitHub account |
| `lp` | Primary personal machine | Personal apps, no work-specific config |
| `sp` | Secondary personal machine | Minimal subset of `lp` |

---

## Where the profile is stored

`scripts/setup.d/00-profile.sh` prompts once and writes:

```yaml title="~/.config/chezmoi/chezmoi.yaml"
data:
  profile: work
```

On subsequent `chezmoi apply` runs, `promptChoiceOnce` in `.chezmoi.yaml.tmpl` reads this value and does **not** prompt again.

To change the profile after setup, edit this file manually.

---

## `profiles/` directory layout

```
profiles/
├── work/
│   ├── .chezmoidata/dock.yaml      ← Dock items for the work profile
│   └── homebrew/Brewfile.tmpl       ← Profile-specific Homebrew packages
├── lp/
│   ├── .chezmoidata/dock.yaml
│   └── homebrew/Brewfile.tmpl
└── sp/
    ├── .chezmoidata/dock.yaml
    └── homebrew/Brewfile.tmpl
```

!!! note
    `profiles/` itself is excluded from the chezmoi target state via `.chezmoiignore.tmpl`. Its contents are loaded only at render time by templates that explicitly reference them (`dot_homebrew/Brewfile.tmpl`, dock script).

---

## How templates use the profile

### Direct branching

```go
{{- if eq .profile "work" }}
brew "azure-cli"
{{- end }}
```

### Profile data inclusion

`dot_homebrew/Brewfile.tmpl` ends with:

```go
{{ includeTemplate (printf "profiles/%s/homebrew/Brewfile.tmpl" .profile) . }}
```

This renders the matching profile-specific Brewfile inline, passing the full chezmoi context.

### Conditional ignore

`.chezmoiignore.tmpl` excludes work-only files when the profile is not `work`:

```go
{{- if ne .profile "work" }}
.gitconf/pro.config
.m2/settings.xml
.oh-my-zsh/custom/plugins/lppro
{{- end }}
```

### Profile-specific dock data

`run_onchange_dockitems-dock.sh.tmpl` reads `.dock.apps` from chezmoi data, which is populated by `profiles/<profile>/.chezmoidata/dock.yaml` (chezmoi auto-loads any `.chezmoidata/*.yaml` from the source state, but only from non-ignored directories — see [Architecture](./architecture.md) for the trick used here).

---

## Adding a new profile

1. Add the new value to the prompt choices in `.chezmoi.yaml.tmpl`.
2. Create `profiles/<new>/homebrew/Brewfile.tmpl` and `profiles/<new>/.chezmoidata/dock.yaml`.
3. Update any template that branches on `.profile`.
4. Update `.chezmoiignore.tmpl` if some files must be excluded for this profile.

---

## Related

- [Homebrew](./homebrew.md) — common vs profile Brewfile
- [Dock](./dock.md) — dock.yaml format
- [Architecture](./architecture.md) — `.chezmoiignore.tmpl` mechanics
