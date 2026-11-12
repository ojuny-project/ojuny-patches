name: Virtualization
id: patch-virtualization
description: QEMU/libvirt/virt-manager support and configuration.
dependencies:
version: 1

# Virtualization

Installs the libvirt daemon, QEMU, virt-manager, and the default guest
lifecycle settings. The patch is off by default.

## Install and enable

```sh
ojuny-patches sync
ojuny-patches install patch-virtualization
```

Then enable the Virtualization patch on the Patches page, or set:

```nix
ojuny.patch.virt.enable = true;
```

## User access

The patch does not add the desktop user to the `libvirtd` group. Group
membership grants control of the system daemon and is a conscious security
choice, not a default.

The supported local path is polkit: the local graphical session authorises
`virsh -c qemu:///system` and virt-manager through the polkit agent. Over SSH
there is no polkit agent, so the session-path call fails unless the user runs it
with sudo, uses the user-session daemon where available, or deliberately joins
the `libvirtd` group. Group membership applies to new sessions, so reconnect
after a rebuild.

`virt-manager` over SSH is not a supported path. Use a local session, or
`virsh -c qemu:///system` from a local terminal.

## Verify

```sh
virsh -c qemu:///system list --all
systemctl status libvirtd
```

The first command succeeds through polkit in a local graphical session without
adding the user to any group.
