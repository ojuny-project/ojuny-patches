/*
  @menu
  displayname = "Logitech G13";
  icon = "input-gaming-symbolic";
  order = 230;
  category = "Patches";
  systems = [ "all" ];
*/

{ self, ... }:

let
  detectorSources = [
    "cpu"
    "ram"
    "disk"
    "gpu"
    "network"
    "battery"
    "audio"
    "media"
    "workspace"
    "keymode"
    "layout"
    "clock"
    "date"
    "uptime"
    "weather"
    "custom"
  ];

  bindFields = [
    "modifier"
    "keys"
    "dispatcher"
    "args"
    "description"
    "group"
    "subcat"
    "repeats"
  ];

  bindFieldTypes = [
    "list"
    "list"
    "str"
    "str"
    "str"
    "str"
    "str"
    "int"
  ];

  bindPreview = [
    "subcat"
    "modifier"
    "keys"
  ];
in
{
  flake.modules.nixos.patch-logitech-g13 =
    { config, lib, ... }:
    let
      cfg = config.ojuny.patch.logitech-g13;
      active = cfg.enable && (config.ojuny.patches or true);

      textOption = default: description: lib.mkOption {
        type = lib.types.str;
        inherit default description;
      };

      enumOption = choices: default: description: lib.mkOption {
        type = lib.types.enum choices;
        inherit default description;
      };

      mkDetector = refresh: extra: lib.mkOption {
        type = lib.types.submodule {
          options = {
            refresh = lib.mkOption {
              type = lib.types.int;
              default = refresh;
              description = "Refresh interval in seconds.";
            };
            timeout = lib.mkOption {
              type = lib.types.int;
              default = 2;
              description = "Timeout for one detector pass, in seconds.";
            };
          } // extra;
        };
        default = { };
        description = "Detector settings.";
      };

      mkBindRow = bankName: lib.types.submodule {
        options = {
          modifier = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Modifier list for the chord the G13 sends.";
          };
          keys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Key list for the chord the G13 sends.";
          };
          dispatcher = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Mango dispatcher shown in the keybinds menu.";
          };
          args = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Mango dispatcher arguments shown in the keybinds menu.";
          };
          description = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Visible bind description.";
          };
          group = lib.mkOption {
            type = lib.types.str;
            default = bankName;
            description = "DMS keybinds category.";
          };
          subcat = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Visible G13 key label.";
          };
          repeats = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "Macro repeats: 0 runs once, 1 repeats while held, N runs N times.";
          };
        };
      };

      mkBank = bankName: lib.mkOption {
        type = lib.types.attrsOf (mkBindRow bankName);
        default = { };
        description = "Bind rows keyed by G13 key in the ${bankName} bank.";
      };
    in
    {
      options.ojuny.patch.logitech-g13 = {
        enable = lib.mkEnableOption "the Logitech G13 patch";

        display = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable the LCD render loop and detector services.";
          };
          refreshMs = lib.mkOption {
            type = lib.types.int;
            default = 500;
            description = "LCD render interval in milliseconds.";
          };
          lines = lib.mkOption {
            type = lib.types.listOf (
              lib.types.submodule {
                options = {
                  source = lib.mkOption {
                    type = lib.types.enum detectorSources;
                    default = "cpu";
                    description = "Detector source for this line.";
                  };
                  format = lib.mkOption {
                    type = lib.types.str;
                    default = "";
                    description = "Line template with $variable placeholders.";
                  };
                  enabled = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Show this line on the LCD.";
                  };
                };
              }
            );
            default = [ ];
            description = "Up to five LCD lines.";
          };
        };

        detectors = {
          cpu = mkDetector 1 { };
          ram = mkDetector 1 { };
          disk = mkDetector 2 {
            mount = textOption "/" "Mount point used for disk usage and read/write rates.";
          };
          gpu = mkDetector 1 {
            vendor = enumOption [ "auto" "nvidia" "amd" "intel" ] "auto" "GPU vendor. auto checks sysfs and nvidia-smi.";
          };
          network = mkDetector 1 {
            interface = textOption "auto" "Network interface. auto uses the default route interface.";
          };
          battery = mkDetector 30 {
            device = textOption "auto" "UPower battery device. auto uses the first battery.";
          };
          audio = mkDetector 1 { };
          media = mkDetector 1 { };
          workspace = mkDetector 1 { };
          keymode = mkDetector 1 { };
          layout = mkDetector 1 { };
          clock = mkDetector 1 { };
          date = mkDetector 60 { };
          uptime = mkDetector 60 { };
          weather = mkDetector 900 {
            location = textOption "" "Location passed to wttr.in. Empty uses the request IP location.";
          };
          custom = mkDetector 5 {
            command = textOption "" "Shell command whose output is exposed as $custom and $custom_<key>.";
          };
        };

        bindings = {
          bank1 = mkBank "Workspaces";
          bank2 = mkBank "Windows";
          bank3 = mkBank "Media";
          bank4 = mkBank "Apps";
        };
      };

      imports = [ self.modules.nixos.logitech-g13-backend ];

      config = {
        # @option widget = "switch"; label = "Logitech G13"; group = "Logitech G13"; groupOrder = 10; order = 10; description = "Enable the G13 driver, LCD display and bind banks.";
        ojuny.patch.logitech-g13.enable = false;

        # @option widget = "switch"; label = "LCD display"; group = "Display"; groupOrder = 20; order = 10; visibleWhen.path = "ojuny.patch.logitech-g13.enable"; visibleWhen.equals = true; description = "Run the detector and render services.";
        ojuny.patch.logitech-g13.display.enable = true;

        # @option widget = "spin"; label = "Refresh interval"; group = "Display"; groupOrder = 20; order = 20; min = 100; step = 100; unit = "ms"; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "How often the render loop builds and compares a frame.";
        ojuny.patch.logitech-g13.display.refreshMs = 500;

        # @option widget = "table-list"; label = "LCD lines"; group = "Display"; groupOrder = 20; order = 30; columns = [ "source" "format" "enabled" ]; columnTypes = [ "dropdown" "str" "bool" ]; choices = [ "cpu" "ram" "disk" "gpu" "network" "battery" "audio" "media" "workspace" "keymode" "layout" "clock" "date" "uptime" "weather" "custom" ]; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Up to five lines. Each line is truncated to 25 characters.";
        ojuny.patch.logitech-g13.display.lines = [
          { source = "cpu"; format = "$cpu_clock $cpu_usage% $cpu_temp   $time"; enabled = true; }
          { source = "ram"; format = "u$ram_used c$ram_cached f$ram_free"; enabled = true; }
          { source = "disk"; format = "$disk_used R$disk_read W$disk_write"; enabled = true; }
          { source = "gpu"; format = "$gpu_usage% $gpu_clock $gpu_vram $gpu_temp"; enabled = true; }
          { source = "media"; format = "$media_title"; enabled = true; }
        ];

        # @option widget = "submodule"; label = "CPU detector"; group = "Detectors"; groupOrder = 30; order = 10; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "CPU clock, usage, temperature and time.";
        ojuny.patch.logitech-g13.detectors.cpu = { refresh = 1; timeout = 2; };

        # @option widget = "submodule"; label = "RAM detector"; group = "Detectors"; groupOrder = 30; order = 20; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Used, cached and free memory.";
        ojuny.patch.logitech-g13.detectors.ram = { refresh = 1; timeout = 2; };

        # @option widget = "submodule"; label = "Disk detector"; group = "Detectors"; groupOrder = 30; order = 30; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Disk usage and read/write rates.";
        ojuny.patch.logitech-g13.detectors.disk = { refresh = 2; timeout = 2; mount = "/"; };

        # @option widget = "submodule"; label = "GPU detector"; group = "Detectors"; groupOrder = 30; order = 40; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "GPU usage, clock, VRAM and temperature.";
        ojuny.patch.logitech-g13.detectors.gpu = { refresh = 1; timeout = 2; vendor = "auto"; };

        # @option widget = "submodule"; label = "Network detector"; group = "Detectors"; groupOrder = 30; order = 50; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Interface state, address, signal and traffic rates.";
        ojuny.patch.logitech-g13.detectors.network = { refresh = 1; timeout = 2; interface = "auto"; };

        # @option widget = "submodule"; label = "Battery detector"; group = "Detectors"; groupOrder = 30; order = 60; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Battery percentage, state and remaining time.";
        ojuny.patch.logitech-g13.detectors.battery = { refresh = 30; timeout = 2; device = "auto"; };

        # @option widget = "submodule"; label = "Audio detector"; group = "Detectors"; groupOrder = 30; order = 70; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Output and input volume and mute state.";
        ojuny.patch.logitech-g13.detectors.audio = { refresh = 1; timeout = 2; };

        # @option widget = "submodule"; label = "Media detector"; group = "Detectors"; groupOrder = 30; order = 80; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Player status, title, artist, album and timing.";
        ojuny.patch.logitech-g13.detectors.media = { refresh = 1; timeout = 2; };

        # @option widget = "submodule"; label = "Workspace detector"; group = "Detectors"; groupOrder = 30; order = 90; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Active Mango workspace and its layout.";
        ojuny.patch.logitech-g13.detectors.workspace = { refresh = 1; timeout = 2; };

        # @option widget = "submodule"; label = "Keymode detector"; group = "Detectors"; groupOrder = 30; order = 100; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Current Mango keymode.";
        ojuny.patch.logitech-g13.detectors.keymode = { refresh = 1; timeout = 2; };

        # @option widget = "submodule"; label = "Keyboard layout detector"; group = "Detectors"; groupOrder = 30; order = 110; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Current XKB keyboard layout.";
        ojuny.patch.logitech-g13.detectors.layout = { refresh = 1; timeout = 2; };

        # @option widget = "submodule"; label = "Clock detector"; group = "Detectors"; groupOrder = 30; order = 120; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Current local time.";
        ojuny.patch.logitech-g13.detectors.clock = { refresh = 1; timeout = 2; };

        # @option widget = "submodule"; label = "Date detector"; group = "Detectors"; groupOrder = 30; order = 130; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Current local date.";
        ojuny.patch.logitech-g13.detectors.date = { refresh = 60; timeout = 2; };

        # @option widget = "submodule"; label = "Uptime detector"; group = "Detectors"; groupOrder = 30; order = 140; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "System uptime.";
        ojuny.patch.logitech-g13.detectors.uptime = { refresh = 60; timeout = 2; };

        # @option widget = "submodule"; label = "Weather detector"; group = "Detectors"; groupOrder = 30; order = 150; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Weather from wttr.in.";
        ojuny.patch.logitech-g13.detectors.weather = { refresh = 900; timeout = 2; location = ""; };

        # @option widget = "submodule"; label = "Custom detector"; group = "Detectors"; groupOrder = 30; order = 160; visibleWhen.path = "ojuny.patch.logitech-g13.display.enable"; visibleWhen.equals = true; description = "Run a shell command and expose its output.";
        ojuny.patch.logitech-g13.detectors.custom = { refresh = 5; timeout = 2; command = ""; };

        # @option widget = "keybinds"; label = "Bank 1: Workspaces"; group = "Banks"; groupOrder = 40; order = 10; bindFields = [ "modifier" "keys" "dispatcher" "args" "description" "group" "subcat" "repeats" ]; bindFieldTypes = [ "list" "list" "str" "str" "str" "str" "str" "int" ]; bindPreview = [ "subcat" "modifier" "keys" ]; visibleWhen.path = "ojuny.patch.logitech-g13.enable"; visibleWhen.equals = true; description = "G1 to G22 workspace and overview chords, plus the thumb and stick rows.";
        ojuny.patch.logitech-g13.bindings.bank1 = {
          g1 = { modifier = [ "SUPER" ]; keys = [ "1" ]; dispatcher = "comboview"; args = "1"; description = "Switch to workspace, hold for multi-tag"; group = "Workspaces"; subcat = "G1"; repeats = 0; };
          g2 = { modifier = [ "SUPER" ]; keys = [ "2" ]; dispatcher = "comboview"; args = "2"; description = "Switch to workspace, hold for multi-tag"; group = "Workspaces"; subcat = "G2"; repeats = 0; };
          g3 = { modifier = [ "SUPER" ]; keys = [ "3" ]; dispatcher = "comboview"; args = "3"; description = "Switch to workspace, hold for multi-tag"; group = "Workspaces"; subcat = "G3"; repeats = 0; };
          g4 = { modifier = [ "SUPER" ]; keys = [ "4" ]; dispatcher = "comboview"; args = "4"; description = "Switch to workspace, hold for multi-tag"; group = "Workspaces"; subcat = "G4"; repeats = 0; };
          g5 = { modifier = [ "SUPER" ]; keys = [ "5" ]; dispatcher = "comboview"; args = "5"; description = "Switch to workspace, hold for multi-tag"; group = "Workspaces"; subcat = "G5"; repeats = 0; };
          g6 = { modifier = [ "SUPER" ]; keys = [ "6" ]; dispatcher = "comboview"; args = "6"; description = "Switch to workspace, hold for multi-tag"; group = "Workspaces"; subcat = "G6"; repeats = 0; };
          g7 = { modifier = [ "SUPER" ]; keys = [ "7" ]; dispatcher = "comboview"; args = "7"; description = "Switch to workspace, hold for multi-tag"; group = "Workspaces"; subcat = "G7"; repeats = 0; };
          g8 = { modifier = [ "SUPER" ]; keys = [ "8" ]; dispatcher = "comboview"; args = "8"; description = "Switch to workspace, hold for multi-tag"; group = "Workspaces"; subcat = "G8"; repeats = 0; };
          g9 = { modifier = [ "SUPER" ]; keys = [ "9" ]; dispatcher = "comboview"; args = "9"; description = "Switch to workspace, hold for multi-tag"; group = "Workspaces"; subcat = "G9"; repeats = 0; };
          g10 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "1" ]; dispatcher = "tagsilent"; args = "1"; description = "Move window to workspace"; group = "Workspaces"; subcat = "G10"; repeats = 0; };
          g11 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "2" ]; dispatcher = "tagsilent"; args = "2"; description = "Move window to workspace"; group = "Workspaces"; subcat = "G11"; repeats = 0; };
          g12 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "3" ]; dispatcher = "tagsilent"; args = "3"; description = "Move window to workspace"; group = "Workspaces"; subcat = "G12"; repeats = 0; };
          g13 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "4" ]; dispatcher = "tagsilent"; args = "4"; description = "Move window to workspace"; group = "Workspaces"; subcat = "G13"; repeats = 0; };
          g14 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "5" ]; dispatcher = "tagsilent"; args = "5"; description = "Move window to workspace"; group = "Workspaces"; subcat = "G14"; repeats = 0; };
          g15 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "6" ]; dispatcher = "tagsilent"; args = "6"; description = "Move window to workspace"; group = "Workspaces"; subcat = "G15"; repeats = 0; };
          g16 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "7" ]; dispatcher = "tagsilent"; args = "7"; description = "Move window to workspace"; group = "Workspaces"; subcat = "G16"; repeats = 0; };
          g17 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "8" ]; dispatcher = "tagsilent"; args = "8"; description = "Move window to workspace"; group = "Workspaces"; subcat = "G17"; repeats = 0; };
          g18 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "9" ]; dispatcher = "tagsilent"; args = "9"; description = "Move window to workspace"; group = "Workspaces"; subcat = "G18"; repeats = 0; };
          g19 = { modifier = [ "ALT" ]; keys = [ "Tab" ]; dispatcher = "overcircle"; args = "next"; description = "Toggle or cycle overview"; group = "Workspaces"; subcat = "G19"; repeats = 0; };
          g20 = { modifier = [ "SUPER" ]; keys = [ "SPACE" ]; dispatcher = "spawn"; args = "dms ipc call spotlight toggle"; description = "Toggle launcher"; group = "Workspaces"; subcat = "G20"; repeats = 0; };
          g21 = { modifier = [ "SUPER" ]; keys = [ "Return" ]; dispatcher = "spawn"; args = "ojuny-ghostty"; description = "Open terminal"; group = "Workspaces"; subcat = "G21"; repeats = 0; };
          g22 = { modifier = [ "SUPER" ]; keys = [ "X" ]; dispatcher = "spawn"; args = "dms ipc call dankMenu toggle root"; description = "Toggle menu"; group = "Workspaces"; subcat = "G22"; repeats = 0; };
          thumb-left = { modifier = [ ]; keys = [ "Escape" ]; dispatcher = "key"; args = "Escape"; description = "Send Escape"; group = "Workspaces"; subcat = "Thumb Left"; repeats = 0; };
          thumb-down = { modifier = [ ]; keys = [ "Enter" ]; dispatcher = "key"; args = "Enter"; description = "Send Enter"; group = "Workspaces"; subcat = "Thumb Down"; repeats = 0; };
          thumb-top = { modifier = [ ]; keys = [ "Space" ]; dispatcher = "key"; args = "Space"; description = "Send Space"; group = "Workspaces"; subcat = "Thumb Top"; repeats = 0; };
          stick-left = { modifier = [ "SUPER" ]; keys = [ "A" ]; dispatcher = "focusdir"; args = "left"; description = "Focus window left"; group = "Workspaces"; subcat = "Stick Left"; repeats = 0; };
          stick-right = { modifier = [ "SUPER" ]; keys = [ "D" ]; dispatcher = "focusdir"; args = "right"; description = "Focus window right"; group = "Workspaces"; subcat = "Stick Right"; repeats = 0; };
          stick-up = { modifier = [ "SUPER" ]; keys = [ "W" ]; dispatcher = "focusdir"; args = "up"; description = "Focus window up"; group = "Workspaces"; subcat = "Stick Up"; repeats = 0; };
          stick-down = { modifier = [ "SUPER" ]; keys = [ "S" ]; dispatcher = "focusdir"; args = "down"; description = "Focus window down"; group = "Workspaces"; subcat = "Stick Down"; repeats = 0; };
        };

        # @option widget = "keybinds"; label = "Bank 2: Windows"; group = "Banks"; groupOrder = 40; order = 20; bindFields = [ "modifier" "keys" "dispatcher" "args" "description" "group" "subcat" "repeats" ]; bindFieldTypes = [ "list" "list" "str" "str" "str" "str" "str" "int" ]; bindPreview = [ "subcat" "modifier" "keys" ]; visibleWhen.path = "ojuny.patch.logitech-g13.enable"; visibleWhen.equals = true; description = "Focus, movement, window, screenshot and system chords, plus the thumb and stick rows.";
        ojuny.patch.logitech-g13.bindings.bank2 = {
          g1 = { modifier = [ "SUPER" ]; keys = [ "W" ]; dispatcher = "focusdir"; args = "up"; description = "Focus window up"; group = "Windows"; subcat = "G1"; repeats = 0; };
          g2 = { modifier = [ "SUPER" ]; keys = [ "A" ]; dispatcher = "focusdir"; args = "left"; description = "Focus window left"; group = "Windows"; subcat = "G2"; repeats = 0; };
          g3 = { modifier = [ "SUPER" ]; keys = [ "S" ]; dispatcher = "focusdir"; args = "down"; description = "Focus window down"; group = "Windows"; subcat = "G3"; repeats = 0; };
          g4 = { modifier = [ "SUPER" ]; keys = [ "D" ]; dispatcher = "focusdir"; args = "right"; description = "Focus window right"; group = "Windows"; subcat = "G4"; repeats = 0; };
          g5 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "W" ]; dispatcher = "move_client"; args = "up"; description = "Move window up"; group = "Windows"; subcat = "G5"; repeats = 0; };
          g6 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "A" ]; dispatcher = "move_client"; args = "left"; description = "Move window left"; group = "Windows"; subcat = "G6"; repeats = 0; };
          g7 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "S" ]; dispatcher = "move_client"; args = "down"; description = "Move window down"; group = "Windows"; subcat = "G7"; repeats = 0; };
          g8 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "D" ]; dispatcher = "move_client"; args = "right"; description = "Move window right"; group = "Windows"; subcat = "G8"; repeats = 0; };
          g9 = { modifier = [ "SUPER" ]; keys = [ "Q" ]; dispatcher = "killclient"; args = ""; description = "Kill client"; group = "Windows"; subcat = "G9"; repeats = 0; };
          g10 = { modifier = [ "SUPER" ]; keys = [ "F" ]; dispatcher = "togglemaximizescreen"; args = ""; description = "Toggle maximize"; group = "Windows"; subcat = "G10"; repeats = 0; };
          g11 = { modifier = [ "SUPER" ]; keys = [ "F11" ]; dispatcher = "togglefullscreen"; args = ""; description = "Toggle fullscreen"; group = "Windows"; subcat = "G11"; repeats = 0; };
          g12 = { modifier = [ "SUPER" ]; keys = [ "H" ]; dispatcher = "spawn_shell"; args = "ojuny-snap"; description = "Float, unfloat or snap the focused window"; group = "Windows"; subcat = "G12"; repeats = 0; };
          g13 = { modifier = [ "SUPER" ]; keys = [ "T" ]; dispatcher = "tag_special_tag"; args = ""; description = "Move window into or out of special workspace"; group = "Windows"; subcat = "G13"; repeats = 0; };
          g14 = { modifier = [ "SUPER" "ALT" ]; keys = [ "SPACE" ]; dispatcher = "toggle_special_tag"; args = ""; description = "Toggle special workspace"; group = "Windows"; subcat = "G14"; repeats = 0; };
          g15 = { modifier = [ "SUPER" ]; keys = [ "V" ]; dispatcher = "spawn_shell"; args = "ojuny-g13-paste"; description = "Paste clipboard"; group = "Windows"; subcat = "G15"; repeats = 0; };
          g16 = { modifier = [ "SUPER" ]; keys = [ "Z" ]; dispatcher = "groupleave"; args = ""; description = "Leave group"; group = "Windows"; subcat = "G16"; repeats = 0; };
          g17 = { modifier = [ "SUPER" ]; keys = [ "R" ]; dispatcher = "reload_config"; args = ""; description = "Reload configuration"; group = "Windows"; subcat = "G17"; repeats = 0; };
          g18 = { modifier = [ "SUPER" ]; keys = [ "K" ]; dispatcher = "spawn"; args = "dms ipc call keybinds open binds"; description = "Show keybinds"; group = "Windows"; subcat = "G18"; repeats = 0; };
          g19 = { modifier = [ ]; keys = [ "PRINT" ]; dispatcher = "spawn"; args = "dms screenshot"; description = "Selection screenshot"; group = "Windows"; subcat = "G19"; repeats = 0; };
          g20 = { modifier = [ "SUPER" ]; keys = [ "PRINT" ]; dispatcher = "spawn"; args = "dms screenshot window"; description = "Focused window screenshot"; group = "Windows"; subcat = "G20"; repeats = 0; };
          g21 = { modifier = [ "ALT" ]; keys = [ "PRINT" ]; dispatcher = "spawn"; args = "dms screenshot full"; description = "Fullscreen screenshot"; group = "Windows"; subcat = "G21"; repeats = 0; };
          g22 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "Escape" ]; dispatcher = "quit"; args = ""; description = "Quit Mango"; group = "Windows"; subcat = "G22"; repeats = 0; };
          thumb-left = { modifier = [ ]; keys = [ "Escape" ]; dispatcher = "key"; args = "Escape"; description = "Send Escape"; group = "Windows"; subcat = "Thumb Left"; repeats = 0; };
          thumb-down = { modifier = [ ]; keys = [ "Enter" ]; dispatcher = "key"; args = "Enter"; description = "Send Enter"; group = "Windows"; subcat = "Thumb Down"; repeats = 0; };
          thumb-top = { modifier = [ ]; keys = [ "Space" ]; dispatcher = "key"; args = "Space"; description = "Send Space"; group = "Windows"; subcat = "Thumb Top"; repeats = 0; };
          stick-left = { modifier = [ "SUPER" ]; keys = [ "A" ]; dispatcher = "focusdir"; args = "left"; description = "Focus window left"; group = "Windows"; subcat = "Stick Left"; repeats = 0; };
          stick-right = { modifier = [ "SUPER" ]; keys = [ "D" ]; dispatcher = "focusdir"; args = "right"; description = "Focus window right"; group = "Windows"; subcat = "Stick Right"; repeats = 0; };
          stick-up = { modifier = [ "SUPER" ]; keys = [ "W" ]; dispatcher = "focusdir"; args = "up"; description = "Focus window up"; group = "Windows"; subcat = "Stick Up"; repeats = 0; };
          stick-down = { modifier = [ "SUPER" ]; keys = [ "S" ]; dispatcher = "focusdir"; args = "down"; description = "Focus window down"; group = "Windows"; subcat = "Stick Down"; repeats = 0; };
        };

        # @option widget = "keybinds"; label = "Bank 3: Media"; group = "Banks"; groupOrder = 40; order = 30; bindFields = [ "modifier" "keys" "dispatcher" "args" "description" "group" "subcat" "repeats" ]; bindFieldTypes = [ "list" "list" "str" "str" "str" "str" "str" "int" ]; bindPreview = [ "subcat" "modifier" "keys" ]; visibleWhen.path = "ojuny.patch.logitech-g13.enable"; visibleWhen.equals = true; description = "Media keys and application, screenshot, overview and window actions, plus the thumb and stick rows.";
        ojuny.patch.logitech-g13.bindings.bank3 = {
          g1 = { modifier = [ ]; keys = [ "mute" ]; dispatcher = "spawn"; args = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; description = "Mute output"; group = "Media"; subcat = "G1"; repeats = 0; };
          g2 = { modifier = [ ]; keys = [ "volumedown" ]; dispatcher = "spawn"; args = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; description = "Lower output volume"; group = "Media"; subcat = "G2"; repeats = 0; };
          g3 = { modifier = [ ]; keys = [ "volumeup" ]; dispatcher = "spawn"; args = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"; description = "Raise output volume"; group = "Media"; subcat = "G3"; repeats = 0; };
          g4 = { modifier = [ ]; keys = [ "playpause" ]; dispatcher = "spawn"; args = "playerctl play-pause"; description = "Play or pause media"; group = "Media"; subcat = "G4"; repeats = 0; };
          g5 = { modifier = [ ]; keys = [ "previoussong" ]; dispatcher = "spawn"; args = "playerctl previous"; description = "Previous track"; group = "Media"; subcat = "G5"; repeats = 0; };
          g6 = { modifier = [ ]; keys = [ "nextsong" ]; dispatcher = "spawn"; args = "playerctl next"; description = "Next track"; group = "Media"; subcat = "G6"; repeats = 0; };
          g7 = { modifier = [ ]; keys = [ "brightnessdown" ]; dispatcher = "spawn"; args = "brightnessctl set 5%-"; description = "Decrease screen brightness"; group = "Media"; subcat = "G7"; repeats = 0; };
          g8 = { modifier = [ ]; keys = [ "brightnessup" ]; dispatcher = "spawn"; args = "brightnessctl set +5%"; description = "Increase screen brightness"; group = "Media"; subcat = "G8"; repeats = 0; };
          g9 = { modifier = [ "SUPER" ]; keys = [ "B" ]; dispatcher = "spawn"; args = "firefox --new-window"; description = "Open browser"; group = "Media"; subcat = "G9"; repeats = 0; };
          g10 = { modifier = [ "SUPER" ]; keys = [ "E" ]; dispatcher = "spawn"; args = "dfiles open"; description = "Open files"; group = "Media"; subcat = "G10"; repeats = 0; };
          g11 = { modifier = [ "SUPER" ]; keys = [ "SPACE" ]; dispatcher = "spawn"; args = "dms ipc call spotlight toggle"; description = "Toggle launcher"; group = "Media"; subcat = "G11"; repeats = 0; };
          g12 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "E" ]; dispatcher = "spawn"; args = "dms ipc call spotlight toggleQuery ':e '"; description = "Emoji picker"; group = "Media"; subcat = "G12"; repeats = 0; };
          g13 = { modifier = [ "SUPER" ]; keys = [ "Return" ]; dispatcher = "spawn"; args = "ojuny-ghostty"; description = "Open terminal"; group = "Media"; subcat = "G13"; repeats = 0; };
          g14 = { modifier = [ "ALT" ]; keys = [ "Tab" ]; dispatcher = "overcircle"; args = "next"; description = "Toggle or cycle overview"; group = "Media"; subcat = "G14"; repeats = 0; };
          g15 = { modifier = [ ]; keys = [ "PRINT" ]; dispatcher = "spawn"; args = "dms screenshot"; description = "Selection screenshot"; group = "Media"; subcat = "G15"; repeats = 0; };
          g16 = { modifier = [ "SUPER" ]; keys = [ "PRINT" ]; dispatcher = "spawn"; args = "dms screenshot window"; description = "Focused window screenshot"; group = "Media"; subcat = "G16"; repeats = 0; };
          g17 = { modifier = [ "ALT" ]; keys = [ "PRINT" ]; dispatcher = "spawn"; args = "dms screenshot full"; description = "Fullscreen screenshot"; group = "Media"; subcat = "G17"; repeats = 0; };
          g18 = { modifier = [ "SUPER" ]; keys = [ "Q" ]; dispatcher = "killclient"; args = ""; description = "Kill client"; group = "Media"; subcat = "G18"; repeats = 0; };
          g19 = { modifier = [ "SUPER" ]; keys = [ "F" ]; dispatcher = "togglemaximizescreen"; args = ""; description = "Toggle maximize"; group = "Media"; subcat = "G19"; repeats = 0; };
          g20 = { modifier = [ "SUPER" ]; keys = [ "F11" ]; dispatcher = "togglefullscreen"; args = ""; description = "Toggle fullscreen"; group = "Media"; subcat = "G20"; repeats = 0; };
          g21 = { modifier = [ "SUPER" ]; keys = [ "H" ]; dispatcher = "spawn_shell"; args = "ojuny-snap"; description = "Float, unfloat or snap the focused window"; group = "Media"; subcat = "G21"; repeats = 0; };
          g22 = { modifier = [ "SUPER" ]; keys = [ "K" ]; dispatcher = "spawn"; args = "dms ipc call keybinds open binds"; description = "Show keybinds"; group = "Media"; subcat = "G22"; repeats = 0; };
          thumb-left = { modifier = [ ]; keys = [ "Escape" ]; dispatcher = "key"; args = "Escape"; description = "Send Escape"; group = "Media"; subcat = "Thumb Left"; repeats = 0; };
          thumb-down = { modifier = [ ]; keys = [ "Enter" ]; dispatcher = "key"; args = "Enter"; description = "Send Enter"; group = "Media"; subcat = "Thumb Down"; repeats = 0; };
          thumb-top = { modifier = [ ]; keys = [ "Space" ]; dispatcher = "key"; args = "Space"; description = "Send Space"; group = "Media"; subcat = "Thumb Top"; repeats = 0; };
          stick-left = { modifier = [ "SUPER" ]; keys = [ "A" ]; dispatcher = "focusdir"; args = "left"; description = "Focus window left"; group = "Media"; subcat = "Stick Left"; repeats = 0; };
          stick-right = { modifier = [ "SUPER" ]; keys = [ "D" ]; dispatcher = "focusdir"; args = "right"; description = "Focus window right"; group = "Media"; subcat = "Stick Right"; repeats = 0; };
          stick-up = { modifier = [ "SUPER" ]; keys = [ "W" ]; dispatcher = "focusdir"; args = "up"; description = "Focus window up"; group = "Media"; subcat = "Stick Up"; repeats = 0; };
          stick-down = { modifier = [ "SUPER" ]; keys = [ "S" ]; dispatcher = "focusdir"; args = "down"; description = "Focus window down"; group = "Media"; subcat = "Stick Down"; repeats = 0; };
        };

        # @option widget = "keybinds"; label = "Bank 4: Apps"; group = "Banks"; groupOrder = 40; order = 40; bindFields = [ "modifier" "keys" "dispatcher" "args" "description" "group" "subcat" "repeats" ]; bindFieldTypes = [ "list" "list" "str" "str" "str" "str" "str" "int" ]; bindPreview = [ "subcat" "modifier" "keys" ]; visibleWhen.path = "ojuny.patch.logitech-g13.enable"; visibleWhen.equals = true; description = "Application, launcher, menu, screenshot, window and workspace actions, plus the thumb and stick rows.";
        ojuny.patch.logitech-g13.bindings.bank4 = {
          g1 = { modifier = [ "SUPER" ]; keys = [ "B" ]; dispatcher = "spawn"; args = "firefox --new-window"; description = "Open browser"; group = "Apps"; subcat = "G1"; repeats = 0; };
          g2 = { modifier = [ "SUPER" ]; keys = [ "E" ]; dispatcher = "spawn"; args = "dfiles open"; description = "Open files"; group = "Apps"; subcat = "G2"; repeats = 0; };
          g3 = { modifier = [ "SUPER" ]; keys = [ "SPACE" ]; dispatcher = "spawn"; args = "dms ipc call spotlight toggle"; description = "Toggle launcher"; group = "Apps"; subcat = "G3"; repeats = 0; };
          g4 = { modifier = [ "SUPER" ]; keys = [ "X" ]; dispatcher = "spawn"; args = "dms ipc call dankMenu toggle root"; description = "Toggle menu"; group = "Apps"; subcat = "G4"; repeats = 0; };
          g5 = { modifier = [ "SUPER" ]; keys = [ "Return" ]; dispatcher = "spawn"; args = "ojuny-ghostty"; description = "Open terminal"; group = "Apps"; subcat = "G5"; repeats = 0; };
          g6 = { modifier = [ "SUPER" ]; keys = [ "Tab" ]; dispatcher = "spawn"; args = "ojuny-ghostty"; description = "Open terminal"; group = "Apps"; subcat = "G6"; repeats = 0; };
          g7 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "E" ]; dispatcher = "spawn"; args = "dms ipc call spotlight toggleQuery ':e '"; description = "Emoji picker"; group = "Apps"; subcat = "G7"; repeats = 0; };
          g8 = { modifier = [ "SUPER" "SHIFT" ]; keys = [ "V" ]; dispatcher = "spawn"; args = "dms ipc call clipboard toggle"; description = "Clipboard history"; group = "Apps"; subcat = "G8"; repeats = 0; };
          g9 = { modifier = [ "SUPER" ]; keys = [ "K" ]; dispatcher = "spawn"; args = "dms ipc call keybinds open binds"; description = "Show keybinds"; group = "Apps"; subcat = "G9"; repeats = 0; };
          g10 = { modifier = [ "ALT" ]; keys = [ "Tab" ]; dispatcher = "overcircle"; args = "next"; description = "Toggle or cycle overview"; group = "Apps"; subcat = "G10"; repeats = 0; };
          g11 = { modifier = [ ]; keys = [ "PRINT" ]; dispatcher = "spawn"; args = "dms screenshot"; description = "Selection screenshot"; group = "Apps"; subcat = "G11"; repeats = 0; };
          g12 = { modifier = [ "SUPER" ]; keys = [ "PRINT" ]; dispatcher = "spawn"; args = "dms screenshot window"; description = "Focused window screenshot"; group = "Apps"; subcat = "G12"; repeats = 0; };
          g13 = { modifier = [ "ALT" ]; keys = [ "PRINT" ]; dispatcher = "spawn"; args = "dms screenshot full"; description = "Fullscreen screenshot"; group = "Apps"; subcat = "G13"; repeats = 0; };
          g14 = { modifier = [ "SUPER" ]; keys = [ "Q" ]; dispatcher = "killclient"; args = ""; description = "Kill client"; group = "Apps"; subcat = "G14"; repeats = 0; };
          g15 = { modifier = [ "SUPER" ]; keys = [ "F" ]; dispatcher = "togglemaximizescreen"; args = ""; description = "Toggle maximize"; group = "Apps"; subcat = "G15"; repeats = 0; };
          g16 = { modifier = [ "SUPER" ]; keys = [ "F11" ]; dispatcher = "togglefullscreen"; args = ""; description = "Toggle fullscreen"; group = "Apps"; subcat = "G16"; repeats = 0; };
          g17 = { modifier = [ "SUPER" ]; keys = [ "H" ]; dispatcher = "spawn_shell"; args = "ojuny-snap"; description = "Float, unfloat or snap the focused window"; group = "Apps"; subcat = "G17"; repeats = 0; };
          g18 = { modifier = [ "SUPER" ]; keys = [ "Z" ]; dispatcher = "groupleave"; args = ""; description = "Leave group"; group = "Apps"; subcat = "G18"; repeats = 0; };
          g19 = { modifier = [ "SUPER" ]; keys = [ "T" ]; dispatcher = "tag_special_tag"; args = ""; description = "Move window into or out of special workspace"; group = "Apps"; subcat = "G19"; repeats = 0; };
          g20 = { modifier = [ "SUPER" "ALT" ]; keys = [ "SPACE" ]; dispatcher = "toggle_special_tag"; args = ""; description = "Toggle special workspace"; group = "Apps"; subcat = "G20"; repeats = 0; };
          g21 = { modifier = [ "SUPER" ]; keys = [ "Right" ]; dispatcher = "viewtoright"; args = "0"; description = "Next workspace"; group = "Apps"; subcat = "G21"; repeats = 0; };
          g22 = { modifier = [ "SUPER" ]; keys = [ "Left" ]; dispatcher = "viewtoleft"; args = "0"; description = "Previous workspace"; group = "Apps"; subcat = "G22"; repeats = 0; };
          thumb-left = { modifier = [ ]; keys = [ "Escape" ]; dispatcher = "key"; args = "Escape"; description = "Send Escape"; group = "Apps"; subcat = "Thumb Left"; repeats = 0; };
          thumb-down = { modifier = [ ]; keys = [ "Enter" ]; dispatcher = "key"; args = "Enter"; description = "Send Enter"; group = "Apps"; subcat = "Thumb Down"; repeats = 0; };
          thumb-top = { modifier = [ ]; keys = [ "Space" ]; dispatcher = "key"; args = "Space"; description = "Send Space"; group = "Apps"; subcat = "Thumb Top"; repeats = 0; };
          stick-left = { modifier = [ "SUPER" ]; keys = [ "A" ]; dispatcher = "focusdir"; args = "left"; description = "Focus window left"; group = "Apps"; subcat = "Stick Left"; repeats = 0; };
          stick-right = { modifier = [ "SUPER" ]; keys = [ "D" ]; dispatcher = "focusdir"; args = "right"; description = "Focus window right"; group = "Apps"; subcat = "Stick Right"; repeats = 0; };
          stick-up = { modifier = [ "SUPER" ]; keys = [ "W" ]; dispatcher = "focusdir"; args = "up"; description = "Focus window up"; group = "Apps"; subcat = "Stick Up"; repeats = 0; };
          stick-down = { modifier = [ "SUPER" ]; keys = [ "S" ]; dispatcher = "focusdir"; args = "down"; description = "Focus window down"; group = "Apps"; subcat = "Stick Down"; repeats = 0; };
        };

        home-manager.sharedModules = lib.mkIf active [
          self.modules.homeManager.logitech-g13-backend
        ];
      };
    };

  flake.modules.nixos.logitech-g13-backend =
    { config, lib, pkgs, ... }:
    let
      cfg = config.ojuny.patch.logitech-g13;
      active = cfg.enable && (config.ojuny.patches or true);
      stylixAvailable = config ? lib.stylix.colors;

      g13Cli = pkgs.writeShellScriptBin "g13-cli" ''
        PIPE="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/g13-lcd"
        printf '%b\n' "$1" > "$PIPE"
      '';

      g13Int = pkgs.writeShellScriptBin "g13-int" ''
        export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.bash ]}:$PATH
        STATE_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/g13"
        mkdir -p "$STATE_DIR"
        INPUT="$1"
        BOX="+-----------------------+
        |                       |
        |                       |
        |                       |
        +-----------------------+"
        mapfile -t ROWS <<< "$BOX"
        TOP="''${ROWS[0]}"
        BOT="''${ROWS[-1]}"
        INNER_W=$(( ''${#TOP} - 2 ))
        INNER_H=$(( ''${#ROWS[@]} - 2 ))
        mapfile -t LINES < <(fold -s -w "$INNER_W" <<< "$INPUT" | cut -c1-"$INNER_W" | head -n "$INNER_H")
        center() {
          local s="$1" w="$2" len=''${#1}
          (( len > w )) && s="''${s:0:w}" && len=$w
          local pad=$(( (w - len) / 2 ))
          printf '%*s%s%*s' "$pad" "" "$s" "$((w - len - pad))" ""
        }
        FORMAT="$TOP"
        lines=''${#LINES[@]}
        top_pad=$(( (INNER_H - lines) / 2 ))
        (( top_pad < 0 )) && top_pad=0
        for (( i=0; i<INNER_H; i++ )); do
          if (( i < top_pad )) || (( i >= top_pad + lines )); then
            row="$(printf '%*s' "$INNER_W" "")"
          else
            row="$(center "''${LINES[i-top_pad]:-}" "$INNER_W")"
          fi
          FORMAT+=$'\n'"|''${row}|"
        done
        FORMAT+=$'\n'"$BOT"
        printf '%s\n' "$FORMAT" > "$STATE_DIR/int.g13"
      '';

      g13Raw = pkgs.writeShellScriptBin "g13-raw" ''
        export PATH=${lib.makeBinPath [ pkgs.coreutils ]}:$PATH
        STATE_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/g13"
        mkdir -p "$STATE_DIR"
        printf '%s\n' "$1" > "$STATE_DIR/int-raw.g13"
      '';

      g13Paste = pkgs.writeShellScriptBin "ojuny-g13-paste" ''
        export PATH=${lib.makeBinPath [ pkgs.ydotool pkgs.wl-clipboard pkgs.coreutils ]}:$PATH
        ydotool key 125:0
        sleep 0.1
        ydotool type "$(wl-paste)"
      '';

      driver = pkgs.stdenv.mkDerivation {
        pname = "linux-g13-driver";
        version = "unstable";
        src = pkgs.fetchFromGitHub {
          owner = "Lordbooker";
          repo = "linux-g13-driver";
          rev = "0b396f0aef55e7e83c4b3d79c07f6cdd781a9381";
          hash = "sha256-I7oRQZiF0o5jPIHILnSeZRXgrhmsK6WjtT0XDu1UibE=";
        };
        sourceRoot = "source/g13-driver";
        nativeBuildInputs = with pkgs; [
          cmake
          pkg-config
        ];
        buildInputs = [
          pkgs.libusb1
          pkgs.gtk3
          pkgs.libappindicator-gtk3
          g13Cli
        ];
        dontConfigure = true;
        buildPhase = ''
          cd src
          make build-driver
        '';
        installPhase = ''
          cd ..
          install -Dm755 Linux-G13-Driver $out/bin/linux-g13-driver
          install -Dm644 src/udev/99-g13.rules $out/lib/udev/rules.d/99-g13.rules
        '';
      };

      pythonSource = pkgs.writeText "ojuny-g13.py" ''
        #!${pkgs.python3}/bin/python3
        """Ojuny Logitech G13 detector and LCD render loop."""

        import argparse
        import json
        import os
        import re
        import shutil
        import subprocess
        import sys
        import time
        import urllib.parse
        from pathlib import Path

        RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR") or ("/run/user/" + str(os.getuid()))
        STATE_DIR = os.path.join(RUNTIME_DIR, "ojuny", "g13")
        G13_DIR = os.path.join(RUNTIME_DIR, "g13")
        FIFO_PATH = os.path.join(RUNTIME_DIR, "g13-lcd")
        DEFAULT_CONFIG = os.environ.get("OJUNY_G13_CONFIG")


        def load_config(path):
            with open(path, "r", encoding="utf-8") as handle:
                return json.load(handle)


        def atomic_write(path, text):
            directory = os.path.dirname(path)
            if directory:
                os.makedirs(directory, exist_ok=True)
            temporary = path + "." + str(os.getpid()) + ".tmp"
            with open(temporary, "w", encoding="utf-8") as handle:
                handle.write(text)
            os.replace(temporary, path)


        def run(args, timeout):
            try:
                result = subprocess.run(
                    args,
                    capture_output=True,
                    text=True,
                    timeout=max(1, int(timeout)),
                    check=False,
                )
                return result.returncode, result.stdout.strip(), result.stderr.strip()
            except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
                return 1, "", ""


        def read_text(path):
            try:
                return Path(path).read_text(encoding="utf-8", errors="replace")
            except OSError:
                return ""


        def read_int(path):
            try:
                return int(Path(path).read_text(encoding="utf-8").strip())
            except (OSError, ValueError):
                return None


        def format_gb_from_kb(value):
            return f"{value / (1024 * 1024):.1f}GB"


        def format_gb_from_bytes(value):
            return f"{value / (1024 ** 3):.1f}G"


        def format_rate(value):
            if value >= 1024 * 1024:
                return f"{value / (1024 * 1024):.1f}MB/s"
            if value >= 1024:
                return f"{value / 1024:.1f}KB/s"
            return f"{value:.0f}B/s"


        def cpu_clock():
            for line in read_text("/proc/cpuinfo").splitlines():
                if line.startswith("cpu MHz"):
                    try:
                        return f"{float(line.split(':', 1)[1]) / 1000.0:.1f}GHz"
                    except ValueError:
                        return ""
            return ""


        def cpu_usage():
            def sample():
                line = read_text("/proc/stat").splitlines()[0]
                fields = [int(part) for part in line.split()[1:]]
                idle = fields[3] + (fields[4] if len(fields) > 4 else 0)
                return sum(fields), idle

            try:
                total1, idle1 = sample()
                time.sleep(0.1)
                total2, idle2 = sample()
            except (IndexError, ValueError):
                return ""
            total_delta = total2 - total1
            if total_delta <= 0:
                return ""
            return f"{100.0 * (1.0 - (idle2 - idle1) / total_delta):.0f}"


        def cpu_temp():
            preferred = ("k10temp", "coretemp", "zenpower", "cpu_thermal", "soc_thermal")
            candidates = []
            for hwmon in sorted(Path("/sys/class/hwmon").glob("hwmon*")):
                name = read_text(os.path.join(hwmon, "name")).strip()
                for temp in sorted(hwmon.glob("temp*_input")):
                    value = read_int(temp)
                    if value is not None:
                        candidates.append((0 if name in preferred else 1, value))
            if not candidates:
                return ""
            candidates.sort(key=lambda item: item[0])
            return f"{candidates[0][1] / 1000.0:.0f}c"


        def detect_cpu(cfg, timeout):
            return {
                "cpu_clock": cpu_clock(),
                "cpu_usage": cpu_usage(),
                "cpu_temp": cpu_temp(),
                "time": time.strftime("%H:%M"),
            }


        def detect_ram(cfg, timeout):
            info = {}
            for line in read_text("/proc/meminfo").splitlines():
                if ":" not in line:
                    continue
                key, value = line.split(":", 1)
                try:
                    info[key.strip()] = int(value.strip().split()[0])
                except (IndexError, ValueError):
                    continue
            total = info.get("MemTotal", 0)
            free = info.get("MemFree", 0)
            available = info.get("MemAvailable", free)
            cached = info.get("Cached", 0) + info.get("SReclaimable", 0) + info.get("Buffers", 0)
            used = max(0, total - available)
            return {
                "ram_used": format_gb_from_kb(used),
                "ram_cached": format_gb_from_kb(cached),
                "ram_free": format_gb_from_kb(free),
                "ram_total": format_gb_from_kb(total),
                "ram_percent": f"{100.0 * used / total:.0f}%" if total else "",
            }


        def disk_device(mount, timeout):
            code, out, _ = run(["df", "-P", mount], timeout)
            if code != 0:
                return ""
            lines = out.splitlines()
            if len(lines) < 2:
                return ""
            device = lines[1].split()[0]
            if not device.startswith("/dev/"):
                return ""
            name = os.path.basename(device)
            if name.startswith("nvme") and "p" in name:
                return name.rsplit("p", 1)[0]
            return re.sub(r"\d+$", "", name)


        def diskstats(name):
            for line in read_text("/proc/diskstats").splitlines():
                parts = line.split()
                if len(parts) >= 10 and parts[2] == name:
                    return int(parts[5]), int(parts[9])
            return None


        def detect_disk(cfg, timeout):
            mount = cfg.get("mount") or "/"
            code, out, _ = run(["df", "-P", "-h", mount], timeout)
            used = ""
            free = ""
            if code == 0:
                lines = out.splitlines()
                if len(lines) >= 2:
                    fields = lines[1].split()
                    if len(fields) >= 5:
                        free = fields[3]
                        used = fields[4]
            read_rate = ""
            write_rate = ""
            name = disk_device(mount, timeout)
            if name:
                first = diskstats(name)
                time.sleep(1.0)
                second = diskstats(name)
                if first and second:
                    read_rate = format_rate(max(0, second[0] - first[0]) * 512)
                    write_rate = format_rate(max(0, second[1] - first[1]) * 512)
            return {
                "disk_used": used,
                "disk_free": free,
                "disk_read": read_rate,
                "disk_write": write_rate,
            }


        def drm_device(vendor_id):
            for base in sorted(Path("/sys/class/drm").glob("card[0-9]*")):
                if read_text(base / "device" / "vendor").strip().lower() == vendor_id:
                    return base / "device"
            return None


        def gpu_vendor(cfg):
            selected = cfg.get("vendor", "auto")
            if selected != "auto":
                return selected
            for base in sorted(Path("/sys/class/drm").glob("card[0-9]*")):
                vendor = read_text(base / "device" / "vendor").strip().lower()
                if vendor == "0x10de":
                    return "nvidia"
                if vendor == "0x1002":
                    return "amd"
                if vendor == "0x8086":
                    return "intel"
            if shutil.which("nvidia-smi"):
                return "nvidia"
            return ""


        def gpu_temp(device):
            for hwmon in sorted(Path(device, "hwmon").glob("hwmon*")):
                value = read_int(hwmon / "temp1_input")
                if value is not None:
                    return f"{value / 1000.0:.0f}c"
            return ""


        def detect_gpu(cfg, timeout):
            vendor = gpu_vendor(cfg)
            values = {
                "gpu_vendor": vendor,
                "gpu_usage": "",
                "gpu_clock": "",
                "gpu_vram": "",
                "gpu_temp": "",
            }
            if vendor == "nvidia":
                code, out, _ = run(
                    [
                        "nvidia-smi",
                        "--query-gpu=utilization.gpu,clocks.current.graphics,memory.used,temperature.gpu",
                        "--format=csv,noheader,nounits",
                    ],
                    timeout,
                )
                if code == 0 and out:
                    parts = [part.strip() for part in out.splitlines()[0].split(",")]
                    if len(parts) >= 4:
                        try:
                            values["gpu_usage"] = parts[0]
                            values["gpu_clock"] = f"{float(parts[1]) / 1000.0:.1f}GHz"
                            values["gpu_vram"] = f"{float(parts[2]) / 1024.0:.1f}G"
                            values["gpu_temp"] = f"{parts[3]}c"
                        except ValueError:
                            pass
                return values
            device = drm_device("0x1002") if vendor == "amd" else drm_device("0x8086")
            if device is None:
                return values
            if vendor == "amd":
                usage = read_int(device / "gpu_busy_percent")
                if usage is not None:
                    values["gpu_usage"] = str(usage)
                clock_text = read_text(device / "pp_dpm_sclk")
                match = re.search(r"(\d+)Mhz\s+\*", clock_text, re.IGNORECASE)
                if match:
                    values["gpu_clock"] = f"{int(match.group(1)) / 1000.0:.1f}GHz"
                vram = read_int(device / "mem_info_vram_used")
                if vram is not None:
                    values["gpu_vram"] = format_gb_from_bytes(vram)
            else:
                usage = read_int(device / "gt" / "gt0" / "engine" / "rcs0" / "busy")
                if usage is None:
                    usage = read_int(device / "engine" / "rcs0" / "busy")
                if usage is not None:
                    values["gpu_usage"] = str(usage)
                clock = read_int(device / "gt" / "gt0" / "rps" / "cur_freq_mhz")
                if clock is None:
                    clock = read_int(device / "gt_cur_freq_mhz")
                if clock is not None:
                    values["gpu_clock"] = f"{clock / 1000.0:.1f}GHz"
                values["gpu_vram"] = "N/A"
            values["gpu_temp"] = gpu_temp(device)
            return values


        def default_interface(timeout):
            code, out, _ = run(["ip", "route", "show", "default"], timeout)
            if code == 0:
                match = re.search(r"\bdev\s+(\S+)", out)
                if match:
                    return match.group(1)
            return ""


        def detect_network(cfg, timeout):
            interface = cfg.get("interface", "auto")
            if interface == "auto":
                interface = default_interface(timeout)
            values = {
                "network_interface": interface,
                "network_state": "",
                "network_connection": "",
                "network_ip": "",
                "network_signal": "",
                "network_rx": "",
                "network_tx": "",
            }
            if not interface:
                return values
            code, out, _ = run(["nmcli", "-t", "-f", "DEVICE,STATE,CONNECTION", "device", "status"], timeout)
            if code == 0:
                for line in out.splitlines():
                    parts = line.split(":")
                    if parts and parts[0] == interface:
                        values["network_state"] = parts[1] if len(parts) > 1 else ""
                        values["network_connection"] = ":".join(parts[2:]) if len(parts) > 2 else ""
                        break
            code, out, _ = run(["ip", "-4", "-o", "addr", "show", "dev", interface], timeout)
            if code == 0:
                match = re.search(r"inet\s+([0-9.]+)/", out)
                if match:
                    values["network_ip"] = match.group(1)
            code, out, _ = run(["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi"], timeout)
            if code == 0:
                for line in out.splitlines():
                    parts = line.split(":")
                    if len(parts) >= 3 and parts[0] == "yes":
                        values["network_signal"] = parts[2]
                        break
            rx_path = "/sys/class/net/" + interface + "/statistics/rx_bytes"
            tx_path = "/sys/class/net/" + interface + "/statistics/tx_bytes"
            first_rx = read_int(rx_path)
            first_tx = read_int(tx_path)
            if first_rx is None or first_tx is None:
                return values
            time.sleep(1.0)
            second_rx = read_int(rx_path)
            second_tx = read_int(tx_path)
            if second_rx is not None:
                values["network_rx"] = format_rate(max(0, second_rx - first_rx))
            if second_tx is not None:
                values["network_tx"] = format_rate(max(0, second_tx - first_tx))
            return values


        def battery_device(cfg, timeout):
            selected = cfg.get("device", "auto")
            code, out, _ = run(["upower", "-e"], timeout)
            devices = []
            if code == 0:
                devices = [line for line in out.splitlines() if "battery" in line.lower()]
            if selected != "auto" and selected:
                if selected.startswith("/"):
                    return selected
                for device in devices:
                    if selected.lower() in device.lower():
                        return device
                return ""
            return devices[0] if devices else ""


        def detect_battery(cfg, timeout):
            percentile = ""
            state = ""
            remaining = ""
            path = battery_device(cfg, timeout)
            if path:
                code, out, _ = run(["upower", "-i", path], timeout)
                if code == 0:
                    for line in out.splitlines():
                        if ":" not in line:
                            continue
                        key, value = line.split(":", 1)
                        key = key.strip().lower()
                        value = value.strip()
                        if key == "percentage":
                            percentile = value
                        elif key == "state":
                            state = value
                        elif key in ("time to empty", "time to full"):
                            remaining = value
            if not percentile:
                for base in sorted(Path("/sys/class/power_supply").glob("BAT*")):
                    capacity = read_int(base / "capacity")
                    if capacity is not None:
                        percentile = str(capacity) + "%"
                    state = read_text(base / "status").strip().lower()
                    break
            return {
                "battery_percent": percentile,
                "battery_state": state,
                "battery_time": remaining,
            }


        def detect_audio(cfg, timeout):
            values = {
                "audio_volume": "",
                "audio_muted": "",
                "audio_source_volume": "",
                "audio_source_muted": "",
            }
            code, out, _ = run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], timeout)
            if code == 0:
                match = re.search(r"Volume:\s*([0-9.]+)", out)
                if match:
                    values["audio_volume"] = f"{float(match.group(1)) * 100:.0f}%"
                values["audio_muted"] = "muted" if "[MUTED]" in out.upper() else ""
            else:
                code, out, _ = run(["pactl", "get-sink-volume", "@DEFAULT_SINK@"], timeout)
                if code == 0:
                    match = re.search(r"(\d+)%", out)
                    if match:
                        values["audio_volume"] = match.group(1) + "%"
                code, out, _ = run(["pactl", "get-sink-mute", "@DEFAULT_SINK@"], timeout)
                if code == 0:
                    values["audio_muted"] = "muted" if "yes" in out.lower() else ""
            code, out, _ = run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"], timeout)
            if code == 0:
                match = re.search(r"Volume:\s*([0-9.]+)", out)
                if match:
                    values["audio_source_volume"] = f"{float(match.group(1)) * 100:.0f}%"
                values["audio_source_muted"] = "muted" if "[MUTED]" in out.upper() else ""
            else:
                code, out, _ = run(["pactl", "get-source-volume", "@DEFAULT_SOURCE@"], timeout)
                if code == 0:
                    match = re.search(r"(\d+)%", out)
                    if match:
                        values["audio_source_volume"] = match.group(1) + "%"
                code, out, _ = run(["pactl", "get-source-mute", "@DEFAULT_SOURCE@"], timeout)
                if code == 0:
                    values["audio_source_muted"] = "muted" if "yes" in out.lower() else ""
            return values


        def detect_media(cfg, timeout):
            fields = {
                "media_status": "{{status}}",
                "media_title": "{{title}}",
                "media_artist": "{{artist}}",
                "media_album": "{{album}}",
                "media_position": "{{duration(position)}}",
                "media_length": "{{duration(mpris:length)}}",
            }
            values = {name: "" for name in fields}
            for name, template in fields.items():
                code, out, _ = run(["playerctl", "metadata", "--format", template], timeout)
                if code == 0:
                    values[name] = out
            return values


        def detect_workspace(cfg, timeout):
            monitor = ""
            code, out, _ = run(["mmsg", "get", "all-monitors"], timeout)
            if code == 0:
                try:
                    for item in json.loads(out).get("monitors", []):
                        if item.get("active"):
                            monitor = item.get("name", "")
                            break
                except json.JSONDecodeError:
                    pass
            workspace = ""
            layout = ""
            code, out, _ = run(["mmsg", "get", "all-tags"], timeout)
            if code == 0:
                try:
                    for entry in json.loads(out).get("all_tags", []):
                        if monitor and entry.get("monitor") != monitor:
                            continue
                        active = [tag for tag in entry.get("tags", []) if tag.get("is_active")]
                        if active:
                            workspace = ",".join(str(tag.get("index")) for tag in active)
                            layout = str(active[0].get("layout", ""))
                            if not monitor:
                                monitor = str(entry.get("monitor", ""))
                            break
                except json.JSONDecodeError:
                    pass
            return {
                "workspace": workspace,
                "workspace_layout": layout,
                "workspace_monitor": monitor,
            }


        def detect_keymode(cfg, timeout):
            code, out, _ = run(["mmsg", "get", "keymode"], timeout)
            if code == 0:
                try:
                    return {"keymode": str(json.loads(out).get("keymode", ""))}
                except json.JSONDecodeError:
                    pass
            return {"keymode": ""}


        def detect_layout(cfg, timeout):
            code, out, _ = run(["mmsg", "get", "keyboardlayout"], timeout)
            if code == 0:
                try:
                    return {"layout": str(json.loads(out).get("layout", ""))}
                except json.JSONDecodeError:
                    pass
            return {"layout": ""}


        def detect_clock(cfg, timeout):
            return {"time": time.strftime("%H:%M")}


        def detect_date(cfg, timeout):
            now = time.localtime()
            return {
                "date": time.strftime("%Y-%m-%d", now),
                "weekday": time.strftime("%A", now),
                "day": time.strftime("%d", now),
                "month": time.strftime("%B", now),
                "year": time.strftime("%Y", now),
            }


        def detect_uptime(cfg, timeout):
            parts = read_text("/proc/uptime").split()
            if not parts:
                return {"uptime": "", "uptime_days": "", "uptime_hours": ""}
            try:
                seconds = int(float(parts[0]))
            except ValueError:
                return {"uptime": "", "uptime_days": "", "uptime_hours": ""}
            days, remainder = divmod(seconds, 86400)
            hours, remainder = divmod(remainder, 3600)
            minutes = remainder // 60
            pieces = []
            if days:
                pieces.append(str(days) + "d")
            if hours:
                pieces.append(str(hours) + "h")
            pieces.append(str(minutes) + "m")
            return {
                "uptime": " ".join(pieces),
                "uptime_days": str(days),
                "uptime_hours": str(hours),
            }


        def detect_weather(cfg, timeout):
            location = cfg.get("location", "").strip()
            query = urllib.parse.quote(location) if location else ""
            url = "https://wttr.in/" + query + "?format=%l|%t|%C|%h|%w"
            code, out, _ = run(["curl", "-fsS", "--max-time", str(max(1, int(timeout))), url], timeout)
            if code != 0:
                return {
                    "weather_location": location,
                    "weather_temp": "",
                    "weather_condition": "",
                    "weather_humidity": "",
                    "weather_wind": "",
                }
            parts = out.split("|")
            while len(parts) < 5:
                parts.append("")
            return {
                "weather_location": parts[0].strip() or location,
                "weather_temp": parts[1].strip(),
                "weather_condition": parts[2].strip(),
                "weather_humidity": parts[3].strip(),
                "weather_wind": parts[4].strip(),
            }


        def detect_custom(cfg, timeout):
            command = cfg.get("command", "")
            if not command:
                return {"custom": ""}
            code, out, _ = run(["sh", "-c", command], timeout)
            if code != 0:
                return {"custom": ""}
            lines = [line for line in out.splitlines() if line.strip()]
            values = {"custom": lines[0] if lines else ""}
            for line in lines:
                if "=" not in line:
                    continue
                key, value = line.split("=", 1)
                key = re.sub(r"[^A-Za-z0-9_]", "_", key.strip()).lower()
                if key:
                    values["custom_" + key] = value.strip()
            return values


        DETECTORS = {
            "cpu": detect_cpu,
            "ram": detect_ram,
            "disk": detect_disk,
            "gpu": detect_gpu,
            "network": detect_network,
            "battery": detect_battery,
            "audio": detect_audio,
            "media": detect_media,
            "workspace": detect_workspace,
            "keymode": detect_keymode,
            "layout": detect_layout,
            "clock": detect_clock,
            "date": detect_date,
            "uptime": detect_uptime,
            "weather": detect_weather,
            "custom": detect_custom,
        }


        def detect(source, config_path):
            config = load_config(config_path)
            detector = config.get("detectors", {}).get(source)
            function = DETECTORS.get(source)
            if detector is None or function is None:
                print("ojuny-g13: unknown detector " + source, file=sys.stderr)
                return 1
            interval = max(1, int(detector.get("refresh", 1)))
            timeout = max(1, int(detector.get("timeout", 2)))
            while True:
                started = time.monotonic()
                try:
                    values = function(detector, timeout)
                    if (
                        time.monotonic() - started <= timeout
                        and values
                        and any(str(value) != "" for value in values.values())
                    ):
                        payload = {
                            "timestamp": time.time(),
                            "values": values,
                        }
                        atomic_write(
                            os.path.join(STATE_DIR, source + ".json"),
                            json.dumps(payload, sort_keys=True),
                        )
                except Exception as error:
                    print("ojuny-g13: " + source + ": " + str(error), file=sys.stderr, flush=True)
                elapsed = time.monotonic() - started
                time.sleep(max(0.0, interval - elapsed))


        def read_values(source):
            try:
                data = json.loads(Path(os.path.join(STATE_DIR, source + ".json")).read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                return {}
            values = data.get("values", {})
            if not isinstance(values, dict):
                return {}
            return {str(key): str(value) for key, value in values.items()}


        def substitute(text, values):
            return re.sub(
                r"\$([A-Za-z_][A-Za-z0-9_]*)",
                lambda match: values.get(match.group(1), ""),
                text,
            )


        def cap_frame(text):
            return "\n".join(line[:25] for line in text.splitlines()[:5])


        def read_interrupt():
            for name in ("int-raw.g13", "int.g13"):
                path = os.path.join(G13_DIR, name)
                text = read_text(path)
                if text.strip():
                    return path, text
            return None, None


        def clear_interrupt(path):
            try:
                with open(path, "w", encoding="utf-8"):
                    pass
            except OSError:
                pass


        def write_fifo(frame):
            payload = (frame + "\n").encode("utf-8")
            try:
                descriptor = os.open(FIFO_PATH, os.O_WRONLY | os.O_NONBLOCK)
            except OSError:
                return False
            try:
                os.write(descriptor, payload)
                return True
            except OSError:
                return False
            finally:
                os.close(descriptor)


        def render(config_path):
            config = load_config(config_path)
            display = config.get("display", {})
            if not display.get("enable", True):
                return 0
            interval = max(0.1, float(display.get("refreshMs", 500)) / 1000.0)
            lines = [line for line in display.get("lines", []) if line.get("enabled", True)]
            last_frame = None
            next_run = time.monotonic()
            while True:
                interrupt_path, interrupt_text = read_interrupt()
                if interrupt_text is not None:
                    frame = cap_frame(interrupt_text)
                else:
                    source_values = {}
                    rendered = []
                    for line in lines[:5]:
                        source = line.get("source", "")
                        if source not in source_values:
                            source_values[source] = read_values(source)
                        values = source_values[source]
                        rendered.append(substitute(line.get("format", ""), values) if values else "")
                    frame = cap_frame("\n".join(rendered))
                if frame != last_frame:
                    if write_fifo(frame):
                        last_frame = frame
                        if interrupt_path:
                            clear_interrupt(interrupt_path)
                next_run += interval
                delay = next_run - time.monotonic()
                if delay > 0:
                    time.sleep(delay)
                else:
                    next_run = time.monotonic()


        def main(argv):
            parser = argparse.ArgumentParser(prog="ojuny-g13")
            parser.add_argument("--config", default=DEFAULT_CONFIG)
            subparsers = parser.add_subparsers(dest="command", required=True)

            detect_parser = subparsers.add_parser("detect")
            detect_parser.add_argument("source")
            detect_parser.add_argument("--config", dest="detect_config")

            render_parser = subparsers.add_parser("render")
            render_parser.add_argument("--config", dest="render_config")

            args = parser.parse_args(argv)
            config_path = args.detect_config if getattr(args, "detect_config", None) else None
            if config_path is None:
                config_path = args.render_config if getattr(args, "render_config", None) else None
            if config_path is None:
                config_path = args.config
            if not config_path:
                parser.error("--config or OJUNY_G13_CONFIG is required")

            if args.command == "detect":
                return detect(args.source, config_path)
            if args.command == "render":
                return render(config_path)
            return 2


        if __name__ == "__main__":
            sys.exit(main(sys.argv[1:]))
      '';

      pythonScript = pkgs.runCommandLocal "ojuny-g13.py" {
        nativeBuildInputs = [ pkgs.python3 ];
      } ''
        install -Dm755 ${pythonSource} $out/bin/ojuny-g13.py
        python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' $out/bin/ojuny-g13.py
      '';

      ojunyG13 = pkgs.writeShellApplication {
        name = "ojuny-g13";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          exec ${pythonScript}/bin/ojuny-g13.py "$@"
        '';
      };

      configFile = pkgs.writeText "ojuny-g13.json" (
        builtins.toJSON {
          display = {
            inherit (cfg.display) enable refreshMs;
            lines = map (line: { inherit (line) source format enabled; }) cfg.display.lines;
          };
          detectors = cfg.detectors;
        }
      );

      servicePath =
        with pkgs;
        [
          bash
          coreutils
          gnugrep
          gawk
          procps
          util-linux
          playerctl
          wireplumber
          pulseaudio
          iproute2
          networkmanager
          curl
          upower
        ]
        ++ [ ojunyG13 g13Cli ]
        ++ lib.optional (mangoPackage != null) mangoPackage;

      mangoPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.mango or null;

      detectorSources = lib.unique (
        map (line: line.source) (builtins.filter (line: line.enabled) cfg.display.lines)
      );

      detectorService = source: {
        description = "Ojuny G13 ${source} detector";
        after = [ "g13.service" ];
        wants = [ "g13.service" ];
        partOf = [ "mango-session.target" ];
        wantedBy = [ "mango-session.target" ];
        path = servicePath;
        restartTriggers = [
          configFile
          pythonScript
        ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${ojunyG13}/bin/ojuny-g13 detect ${source} --config ${configFile}";
          Restart = "on-failure";
          RestartSec = 5;
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };

      renderService = {
        description = "Ojuny G13 LCD render loop";
        after = [ "g13.service" ];
        wants = [ "g13.service" ];
        partOf = [ "mango-session.target" ];
        wantedBy = [ "mango-session.target" ];
        path = servicePath;
        restartTriggers = [
          configFile
          pythonScript
        ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${ojunyG13}/bin/ojuny-g13 render --config ${configFile}";
          Restart = "on-failure";
          RestartSec = 5;
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
    in
    {
      config = lib.mkMerge [
        (lib.mkIf active {
          assertions = [
            {
              assertion = stylixAvailable;
              message = "patch-logitech-g13: Stylix is required for the derived bank colors.";
            }
            {
              assertion = builtins.length cfg.display.lines <= 5;
              message = "patch-logitech-g13: display.lines supports at most 5 rows.";
            }
            {
              assertion = lib.count (line: line.enabled) cfg.display.lines >= 1;
              message = "patch-logitech-g13: at least one display line must be enabled.";
            }
            {
              assertion = cfg.display.refreshMs >= 100;
              message = "patch-logitech-g13: display.refreshMs must be at least 100.";
            }
            {
              assertion = lib.all (
                detector: detector.refresh > 0
              ) (builtins.attrValues cfg.detectors);
              message = "patch-logitech-g13: every detector refresh must be positive.";
            }
            {
              assertion = lib.all (
                line: line.source != "custom" || cfg.detectors.custom.command != ""
              ) (builtins.filter (line: line.enabled) cfg.display.lines);
              message = "patch-logitech-g13: an enabled custom line needs detectors.custom.command.";
            }
            {
              assertion = lib.all (
                bank: lib.all (row: row.keys != [ ]) (builtins.attrValues bank)
              ) (builtins.attrValues cfg.bindings);
              message = "patch-logitech-g13: every bind row needs at least one key.";
            }
          ];

          hardware.uinput.enable = true;
          services.udev.packages = [ driver ];
          services.upower.enable = lib.mkDefault true;
          environment.systemPackages = [
            driver
            g13Cli
            g13Int
            g13Raw
            g13Paste
            ojunyG13
          ];
          environment.sessionVariables.OJUNY_G13_CONFIG = configFile;

          systemd.user.services =
            {
              g13 = {
                description = "Logitech G13 driver";
                after = [ "graphical-session.target" ];
                wants = [ "graphical-session.target" ];
                path = [
                  g13Cli
                  pkgs.coreutils
                ];
                serviceConfig = {
                  Type = "simple";
                  ExecStart = "${driver}/bin/linux-g13-driver";
                  Restart = "on-failure";
                  RestartSec = 5;
                  StandardOutput = "journal";
                  StandardError = "journal";
                };
                wantedBy = [ "default.target" ];
              };
            }
            // lib.optionalAttrs cfg.display.enable (
              {
                ojuny-g13-render = renderService;
              }
              // lib.listToAttrs (
                map (
                  source:
                  lib.nameValuePair "ojuny-g13-detector@${source}" (detectorService source)
                ) detectorSources
              )
            );
        })
        (lib.mkIf (active && config ? desktop.ojuny.dankMenu) {
          desktop.ojuny.dankMenu.extraEntries = {
            "trigger.ojuny-g13" = {
              icon = "input-gaming";
              label = "Logitech G13";
              aliases = [
                "g13"
                "logitech"
              ];
            };
            "trigger.ojuny-g13.binds" = {
              icon = "preferences-desktop-keyboard";
              label = "Show G13 keybinds";
              action = "dms ipc call keybinds open g13";
            };
          };
        })
      ];
    };

  flake.modules.homeManager.logitech-g13-backend =
    { lib, osConfig, ... }:
    let
      cfg = osConfig.ojuny.patch.logitech-g13;
      active = cfg.enable && (osConfig.ojuny.patches or true);
      stylixAvailable = osConfig ? lib.stylix.colors;
      namedColors = if stylixAvailable then self.colors osConfig.lib.stylix.colors else { };

      gIndex = {
        g1 = 0;
        g2 = 1;
        g3 = 2;
        g4 = 3;
        g5 = 4;
        g6 = 5;
        g7 = 6;
        g8 = 7;
        g9 = 8;
        g10 = 9;
        g11 = 10;
        g12 = 11;
        g13 = 12;
        g14 = 13;
        g15 = 14;
        g16 = 15;
        g17 = 16;
        g18 = 17;
        g19 = 18;
        g20 = 19;
        g21 = 20;
        g22 = 21;
        undef1 = 22;
        light-state = 23;
        bd = 24;
        l1 = 25;
        l2 = 26;
        l3 = 27;
        l4 = 28;
        m1 = 29;
        m2 = 30;
        m3 = 31;
        mr = 32;
        thumb-left = 33;
        thumb-down = 34;
        thumb-top = 35;
        stick-up = 36;
        stick-left = 37;
        stick-right = 38;
        stick-down = 39;
      };

      keyCodes = {
        esc = 1;
        escape = 1;
        "1" = 2;
        "2" = 3;
        "3" = 4;
        "4" = 5;
        "5" = 6;
        "6" = 7;
        "7" = 8;
        "8" = 9;
        "9" = 10;
        "0" = 11;
        minus = 12;
        equal = 13;
        backspace = 14;
        tab = 15;
        q = 16;
        w = 17;
        e = 18;
        r = 19;
        t = 20;
        y = 21;
        u = 22;
        i = 23;
        o = 24;
        p = 25;
        leftbrace = 26;
        rightbrace = 27;
        enter = 28;
        return = 28;
        leftctrl = 29;
        ctrl = 29;
        a = 30;
        s = 31;
        d = 32;
        f = 33;
        g = 34;
        h = 35;
        j = 36;
        k = 37;
        l = 38;
        semicolon = 39;
        apostrophe = 40;
        grave = 41;
        backtick = 41;
        leftshift = 42;
        shift = 42;
        backslash = 43;
        z = 44;
        x = 45;
        c = 46;
        v = 47;
        b = 48;
        n = 49;
        m = 50;
        comma = 51;
        dot = 52;
        slash = 53;
        rightshift = 54;
        kpasterisk = 55;
        leftalt = 56;
        alt = 56;
        space = 57;
        capslock = 58;
        f1 = 59;
        f2 = 60;
        f3 = 61;
        f4 = 62;
        f5 = 63;
        f6 = 64;
        f7 = 65;
        f8 = 66;
        f9 = 67;
        f10 = 68;
        numlock = 69;
        scrolllock = 70;
        kp7 = 71;
        kp8 = 72;
        kp9 = 73;
        kpminus = 74;
        kp4 = 75;
        kp5 = 76;
        kp6 = 77;
        kpplus = 78;
        kp1 = 79;
        kp2 = 80;
        kp3 = 81;
        kp0 = 82;
        kpdot = 83;
        f11 = 87;
        f12 = 88;
        kpenter = 96;
        rightctrl = 97;
        kpslash = 98;
        sysrq = 99;
        print = 99;
        printscreen = 99;
        rightalt = 100;
        home = 102;
        up = 103;
        pageup = 104;
        left = 105;
        right = 106;
        end = 107;
        down = 108;
        pagedown = 109;
        insert = 110;
        delete = 111;
        mute = 113;
        volumedown = 114;
        volumeup = 115;
        power = 116;
        kpequal = 117;
        pause = 119;
        kpcomma = 121;
        hangeul = 122;
        hanja = 123;
        yen = 124;
        leftmeta = 125;
        super = 125;
        rightmeta = 126;
        compose = 127;
        stop = 128;
        again = 129;
        props = 130;
        undo = 131;
        front = 132;
        copy = 133;
        open = 134;
        paste = 135;
        find = 136;
        cut = 137;
        help = 138;
        menu = 139;
        calc = 140;
        setup = 141;
        sleep = 142;
        wakeup = 143;
        www = 150;
        mail = 155;
        back = 158;
        forward = 159;
        nextsong = 163;
        playpause = 164;
        previoussong = 165;
        stopcd = 166;
        homepage = 172;
        refresh = 173;
        edit = 176;
        scrollup = 178;
        scrolldown = 179;
        new = 181;
        f13 = 183;
        f14 = 184;
        f15 = 185;
        f16 = 186;
        f17 = 187;
        f18 = 188;
        f19 = 189;
        f20 = 190;
        f21 = 191;
        f22 = 192;
        f23 = 193;
        f24 = 194;
        pausecd = 201;
        play = 207;
        fastforward = 208;
        rewind = 209;
        search = 217;
        brightnessdown = 224;
        brightnessup = 225;
        media = 226;
        xf86audiomute = 113;
        xf86audiolowervolume = 114;
        xf86audioraisevolume = 115;
        xf86audioplay = 164;
        xf86audionext = 163;
        xf86audioprev = 165;
        xf86monbrightnessdown = 224;
        xf86monbrightnessup = 225;
      };

      modifierCodes = {
        SUPER = 125;
        META = 125;
        WIN = 125;
        SHIFT = 42;
        ALT = 56;
        CTRL = 29;
        CONTROL = 29;
      };

      normalize = name: lib.toLower (lib.replaceStrings [ " " "_" "\t" ] [ "-" "-" "-" ] name);

      resolveGIndex = name: gIndex.${normalize name} or (throw "patch-logitech-g13: unknown G13 key '${name}'");

      resolveKey = key:
        let
          normalized = normalize key;
        in
        keyCodes.${normalized} or (
          if builtins.match "[0-9]+" normalized != null then
            lib.toInt normalized
          else
            throw "patch-logitech-g13: unknown key '${key}'"
        );

      resolveModifier = modifier: modifierCodes.${lib.toUpper modifier} or (throw "patch-logitech-g13: unknown modifier '${modifier}'");

      banks = [
        {
          number = 1;
          name = "Workspaces";
          color = "functions";
          rows = cfg.bindings.bank1;
        }
        {
          number = 2;
          name = "Windows";
          color = "keywords";
          rows = cfg.bindings.bank2;
        }
        {
          number = 3;
          name = "Media";
          color = "strings";
          rows = cfg.bindings.bank3;
        }
        {
          number = 4;
          name = "Apps";
          color = "support";
          rows = cfg.bindings.bank4;
        }
      ];

      sortedNames = bank: builtins.sort (a: b: a < b) (builtins.attrNames bank.rows);

      rowEntries = bank: lib.imap0 (index: name: {
        inherit index name;
        row = bank.rows.${name};
      }) (sortedNames bank);

      modifiersOf = row: builtins.filter (modifier: normalize modifier != "none") row.modifier;

      isChord = row: modifiersOf row != [ ] || builtins.length row.keys > 1;

      macroId = bank: entry: (bank.number - 1) * 50 + entry.index;

      macroSequence = row:
        let
          modifiers = map resolveModifier (modifiersOf row);
          keys = map resolveKey row.keys;
        in
        lib.concatStringsSep "," (
          map (code: "kd.${toString code}") modifiers
          ++ map (code: "kd.${toString code}") keys
          ++ [ "d.20" ]
          ++ map (code: "ku.${toString code}") (lib.reverseList keys)
          ++ map (code: "ku.${toString code}") (lib.reverseList modifiers)
        );

      compileBinding = bank: entry:
        if entry.row.keys == [ ] then
          ""
        else if isChord entry.row then
          "G${toString (resolveGIndex entry.name)}=m,${toString (macroId bank entry)},${toString entry.row.repeats}"
        else
          "G${toString (resolveGIndex entry.name)}=p,k.${toString (resolveKey (builtins.head entry.row.keys))}";

      bankColor = colorName:
        let
          hex = namedColors.${colorName}.hex;
        in
        lib.concatStringsSep "," [
          (toString (lib.fromHexString (builtins.substring 1 2 hex)))
          (toString (lib.fromHexString (builtins.substring 3 2 hex)))
          (toString (lib.fromHexString (builtins.substring 5 2 hex)))
        ];

      compileBank = bank:
        let
          lines = map (entry: compileBinding bank entry) (rowEntries bank);
        in
        "color=${bankColor bank.color}\n" + lib.concatStringsSep "\n" lines + "\n";

      bankMacros = bank:
        map
          (
            entry: {
              id = macroId bank entry;
              file = ".config/g13/macro-${toString (macroId bank entry)}.properties";
              text = ''
                sequence=${macroSequence entry.row}
                name=${entry.name}
                id=${toString (macroId bank entry)}
              '';
            }
          )
          (builtins.filter (entry: isChord entry.row) (rowEntries bank));

      bindingFiles = lib.listToAttrs (
        map
          (
            bank:
            lib.nameValuePair ".config/g13/bindings-${toString (bank.number - 1)}.properties" {
              text = compileBank bank;
              force = true;
            }
          )
          banks
      );

      macroFiles = lib.listToAttrs (
        lib.concatMap (
          bank:
          map
            (
              macro:
              lib.nameValuePair macro.file {
                inherit (macro) text;
                force = true;
              }
            )
            (bankMacros bank)
        ) banks
      );

      allRows = lib.concatMap (bank: map (entry: entry.row) (rowEntries bank)) banks;

      actionText = row: lib.concatStringsSep " " ([ row.dispatcher ] ++ lib.optional (row.args != "") row.args);

      cheatsheet = {
        title = "Logitech G13";
        provider = "g13";
        binds = lib.mapAttrs (
          _group: rows:
          map (row: {
            key = row.subcat;
            desc = row.description;
            action = actionText row;
          }) rows
        ) (lib.groupBy (row: if row.group == "" then "Other" else row.group) allRows);
      };
    in
    {
      config = lib.mkIf (active && stylixAvailable) {
        home.file = bindingFiles // macroFiles // {
          ".config/dms/cheatsheets/g13.json" = {
            text = builtins.toJSON cheatsheet;
            force = true;
          };
        };
      };
    };
}
