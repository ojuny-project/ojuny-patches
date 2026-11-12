name: Ojuny agent
id: patch-ojuny-agent
description: Approval-gated maintenance agent and read-only assistant for the Ojuny flake, with a flake-safe CLI for validation and git sync
dependencies: patch-development
version: 2

# Ojuny agent

This patch adds two OpenCode agents and the `ojuny-agent-cli` safety CLI. It is
off by default. It requires `patch-development` and the OpenCode agent from that
patch. The agent configuration uses the OpenCode V2 `agents` and `permissions`
shape because path-scoped edit rules are required for the flake boundary.

## Install and enable

```sh
ojuny-patches sync
ojuny-patches install patch-ojuny-agent
```

Installing copies one Nix module and enables nothing. `ojuny-patches install`
stages the module with `git add`, because a Nix flake ignores an untracked
module. If you add a module by hand, stage it with the settings GUI Sync button
or `git add modules/patches/patch-ojuny-agent.nix`. Open the settings GUI, go
to Patches, turn on Ojuny agent, confirm that Development and its OpenCode agent
are enabled, then rebuild.

The patch asserts that `ojuny.patch.development.enable` and
`ojuny.patch.development.agents.opencode.enable` are true. It does not enable
them itself.

To remove, turn Ojuny agent off, rebuild, run
`ojuny-patches remove patch-ojuny-agent`, and rebuild again. Removing the file
while the switch is still on leaves an option without a declaration and fails
evaluation.

## Agents

`ojuny-agent` is the full agentic flavour. It can edit or create files inside
the flake only with explicit approval, validate every edit, show a diff, revert
changes, and sync the flake git. It can ask to use network clients and web
fetching. It cannot rebuild, activate, use sudo, install packages, or change
services. Runtime `ojuny` commands are denied by default. The Allow runtime
actions switch turns them into approval-gated commands, but sudo and rebuilds
stay denied.

`ojuny-assist` is the read-only flavour. It answers questions about Ojuny, the
settings menu, patches, the flake, and the `ojuny` CLI. It cannot edit, create,
sync, revert, lock, rebuild, or mutate anything. Its shell is read-only, and
network clients such as `curl`, `wget`, `nc`, `socat`, `ssh`, `scp`, and `rsync`
are denied.

Both agents load the flake `AGENTS.md` when it exists. The patch does not create
that file; the agent guide works without it.

## The CLI

`ojuny-agent-cli` is the flake-safe interface. Read-only commands are `guide`,
`status`, `settings list`, `settings show`, `patches list`, `patches show`,
`diagnose`, `docs`, `diff`, `validate`, `sync --status`, and `sync --dry-run`.

Mutating commands require `--yes`: `sync`, `sync --continue`, `sync --abort`,
`revert`, `revert --all`, and `lock`. Mutating commands never accept `--flake`
and always use the configured Ojuny flake.

## Edit workflow

1. Locate the page with `ojuny-agent-cli settings show <page>`.
2. Read the module and the governing docs.
3. Propose the file, line, old value, new value, and validation plan.
4. Wait for explicit approval.
5. Apply the edit inside the flake only.
6. Run `ojuny-agent-cli validate`.
7. Fix or revert a failed change. Do not ask for a rebuild.
8. Show `ojuny-agent-cli diff`. The user rebuilds.

Choose Allow once for an edit. Allow always saves a durable allow rule for that
path and removes the per-change approval prompt for later edits.

Validation runs the changed-file parse and format checks, `nix flake check
--no-build`, and a host evaluation. It does not build or activate the system.

Generated files are denied even inside the flake: `flake.lock`,
`modules/07-system/00-hardware.nix`, `modules/07-system/facter.json`,
`modules/07-system/00-hardware-quirks.nix`, and
`modules/01-users/01-user.nix`.

## Git sync and conflicts

`sync --status` and `sync --dry-run` are read-only. A real sync requires a clean
worktree and `--yes`. The CLI creates a backup ref, fetches, then fast-forwards
or prepares a no-commit merge. It never pushes and never rewrites history.

Conflicts are never auto-resolved. The agent explains both sides, proposes a
resolution, asks for approval, edits the conflicted files, runs `validate`, and
then runs `sync --continue`. `sync --abort` aborts an in-progress merge.
`flake.lock` conflicts are resolved deliberately and regenerated with `lock`.

## Safety limits

- No sudo, rebuild, activation, package installation, or service changes.
- No edits outside the flake.
- No edits to generated hardware, account, or secret files.
- No reads of `.env`, key, age, or secret files.
- No raw `git pull`, merge, rebase, reset, commit, push, or clean. Use the CLI.
- The explain agent denies write actions and network clients. The full agent asks
  for approval before it edits, creates, fetches, or runs a network client.
- The CLI does not push.

## Documentation

- `docs/11-agent.md` in the fork explains the agent model for users.
- `AGENTS.md` is the flake contributor guide once it lands.
- The CLI `guide` command prints the same guidance to an agent.
