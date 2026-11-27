/*
  @menu
  displayname = "Corsair RGB";
  icon = "input-keyboard-symbolic";
  order = 220;
  description = "Dynamic ckb-next RGB lighting driven by Stylix colors, Mango binds and DMS state";
  category = "Patches";
  systems = [ "all" ];
*/

{ self, ... }:

{
  flake.modules.nixos.patch-corsair-rgb =
    { config, lib, ... }:
    {
      options.ojuny.patch.corsair-rgb.enable = lib.mkEnableOption "the Corsair RGB patch";

      imports = [ self.modules.nixos.corsair-rgb-backend ];

      config = {
        # @option widget = "switch"; label = "Corsair RGB"; group = "Corsair RGB"; groupOrder = 10; order = 10; description = "Enable ckb-next and the dynamic RGB daemon.";
        ojuny.patch.corsair-rgb.enable = false;

        # @option widget = "dropdown"; label = "Ambient"; group = "Palette"; groupOrder = 20; order = 10; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color every key starts at. Pick a foreground or accent color. It is dimmed by Ambient level so the highlights stay brighter.";
        ojuny.patch.corsair-rgb.palette.ambient = "functions";

        # @option widget = "slider"; label = "Ambient level"; group = "Palette"; groupOrder = 20; order = 15; min = 0; max = 100; step = 1; unit = "%"; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Brightness of the ambient background. 30 keeps the base color visible without washing out the highlights.";
        ojuny.patch.corsair-rgb.ambientLevel = 30;

        # @option widget = "dropdown"; label = "Unlit"; group = "Palette"; groupOrder = 20; order = 20; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for volume-bar keys below the current volume. Pick a foreground or accent color. It is dimmed by Unlit level.";
        ojuny.patch.corsair-rgb.palette.unlit = "functions";

        # @option widget = "slider"; label = "Unlit level"; group = "Palette"; groupOrder = 20; order = 25; min = 0; max = 100; step = 1; unit = "%"; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Brightness of unlit volume keys and empty tag digits.";
        ojuny.patch.corsair-rgb.unlitLevel = 15;

        # @option widget = "dropdown"; label = "Muted"; group = "Palette"; groupOrder = 20; order = 30; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Low-contrast color available to state rows; no built-in highlight uses it.";
        ojuny.patch.corsair-rgb.palette.muted = "darkForeground";

        # @option widget = "dropdown"; label = "Neutral"; group = "Palette"; groupOrder = 20; order = 40; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for tag digits that have windows but are not active.";
        ojuny.patch.corsair-rgb.palette.neutral = "defaultForeground";

        # @option widget = "dropdown"; label = "Bright"; group = "Palette"; groupOrder = 20; order = 50; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "High-contrast color available to state rows; no built-in highlight uses it.";
        ojuny.patch.corsair-rgb.palette.bright = "lightForeground";

        # @option widget = "dropdown"; label = "Primary"; group = "Palette"; groupOrder = 20; order = 60; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for keys bound in the active Mango keymode.";
        ojuny.patch.corsair-rgb.palette.primary = "functions";

        # @option widget = "dropdown"; label = "Secondary"; group = "Palette"; groupOrder = 20; order = 70; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Spare accent available to state rows; no built-in highlight uses it.";
        ojuny.patch.corsair-rgb.palette.secondary = "keywords";

        # @option widget = "dropdown"; label = "Accent"; group = "Palette"; groupOrder = 20; order = 80; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for modifier keys in active keymode and state highlights.";
        ojuny.patch.corsair-rgb.palette.accent = "support";

        # @option widget = "dropdown"; label = "Success"; group = "Palette"; groupOrder = 20; order = 90; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for low-volume bars and success state rows.";
        ojuny.patch.corsair-rgb.palette.success = "strings";

        # @option widget = "dropdown"; label = "Warning"; group = "Palette"; groupOrder = 20; order = 100; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for warning state rows.";
        ojuny.patch.corsair-rgb.palette.warning = "classes";

        # @option widget = "dropdown"; label = "Attention"; group = "Palette"; groupOrder = 20; order = 110; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for mid-volume bars and attention state rows.";
        ojuny.patch.corsair-rgb.palette.attention = "integers";

        # @option widget = "dropdown"; label = "Error"; group = "Palette"; groupOrder = 20; order = 120; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for urgent tag digits, high-volume bars, and error state rows.";
        ojuny.patch.corsair-rgb.palette.error = "variables";

        # @option widget = "dropdown"; label = "Special"; group = "Palette"; groupOrder = 20; order = 130; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Spare accent available to state rows; no built-in highlight uses it.";
        ojuny.patch.corsair-rgb.palette.special = "deprecated";

        # @option widget = "slider"; label = "Gamma"; group = "Palette"; groupOrder = 20; order = 140; min = 1.0; max = 3.5; step = 0.1; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Brightness curve applied to every key color. Higher values brighten dark colors more.";
        ojuny.patch.corsair-rgb.gamma = 2.8;

        # @option widget = "text"; label = "Devices"; group = "Runtime"; groupOrder = 30; order = 10; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "`auto` finds RGB-capable ckb-next devices. A comma-separated list forces specific devices.";
        ojuny.patch.corsair-rgb.devices = "auto";

        # @option widget = "spin"; label = "Refresh seconds"; group = "Runtime"; groupOrder = 30; order = 20; min = 5; max = 600; unit = "s"; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Reapply the whole frame when no keymode, tag, DMS, or volume event arrives.";
        ojuny.patch.corsair-rgb.refreshSeconds = 60;

        # @option widget = "spin"; label = "State refresh seconds"; group = "Runtime"; groupOrder = 30; order = 30; min = 1; max = 60; unit = "s"; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "How often DMS and volume state are checked.";
        ojuny.patch.corsair-rgb.stateRefreshSeconds = 2;

        # @option widget = "switch"; label = "Volume bar"; group = "Volume bar"; groupOrder = 40; order = 10; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Light the selected keys as a bar; the number of lit keys follows the sink volume.";
        ojuny.patch.corsair-rgb.volumeBar.enable = true;

        # @option widget = "dropdown"; label = "Volume mode"; group = "Volume bar"; groupOrder = 40; order = 30; choices = [ "solid" "ramp" "heat" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "`solid` uses one color; `ramp` colors each lit key by position; `heat` colors the bar by level.";
        ojuny.patch.corsair-rgb.volumeBar.mode = "solid";

        # @option widget = "dropdown"; label = "Volume color"; group = "Volume bar"; groupOrder = 40; order = 40; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for every lit key in solid mode.";
        ojuny.patch.corsair-rgb.volumeBar.color = "functions";

        # @option widget = "dropdown"; label = "Volume low"; group = "Volume bar"; groupOrder = 40; order = 50; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for the low third of the bar in ramp mode, and the whole bar at low volume in heat mode.";
        ojuny.patch.corsair-rgb.volumeBar.low = "strings";

        # @option widget = "dropdown"; label = "Volume mid"; group = "Volume bar"; groupOrder = 40; order = 60; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for the middle third of the bar in ramp mode, and the whole bar at mid volume in heat mode.";
        ojuny.patch.corsair-rgb.volumeBar.mid = "integers";

        # @option widget = "dropdown"; label = "Volume high"; group = "Volume bar"; groupOrder = 40; order = 70; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for the high third of the bar in ramp mode, and the whole bar at high volume in heat mode.";
        ojuny.patch.corsair-rgb.volumeBar.high = "variables";

        # @option widget = "switch"; label = "Tag indicators"; group = "Tags"; groupOrder = 50; order = 10; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Light number keys 1 to 0 for Mango tags: active, occupied, urgent, and empty.";
        ojuny.patch.corsair-rgb.tags.enable = true;

        # @option widget = "dropdown"; label = "Tag active"; group = "Tags"; groupOrder = 50; order = 20; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for the tag currently shown on the monitor.";
        ojuny.patch.corsair-rgb.tags.active = "functions";

        # @option widget = "dropdown"; label = "Tag occupied"; group = "Tags"; groupOrder = 50; order = 30; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for a tag that has windows but is not currently shown.";
        ojuny.patch.corsair-rgb.tags.occupied = "defaultForeground";

        # @option widget = "dropdown"; label = "Tag urgent"; group = "Tags"; groupOrder = 50; order = 40; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for a tag containing an urgent window.";
        ojuny.patch.corsair-rgb.tags.urgent = "variables";

        # @option widget = "dropdown"; label = "Tag empty"; group = "Tags"; groupOrder = 50; order = 50; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for a tag with no windows.";
        ojuny.patch.corsair-rgb.tags.empty = "comments";

        # @option widget = "switch"; label = "Keymode binds"; group = "Keymode"; groupOrder = 60; order = 10; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Light the keys and modifiers used by the current Mango keymode.";
        ojuny.patch.corsair-rgb.keymode.enable = true;

        # @option widget = "dropdown"; label = "Modifier color"; group = "Keymode"; groupOrder = 60; order = 20; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Color for SUPER, SHIFT, ALT, and CTRL when an active bind uses them.";
        ojuny.patch.corsair-rgb.keymode.modifierColor = "support";

        # @option widget = "table-list"; label = "State binds"; group = "State binds"; groupOrder = 70; order = 10; columns = [ "name" "match" "probe" "color" "enabled" ]; columnTypes = [ "str" "str" "str" "dropdown" "bool" ]; choices = [ "defaultBackground" "lighterBackground" "selectionBackground" "comments" "darkForeground" "defaultForeground" "lightForeground" "lightBackground" "variables" "integers" "classes" "strings" "support" "functions" "keywords" "deprecated" ]; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "When the selected DMS state is active, light the keys of every bind whose action contains the match text. probe selects the state source.";
        ojuny.patch.corsair-rgb.stateBinds = [
          {
            name = "Night mode";
            match = "night";
            probe = "dms-night";
            color = "support";
            enabled = true;
          }
          {
            name = "Do not disturb";
            match = "inhibit";
            probe = "dms-dnd";
            color = "classes";
            enabled = true;
          }
          {
            name = "Muted";
            match = "mute";
            probe = "audio-muted";
            color = "variables";
            enabled = true;
          }
          {
            name = "Media playing";
            match = "playpause";
            probe = "media-playing";
            color = "strings";
            enabled = true;
          }
        ];

        # @option widget = "switch"; label = "Ojuny menu shortcuts"; group = "Ojuny menu"; groupOrder = 80; order = 10; visibleWhen.path = "ojuny.patch.corsair-rgb.enable"; visibleWhen.equals = true; description = "Add Toggle lighting, Reload lighting, and Lighting status to the Ojuny application menu opened with SUPER+X.";
        ojuny.patch.corsair-rgb.dms.menuEntry = true;
      };
    };

  flake.modules.nixos.corsair-rgb-backend =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      cfg = config.ojuny.patch.corsair-rgb;
      active = cfg.enable && (config.ojuny.patches or true);

      namedColors = [
        "defaultBackground"
        "lighterBackground"
        "selectionBackground"
        "comments"
        "darkForeground"
        "defaultForeground"
        "lightForeground"
        "lightBackground"
        "variables"
        "integers"
        "classes"
        "strings"
        "support"
        "functions"
        "keywords"
        "deprecated"
      ];

      colorType = lib.types.enum namedColors;

      stylixAvailable = options ? stylix;
      namedColorsAvailable = stylixAvailable && self ? colors;
      colors = if namedColorsAvailable then self.colors config.lib.stylix.colors else null;
      hex = name: colors.${name}.hex;

      pythonSource = pkgs.writeTextFile {
        name = "ojuny-rgb.py";
        executable = true;
        text = ''
          #!${pkgs.python3}/bin/python3
          """Dynamic Corsair RGB lighting for Ojuny."""

          import argparse
          import glob
          import json
          import os
          import re
          import signal
          import socket
          import struct
          import subprocess
          import sys
          import threading
          import time
          from pathlib import Path

          RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
          CKBDIR = os.environ.get("OJUNY_RGB_CKB_DIR", "/dev/input")
          STATE_PATH = os.path.join(RUNTIME_DIR, "ojuny-rgb.json")
          PID_PATH = os.path.join(RUNTIME_DIR, "ojuny-rgb.pid")
          WRITE_WARNINGS = set()

          MODIFIER_KEYS = {
              "SUPER": "lwin",
              "META": "lwin",
              "WIN": "lwin",
              "SHIFT": "lshift",
              "ALT": "lalt",
              "CTRL": "lctrl",
              "CONTROL": "lctrl",
          }

          KEY_NAMES = {
              "RETURN": "enter",
              "ENTER": "enter",
              "ESCAPE": "esc",
              "ESC": "esc",
              "BACKSPACE": "bspace",
              "SPACE": "space",
              "TAB": "tab",
              "PRINT": "prtscn",
              "PRINTSCREEN": "prtscn",
              "SYSRQ": "prtscn",
              "LEFT": "left",
              "RIGHT": "right",
              "UP": "up",
              "DOWN": "down",
              "HOME": "home",
              "END": "end",
              "INSERT": "ins",
              "DELETE": "del",
              "PAGEUP": "pgup",
              "PAGEDOWN": "pgdn",
              "CAPSLOCK": "caps",
              "MUTE": "mute",
              "VOLUMEDOWN": "voldn",
              "VOLUMEUP": "volup",
              "PLAYPAUSE": "play",
              "NEXTSONG": "next",
              "PREVIOUSSONG": "prev",
              "BRIGHTNESSDOWN": "lightdn",
              "BRIGHTNESSUP": "lightup",
              "MINUS": "minus",
              "EQUAL": "equal",
              "LEFTBRACE": "lbrace",
              "RIGHTBRACE": "rbrace",
              "BACKSLASH": "bslash",
              "SEMICOLON": "colon",
              "APOSTROPHE": "quote",
              "GRAVE": "grave",
              "COMMA": "comma",
              "DOT": "dot",
              "SLASH": "slash",
          }

          for _index in range(1, 25):
              KEY_NAMES[f"F{_index}"] = f"f{_index}"


          def log(message):
              print(f"ojuny-rgb: {message}", file=sys.stderr, flush=True)


          def read_json(path):
              with open(path, "r", encoding="utf-8") as handle:
                  return json.load(handle)


          def atomic_write(path, text):
              directory = os.path.dirname(path)
              if directory:
                  os.makedirs(directory, exist_ok=True)
              temporary = path + ".tmp"
              with open(temporary, "w", encoding="utf-8") as handle:
                  handle.write(text)
              os.replace(temporary, path)


          def run_command(args, timeout=2.0):
              try:
                  result = subprocess.run(
                      args,
                      capture_output=True,
                      text=True,
                      timeout=timeout,
                      check=False,
                  )
                  return result.returncode, result.stdout.strip(), result.stderr.strip()
              except (FileNotFoundError, subprocess.TimeoutExpired, OSError) as error:
                  return 1, "", str(error)


          def apply_gamma(value, gamma):
              text = str(value).lstrip("#")
              if len(text) != 6:
                  return "000000"
              channels = []
              for index in (0, 2, 4):
                  try:
                      channel = int(text[index:index + 2], 16)
                  except ValueError:
                      channel = 0
                  channels.append(max(0, min(255, int(((channel / 255.0) ** gamma) * 255))))
              return "".join(f"{channel:02X}" for channel in channels)


          def scale_color(value, level):
              text = str(value).lstrip("#")
              if len(text) != 6:
                  return "000000"
              factor = max(0, min(100, int(level))) / 100.0
              channels = []
              for index in (0, 2, 4):
                  try:
                      channel = int(text[index:index + 2], 16)
                  except ValueError:
                      channel = 0
                  channels.append(max(0, min(255, int(channel * factor))))
              return "".join(f"{channel:02X}" for channel in channels)


          def translate_key(value):
              if isinstance(value, int):
                  value = str(value)
              if not isinstance(value, str):
                  return None
              text = value.strip()
              if not text:
                  return None
              upper = text.upper()
              if upper in KEY_NAMES:
                  return KEY_NAMES[upper]
              if len(text) == 1 and text.isalnum():
                  return text.lower()
              if text.isdigit():
                  return text
              return None


          def translate_modifier(value):
              if not isinstance(value, str):
                  return None
              return MODIFIER_KEYS.get(value.strip().upper())


          def bind_keys(bind):
              keys = []
              modifiers = []
              for key in bind.get("keys", []) or []:
                  translated = translate_key(key)
                  if translated:
                      keys.append(translated)
              for modifier in bind.get("modifier", []) or []:
                  translated = translate_modifier(modifier)
                  if translated:
                      modifiers.append(translated)
              return keys, modifiers


          def normalize_device(name):
              text = str(name).strip()
              if not text:
                  return None
              if text.startswith("/"):
                  return text
              if text.startswith("ckb"):
                  return os.path.join(CKBDIR, text)
              return os.path.join(CKBDIR, text)


          def detect_devices(selection):
              candidates = []
              connected = Path(CKBDIR) / "ckb0" / "connected"
              if connected.exists():
                  try:
                      for line in connected.read_text(encoding="utf-8", errors="replace").splitlines():
                          parts = line.split()
                          if len(parts) >= 2:
                              candidates.append((parts[0], " ".join(parts[2:]) or parts[1]))
                  except OSError:
                      pass
              if selection and str(selection).strip().lower() != "auto":
                  candidates = []
                  for item in str(selection).split(","):
                      device = normalize_device(item)
                      if device:
                          candidates.append((device, os.path.basename(device)))
              devices = []
              for device, name in candidates:
                  features_path = Path(device) / "features"
                  command_path = Path(device) / "cmd"
                  if not features_path.exists() or not command_path.exists():
                      continue
                  try:
                      features = features_path.read_text(encoding="utf-8", errors="replace").split()
                  except OSError:
                      continue
                  if "rgb" not in features:
                      continue
                  devices.append({"path": device, "name": name, "cmd": str(command_path)})
              return devices


          def write_commands(device, commands):
              if not commands:
                  return False
              path = device["cmd"]
              payload = "\n".join(commands) + "\n"
              try:
                  descriptor = os.open(path, os.O_WRONLY | os.O_NONBLOCK)
              except OSError as error:
                  if path not in WRITE_WARNINGS:
                      WRITE_WARNINGS.add(path)
                      log(f"cannot open {path}: {error}")
                  return False
              try:
                  os.write(descriptor, payload.encode("utf-8"))
                  return True
              except OSError as error:
                  if path not in WRITE_WARNINGS:
                      WRITE_WARNINGS.add(path)
                      log(f"cannot write {path}: {error}")
                  return False
              finally:
                  os.close(descriptor)


          def read_volume():
              code, output, _ = run_command(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
              if code == 0:
                  match = re.search(r"Volume:\s*([0-9.]+)", output)
                  if match:
                      volume = max(0, min(100, round(float(match.group(1)) * 100)))
                      return volume, "MUTED" in output.upper()
              code, output, _ = run_command(["pactl", "get-sink-volume", "@DEFAULT_SINK@"])
              if code == 0:
                  match = re.search(r"(\d+)%", output)
                  if match:
                      return max(0, min(100, int(match.group(1)))), False
              return 0, True


          class MangoClient:
              def __init__(self):
                  self.socket_path = None
                  self.lock = threading.Lock()
                  self.keymode = ""
                  self.tags = {"active": set(), "urgent": set(), "occupied": set()}
                  self.layout = ""
                  self.logged_path = None
                  self.event = threading.Event()
                  self.stop = threading.Event()

              def start(self):
                  threading.Thread(target=self._supervise, daemon=True).start()

              def _find(self):
                  matches = glob.glob(os.path.join(RUNTIME_DIR, "mango-*.sock"))
                  matches = [item for item in matches if os.path.exists(item)]
                  matches.sort(key=lambda item: os.path.getmtime(item), reverse=True)
                  return matches[0] if matches else None

              def _supervise(self):
                  while not self.stop.is_set():
                      path = self._find()
                      if not path:
                          if self.logged_path is not None:
                              log("Mango IPC socket lost; retrying")
                              self.logged_path = None
                          time.sleep(1.0)
                          continue
                      if path != self.logged_path:
                          log(f"watching Mango IPC at {path}")
                          self.logged_path = path
                      self.socket_path = path
                      workers = [
                          threading.Thread(target=self._watch, args=("watch keymode", self._on_keymode), daemon=True),
                          threading.Thread(target=self._watch, args=("watch all-tags", self._on_tags), daemon=True),
                          threading.Thread(target=self._watch, args=("watch keyboardlayout", self._on_layout), daemon=True),
                      ]
                      for worker in workers:
                          worker.start()
                      for worker in workers:
                          worker.join()
                      self.socket_path = None
                      time.sleep(1.0)

              def _watch(self, command, handler):
                  while not self.stop.is_set():
                      path = self.socket_path
                      if not path:
                          return
                      try:
                          with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
                              client.settimeout(2.0)
                              client.connect(path)
                              client.sendall((command + "\n").encode("utf-8"))
                              client.settimeout(None)
                              buffer = b""
                              while not self.stop.is_set():
                                  chunk = client.recv(65536)
                                  if not chunk:
                                      break
                                  buffer += chunk
                                  while b"\n" in buffer:
                                      line, buffer = buffer.split(b"\n", 1)
                                      if not line.strip():
                                          continue
                                      try:
                                          data = json.loads(line.decode("utf-8"))
                                      except (json.JSONDecodeError, UnicodeDecodeError):
                                          continue
                                      handler(data)
                      except (OSError, socket.timeout):
                          pass
                      if not self.stop.is_set():
                          self.socket_path = self._find() or path
                          time.sleep(0.5)

              def _on_keymode(self, data):
                  with self.lock:
                      self.keymode = str(data.get("keymode", ""))
                      log(f"keymode: {self.keymode}")
                  self.event.set()

              def _on_layout(self, data):
                  with self.lock:
                      self.layout = str(data.get("layout", ""))
                  self.event.set()

              def _on_tags(self, data):
                  active, urgent, occupied = set(), set(), set()
                  for monitor in data.get("all_tags", []) or []:
                      for tag in monitor.get("tags", []) or []:
                          try:
                              index = int(tag.get("index", 0))
                          except (TypeError, ValueError):
                              continue
                          if index <= 0:
                              continue
                          if tag.get("is_active"):
                              active.add(index)
                          if tag.get("is_urgent"):
                              urgent.add(index)
                          if int(tag.get("client_count", 0) or 0) > 0:
                              occupied.add(index)
                  with self.lock:
                      self.tags = {"active": active, "urgent": urgent, "occupied": occupied}
                  self.event.set()

              def snapshot(self):
                  with self.lock:
                      return {
                          "keymode": self.keymode,
                          "layout": self.layout,
                          "tags": {name: set(values) for name, values in self.tags.items()},
                      }


          class DmsClient:
              def __init__(self, interval):
                  self.interval = interval
                  self.socket_path = None
                  self.lock = threading.Lock()
                  self.state = {"night": False, "dnd": False, "muted": False, "playing": False}
                  self.event = threading.Event()
                  self.stop = threading.Event()

              def start(self):
                  threading.Thread(target=self._poll, daemon=True).start()

              def _find(self):
                  matches = glob.glob(os.path.join(RUNTIME_DIR, "quickshell", "by-pid", "*", "ipc.sock"))
                  matches = [item for item in matches if os.path.exists(item)]
                  matches.sort(key=lambda item: os.path.getmtime(item), reverse=True)
                  return matches[0] if matches else None

              def _poll(self):
                  while not self.stop.is_set():
                      path = self._find()
                      if not path:
                          time.sleep(max(1.0, self.interval))
                          continue
                      self.socket_path = path
                      state = {
                          "night": self._night(),
                          "dnd": self._dnd(),
                          "muted": self._muted(),
                          "playing": self._playing(),
                      }
                      with self.lock:
                          changed = state != self.state
                          self.state = state
                      if changed:
                          self.event.set()
                      time.sleep(max(0.5, self.interval))

              def _night(self):
                  value = self.call("night", "status")
                  return bool(value and "Night mode: enabled" in value)

              def _dnd(self):
                  value = self.call("notifications", "getDoNotDisturb")
                  return str(value).strip().lower() == "true"

              def _muted(self):
                  value = self.call("audio", "status")
                  return bool(value and "(muted)" in value.lower())

              def _playing(self):
                  code, output, _ = run_command(["playerctl", "status"], timeout=1.0)
                  return code == 0 and output.strip() == "Playing"

              @staticmethod
              def _read_exact(client, size):
                  data = b""
                  while len(data) < size:
                      chunk = client.recv(size - len(data))
                      if not chunk:
                          raise OSError("ipc closed")
                      data += chunk
                  return data

              @staticmethod
              def _write_qstring(buffer, value):
                  encoded = str(value).encode("utf-16-be")
                  buffer.extend(struct.pack(">I", len(encoded)))
                  buffer.extend(encoded)

              def _read_qstring(self, client):
                  length = struct.unpack(">I", self._read_exact(client, 4))[0]
                  if length == 0xFFFFFFFF:
                      return ""
                  return self._read_exact(client, length).decode("utf-16-be")

              def call(self, target, function, args=None):
                  if not self.socket_path:
                      return None
                  values = args or []
                  buffer = bytearray()
                  buffer.append(3)
                  self._write_qstring(buffer, target)
                  self._write_qstring(buffer, function)
                  buffer.extend(struct.pack(">I", len(values)))
                  for value in values:
                      self._write_qstring(buffer, value)
                  try:
                      with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
                          client.settimeout(2.0)
                          client.connect(self.socket_path)
                          client.sendall(buffer)
                          index = self._read_exact(client, 1)[0]
                          if index != 5:
                              return None
                          void = self._read_exact(client, 1)[0]
                          value = self._read_qstring(client)
                          return None if void else value
                  except (OSError, socket.timeout, struct.error, UnicodeDecodeError):
                      return None

              def snapshot(self):
                  with self.lock:
                      return dict(self.state)


          class Daemon:
              def __init__(self, config_path, binds_path):
                  self.config_path = config_path
                  self.binds_path = binds_path
                  self.stop_event = threading.Event()
                  self.volume_event = threading.Event()
                  self.config = {}
                  self.binds = {}
                  self.palette = {}
                  self.volume_config = {}
                  self.tags_config = {}
                  self.keymode_config = {}
                  self.state_binds = []
                  self.refresh = 60.0
                  self.state_refresh = 2.0
                  self.volume = 0
                  self.muted = False
                  self.last_apply = 0.0
                  self.last_device_scan = 0.0
                  self.enabled = True
                  self.activated = set()
                  self.last_frame = None
                  self.reload()
                  self.devices = detect_devices(self.config.get("devices", "auto"))
                  self.mango = MangoClient()
                  self.dms = DmsClient(float(self.config.get("stateRefreshSeconds", 2)))
                  self.log_devices()
                  self.write_state()

              def log_devices(self):
                  if self.devices:
                      log("detected devices: " + ", ".join(device["path"] for device in self.devices))
                  else:
                      log("no RGB-capable ckb-next devices found; retrying")

              def reload(self):
                  self.config = read_json(self.config_path)
                  self.binds = read_json(self.binds_path).get("modes", {})
                  gamma = float(self.config.get("gamma", 2.8))
                  self.palette = {
                      name: apply_gamma(value, gamma)
                      for name, value in self.config.get("palette", {}).items()
                  }
                  self.ambient_level = int(self.config.get("ambientLevel", 30))
                  self.unlit_level = int(self.config.get("unlitLevel", 15))
                  self.ambient_color = scale_color(self.palette.get("ambient", "#000000"), self.ambient_level)
                  self.unlit_color = scale_color(self.palette.get("unlit", "#000000"), self.unlit_level)
                  self.has_binds = any(self.binds.values())
                  self.volume_config = self.config.get("volumeBar", {})
                  self.tags_config = self.config.get("tags", {})
                  self.keymode_config = self.config.get("keymode", {})
                  self.state_binds = self.config.get("stateBinds", [])
                  self.refresh = float(self.config.get("refreshSeconds", 60))
                  self.state_refresh = float(self.config.get("stateRefreshSeconds", 2))
                  total = sum(len(binds) for binds in self.binds.values())
                  log(f"loaded {total} binds in {len(self.binds)} modes")
                  self.last_frame = None

              def role_color(self, name, fallback=None):
                  if name == "ambient":
                      return self.ambient_color
                  if name == "unlit":
                      return self.unlit_color
                  return self.palette.get(name, fallback or self.palette.get("accent", "FFFFFF"))

              def volume_color(self, index, lit):
                  mode = self.volume_config.get("mode", "solid")
                  if mode == "solid":
                      return self.role_color(self.volume_config.get("color", "functions"))
                  if mode == "heat":
                      if self.volume < 50:
                          return self.role_color(self.volume_config.get("low", "strings"))
                      if self.volume < 80:
                          return self.role_color(self.volume_config.get("mid", "integers"))
                      return self.role_color(self.volume_config.get("high", "variables"))
                  fraction = index / max(1, lit - 1)
                  if fraction < 0.33:
                      return self.role_color(self.volume_config.get("low", "strings"))
                  if fraction < 0.66:
                      return self.role_color(self.volume_config.get("mid", "integers"))
                  return self.role_color(self.volume_config.get("high", "variables"))

              def probe_active(self, probe, dms_state):
                  if probe == "dms-night":
                      return dms_state.get("night", False)
                  if probe == "dms-dnd":
                      return dms_state.get("dnd", False)
                  if probe == "audio-muted":
                      return dms_state.get("muted", False)
                  if probe == "media-playing":
                      return dms_state.get("playing", False)
                  return False

              def apply(self):
                  self.last_apply = time.monotonic()
                  if not self.devices:
                      self.devices = detect_devices(self.config.get("devices", "auto"))
                  if not self.devices:
                      self.write_state()
                      return
                  if not self.enabled:
                      self.last_frame = None
                      for device in self.devices:
                          commands = []
                          if device["path"] not in self.activated:
                              commands.append("active")
                              self.activated.add(device["path"])
                          commands.append("rgb 000000")
                          write_commands(device, commands)
                      self.write_state()
                      return

                  snapshot = self.mango.snapshot()
                  overrides = {}

                  if self.tags_config.get("enable", True):
                      active = snapshot["tags"]["active"]
                      urgent = snapshot["tags"]["urgent"]
                      occupied = snapshot["tags"]["occupied"]
                      for index in range(1, 11):
                          key = "0" if index == 10 else str(index)
                          if index in active:
                              color = self.role_color(self.tags_config.get("active", "functions"))
                          elif index in urgent:
                              color = self.role_color(self.tags_config.get("urgent", "variables"))
                          elif index in occupied:
                              color = self.role_color(self.tags_config.get("occupied", "defaultForeground"))
                          else:
                              color = self.role_color(self.tags_config.get("empty", "comments"))
                          overrides[key] = color

                  if self.volume_config.get("enable", True):
                      keys = [translate_key(key) for key in self.volume_config.get("keys", [])]
                      keys = [key for key in keys if key]
                      if keys:
                          lit = round((self.volume / 100.0) * len(keys))
                          for index, key in enumerate(keys):
                              if index < lit:
                                  overrides[key] = self.volume_color(index, lit)
                              else:
                                  overrides[key] = self.unlit_color

                  if self.keymode_config.get("enable", True):
                      active_mode = str(snapshot.get("keymode", "") or "default").lower()
                      modes = ["common"]
                      if active_mode and active_mode != "common":
                          modes.append(active_mode)
                      group_colors = {
                          "navigation": "primary",
                          "windows": "error",
                          "applications": "success",
                          "system": "special",
                          "alt modes": "warning",
                          "media": "attention",
                      }
                      modifier_color = self.role_color(self.keymode_config.get("modifierColor", "support"))
                      for mode in modes:
                          for bind in self.binds.get(mode, []) or []:
                              keys, modifiers = bind_keys(bind)
                              group = str(bind.get("group", "")).lower()
                              key_color = self.role_color(group_colors.get(group, "accent"))
                              for key in keys:
                                  overrides[key] = key_color
                              for modifier in modifiers:
                                  overrides[modifier] = modifier_color

                      if not self.has_binds:
                          layouts = {
                              "default": (
                                  ("a,w,d,s,lshift,rshift,lwin,esc", "secondary"),
                                  ("f1,f2,f3,f4", "unlit"),
                              ),
                              "window": (
                                  ("a,w,d,s,lshift,rshift,lwin,f1", "warning"),
                                  ("f2,f3,f4", "unlit"),
                                  ("esc", "error"),
                              ),
                              "group": (
                                  ("a,w,s,d,lshift,rshift,lwin,f2", "error"),
                                  ("f1,f3,f4", "unlit"),
                                  ("esc", "error"),
                              ),
                              "scripts": (
                                  ("a,w,s,d,lshift,rshift,lwin,f3", "primary"),
                                  ("f1,f2,f4", "unlit"),
                                  ("esc", "error"),
                              ),
                              "theming": (
                                  ("a,w,d,s,lshift,rshift,lwin,f4", "success"),
                                  ("f1,f2,f3", "unlit"),
                                  ("esc", "error"),
                              ),
                          }
                          aliases = {
                              "movement": "window",
                              "groups": "group",
                              "resize": "scripts",
                          }
                          layout = layouts.get(aliases.get(active_mode, active_mode), layouts["default"])
                          for key_list, role in layout:
                              for key in key_list.split(","):
                                  overrides[key] = self.role_color(role)

                  dms_state = self.dms.snapshot()
                  for state in self.state_binds:
                      if not state.get("enabled", True):
                          continue
                      if not self.probe_active(state.get("probe", ""), dms_state):
                          continue
                      color = self.role_color(state.get("color", "accent"))
                      match = str(state.get("match", "")).lower()
                      if not match:
                          continue
                      for mode_binds in self.binds.values():
                          for bind in mode_binds or []:
                              text = " ".join(
                                  [
                                      str(bind.get("dispatcher", "")),
                                      " ".join(str(arg) for arg in bind.get("args", []) or []),
                                  ]
                              ).lower()
                              if match not in text:
                                  continue
                              keys, modifiers = bind_keys(bind)
                              for key in keys:
                                  overrides[key] = color
                              for modifier in modifiers:
                                  overrides[modifier] = modifier_color

                  frame = (
                      tuple(sorted(device["path"] for device in self.devices)),
                      self.ambient_color,
                      tuple(sorted(overrides.items())),
                  )
                  if frame == self.last_frame:
                      self.write_state(snapshot)
                      return
                  self.last_frame = frame

                  groups = {}
                  for key, color in overrides.items():
                      groups.setdefault(color, []).append(key)
                  for device in self.devices:
                      commands = []
                      if device["path"] not in self.activated:
                          commands.append("active")
                          self.activated.add(device["path"])
                      commands.append("rgb " + self.ambient_color)
                      for color, keys in groups.items():
                          commands.append("rgb " + ",".join(keys) + ":" + color)
                      write_commands(device, commands)

                  self.write_state(snapshot)

              def write_state(self, snapshot=None):
                  snapshot = snapshot or {}
                  state = {
                      "pid": os.getpid(),
                      "config": self.config_path,
                      "binds": self.binds_path,
                      "devices": [device["path"] for device in self.devices],
                      "enabled": self.enabled,
                      "volume": self.volume,
                      "muted": self.muted,
                      "keymode": snapshot.get("keymode", ""),
                      "layout": snapshot.get("layout", ""),
                      "tags": {
                          name: sorted(values)
                          for name, values in (snapshot.get("tags", {}) or {}).items()
                      },
                      "dms": self.dms.snapshot(),
                      "bindModes": {mode: len(binds) for mode, binds in self.binds.items()},
                      "palette": self.palette,
                      "paletteSource": "stylix",
                      "watchers": {
                          "mango": bool(self.mango.socket_path),
                          "dms": bool(self.dms.socket_path),
                      },
                      "lastApply": self.last_apply,
                  }
                  atomic_write(STATE_PATH, json.dumps(state, indent=2, sort_keys=True))

              def _volume_watch(self):
                  while not self.stop_event.is_set():
                      try:
                          process = subprocess.Popen(
                              ["pactl", "subscribe"],
                              stdout=subprocess.PIPE,
                              text=True,
                              bufsize=1,
                          )
                          for line in process.stdout:
                              if self.stop_event.is_set():
                                  break
                              if "change" in line or "new" in line or "remove" in line:
                                  self.volume_event.set()
                          process.wait(timeout=1)
                      except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
                          if self.stop_event.is_set():
                              break
                          time.sleep(max(1.0, self.state_refresh))

              def toggle(self):
                  self.enabled = not self.enabled
                  self.last_frame = None
                  if not self.enabled:
                      for device in self.devices:
                          commands = []
                          if device["path"] not in self.activated:
                              commands.append("active")
                              self.activated.add(device["path"])
                          commands.append("rgb 000000")
                          write_commands(device, commands)
                      self.write_state()
                      return
                  self.apply()

              def run(self):
                  atomic_write(PID_PATH, str(os.getpid()) + "\n")
                  self.mango.start()
                  self.dms.start()
                  threading.Thread(target=self._volume_watch, daemon=True).start()
                  while not self.stop_event.is_set():
                      now = time.monotonic()
                      if now - self.last_device_scan >= 5.0:
                          self.last_device_scan = now
                          new_devices = detect_devices(self.config.get("devices", "auto"))
                          new_paths = [device["path"] for device in new_devices]
                          old_paths = [device["path"] for device in self.devices]
                          if new_paths != old_paths:
                              self.devices = new_devices
                              self.activated = set()
                              self.last_frame = None
                              self.log_devices()
                              if self.devices:
                                  self.apply()
                      if self.mango.event.is_set() or self.dms.event.is_set() or self.volume_event.is_set():
                          self.mango.event.clear()
                          self.dms.event.clear()
                          self.volume_event.clear()
                          volume, muted = read_volume()
                          if (volume, muted) != (self.volume, self.muted):
                              self.volume, self.muted = volume, muted
                          self.apply()
                      if now - self.last_apply >= self.refresh:
                          volume, muted = read_volume()
                          if (volume, muted) != (self.volume, self.muted):
                              self.volume, self.muted = volume, muted
                          self.apply()
                      time.sleep(0.1)
                  try:
                      os.unlink(PID_PATH)
                  except OSError:
                      pass


          def read_pid():
              try:
                  return int(Path(PID_PATH).read_text(encoding="utf-8").strip())
              except (OSError, ValueError):
                  return None


          def print_status(as_json):
              try:
                  state = read_json(STATE_PATH)
              except (OSError, json.JSONDecodeError):
                  state = {"running": False}
              else:
                  state["running"] = True
              if as_json:
                  print(json.dumps(state, indent=2, sort_keys=True))
                  return
              if not state.get("running"):
                  print("ojuny-rgb: not running")
                  return
              print(f"pid: {state.get('pid')}")
              print(f"enabled: {state.get('enabled')}")
              print(f"keymode: {state.get('keymode')}")
              print(f"layout: {state.get('layout')}")
              print(f"volume: {state.get('volume')}% muted={state.get('muted')}")
              print(f"devices: {', '.join(state.get('devices', [])) or 'none'}")
              print(f"bind modes: {state.get('bindModes')}")
              print(f"palette source: {state.get('paletteSource')}")
              print(f"watchers: {state.get('watchers')}")
              print(f"palette: {json.dumps(state.get('palette', {}), sort_keys=True)}")
              print(f"last apply: {state.get('lastApply')}")


          def main(argv):
              parser = argparse.ArgumentParser(prog="ojuny-rgb")
              parser.add_argument("--config", help="Generated RGB configuration")
              parser.add_argument("--binds", help="Generated bind map")
              parser.add_argument("--json", action="store_true", help="JSON output")
              subparsers = parser.add_subparsers(dest="command", required=True)

              run_parser = subparsers.add_parser("run")
              run_parser.add_argument("--config", dest="run_config")
              run_parser.add_argument("--binds", dest="run_binds")

              apply_parser = subparsers.add_parser("apply")
              apply_parser.add_argument("--config", dest="apply_config")
              apply_parser.add_argument("--binds", dest="apply_binds")
              apply_parser.add_argument("--json", action="store_true", dest="sub_json")

              status_parser = subparsers.add_parser("status")
              status_parser.add_argument("--json", action="store_true", dest="sub_json")

              devices_parser = subparsers.add_parser("devices")
              devices_parser.add_argument("--json", action="store_true", dest="sub_json")

              subparsers.add_parser("toggle")
              subparsers.add_parser("reload")

              args = parser.parse_args(argv)
              if getattr(args, "sub_json", False):
                  args.json = True

              if args.command == "run":
                  config_path = args.run_config or args.config
                  binds_path = args.run_binds or args.binds
                  if not config_path or not binds_path:
                      parser.error("run needs --config and --binds")
                  daemon = Daemon(config_path, binds_path)

                  def handle(signum, _frame):
                      if signum == signal.SIGUSR1:
                          daemon.toggle()
                      elif signum in (signal.SIGHUP, signal.SIGUSR2):
                          daemon.reload()
                          daemon.apply()
                      elif signum in (signal.SIGTERM, signal.SIGINT):
                          daemon.stop_event.set()

                  signal.signal(signal.SIGUSR1, handle)
                  signal.signal(signal.SIGHUP, handle)
                  signal.signal(signal.SIGUSR2, handle)
                  signal.signal(signal.SIGTERM, handle)
                  signal.signal(signal.SIGINT, handle)
                  daemon.run()
                  return 0

              if args.command == "apply":
                  config_path = args.apply_config or args.config
                  binds_path = args.apply_binds or args.binds
                  if not config_path or not binds_path:
                      parser.error("apply needs --config and --binds")
                  daemon = Daemon(config_path, binds_path)
                  daemon.apply()
                  print_status(args.json)
                  return 0

              if args.command == "devices":
                  config_path = args.config
                  devices = detect_devices("auto")
                  if config_path:
                      try:
                          devices = detect_devices(read_json(config_path).get("devices", "auto"))
                      except (OSError, json.JSONDecodeError):
                          pass
                  if args.json:
                      print(json.dumps(devices, indent=2, sort_keys=True))
                  else:
                      for device in devices:
                          print(f"{device['path']} {device['name']}")
                  return 0

              if args.command == "status":
                  print_status(args.json)
                  return 0

              if args.command in ("toggle", "reload"):
                  pid = read_pid()
                  if not pid:
                      print("ojuny-rgb: no running daemon", file=sys.stderr)
                      return 1
                  try:
                      os.kill(pid, signal.SIGUSR1 if args.command == "toggle" else signal.SIGHUP)
                  except OSError as error:
                      print(f"ojuny-rgb: {error}", file=sys.stderr)
                      return 1
                  return 0

              return 2


          if __name__ == "__main__":
              sys.exit(main(sys.argv[1:]))
        '';
      };

      pythonScript = pkgs.runCommandLocal "ojuny-rgb.py" { nativeBuildInputs = [ pkgs.python3 ]; } ''
        install -Dm755 ${pythonSource} $out/bin/ojuny-rgb.py
        python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' $out/bin/ojuny-rgb.py
      '';

      ojunyRgb = pkgs.writeShellApplication {
        name = "ojuny-rgb";
        runtimeInputs = [
          pkgs.python3
          pkgs.wireplumber
          pkgs.pulseaudio
          pkgs.playerctl
        ];
        text = ''
          exec ${pythonScript}/bin/ojuny-rgb.py "$@"
        '';
      };

      bindMap = config.desktop.ojuny.mango.binds or { };

      bindJson =
        bind:
        let
          rawArgs = bind.args or null;
        in
        {
          modifier = bind.modifier or [ ];
          keys = bind.keys or [ ];
          dispatcher = bind.dispatcher or "";
          args =
            if rawArgs == null then
              [ ]
            else if builtins.isList rawArgs then
              map toString rawArgs
            else
              [ (toString rawArgs) ];
          description = bind.description or "";
          group = bind.group or "";
          subcat = bind.subcat or "";
        };

      bindsJson = pkgs.writeText "ojuny-rgb-binds.json" (
        builtins.toJSON {
          modes = builtins.mapAttrs (_mode: modeBinds: map bindJson (builtins.attrValues modeBinds)) bindMap;
        }
      );

      rgbConfig = pkgs.writeText "ojuny-rgb.json" (
        builtins.toJSON {
          gamma = cfg.gamma;
          ambientLevel = cfg.ambientLevel;
          unlitLevel = cfg.unlitLevel;
          devices = cfg.devices;
          refreshSeconds = cfg.refreshSeconds;
          stateRefreshSeconds = cfg.stateRefreshSeconds;
          palette = {
            ambient = hex cfg.palette.ambient;
            unlit = hex cfg.palette.unlit;
            muted = hex cfg.palette.muted;
            neutral = hex cfg.palette.neutral;
            bright = hex cfg.palette.bright;
            primary = hex cfg.palette.primary;
            secondary = hex cfg.palette.secondary;
            accent = hex cfg.palette.accent;
            success = hex cfg.palette.success;
            warning = hex cfg.palette.warning;
            attention = hex cfg.palette.attention;
            error = hex cfg.palette.error;
            special = hex cfg.palette.special;
          }
          // builtins.listToAttrs (
            map (name: {
              inherit name;
              value = hex name;
            }) namedColors
          );
          volumeBar = {
            enable = cfg.volumeBar.enable;
            keys = [
              "f1"
              "f2"
              "f3"
              "f4"
              "f5"
              "f6"
              "f7"
              "f8"
              "f9"
              "f10"
              "f11"
              "f12"
            ];
            mode = cfg.volumeBar.mode;
            color = cfg.volumeBar.color;
            low = cfg.volumeBar.low;
            mid = cfg.volumeBar.mid;
            high = cfg.volumeBar.high;
          };
          tags = {
            enable = cfg.tags.enable;
            active = cfg.tags.active;
            occupied = cfg.tags.occupied;
            urgent = cfg.tags.urgent;
            empty = cfg.tags.empty;
          };
          keymode = {
            enable = cfg.keymode.enable;
            modifierColor = cfg.keymode.modifierColor;
          };
          stateBinds = cfg.stateBinds;
        }
      );
    in
    {
      options.ojuny.patch.corsair-rgb = {
        gamma = lib.mkOption {
          type = lib.types.float;
          default = 2.8;
          description = "Brightness curve applied to every key color.";
        };

        ambientLevel = lib.mkOption {
          type = lib.types.int;
          default = 30;
          description = "Ambient background brightness percentage.";
        };

        unlitLevel = lib.mkOption {
          type = lib.types.int;
          default = 15;
          description = "Unlit volume key brightness percentage.";
        };

        devices = lib.mkOption {
          type = lib.types.str;
          default = "auto";
          description = "auto or a comma-separated list of ckb-next devices.";
        };

        refreshSeconds = lib.mkOption {
          type = lib.types.int;
          default = 60;
          description = "Fallback reapply interval.";
        };

        stateRefreshSeconds = lib.mkOption {
          type = lib.types.int;
          default = 2;
          description = "DMS and volume state sampling interval.";
        };

        palette = {
          ambient = lib.mkOption {
            type = colorType;
            default = "functions";
            description = "Ambient key color before highlights.";
          };
          unlit = lib.mkOption {
            type = colorType;
            default = "functions";
            description = "Unlit volume key color.";
          };
          muted = lib.mkOption {
            type = colorType;
            default = "darkForeground";
            description = "Muted color.";
          };
          neutral = lib.mkOption {
            type = colorType;
            default = "defaultForeground";
            description = "Neutral foreground.";
          };
          bright = lib.mkOption {
            type = colorType;
            default = "lightForeground";
            description = "Bright foreground.";
          };
          primary = lib.mkOption {
            type = colorType;
            default = "functions";
            description = "Primary accent.";
          };
          secondary = lib.mkOption {
            type = colorType;
            default = "keywords";
            description = "Spare accent available to state rows; no built-in highlight uses it.";
          };
          accent = lib.mkOption {
            type = colorType;
            default = "support";
            description = "Color for modifier keys in active keymode and state highlights.";
          };
          success = lib.mkOption {
            type = colorType;
            default = "strings";
            description = "Color for low-volume bars and success state rows.";
          };
          warning = lib.mkOption {
            type = colorType;
            default = "classes";
            description = "Color for warning state rows.";
          };
          attention = lib.mkOption {
            type = colorType;
            default = "integers";
            description = "Color for mid-volume bars and attention state rows.";
          };
          error = lib.mkOption {
            type = colorType;
            default = "variables";
            description = "Error color.";
          };
          special = lib.mkOption {
            type = colorType;
            default = "deprecated";
            description = "Spare accent available to state rows; no built-in highlight uses it.";
          };
        };

        volumeBar = {
          enable = lib.mkEnableOption "the volume bar";

          mode = lib.mkOption {
            type = lib.types.enum [
              "solid"
              "ramp"
              "heat"
            ];
            default = "solid";
            description = "Volume bar color mode.";
          };

          color = lib.mkOption {
            type = colorType;
            default = "functions";
            description = "Solid volume color.";
          };
          low = lib.mkOption {
            type = colorType;
            default = "strings";
            description = "Low volume color.";
          };
          mid = lib.mkOption {
            type = colorType;
            default = "integers";
            description = "Mid volume color.";
          };
          high = lib.mkOption {
            type = colorType;
            default = "variables";
            description = "High volume color.";
          };
        };

        tags = {
          enable = lib.mkEnableOption "tag indicators";

          active = lib.mkOption {
            type = colorType;
            default = "functions";
            description = "Active tag color.";
          };
          occupied = lib.mkOption {
            type = colorType;
            default = "defaultForeground";
            description = "Occupied tag color.";
          };
          urgent = lib.mkOption {
            type = colorType;
            default = "variables";
            description = "Urgent tag color.";
          };
          empty = lib.mkOption {
            type = colorType;
            default = "comments";
            description = "Empty tag color.";
          };
        };

        keymode = {
          enable = lib.mkEnableOption "keymode bind highlighting";

          modifierColor = lib.mkOption {
            type = colorType;
            default = "support";
            description = "Modifier color for active binds.";
          };
        };

        stateBinds = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Display name.";
                };
                match = lib.mkOption {
                  type = lib.types.str;
                  description = "Case-insensitive bind action substring.";
                };
                probe = lib.mkOption {
                  type = lib.types.str;
                  description = "DMS state probe.";
                };
                color = lib.mkOption {
                  type = colorType;
                  default = "support";
                  description = "Highlight color.";
                };
                enabled = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Enable this state.";
                };
              };
            }
          );
          default = [ ];
          description = "Bind-driven state highlights.";
        };

        dms = {
          menuEntry = lib.mkEnableOption "the Dynamic RGB menu entry";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf active {
          assertions = [
            {
              assertion = options ? desktop.ojuny.mango.binds;
              message = "patch-corsair-rgb: desktop.ojuny.mango.binds is required for bind-driven highlighting.";
            }
            {
              assertion = cfg.devices != "";
              message = "patch-corsair-rgb: devices must not be empty.";
            }
            {
              assertion = lib.all (state: !state.enabled || state.match != "") cfg.stateBinds;
              message = "patch-corsair-rgb: every enabled stateBinds row needs a match.";
            }
            {
              assertion = lib.all (
                state:
                builtins.elem state.probe [
                  "dms-night"
                  "dms-dnd"
                  "audio-muted"
                  "media-playing"
                ]
              ) cfg.stateBinds;
              message = "patch-corsair-rgb: stateBinds.probe must be dms-night, dms-dnd, audio-muted, or media-playing.";
            }
            {
              assertion = namedColorsAvailable;
              message = "patch-corsair-rgb: Stylix and the ojuny named-colors module (flake.colors) are required for the palette.";
            }
          ];

          hardware.ckb-next.enable = true;
        })
        (lib.mkIf (active && namedColorsAvailable) {
          environment.systemPackages = [ ojunyRgb ];

          systemd.user.services.ojuny-rgb = {
            description = "Ojuny Corsair RGB daemon";
            wantedBy = [ "default.target" ];
            restartTriggers = [
              rgbConfig
              bindsJson
              pythonScript
            ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${ojunyRgb}/bin/ojuny-rgb run --config ${rgbConfig} --binds ${bindsJson}";
              Restart = "on-failure";
              RestartSec = 2;
            };
          };
        })
        (lib.optionalAttrs (options ? desktop.ojuny.dankMenu) {
          desktop.ojuny.dankMenu.extraEntries =
            lib.mkIf (active && namedColorsAvailable && cfg.dms.menuEntry)
              {
                "trigger.ojuny-rgb" = {
                  icon = "lightbulb";
                  label = "Dynamic RGB";
                  aliases = [
                    "rgb"
                    "keyboard"
                  ];
                };
                "trigger.ojuny-rgb.toggle" = {
                  icon = "toggle_on";
                  label = "Toggle lighting";
                  action = "${ojunyRgb}/bin/ojuny-rgb toggle";
                };
                "trigger.ojuny-rgb.reload" = {
                  icon = "refresh";
                  label = "Reload lighting";
                  action = "${ojunyRgb}/bin/ojuny-rgb reload";
                };
                "trigger.ojuny-rgb.status" = {
                  icon = "info";
                  label = "Lighting status";
                  action = "ghostty -e sh -c '${ojunyRgb}/bin/ojuny-rgb status; printf \"\\nPress Enter to close.\\n\"; read -r _'";
                };
              };
        })
      ];
    };
}
