# Dock

> [← Documentation index](./README.md)

Dock layout is declared per profile and applied via [dockutil](https://github.com/kcrawford/dockutil).

!!! tip "TL;DR"
    - Dock items live in `profiles/<profile>/.chezmoidata/dock.yaml`.
    - `run_onchange_dockitems-dock.sh.tmpl` re-runs automatically whenever the file changes.

---

## File format

```yaml title="profiles/<profile>/.chezmoidata/dock.yaml"
dock:
  apps:
    - /Applications/System Settings.app
    - /Applications/Firefox.app
    - /Applications/Safari.app
```

Each entry is the absolute path to an `.app` bundle.

---

## How it is applied

`.chezmoiscripts/run_onchange_dockitems-dock.sh.tmpl` is a chezmoi `run_onchange` script:

1. Wipes the Dock with `dockutil --remove all`.
2. Re-adds each app from `dock.apps`.
3. Adds `~/Downloads` as a fan-view stack.
4. Restarts the Dock.

The script is re-run only when the **hash of the rendered template** changes — meaning when you edit `dock.yaml` and run `chezmoi apply`.

---

## Edit the Dock

```sh
vi profiles/<profile>/.chezmoidata/dock.yaml
chezmoi apply
```

The Dock will be rebuilt from scratch.

!!! warning
    Adding an app to `dock.yaml` requires that the app actually exists in `/Applications/`. Make sure the corresponding entry exists in the matching `profiles/<profile>/homebrew/Brewfile.tmpl` (as a `cask` or `mas` entry).

---

## Per-profile contents

| Profile | Apps (excerpt) |
|---|---|
| `work` | System Settings, Outlook, Teams, Firefox, Firefox Developer Edition, Chrome, Safari, Word, Excel, PowerPoint |
| `lp` | App Store, System Settings, iPhone Mirroring, Activity Monitor, iTerm, Mail, browsers, Office, Steam |
| `sp` | App Store, System Settings, Activity Monitor, Mail, browsers, Office |

Exact list: see each `profiles/<profile>/.chezmoidata/dock.yaml`.

---

## Related

- [Profiles](./profiles.md) — profile data structure
- [Homebrew](./homebrew.md) — install the apps before adding them to the Dock
