# ojuny-patches

The default patch registry for Ojuny on NixOS. A patch is a Nix module in a git
repository, installed by `ojuny-patches` from the Ojuny CLI. Installing copies
one module into your flake; enabling it is a separate step in the settings
menu.

Status: untested on commit `edc5f6e` (2026-11-03). The catalogue is generated
and checked in CI. The install commands below have not been run against this
commit.

## Requirements

NixOS with flakes enabled, `git`, and `ojuny-patches` on `PATH`. Installation
writes into the flake directory, which needs write permission. Disk and memory
use are not measured. Fetching a patch repository needs network access.

## Install

```sh
ojuny-patches sync
ojuny-patches list available
ojuny-patches install patch-zed
```

`sync` refreshes the local registry. `list available` prints IDs;
[CATALOGUE.md](CATALOGUE.md) adds descriptions and versions. `install` copies
`modules/patches/patch-zed.nix` into the flake and leaves the patch disabled.
Expected output is not recorded.

## Usage

Enable the patch on its page in the settings menu, or set the option and
rebuild:

```nix
ojuny.patch.zed.enable = true;
```

Options differ per patch; the patch page lists them. To remove one, turn the
switch off, rebuild, then run:

```sh
ojuny-patches remove patch-zed
```

Rebuild once more. Removing the module while the switch is still on leaves an
option without a declaration and fails evaluation.

## Registry layout

```
CATALOGUE.md               generated list of patches
patch-<name>/metadata.md    name, id, description, dependencies, version
modules/patches/<id>.nix    the module
scripts/gen-catalogue.py    catalogue generator
```

The ID must match the directory: `patch-zed/` and
`modules/patches/patch-zed.nix`.

## Publishing a patch

Add `patch-<name>/metadata.md` and `modules/patches/patch-<name>.nix`, then run
`python3 scripts/gen-catalogue.py` and commit the regenerated catalogue. The
metadata needs all five fields: name, id, description, dependencies, and
version. The description is required and must be longer than one word.
`dependencies` is a comma-separated list of patch IDs. CI fails when a field is
missing, a description is empty or one word, or the catalogue is out of date.

## Limits and security

Patches are third-party content. A patch module is evaluated with the same
privileges as the rest of the configuration: it can set any NixOS option, add
packages, enable services, or replace the desktop. Read the module before
installing it. Reinstalling overwrites local edits to the installed module, and
removal is manual. The registry does not review what a patch does.

## Documentation

- [CATALOGUE.md](CATALOGUE.md): which patches exist, with version and description
- [patch-development/metadata.md](patch-development/metadata.md): a complete metadata file with install notes
- [scripts/gen-catalogue.py](scripts/gen-catalogue.py): how the catalogue is built
- [.github/workflows/docs.yml](.github/workflows/docs.yml): what CI checks

## Contributing

Open issues at [ojuny-project/ojuny-patches](https://github.com/ojuny-project/ojuny-patches).
A patch pull request includes the metadata file, the module, and a regenerated
`CATALOGUE.md`.

## License

GNU General Public License version 3, see [LICENSE](LICENSE). Installed
upstream packages and assets keep their own licenses.
