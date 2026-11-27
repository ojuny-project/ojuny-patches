name: Logitech G13
id: patch-logitech-g13
description: Logitech G13 driver, non-blocking LCD display and Mango bind banks
dependencies:
version: 1

## Install, enable, remove

```sh
ojuny-patches sync
ojuny-patches install patch-logitech-g13
```

Installation copies the module and enables nothing. Open the settings GUI, go to Patches, turn on Logitech G13, then rebuild. The settings page is the configuration surface. The upstream Java GUI is not included and is not used.

To remove, turn Logitech G13 off, rebuild, run `ojuny-patches remove patch-logitech-g13`, and rebuild again.

## Display

The LCD display is off by default. Enable it after enabling the patch.

The line table holds the LCD rows. Each row is one line, and its dropdown combines a source with a detail level:

- Off leaves the line blank.
- Default is the normal summary.
- Compact is the shortest useful line.
- Detailed adds values and may be truncated to 25 characters.

Add, remove, or reorder rows in the table. The row order is the display order.

Media titles longer than 25 characters scroll one character per media refresh. The offset resets when the track changes.

Detector settings are under Advanced. Each detector runs in its own user service and writes a JSON snapshot under `$XDG_RUNTIME_DIR/ojuny/g13/`. The render loop runs at `display.refreshMs`, reads the latest snapshots, substitutes values, and writes `/run/user/<uid>/g13-lcd` only when the frame changes. A slow detector never blocks the render loop; its line keeps the last successful value, and a source with no value yet leaves its line blank.

`g13-int` writes a framed temporary message and `g13-raw` writes a raw temporary message. The render loop shows either file for one pass, then returns to the status frame.

## Binds

Bank 1 ships with a non-keyboard layout: scratchpad, window state, layout switching, DMS system toggles, DMS panels, and the movement, groups, and resize mode controls. Banks 2 to 4 are empty for the user to fill.

The G13 sends its own `SUPER+ALT+CTRL` chord namespace. The patch adds matching Mango binds, so the device never duplicates the main keyboard chords. Bank rows are a list-shaped keybinds table. The title is the action, the preview is the G13 key, and the rows stay in physical order.

The stick uses `F13` to `F16`. A small evdev filter grabs the driver's virtual `G13` device, forwards a filtered `G13 Filtered` device, and ignores a different stick direction for 300 ms after one direction is accepted. This removes diagonal double-triggering without changing the driver.

Mango gets mode-specific stick and thumb binds:

- default: focus, focusstack, and stack navigation.
- movement: exchange, exchange_stack, and movement.
- groups: groupjoin, groupfocus, and groups.
- resize: smartresizewin and mode switching.

The same rows are registered in the DMS keybinds menu as the `g13` provider.

## Colors

Each bank has a color dropdown with all sixteen Stylix names plus `custom`. Choosing `custom` reveals a color picker. Named colors follow the active Stylix palette.

## Limits

- The LCD is 5 lines of 25 characters.
- A detector that fails or times out writes nothing, so the previous value stays visible.
- Weather uses `curl` against `wttr.in`; there is no DMS weather IPC command.
- The G13 bank colors require the Stylix module.
- GPU detection prefers a working `nvidia-smi`, then AMD, then Intel. Choose a vendor explicitly if the automatic result is wrong.
