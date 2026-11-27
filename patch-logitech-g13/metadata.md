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

The LCD is 5 lines by 25 characters. `display.lines` holds up to five rows with a source, a format string, and an enabled switch. At least one row must stay enabled.

Each detector runs in its own user service at its configured refresh interval and writes a JSON snapshot under `$XDG_RUNTIME_DIR/ojuny/g13/`. The render loop runs at `display.refreshMs`, reads the latest snapshots, substitutes `$variable` placeholders, and writes `/run/user/<uid>/g13-lcd` only when the frame changes. A slow detector never blocks the render loop; its line keeps the last successful value, and a source with no value yet leaves its line blank.

`g13-int` writes a framed temporary message and `g13-raw` writes a raw temporary message. The render loop shows either file for one pass, then returns to the status frame.

## Binds

The four banks follow the physical L1 to L4 buttons. Each bank is a regular `keybinds` widget table keyed by G13 key. Bank names are fixed and bank colors come from the Stylix palette.

Chord rows are compiled into internal driver macro files. The macro layer is not exposed as an option. Single-key rows use the driver passthrough format. The same rows are registered in the DMS keybinds menu as the `g13` provider.

## Limits

- The LCD is 5 lines of 25 characters.
- A detector that fails or times out writes nothing, so the previous value stays visible.
- Weather uses `curl` against `wttr.in`; there is no DMS weather IPC command.
- The G13 bank colors require the Stylix module.
