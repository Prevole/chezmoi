# Documentation

Detailed documentation for this chezmoi-managed macOS setup.

For the high-level overview and quickstart, see the [project README](../README.md).

## Pages

| Page | Description |
|---|---|
| [Setup](./setup.md) | Step-by-step machine bootstrap (Xcode CLT → reboot) |
| [1Password](./1password.md) | Vault layout, items, SSH keys, secret model |
| [Profiles](./profiles.md) | `work` / `lp` / `sp` — how profile-aware rendering works |
| [Homebrew](./homebrew.md) | Common vs profile-specific Brewfiles |
| [Git repositories](./git-repos.md) | `repos_clone`, `repo_track`, YAML import |
| [mise](./mise.md) | Global runtime version management |
| [Dock](./dock.md) | dockutil-driven Dock layout per profile |
| [Architecture](./architecture.md) | `setup.d`, `.chezmoiscripts`, templates, ignore rules |
| [Oh My Zsh plugin (`lp`)](./oh-my-zsh-plugin.md) | Custom plugin: navigation, cloning, mega-update |
| [Troubleshooting](./troubleshooting.md) | Common pitfalls and fixes |

## Conventions

- All documentation pages use [MkDocs Material admonition syntax](https://squidfunk.github.io/mkdocs-material/reference/admonitions/) (`!!! warning`, `!!! tip`, `!!! note`). GitHub renders these as plain blockquotes — both work.
- All paths are relative to the repository root unless noted.
- Code blocks always specify a language for syntax highlighting.
