name: Docker
id: patch-docker
description: Docker daemon, rootless mode, pruning, daemon settings and declarative containers
dependencies:
version: 2

# Docker

Installs the Docker daemon in system mode or a per-user rootless daemon, with
optional pruning, daemon settings, and declarative containers. The patch is off
by default.

## Install and enable

```sh
ojuny-patches sync
ojuny-patches install patch-docker
```

Then enable the Docker patch on the Patches page, or set:

```nix
ojuny.patch.docker.enable = true;
```

## User access

The patch does not add the desktop user to the `docker` group. Membership in
that group is root-equivalent and is a conscious security choice, not a default.
Choose one of these paths:

- Run Docker commands through sudo. This keeps the system daemon and the
  declarative containers, but every command needs elevation.
- Switch the Docker mode to `rootless`. The per-user daemon needs no group
  membership. Declarative containers are not supported in rootless mode.
- Deliberately add the user to the `docker` group in the host configuration.
  Group membership applies to new sessions, so reconnect after a rebuild.

The patch never changes group membership itself.

## Verify

```sh
sudo docker run --rm hello-world
```

In rootless mode, run the same command without sudo after switching the mode
and rebuilding.
