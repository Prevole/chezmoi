# 1Password

> [← Documentation index](./README.md)

How this setup uses 1Password as the central secret store: vault layout, required items, SSH key model.

!!! tip "TL;DR"
    - **One vault** named `chezmoi` holds all configuration data (Git identity, repository lists).
    - **One per-machine vault** named after the hostname holds SSH keys, served by the 1Password SSH agent.
    - **No private keys ever live on disk** after the initial bootstrap.

---

## Vaults

### `chezmoi` vault (shared)

Central vault holding all configuration items used by chezmoi templates. Create it manually before running the setup script.

### `<hostname>` vault (per-machine)

Created automatically by `scripts/setup.d/03-1password.sh`. Stores the SSH keys generated for this specific machine. Referenced by `agent.toml` (deployed to `~/.config/1Password/ssh/agent.toml`) so the 1Password SSH agent only serves keys from this vault.

---

## Required items

### `GitHub Configurations` (Login)

Stores the Git identity (commit author, signing email). Used by:

- `dot_gitconfig.tmpl` → `~/.gitconfig`
- `dot_gitconf/perso.config.tmpl` → `~/.gitconf/perso.config`
- `dot_gitconf/pro.config.tmpl` → `~/.gitconf/pro.config` (work profile only)

| Field | Description |
|---|---|
| `username` | GitHub username |
| `email` | Commit email address |
| `name` | Display name (used in Git commits) |
| `org` | GitHub organization (work profile only) |

!!! warning
    The exact field layout is personal. In the current setup there are two GitHub accounts on work machines (primary + personal) and one account on personal machines. Adjust the templates in `dot_gitconf/*.config.tmpl` if your model differs.

### `Git Repositories - <profile>` (Secure Note)

One item per profile: `Git Repositories - work`, `Git Repositories - lp`, `Git Repositories - sp`.

The `notesPlain` field holds a YAML document. See [Git repositories](./git-repos.md) for the YAML schema and tooling.

### SSH Key items (per machine, auto-generated)

Created by `scripts/setup.d/04-ssh-keys.sh` via `op item create --ssh-generate-key Ed25519`. Stored in the per-machine vault.

On a **work** profile, two keys are generated:

| Item | Purpose | `Hosts` field |
|---|---|---|
| Primary key | Work GitHub account | `ssh://git@github.com` |
| Personal key | Personal GitHub account | `ssh://git@github-perso` |

On `lp` / `sp` profiles, only the primary key is generated.

!!! warning "Set the Hosts field manually"
    The 1Password SSH agent uses the `Hosts` field of each SSH Key item to decide which key to serve for a given SSH host. After key generation, open each item in 1Password and set the value as shown above.

### Commit signing key (auto)

The Git config templates (`dot_gitconf/*.config.tmpl`) read the per-machine SSH public key from an item named `<github-username> - <hostname> - ED25519` and enable SSH commit signing via `op-ssh-sign`.

References:

- [Autofill public keys on GitHub](https://developer.1password.com/docs/ssh/public-key-autofill#github)
- [Register a key for commit signing](https://developer.1password.com/docs/ssh/git-commit-signing#step-2-register-your-public-key)

---

## SSH key lifecycle

1. **Generation** — `op item create --ssh-generate-key Ed25519` creates the key directly inside 1Password.
2. **Temporary extraction** — the private key is briefly written to `~/.ssh/` so chezmoi can clone its own remote via SSH during bootstrap.
3. **Apply** — `chezmoi init --apply` deploys `agent.toml`, restarts 1Password.
4. **Cleanup** — `scripts/setup.d/98-ssh-cleanup.sh` deletes the temporary on-disk private keys.
5. **Steady state** — the 1Password SSH agent serves keys for SSH operations and commit signing. **No private key file remains on disk.**

---

## Reading values from templates

chezmoi exposes two helpers used throughout the templates:

- `onepasswordItemFields "<vault>" "<item-id>"` — returns a map of fields.
- `onepasswordRead "op://<vault>/<item>/<field>"` — returns a single field.

Examples in `dot_gitconf/perso.config.tmpl` and `dot_gitconf/pro.config.tmpl`.

---

## Related

- [Setup](./setup.md) — when items are required during bootstrap
- [Git repositories](./git-repos.md) — `Git Repositories - <profile>` YAML schema
- [Troubleshooting](./troubleshooting.md) — `op` sign-in issues, agent not serving keys
