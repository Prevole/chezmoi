# mise — runtime versions

> [← Documentation index](./README.md)

Global runtime version management (Java, Node, Python, Maven, Terraform, Terragrunt, …) via [mise](https://mise.jdx.dev/).

!!! tip "TL;DR"
    - Global versions live in `dot_config/mise/config.toml` → `~/.config/mise/config.toml`.
    - Workflow: `chezmoi edit` → `chezmoi apply` → `mise install`.

---

## Global config

```toml title="~/.config/mise/config.toml"
[tools]
java = "temurin"
maven = "latest"
node = "latest"
python = "latest"
terraform = "latest"
terragrunt = "latest"
```

Source file: `dot_config/mise/config.toml`.

---

## Add or change a version

```sh
chezmoi edit ~/.config/mise/config.toml   # add or update an entry
chezmoi apply                              # propagate to ~/.config/mise/config.toml
mise install                               # install the new version(s)
```

To browse available versions:

```sh
mise ls-remote <tool>
```

---

## Per-project overrides

A project can declare its own runtime versions via a `.mise.toml` at its root. Project-local files are **not** managed by this repository.

```toml title="<project>/.mise.toml"
[tools]
node = "20"
python = "3.12"
```

---

## During bootstrap

`scripts/setup.d/09-mise.sh` runs `mise install` after the dotfiles have been applied. This installs every runtime listed in the deployed `~/.config/mise/config.toml`.

---

## Related

- [Setup](./setup.md) — bootstrap order
- [Troubleshooting](./troubleshooting.md) — if `mise install` fails
