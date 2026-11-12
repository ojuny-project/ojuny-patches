/*
  @menu
  displayname = "Ojuny agent";
  icon = "applications-development-symbolic";
  order = 45;
  description = "Approval-gated maintenance agent and read-only assistant for the Ojuny flake";
  category = "Patches";
  systems = [ "all" ];
*/

{ self, ... }:

{
  flake.modules.nixos.patch-ojuny-agent =
    { config, lib, ... }:
    {
      options.ojuny.patch.ojuny-agent = {
        enable = lib.mkEnableOption "the ojuny agent patch";
        runtimeActions = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Allow the maintenance agent to ask for mutating ojuny commands. Off by default; the default profile is flake-only.";
        };
      };

      imports = [ self.modules.nixos.ojuny-agent-backend ];

      config = {
        # @option widget = "switch"; label = "Ojuny agent"; group = "Agents"; description = "Install the approval-gated maintenance agent, the read-only assistant, and the flake-safe CLI. Requires the development patch and its OpenCode agent.";
        ojuny.patch.ojuny-agent.enable = false;

        # @option widget = "switch"; label = "Allow runtime actions"; group = "Agents"; visibleWhen.path = "ojuny.patch.ojuny-agent.enable"; visibleWhen.equals = true; description = "Allow the maintenance agent to ask for mutating ojuny commands. Every request still needs approval, and sudo, rebuilds, and package changes stay denied.";
        ojuny.patch.ojuny-agent.runtimeActions = false;

        home-manager.sharedModules = lib.mkIf (
          config.ojuny.patch.ojuny-agent.enable && (config.ojuny.patches or true)
        ) [ self.modules.homeManager.ojuny-agent-backend ];
      };
    };

  flake.modules.nixos.ojuny-agent-backend =
    { config, lib, ... }:
    let
      cfg = config.ojuny.patch.ojuny-agent;
      active = cfg.enable && (config.ojuny.patches or true);
      development =
        config.ojuny.patch.development or {
          enable = false;
          agents = {
            opencode = {
              enable = false;
            };
          };
        };
    in
    {
      config = lib.mkIf active {
        assertions = [
          {
            assertion = development.enable;
            message = "patch-ojuny-agent requires patch-development. Set ojuny.patch.development.enable = true.";
          }
          {
            assertion = development.enable && (development.agents.opencode.enable or false);
            message = "patch-ojuny-agent requires the OpenCode agent. Set ojuny.patch.development.agents.opencode.enable = true.";
          }
        ];
      };
    };

  flake.modules.homeManager.ojuny-agent-backend =
    {
      config,
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    let
      cfg =
        osConfig.ojuny.patch.ojuny-agent or {
          enable = false;
          runtimeActions = false;
        };

      development =
        osConfig.ojuny.patch.development or {
          enable = false;
          agents = {
            opencode = {
              enable = false;
            };
          };
        };

      active =
        cfg.enable
        && (osConfig.ojuny.patches or true)
        && development.enable
        && (development.agents.opencode.enable or false);

      flakeRoot =
        osConfig.environment.variables.OJUNY_REPO_PATH
          or "${config.home.homeDirectory}/${osConfig.ojuny.repoPath or "repos/nix-flake"}";

      guide = ''
        # Ojuny agent guide

        ## What Ojuny is

        Ojuny is a single-host NixOS flake. The flake is the source of truth. Read the
        flake before answering questions or proposing a change. Persistent settings
        belong in the settings modules, not in imperative commands.

        ## Layout

        - The flake root contains `flake.nix` and at least one module file. The
          directory layout is not fixed.
        - Install and generation code finds files by the module they declare:
          `flake.modules.nixos.system-configuration`, `users`, `host-imports`,
          `system-hardware`, `system-bootloader` and `system-hardware-quirks`.
          Anonymous generated files fall back to `modules/`.
        - The facter report is `modules/facter.json` when no existing report is
          found.
        - A settings page is one `.nix` file with an `@menu` header.
        - An `@option` comment belongs directly above the assignment it controls.
        - Patches live in `modules/patches/patch-*.nix`.
        - `00-patches.nix` imports every installed `patch-*` module when
          `ojuny.patches` is true.
        - Generated files include the detected `system-hardware` module,
          `facter.json`, and the detected `system-hardware-quirks` module. Do not
          edit them by hand.
        - The installed flake location is `ojuny.repoPath`, projected to
          `/etc/ojuny/flake-path`. Do not hardcode another location.

        ## Settings menu rules

        - One file with `@menu` is one page.
        - Annotated options must sit in a plain attribute set or directly inside a
          `lib.mkIf` attribute set.
        - Never put `@option` inside `lib.mkMerge`, a list literal, `map`, `forEach`,
          or `lib.optionalAttrs`. The scanner does not descend into those shapes.
        - Do not patch the scanner. Change the module shape instead.
        - The GUI edits the assignment. It cannot create an option.
        - Dynamic attribute names are not addressable as settings.
        - The menu editor reads and writes only `desktop.ojuny.dankMenu.menu`.

        ## Patches

        - Install with `ojuny-patches install <id>`.
        - Metadata dependencies are checked by file presence, not by version.
        - Installing does not enable a patch. Enable it in settings, then rebuild.
        - To remove a patch: disable it, rebuild, remove it, rebuild again.
        - The registry is the source of truth for patch names and metadata.

        ## The ojuny CLI

        - `ojuny` observes and controls the running system. Use `--json` for machine
          output.
        - `ojuny` never calls `sudo`. Never add `sudo` on its behalf.
        - Safe read-only commands include `status`, `doctor`, `print-system-details`,
          `print-agent-details`, `crashes`, `logs`, `service status`, `flake status`,
          `flake generations`, `flake option`, `display list`, `display current`,
          `network status`, `network list`, `wifi status`, `wifi list`, `bluetooth
          status`, `bluetooth list`, `sound current`, `sound list`, `media status`,
          `system status`, `system battery`, `multiboot status`, `recovery status`,
          `bootorder status`, `secureboot status`, and `ipc status`.
        - Mutating commands are not part of the default profile. Explain them and ask
          the user to run them, unless runtime actions are explicitly enabled.
        - Do not run `ojuny settings` to inspect a page. It opens the GUI. Use
          `ojuny-agent-cli settings show <page>` instead.

        ## The flake-safe CLI

        `ojuny-agent-cli` is the guarded interface for this flake.

        - Read-only: `guide`, `status`, `settings list`, `settings show`, `patches
          list`, `patches show`, `diagnose`, `docs`, `diff`, `validate`, `sync
          --status`, `sync --dry-run`.
        - Mutating and approval-gated: `sync`, `sync --continue`, `sync --abort`,
          `revert`, and `lock`. Each requires `--yes`.
        - Mutating commands never accept `--flake`. They always use the configured
          Ojuny flake.
        - The CLI never pushes, rewrites history, or runs `sudo`.

        ## Edit workflow

        1. Locate the page with `ojuny-agent-cli settings show <page>`.
        2. Read the module and the governing docs.
        3. Propose the exact file, line, old value, new value, and validation plan.
        4. Wait for explicit user approval.
        5. Apply the edit only inside the flake.
        6. Run `ojuny-agent-cli validate`.
        7. If validation fails, fix the change with a new approval or revert it.
        8. Show `ojuny-agent-cli diff`. The user rebuilds.

        The agent never rebuilds or activates the system.

        ## Sync and merge workflow

        1. Run `ojuny-agent-cli sync --status` and `sync --dry-run`.
        2. A real `sync` requires a clean worktree and `--yes`.
        3. The CLI creates a backup ref, fetches, then fast-forwards or prepares a
           merge.
        4. Conflicts are never auto-resolved. Explain both sides, propose a resolution,
           and ask for approval.
        5. After resolving conflicts, validate and run `sync --continue`.
        6. `sync --abort` aborts an in-progress merge.
        7. `flake.lock` conflicts are resolved deliberately, then regenerated with
           `ojuny-agent-cli lock`.

        ## Limits

        - Never edit outside the flake.
        - Never edit generated hardware, account, or secret files.
        - Never run `sudo`, rebuild, activate, install packages, or change services
          without explicit approval.
        - Never read `.env`, key, age, or secret files.
        - Answer with file paths and line references.
        - If the cause is unclear, say so and ask for the missing information.
      '';

      runtimeActionsNote =
        if cfg.runtimeActions then
          "Runtime actions are enabled. You may ask for mutating ojuny commands, and every request still needs explicit approval."
        else
          "Runtime actions are disabled. Do not run mutating ojuny commands. Explain them and ask the user to run them.";

      agentPrompt =
        guide
        + ''

          ## Your role

          You are ojuny-agent, the full agentic Ojuny maintainer.

          You may edit or create files inside the Ojuny flake only, and only with
          explicit user approval for each change. Before every edit, show the file,
          line, old value, new value, and validation plan. Ask the user to choose
          Allow once for the edit; Allow always removes the per-change prompt. After
          every edit, run ojuny-agent-cli validate. If validation fails, fix the
          change with a new approval or revert it. Never ask the user to rebuild a
          broken flake.

          Use ojuny-agent-cli sync for git. Never run raw git pull, merge, rebase,
          reset, checkout, commit, push, clean, or restore. When a sync has conflicts,
          explain both sides, propose a resolution, get approval, edit the conflicted
          files, validate, and then run sync --continue. Never guess a resolution.

          Use the ojuny CLI for read-only status. Do not run mutating ojuny commands
          unless the user approved them. Never use sudo, rebuild, activate, install
          packages, or change services. Never edit generated hardware, account, or
          secret files. Never read .env, key, age, or secret files.

          When validation passes, show ojuny-agent-cli diff and tell the user to
          rebuild. The user owns the rebuild. If the cause of a problem is unclear,
          say so and ask for the missing information.
        ''
        + "\n"
        + runtimeActionsNote
        + "\n";

      assistPrompt = guide + ''

        ## Your role

        You are ojuny-assist, the read-only Ojuny explainer.

        Answer questions about Ojuny, the settings menu, patches, the flake, and the
        ojuny CLI. Read the flake and the governing docs before answering. Use
        ojuny-agent-cli read-only commands and ojuny read-only commands. Cite file
        paths and line references.

        Never edit, sync, revert, lock, rebuild, activate, install, or mutate
        anything. Do not run non-read-only shell commands and do not run network
        clients such as curl, wget, nc, socat, ssh, scp, or rsync. If the user asks
        for a change, explain the exact setting or file and suggest ojuny-agent or
        the settings GUI. If the answer is not in the available files, say so.
      '';

      allow = action: resource: {
        inherit action resource;
        effect = "allow";
      };
      ask = action: resource: {
        inherit action resource;
        effect = "ask";
      };
      deny = action: resource: {
        inherit action resource;
        effect = "deny";
      };

      readRules = [
        (deny "*" "*")
        (allow "read" "*")
        (deny "read" "*.env")
        (deny "read" "*.env.*")
        (allow "read" "*.env.example")
        (deny "read" "*.age")
        (deny "read" "*.key")
        (deny "read" "*secret*")
        (allow "grep" "*")
        (allow "glob" "*")
        (allow "question" "*")
        (deny "external_directory" "*")
        (ask "external_directory" "${flakeRoot}/*")
      ];

      fileActions = [
        "edit"
        "write"
        "patch"
      ];

      fileRules = action: [
        (deny action "*")
        (ask action "${flakeRoot}/**")
        (deny action "${flakeRoot}/flake.lock")
        (deny action "${flakeRoot}/modules/00-hardware.nix")
        (deny action "${flakeRoot}/modules/facter.json")
        (deny action "${flakeRoot}/modules/backend/00-hardware-quirks.nix")
        (deny action "${flakeRoot}/modules/00-user.nix")
        (deny action "${flakeRoot}/modules/00-configuration.nix")
        (deny action "${flakeRoot}/modules/00-host.nix")
      ];

      editRules = lib.concatMap fileRules fileActions;

      dangerousShell = [
        (deny "shell" "sudo*")
        (deny "shell" "rm*")
        (deny "shell" "mv*")
        (deny "shell" "cp*")
        (deny "shell" "chmod*")
        (deny "shell" "chown*")
        (deny "shell" "nixos-rebuild*")
        (deny "shell" "nix build*")
        (deny "shell" "nix develop*")
        (deny "shell" "nix shell*")
        (deny "shell" "nix run*")
        (deny "shell" "nix flake update*")
        (deny "shell" "nix flake lock*")
        (deny "shell" "nix store*")
        (deny "shell" "nix profile*")
        (deny "shell" "nix-env*")
        (deny "shell" "nix-collect-garbage*")
        (deny "shell" "git push*")
        (deny "shell" "git commit*")
        (deny "shell" "git merge*")
        (deny "shell" "git rebase*")
        (deny "shell" "git pull*")
        (deny "shell" "git fetch*")
        (deny "shell" "git checkout*")
        (deny "shell" "git switch*")
        (deny "shell" "git reset*")
        (deny "shell" "git clean*")
        (deny "shell" "git restore*")
        (deny "shell" "git stash*")
        (deny "shell" "git add*")
        (deny "shell" "git rm*")
        (deny "shell" "git mv*")
        (deny "shell" "git tag*")
        (deny "shell" "git apply*")
        (deny "shell" "git am*")
        (deny "shell" "git cherry-pick*")
        (deny "shell" "git revert*")
        (deny "shell" "systemctl start*")
        (deny "shell" "systemctl stop*")
        (deny "shell" "systemctl restart*")
        (deny "shell" "systemctl reload*")
        (deny "shell" "systemctl enable*")
        (deny "shell" "systemctl disable*")
        (deny "shell" "systemctl mask*")
        (deny "shell" "systemctl unmask*")
        (deny "shell" "systemctl daemon-reload*")
        (deny "shell" "systemctl set-property*")
        (deny "shell" "systemctl edit*")
        (deny "shell" "systemctl isolate*")
        (deny "shell" "systemctl poweroff*")
        (deny "shell" "systemctl reboot*")
        (deny "shell" "systemctl suspend*")
        (deny "shell" "systemctl hibernate*")
        (deny "shell" "systemctl kill*")
        (deny "shell" "ojuny flake activate*")
        (deny "shell" "ojuny flake build*")
        (deny "shell" "ojuny flake rollback*")
        (deny "shell" "ojuny flake gc*")
        (deny "shell" "ojuny flake update*")
        (deny "shell" "ojuny-patches install*")
        (deny "shell" "ojuny-patches remove*")
        (deny "shell" "ojuny-patches reinstall*")
        (deny "shell" "ojuny-patches sync*")
        (deny "shell" "ojuny-patches repo add*")
        (deny "shell" "ojuny-patches repo remove*")
      ];

      networkShell = [
        (deny "shell" "curl*")
        (deny "shell" "wget*")
        (deny "shell" "nc*")
        (deny "shell" "ncat*")
        (deny "shell" "socat*")
        (deny "shell" "telnet*")
        (deny "shell" "ftp*")
        (deny "shell" "ssh*")
        (deny "shell" "scp*")
        (deny "shell" "rsync*")
      ];

      cliRead = [
        "guide"
        "status"
        "settings list"
        "settings show"
        "patches list"
        "patches show"
        "diagnose"
        "docs"
        "diff"
        "validate"
        "sync --status"
        "sync --dry-run"
      ];

      ojunyRead = [
        "status"
        "doctor"
        "print-agent-details"
        "print-system-details"
        "commands"
        "help"
        "crashes"
        "logs"
        "service status"
        "flake status"
        "flake validate"
        "flake generations"
        "flake option"
        "display list"
        "display current"
        "network status"
        "network list"
        "wifi status"
        "wifi list"
        "bluetooth status"
        "bluetooth list"
        "sound current"
        "sound list"
        "media status"
        "system status"
        "system battery"
        "multiboot status"
        "recovery status"
        "bootorder status"
        "secureboot status"
        "ipc status"
        "ipc path"
        "ipc call status"
      ];

      cliReadRules = map (command: allow "shell" ("ojuny-agent-cli " + command + "*")) cliRead;
      ojunyReadRules = map (command: allow "shell" ("ojuny " + command + "*")) ojunyRead;

      readOnlyShell = [
        (allow "shell" "git status*")
        (allow "shell" "git diff*")
        (allow "shell" "git log*")
        (allow "shell" "git show*")
        (allow "shell" "git branch*")
        (allow "shell" "git remote*")
        (allow "shell" "git rev-parse*")
        (allow "shell" "git ls-files*")
        (allow "shell" "git for-each-ref*")
        (allow "shell" "nix flake metadata*")
        (allow "shell" "nix flake show*")
        (allow "shell" "ojuny-patches list*")
        (allow "shell" "ojuny-patches info*")
        (allow "shell" "ojuny-patches repo list*")
        (allow "shell" "systemctl status*")
        (allow "shell" "systemctl --failed*")
        (allow "shell" "systemctl list-units*")
        (allow "shell" "systemctl is-active*")
        (allow "shell" "systemctl is-enabled*")
      ];

      agentShell = [
        (ask "shell" "*")
      ]
      ++ dangerousShell
      ++ [
        (if cfg.runtimeActions then ask "shell" "ojuny *" else deny "shell" "ojuny *")
        (ask "shell" "ojuny-agent-cli *")
        (ask "shell" "ojuny-agent-cli sync*")
        (ask "shell" "ojuny-agent-cli revert*")
        (ask "shell" "ojuny-agent-cli lock*")
      ]
      ++ cliReadRules
      ++ ojunyReadRules
      ++ readOnlyShell;

      assistShell = [
        (deny "shell" "*")
      ]
      ++ dangerousShell
      ++ networkShell
      ++ [
        (deny "shell" "ojuny *")
        (deny "shell" "ojuny-agent-cli sync*")
        (deny "shell" "ojuny-agent-cli revert*")
        (deny "shell" "ojuny-agent-cli lock*")
      ]
      ++ cliReadRules
      ++ ojunyReadRules
      ++ readOnlyShell;

      agentPermissions =
        readRules
        ++ editRules
        ++ agentShell
        ++ [
          (ask "webfetch" "*")
          (ask "websearch" "*")
        ];

      assistPermissions =
        readRules
        ++ lib.concatMap (action: [ (deny action "*") ]) fileActions
        ++ assistShell
        ++ [
          (deny "webfetch" "*")
          (deny "websearch" "*")
        ];

      cliSource = pkgs.writeTextFile {
        name = "ojuny-agent-cli-source";
        destination = "/bin/ojuny-agent-cli";
        executable = true;
        text = ''
          #!${pkgs.python3}/bin/python3
          """Read-only inspection and flake-safe maintenance for Ojuny agents."""

          import datetime
          import json
          import os
          import re
          import shutil
          import socket
          import subprocess
          import sys
          from pathlib import Path

          VERSION = "1"
          EXIT_USAGE = 2
          EXIT_DEPENDENCY = 3
          EXIT_BACKEND = 4
          EXIT_VALIDATION = 5
          EXIT_CONFLICT = 6

          INDENTED_OPEN = chr(39) * 2
          INDENTED_ESCAPE = chr(39) * 3

          GUIDE = ${builtins.toJSON guide}
          DEFAULT_FLAKE = ${builtins.toJSON flakeRoot}

          PROGRAM = "ojuny-agent-cli"
          OPTIONS = {"flake": None, "host": None, "json": False, "yes": False, "dry_run": False}

          DOCS = [
              "README.md",
              "AGENTS.md",
              "docs/02-settings-menu.md",
              "docs/05-settings-gui-limitations.md",
              "docs/03-host-setup.md",
              "docs/07-lifecycle.md",
              "docs/module-tree.md",
              "docs/11-agent.md",
          ]


          class CliError(Exception):
              def __init__(self, code, message, hint=None):
                  self.code = code
                  self.message = message
                  self.hint = hint


          def die(code, message, hint=None):
              raise CliError(code, message, hint)


          def have(name):
              return shutil.which(name) is not None


          def run(cmd, cwd=None):
              return subprocess.run(
                  cmd,
                  cwd=str(cwd) if cwd else None,
                  text=True,
                  capture_output=True,
                  check=False,
              )


          def run_out(cmd, cwd=None):
              result = run(cmd, cwd=cwd)
              return result.stdout.strip() if result.returncode == 0 else ""


          def git(flake, *args):
              return run(["git", "-C", str(flake), *args])


          def parse_global(argv):
              positional = []
              index = 0
              while index < len(argv):
                  arg = argv[index]
                  if arg in ("-h", "--help"):
                      positional.append("help")
                      index += 1
                  elif arg in ("-V", "--version"):
                      positional.append("version")
                      index += 1
                  elif arg == "--flake":
                      if index + 1 >= len(argv):
                          die(EXIT_USAGE, "--flake needs a path")
                      OPTIONS["flake"] = argv[index + 1]
                      index += 2
                  elif arg == "--host":
                      if index + 1 >= len(argv):
                          die(EXIT_USAGE, "--host needs a name")
                      OPTIONS["host"] = argv[index + 1]
                      index += 2
                  elif arg == "--json":
                      OPTIONS["json"] = True
                      index += 1
                  elif arg in ("--yes", "-y"):
                      OPTIONS["yes"] = True
                      index += 1
                  elif arg == "--dry-run":
                      OPTIONS["dry_run"] = True
                      index += 1
                  else:
                      positional.append(arg)
                      index += 1
              return positional


          def emit(command, data, human):
              if OPTIONS["json"]:
                  payload = {"schema": 1, "command": command, "ok": True, "data": data, "meta": {}}
                  print(json.dumps(payload, indent=2))
              else:
                  human(data)


          def fail(command, error):
              if OPTIONS["json"]:
                  payload = {
                      "schema": 1,
                      "command": command,
                      "ok": False,
                      "error": {"code": error.code, "message": error.message, "hint": error.hint},
                      "meta": {},
                  }
                  print(json.dumps(payload, indent=2))
              else:
                  print(f"{PROGRAM}: {error.message}", file=sys.stderr)
                  if error.hint:
                      print(error.hint, file=sys.stderr)
              sys.exit(error.code)


          def require_yes(action):
              if not OPTIONS["yes"]:
                  die(EXIT_USAGE, action + " requires --yes", "The approval flag makes the mutation explicit.")


          def config_flake():
              base = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
              path = base / "nix-settings-gui" / "config.json"
              if not path.is_file():
                  return None
              try:
                  data = json.loads(path.read_text())
              except (OSError, ValueError):
                  return None
              value = data.get("flake_path")
              if isinstance(value, str) and value.strip():
                  return Path(value).expanduser()
              return None


          def current_git_root():
              result = run(["git", "rev-parse", "--show-toplevel"])
              return Path(result.stdout.strip()) if result.returncode == 0 else None


          def resolve_flake(mutable=False):
              explicit = OPTIONS["flake"]
              if mutable and explicit:
                  die(
                      EXIT_USAGE,
                      "mutating commands do not accept --flake",
                      "The CLI only mutates the configured ojuny flake.",
                  )
              candidates = []
              if explicit:
                  candidates.append(Path(explicit))
              env = os.environ.get("OJUNY_FLAKE")
              if env:
                  candidates.append(Path(env).expanduser())
              configured = config_flake()
              if configured:
                  candidates.append(configured)
              if not mutable:
                  root = current_git_root()
                  if root:
                      candidates.append(root)
              candidates.append(Path(DEFAULT_FLAKE).expanduser())
              for candidate in candidates:
                  try:
                      path = candidate.expanduser().resolve()
                  except OSError:
                      continue
                  if (path / "flake.nix").is_file():
                      return path
              die(
                  EXIT_VALIDATION,
                  "cannot find the ojuny flake",
                  "Set OJUNY_FLAKE or the flake path in nix-settings-gui.",
              )


          def resolve_host():
              if OPTIONS["host"]:
                  return OPTIONS["host"]
              env = os.environ.get("OJUNY_HOST")
              if env:
                  return env
              return socket.gethostname().split(".")[0]


          def menu_block(path):
              try:
                  text = path.read_text(errors="replace")
              except OSError:
                  return None
              match = re.search(r"/\*\s*@menu(.*?)\*/", text, re.S)
              return match.group(1) if match else None


          def parse_menu(path, flake):
              block = menu_block(path)
              if block is None:
                  return None
              page = {}
              for key in ("displayname", "category", "description", "icon"):
                  found = re.search(r'\b' + key + r'\s*=\s*"([^"]*)"', block)
                  if found:
                      page[key] = found.group(1)
              found = re.search(r"\border\s*=\s*(-?\d+)", block)
              page["order"] = int(found.group(1)) if found else 0
              page["file"] = str(path.relative_to(flake))
              page["absolute"] = str(path)
              return page


          def find_menus(flake):
              root = flake / "modules"
              if not root.is_dir():
                  return []
              pages = []
              for path in sorted(root.rglob("*.nix")):
                  relative = path.relative_to(root)
                  if path.name.startswith("_"):
                      continue
                  if any(part.startswith(".") for part in relative.parts):
                      continue
                  page = parse_menu(path, flake)
                  if page is not None:
                      pages.append(page)
              pages.sort(key=lambda page: (page.get("category", ""), page.get("order", 0), page.get("displayname", "")))
              return pages


          def find_page(flake, query):
              lowered = query.lower()
              matches = []
              for page in find_menus(flake):
                  name = page.get("displayname", "").lower()
                  stem = Path(page["file"]).stem.lower()
                  if lowered in name or lowered in stem or lowered in page["file"].lower():
                      matches.append(page)
              exact = [
                  page
                  for page in matches
                  if page.get("displayname", "").lower() == lowered or Path(page["file"]).stem.lower() == lowered
              ]
              return exact if len(exact) == 1 else matches


          def nix_comments(text):
              index = 0
              line = 1
              length = len(text)
              while index < length:
                  char = text[index]
                  if char == "#":
                      start_line = line
                      start = index + 1
                      index = text.find("\n", start)
                      if index == -1:
                          index = length
                      yield start_line, line, text[start:index]
                      continue
                  if text.startswith("/*", index):
                      start_line = line
                      start = index + 2
                      depth = 1
                      index = start
                      while index < length and depth:
                          if text.startswith("/*", index):
                              depth += 1
                              index += 2
                          elif text.startswith("*/", index):
                              depth -= 1
                              index += 2
                          else:
                              if text[index] == "\n":
                                  line += 1
                              index += 1
                      yield start_line, line, text[start:index - 2]
                      continue
                  if text.startswith(INDENTED_OPEN, index):
                      index += 2
                      while index < length:
                          if text.startswith(INDENTED_ESCAPE, index) or text.startswith(
                              INDENTED_OPEN + "$", index
                          ):
                              index += 3
                              continue
                          if text.startswith(INDENTED_OPEN, index):
                              index += 2
                              break
                          if text[index] == "\n":
                              line += 1
                          index += 1
                      continue
                  if char == '"':
                      index += 1
                      while index < length:
                          if text[index] == "\\":
                              index += 2
                              continue
                          if text[index] == '"':
                              index += 1
                              break
                          if text[index] == "\n":
                              line += 1
                          index += 1
                      continue
                  if char == "\n":
                      line += 1
                  index += 1


          def option_rows(path):
              try:
                  text = path.read_text(errors="replace")
              except OSError:
                  return []
              lines = text.splitlines()
              rows = []
              for start_line, end_line, body in nix_comments(text):
                  if not any(item.strip().startswith("@option") for item in body.splitlines()):
                      continue
                  cursor = end_line
                  while cursor < len(lines) and not lines[cursor].strip():
                      cursor += 1
                  assignment = lines[cursor].strip() if cursor < len(lines) else ""
                  rows.append(
                      {"line": start_line, "annotation": body.strip(), "assignment": assignment}
                  )
              return rows


          def git_status(flake):
              branch = run_out(["git", "-C", str(flake), "rev-parse", "--abbrev-ref", "HEAD"])
              dirty = bool(run_out(["git", "-C", str(flake), "status", "--porcelain"]))
              upstream = run_out(
                  ["git", "-C", str(flake), "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"]
              )
              ahead = None
              behind = None
              if upstream:
                  counts = run_out(
                      ["git", "-C", str(flake), "rev-list", "--left-right", "--count", "HEAD...@{u}"]
                  ).split()
                  if len(counts) == 2:
                      ahead = int(counts[0])
                      behind = int(counts[1])
              merge = run(["git", "-C", str(flake), "rev-parse", "-q", "--verify", "MERGE_HEAD"]).returncode == 0
              return {
                  "branch": branch or None,
                  "dirty": dirty,
                  "upstream": upstream or None,
                  "ahead": ahead,
                  "behind": behind,
                  "merge_in_progress": merge,
              }


          def opencode_agents():
              base = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "opencode"
              text = ""
              for name in ("opencode.json", "opencode.jsonc"):
                  path = base / name
                  if path.is_file():
                      try:
                          text += path.read_text(errors="replace")
                      except OSError:
                          pass
              return {"ojuny-agent": "ojuny-agent" in text, "ojuny-assist": "ojuny-assist" in text}


          def status_data(flake, host):
              patches_dir = flake / "modules" / "patches"
              patches = [path.stem for path in sorted(patches_dir.glob("patch-*.nix"))] if patches_dir.is_dir() else []
              failed = []
              if have("systemctl"):
                  failed = [line for line in run_out(["systemctl", "--failed", "--no-legend", "--plain"]).splitlines() if line]
              generation = None
              if os.path.islink("/run/current-system"):
                  generation = os.readlink("/run/current-system")
              return {
                  "flake": str(flake),
                  "host": host,
                  "nixos_version": run_out(["nixos-version"]) if have("nixos-version") else None,
                  "generation": generation,
                  "failed_units": failed,
                  "git": git_status(flake),
                  "opencode": opencode_agents(),
                  "patches": patches,
              }


          def print_status(data):
              print("flake: " + data["flake"])
              print("host: " + data["host"])
              print("nixos: " + str(data["nixos_version"]))
              print("generation: " + str(data["generation"]))
              print("failed units: " + (", ".join(data["failed_units"]) if data["failed_units"] else "none"))
              git_data = data["git"]
              print("branch: " + str(git_data["branch"]))
              print("upstream: " + str(git_data["upstream"]))
              print("dirty: " + str(git_data["dirty"]))
              print("ahead: " + str(git_data["ahead"]))
              print("behind: " + str(git_data["behind"]))
              print("agents configured: " + json.dumps(data["opencode"], sort_keys=True))
              print("patches: " + (", ".join(data["patches"]) if data["patches"] else "none"))


          def docs_data(flake):
              rows = []
              for relative in DOCS:
                  path = flake / relative
                  rows.append({"path": relative, "absolute": str(path), "present": path.is_file()})
              return rows


          def print_docs(rows):
              for row in rows:
                  state = "present" if row["present"] else "missing"
                  print(f"{state:8} {row['absolute']}")


          def print_pages(pages):
              if not pages:
                  print("no settings pages found")
                  return
              print(f"{'page':28} {'category':14} {'order':5} file")
              for page in pages:
                  print(
                      f'{page.get("displayname", ""):28} {page.get("category", ""):14} '
                      f'{str(page.get("order", 0)):5} {page["file"]}'
                  )


          def print_page(detail):
              page = detail["page"]
              print("file: " + page["absolute"])
              print("page: " + page.get("displayname", ""))
              print("category: " + page.get("category", ""))
              print("order: " + str(page.get("order", 0)))
              print("description: " + page.get("description", ""))
              print("options:")
              for row in detail["options"]:
                  print(f"  {row['line']}: {row['annotation']}")
                  if row["assignment"]:
                      print("      " + row["assignment"])


          def registry_metadata(patch_id):
              cache = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "ojuny" / "patches"
              if not cache.is_dir():
                  return None
              for path in sorted(cache.glob("*/" + patch_id + "/metadata.md")):
                  return path
              return None


          def parse_metadata(path):
              fields = {}
              if path is None or not path.is_file():
                  return fields
              for line in path.read_text(errors="replace").splitlines():
                  match = re.match(r"^(name|id|description|dependencies|version):\s*(.*)$", line)
                  if match:
                      fields[match.group(1)] = match.group(2).strip()
              return fields


          def patch_rows(flake):
              directory = flake / "modules" / "patches"
              rows = []
              if not directory.is_dir():
                  return rows
              for path in sorted(directory.glob("patch-*.nix")):
                  patch_id = path.stem
                  metadata_path = registry_metadata(patch_id)
                  metadata = parse_metadata(metadata_path)
                  rows.append(
                      {
                          "id": patch_id,
                          "file": str(path.relative_to(flake)),
                          "absolute": str(path),
                          "name": metadata.get("name", ""),
                          "version": metadata.get("version", ""),
                          "dependencies": metadata.get("dependencies", ""),
                          "description": metadata.get("description", ""),
                          "metadata": str(metadata_path) if metadata_path else None,
                      }
                  )
              return rows


          def print_patches(rows):
              if not rows:
                  print("no patches installed")
                  return
              for row in rows:
                  print(row["id"])
                  print("  file: " + row["file"])
                  print("  name: " + row["name"])
                  print("  version: " + row["version"])
                  print("  dependencies: " + (row["dependencies"] or "none"))
                  print("  metadata: " + str(row["metadata"]))
                  if row["description"]:
                      print("  description: " + row["description"])


          def capture(cmd, cwd=None):
              if not have(cmd[0]):
                  return {"available": False, "exit": None, "output": "missing command: " + cmd[0]}
              result = run(cmd, cwd=cwd)
              return {
                  "available": True,
                  "exit": result.returncode,
                  "output": (result.stdout + result.stderr).strip(),
              }


          def diagnose_data(flake):
              return {
                  "system": capture(["nixos-version"]),
                  "kernel": capture(["uname", "-a"]),
                  "failed_units": capture(["systemctl", "--failed", "--no-legend", "--plain"]),
                  "errors": capture(["bash", "-c", "journalctl -p err -b --no-pager 2>/dev/null | tail -100"]),
                  "memory": capture(["free", "-h"]),
                  "disks": capture(["df", "-h", "/", "/home"]),
                  "graphics": capture(
                      ["bash", "-c", 'lspci -k 2>/dev/null | grep -A3 -E "VGA|3D|Display" || true']
                  ),
                  "flake": capture(["nix", "flake", "metadata", "--json", str(flake)]),
              }


          def print_diagnose(data):
              for name, result in data.items():
                  print("## " + name)
                  if not result["available"]:
                      print(result["output"])
                  else:
                      print(result["output"] or "no output")
                  print()


          def diff_data(flake):
              return {
                  "status": run_out(["git", "-C", str(flake), "status", "--short"]),
                  "stat": run_out(["git", "-C", str(flake), "--no-pager", "diff", "--stat"]),
                  "diff": run_out(["git", "-C", str(flake), "--no-pager", "diff"]),
              }


          def print_diff(data):
              if data["status"]:
                  print("## status")
                  print(data["status"])
              if data["stat"]:
                  print("## stat")
                  print(data["stat"])
              if data["diff"]:
                  print("## diff")
                  print(data["diff"])
              if not any(data.values()):
                  print("no changes")


          def changed_nix(flake):
              files = set()
              commands = [
                  ["git", "-C", str(flake), "diff", "--name-only", "--diff-filter=ACMR"],
                  ["git", "-C", str(flake), "ls-files", "--others", "--exclude-standard"],
              ]
              for command in commands:
                  for line in run_out(command).splitlines():
                      if line.endswith(".nix"):
                          files.add(line)
              return sorted(files)


          def check(name, cmd, cwd=None):
              if not have(cmd[0]):
                  return {"name": name, "ok": False, "output": "missing command: " + cmd[0]}
              result = run(cmd, cwd=cwd)
              return {
                  "name": name,
                  "ok": result.returncode == 0,
                  "output": (result.stdout + result.stderr).strip(),
              }


          def validate_data(flake, host):
              checks = [check("diff-check", ["git", "-C", str(flake), "diff", "--check"])]
              for relative in changed_nix(flake):
                  path = flake / relative
                  checks.append(check("parse:" + relative, ["nix-instantiate", "--parse", str(path)]))
                  checks.append(check("format:" + relative, ["nixfmt", "--check", str(path)]))
              baseline = flake / "scripts" / "check-baseline.sh"
              if baseline.is_file():
                  checks.append(check("baseline", ["sh", "scripts/check-baseline.sh"], cwd=flake))
              else:
                  checks.append(check("flake-check", ["nix", "flake", "check", "--no-build"], cwd=flake))
              if host:
                  checks.append(
                      check(
                          "host-eval",
                          [
                              "nix",
                              "eval",
                              "--raw",
                              "path:" + str(flake) + "#nixosConfigurations." + host + ".config.system.build.toplevel.drvPath",
                          ],
                          cwd=flake,
                      )
                  )
              return {
                  "ok": all(item["ok"] for item in checks),
                  "checks": checks,
                  "flake": str(flake),
                  "host": host,
              }


          def print_validate(data):
              for item in data["checks"]:
                  state = "PASS" if item["ok"] else "FAIL"
                  print(state + " " + item["name"])
                  if not item["ok"] and item["output"]:
                      print(item["output"])
                      print()
              print("result: " + ("pass" if data["ok"] else "fail"))


          def backup_refs(flake):
              result = run(
                  ["git", "-C", str(flake), "for-each-ref", "--format=%(refname:short) %(objectname:short)", "refs/ojuny-agent/backup"]
              )
              return [line for line in result.stdout.splitlines() if line]


          def assert_clean(flake):
              if run_out(["git", "-C", str(flake), "status", "--porcelain"]):
                  die(
                      EXIT_CONFLICT,
                      "the flake worktree is not clean",
                      "Commit or stash your changes before syncing.",
                  )


          def upstream_ref(flake):
              upstream = run_out(
                  ["git", "-C", str(flake), "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"]
              )
              if not upstream:
                  die(EXIT_VALIDATION, "the current branch has no upstream", "Set an upstream branch first.")
              return upstream


          def make_backup(flake):
              stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
              ref = "refs/ojuny-agent/backup/" + stamp
              result = git(flake, "update-ref", ref, "HEAD")
              if result.returncode != 0:
                  die(EXIT_BACKEND, "could not create the backup ref", result.stderr.strip())
              return ref


          def sync_status_data(flake):
              data = git_status(flake)
              data["backups"] = backup_refs(flake)
              return data


          def sync_prepare(flake):
              assert_clean(flake)
              upstream = upstream_ref(flake)
              fetched = git(flake, "fetch", "--prune")
              if fetched.returncode != 0:
                  die(EXIT_BACKEND, "git fetch failed", fetched.stderr.strip())
              counts = run_out(
                  ["git", "-C", str(flake), "rev-list", "--left-right", "--count", "HEAD..." + upstream]
              ).split()
              ahead = int(counts[0]) if len(counts) == 2 else 0
              behind = int(counts[1]) if len(counts) == 2 else 0
              if behind == 0:
                  return {"status": "up-to-date", "ahead": ahead, "behind": behind, "backup": None}
              backup = make_backup(flake)
              if ahead == 0:
                  merged = git(flake, "merge", "--ff-only", upstream)
                  if merged.returncode != 0:
                      die(EXIT_BACKEND, "fast-forward failed", merged.stderr.strip())
                  validation = validate_data(flake, resolve_host())
                  if not validation["ok"]:
                      die(EXIT_VALIDATION, "validation failed after fast-forward", "Backup ref: " + backup)
                  return {
                      "status": "fast-forwarded",
                      "ahead": ahead,
                      "behind": behind,
                      "backup": backup,
                      "validation": validation,
                  }
              merged = git(flake, "merge", "--no-commit", "--no-ff", upstream)
              conflicts = run_out(
                  ["git", "-C", str(flake), "diff", "--name-only", "--diff-filter=U"]
              ).splitlines()
              if merged.returncode != 0 or conflicts:
                  return {
                      "status": "conflicts",
                      "ahead": ahead,
                      "behind": behind,
                      "backup": backup,
                      "conflicts": conflicts,
                  }
              validation = validate_data(flake, resolve_host())
              if not validation["ok"]:
                  git(flake, "merge", "--abort")
                  die(EXIT_VALIDATION, "validation failed; merge aborted", "Backup ref: " + backup)
              return {
                  "status": "merge-prepared",
                  "ahead": ahead,
                  "behind": behind,
                  "backup": backup,
                  "validation": validation,
              }


          def sync_continue(flake):
              if git(flake, "rev-parse", "-q", "--verify", "MERGE_HEAD").returncode != 0:
                  die(EXIT_CONFLICT, "no merge is in progress")
              conflicts = run_out(
                  ["git", "-C", str(flake), "diff", "--name-only", "--diff-filter=U"]
              ).splitlines()
              if conflicts:
                  die(EXIT_CONFLICT, "unresolved conflicts remain", "\n".join(conflicts))
              validation = validate_data(flake, resolve_host())
              if not validation["ok"]:
                  die(EXIT_VALIDATION, "validation failed; merge left in progress", "Fix the checks or run sync --abort.")
              committed = git(flake, "commit", "--no-edit")
              if committed.returncode != 0:
                  die(EXIT_BACKEND, "merge commit failed", committed.stderr.strip())
              return {"status": "merged", "validation": validation}


          def sync_abort(flake):
              if git(flake, "rev-parse", "-q", "--verify", "MERGE_HEAD").returncode == 0:
                  aborted = git(flake, "merge", "--abort")
                  if aborted.returncode != 0:
                      die(EXIT_BACKEND, "merge abort failed", aborted.stderr.strip())
                  return {"status": "aborted", "backups": backup_refs(flake)}
              return {"status": "no-merge", "backups": backup_refs(flake)}


          def lock_flake(flake):
              locked = run(["nix", "flake", "lock"], cwd=flake)
              if locked.returncode != 0:
                  die(EXIT_BACKEND, "nix flake lock failed", locked.stderr.strip())
              validation = validate_data(flake, resolve_host())
              if not validation["ok"]:
                  die(EXIT_VALIDATION, "validation failed after lock", "Review the lock change.")
              return {"status": "locked", "validation": validation}


          def inside_flake(flake, path):
              try:
                  resolved = path.resolve()
              except OSError:
                  die(EXIT_USAGE, "cannot resolve path: " + str(path))
              try:
                  resolved.relative_to(flake)
              except ValueError:
                  die(EXIT_VALIDATION, "path is outside the ojuny flake: " + str(path))
              return resolved


          def revert_path(flake, target):
              candidate = Path(target)
              path = inside_flake(flake, candidate if candidate.is_absolute() else Path.cwd() / candidate)
              relative = str(path.relative_to(flake))
              tracked = git(flake, "ls-files", "--error-unmatch", "--", relative).returncode == 0
              if tracked:
                  result = git(flake, "restore", "--source=HEAD", "--worktree", "--", relative)
              else:
                  result = run(["rm", "--", str(path)])
              if result.returncode != 0:
                  die(EXIT_BACKEND, "revert failed", (result.stderr or result.stdout).strip())
              return {"status": "reverted", "path": relative, "tracked": tracked}


          def revert_all(flake):
              result = git(flake, "restore", "--source=HEAD", "--worktree", "--", ".")
              if result.returncode != 0:
                  die(EXIT_BACKEND, "revert failed", result.stderr.strip())
              return {"status": "reverted-all", "status_short": run_out(["git", "-C", str(flake), "status", "--short"])}


          def print_sync(data):
              for key, value in data.items():
                  if key == "validation":
                      print("validation: " + ("pass" if value["ok"] else "fail"))
                  elif key == "conflicts":
                      print("conflicts:")
                      for item in value:
                          print("  " + item)
                  else:
                      print(key + ": " + str(value))


          def print_help():
              print(
                  "usage: ojuny-agent-cli [--flake PATH] [--host NAME] [--json] [--yes] COMMAND ...\n"
                  "\n"
                  "Read-only commands:\n"
                  "  guide                     Print the Ojuny agent guide\n"
                  "  status                    Show flake and system status\n"
                  "  settings list             List settings pages\n"
                  "  settings show <page>      Show a settings page and its options\n"
                  "  patches list              List installed patches\n"
                  "  patches show <id>         Show one installed patch\n"
                  "  diagnose                  Run fixed read-only diagnostics\n"
                  "  docs                      Show governing document paths\n"
                  "  diff                      Show the flake worktree diff\n"
                  "  validate                  Validate the flake worktree\n"
                  "  sync --status             Show git sync state\n"
                  "  sync --dry-run            Print the planned sync commands\n"
                  "\n"
                  "Mutating commands, all requiring --yes:\n"
                  "  sync                      Fetch and prepare a fast-forward or merge\n"
                  "  sync --continue           Validate and commit a prepared merge\n"
                  "  sync --abort              Abort an in-progress merge\n"
                  "  revert <path>             Revert one path inside the flake\n"
                  "  revert --all              Revert tracked changes inside the flake\n"
                  "  lock                      Regenerate flake.lock and validate\n"
                  "\n"
                  "Mutating commands never accept --flake and always use the configured Ojuny flake."
              )


          def command_guide(flake):
              emit("guide", {"guide": GUIDE}, lambda data: print(data["guide"]))


          def command_status(flake, host):
              emit("status", status_data(flake, host), print_status)


          def command_settings(flake, args):
              subcommand = args[0] if args else "list"
              if subcommand == "list":
                  pages = find_menus(flake)
                  emit("settings.list", {"pages": pages}, lambda data: print_pages(data["pages"]))
                  return
              if subcommand == "show":
                  if len(args) < 2:
                      die(EXIT_USAGE, "settings show needs a page name")
                  matches = find_page(flake, args[1])
                  if not matches:
                      die(EXIT_VALIDATION, "settings page not found: " + args[1])
                  if len(matches) > 1:
                      die(
                          EXIT_USAGE,
                          "multiple settings pages match: " + args[1],
                          "\n".join(page["file"] for page in matches),
                      )
                  page = matches[0]
                  options = option_rows(flake / page["file"])
                  emit(
                      "settings.show",
                      {"page": page, "options": options},
                      print_page,
                  )
                  return
              die(EXIT_USAGE, "unknown settings command: " + subcommand)


          def command_patches(flake, args):
              subcommand = args[0] if args else "list"
              rows = patch_rows(flake)
              if subcommand == "list":
                  emit("patches.list", {"patches": rows}, lambda data: print_patches(data["patches"]))
                  return
              if subcommand == "show":
                  if len(args) < 2:
                      die(EXIT_USAGE, "patches show needs a patch id")
                  selected = [row for row in rows if row["id"] == args[1]]
                  if not selected:
                      die(EXIT_VALIDATION, "patch is not installed: " + args[1])
                  row = selected[0]
                  details = dict(row)
                  details["options"] = option_rows(Path(row["absolute"]))
                  emit(
                      "patches.show",
                      details,
                      lambda data: (
                          print_patches([data]),
                          print("options:"),
                          [print(f"  {item['line']}: {item['annotation']}") for item in data["options"]],
                      ),
                  )
                  return
              die(EXIT_USAGE, "unknown patches command: " + subcommand)


          def command_docs(flake):
              emit("docs", {"documents": docs_data(flake)}, lambda data: print_docs(data["documents"]))


          def command_diagnose(flake):
              emit("diagnose", diagnose_data(flake), print_diagnose)


          def command_diff(flake):
              emit("diff", diff_data(flake), print_diff)


          def command_validate(flake, host):
              data = validate_data(flake, host)
              emit("validate", data, print_validate)
              if not data["ok"]:
                  sys.exit(EXIT_VALIDATION)


          def command_sync(flake, args):
              flags = set(args)
              if "--status" in flags and ("--continue" in flags or "--abort" in flags):
                  die(EXIT_USAGE, "choose one of --status, --continue, or --abort")
              if "--continue" in flags and "--abort" in flags:
                  die(EXIT_USAGE, "choose one of --continue or --abort")
              if "--status" in flags:
                  emit("sync.status", sync_status_data(flake), print_sync)
                  return
              if OPTIONS["dry_run"] and ("--abort" in flags or "--continue" in flags):
                  emit(
                      "sync.dry-run",
                      {"status": "dry-run", "action": sorted(flags)},
                      print_sync,
                  )
                  return
              if "--abort" in flags:
                  require_yes("sync --abort")
                  emit("sync.abort", sync_abort(flake), print_sync)
                  return
              if "--continue" in flags:
                  require_yes("sync --continue")
                  emit("sync.continue", sync_continue(flake), print_sync)
                  return
              if OPTIONS["dry_run"]:
                  data = sync_status_data(flake)
                  data["planned"] = [
                      "git fetch --prune",
                      "git merge --ff-only @{u} when no local commits exist",
                      "git merge --no-commit --no-ff @{u} when local commits exist",
                      "validate after the fast-forward, or before sync --continue",
                  ]
                  emit("sync.dry-run", data, print_sync)
                  return
              require_yes("sync")
              data = sync_prepare(flake)
              emit("sync", data, print_sync)
              if data["status"] == "conflicts":
                  sys.exit(EXIT_CONFLICT)


          def command_revert(flake, args):
              if OPTIONS["dry_run"]:
                  emit("revert.dry-run", {"status": "dry-run", "args": args}, print_sync)
                  return
              require_yes("revert")
              if "--all" in args:
                  emit("revert.all", revert_all(flake), print_sync)
                  return
              if not args:
                  die(EXIT_USAGE, "revert needs a path or --all")
              emit("revert", revert_path(flake, args[0]), print_sync)


          def command_lock(flake):
              if OPTIONS["dry_run"]:
                  emit("lock.dry-run", {"status": "dry-run"}, print_sync)
                  return
              require_yes("lock")
              emit("lock", lock_flake(flake), print_sync)


          def main(argv):
              try:
                  positional = parse_global(argv)
              except CliError as error:
                  fail("cli", error)
              if not positional:
                  print_help()
                  return 0
              command = positional[0]
              args = positional[1:]
              if command in ("help", "-h", "--help"):
                  print_help()
                  return 0
              if command in ("version", "-V", "--version"):
                  print(VERSION)
                  return 0
              mutable = command in ("sync", "revert", "lock")
              try:
                  flake = resolve_flake(mutable=mutable)
                  host = resolve_host()
                  if command == "guide":
                      command_guide(flake)
                  elif command == "status":
                      command_status(flake, host)
                  elif command == "settings":
                      command_settings(flake, args)
                  elif command == "patches":
                      command_patches(flake, args)
                  elif command == "docs":
                      command_docs(flake)
                  elif command == "diagnose":
                      command_diagnose(flake)
                  elif command == "diff":
                      command_diff(flake)
                  elif command == "validate":
                      command_validate(flake, host)
                  elif command == "sync":
                      command_sync(flake, args)
                  elif command == "revert":
                      command_revert(flake, args)
                  elif command == "lock":
                      command_lock(flake)
                  else:
                      die(EXIT_USAGE, "unknown command: " + command)
              except CliError as error:
                  fail(command, error)
              return 0


          if __name__ == "__main__":
              sys.exit(main(sys.argv[1:]))
        '';
      };

      cli =
        pkgs.runCommandLocal "ojuny-agent-cli"
          {
            nativeBuildInputs = [ pkgs.python3 ];
          }
          ''
            install -Dm755 ${cliSource}/bin/ojuny-agent-cli $out/bin/ojuny-agent-cli
            python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' $out/bin/ojuny-agent-cli
          '';
    in
    {
      config = lib.mkIf active {
        home.packages = [
          cli
          pkgs.git
          pkgs.nixfmt
          pkgs.pciutils
          pkgs.procps
        ];

        programs.opencode = {
          enable = true;
          settings = {
            agents = {
              "ojuny-agent" = {
                description = "Maintain the Ojuny flake with approval-gated edits, validation, and flake-only git sync.";
                mode = "primary";
                steps = 24;
                system = agentPrompt;
                permissions = agentPermissions;
              };
              "ojuny-assist" = {
                description = "Explain Ojuny, its settings menu, and its patches without editing anything.";
                mode = "primary";
                steps = 12;
                system = assistPrompt;
                permissions = assistPermissions;
              };
            };
          };
        };
      };
    };
}
