name: Corsair RGB
id: patch-corsair-rgb
description: Dynamic ckb-next RGB lighting driven by Stylix colors, Mango binds and DMS state
dependencies:
version: 1

## Requirements

The keyboard must expose `rgb` in its ckb-next `/dev/input/ckb*/features`
file. Bind highlighting reads `desktop.ojuny.mango.binds`, and the patch
asserts that this option exists.
