name: Flatpak
id: patch-flatpak
description: Flatpak support and the bazaar store to easily install, update and manage your flatpaks.
dependencies:
version: 1

# Flatpak

Installs the Flatpak service with its portal integration and the Bazaar
application store. The patch is off by default.

## Install and enable

```sh
ojuny-patches sync
ojuny-patches install patch-flatpak
```

Then enable the Flatpak patch on the Patches page, or set:

```nix
ojuny.patch.flatpak.enable = true;
```

## Flathub

The patch does not add a Flatpak remote. On first launch, Bazaar prompts to add
Flathub, and the user confirms it. This keeps the remote a visible user choice
instead of a silent system change.

Check the result with:

```sh
flatpak remotes
```

If Flathub is missing, open Bazaar and accept its prompt, or add it manually:

```sh
flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
```
