#!/usr/bin/env bash
# Regression check for the patch-development project picker.
#
# Extracts the projects script from the module, stubs dms, nix, the terminal and
# the agent on PATH, and asserts repository discovery, action gating, devshell
# execution, terminal hosting, agent TTY state and Obsidian vault handling.
# Needs no nix evaluation and no running DMS shell.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_file="$repo_root/modules/patches/patch-development.nix"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  if [ -n "${XDG_LOG:-}" ]; then
    for log in "$DMS_LOG" "$NIX_LOG" "$TERMINAL_LOG" "$AGENT_LOG" "$EDITOR_LOG" "$OBSIDIAN_LOG" "$XDG_LOG"; do
      printf -- '--- %s\n' "$log" >&2
      cat "$log" >&2
    done
  fi
  exit 1
}

mapfile -t lines < "$source_file"
start=-1
end=-1
for i in "${!lines[@]}"; do
  if [[ "${lines[$i]}" == *'writeShellScriptBin "projects" '* ]]; then
    start=$i
  elif (( start >= 0 )) && [[ "${lines[$i]}" == "      '';" ]]; then
    end=$i
    break
  fi
done
(( start >= 0 && end > start )) || fail "could not locate the projects script in $source_file"

body=()
skipping_path=0
for ((i = start + 1; i < end; i++)); do
  line=${lines[$i]}
  if [[ "$line" == *'export PATH=${'* ]]; then
    [[ "$line" == *'}:"$PATH"'* ]] || skipping_path=1
    continue
  fi
  if (( skipping_path )); then
    [[ "$line" == *'}:"$PATH"'* ]] && skipping_path=0
    continue
  fi
  body+=("$line")
done

script=$(printf '%s\n' "${body[@]}")
script=${script//"''\${"/'${'}
repos="$tmp/repos"
script=${script//'${cfg.projects.searchRoot}'/$repos}
script=${script//'${lib.escapeShellArg cfg.projects.editorCommand}'/editor-stub}
script=${script//'${lib.escapeShellArg cfg.projects.terminalCommand}'/ghostty}
script=${script//'${lib.escapeShellArg cfg.projects.assistantCommand}'/opencode}
script=${script//'${lib.boolToString projectsAgent}'/true}
[[ "$script" != *'${cfg.'* && "$script" != *'${lib.'* ]] || fail "unresolved Nix interpolation in the extracted script"

mkdir -p "$tmp/bin" "$tmp/empty" "$tmp/home"
mkdir -p "$repos/alpha/.git" "$repos/alpha/.obsidian"
printf '{ }\n' > "$repos/alpha/flake.nix"
mkdir -p "$repos/beta/.git"
mkdir -p "$repos/plain/.git"
mkdir -p "$repos/alpha project #1/.git" "$repos/alpha project #1/.obsidian"
mkdir -p "$repos/nested/.git" "$repos/nested/notes/.obsidian"

cat > "$tmp/bin/dms" <<STUB
#!$BASH
set -euo pipefail
cat >> "\$DMS_LOG"
if [ -n "\${PICKER_ACTION:-}" ] && grep -aqxF -- "\$PICKER_ACTION" "\$DMS_LOG"; then
  printf '%s\n' "\$PICKER_ACTION"
  exit 0
fi
printf '%s\n' "\$PICKER_REPO"
STUB

cat > "$tmp/bin/nix" <<STUB
#!$BASH
printf '%s\n' "\$*" >> "\$NIX_LOG"
if [[ "\${1:-}" == develop && "\${2:-}" == -c ]]; then
  shift 2
  "\$@"
fi
STUB

cat > "$tmp/bin/ghostty" <<STUB
#!$BASH
set -euo pipefail
printf '%s\n' "\$*" >> "\$TERMINAL_LOG"
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    --working-directory=*) shift ;;
    -e) shift; break ;;
    *) shift ;;
  esac
done
[ "\$#" -gt 0 ] || exit 0
command=\$(printf '%q ' "\$@")
exec script -qec "\$command" /dev/null
STUB

cat > "$tmp/bin/opencode" <<STUB
#!$BASH
printf 'argv=%s\n' "\$*" >> "\$AGENT_LOG"
if [ -t 0 ]; then printf 'stdin-tty=yes\n' >> "\$AGENT_LOG"; else printf 'stdin-tty=no\n' >> "\$AGENT_LOG"; fi
if [ -t 1 ]; then printf 'stdout-tty=yes\n' >> "\$AGENT_LOG"; else printf 'stdout-tty=no\n' >> "\$AGENT_LOG"; fi
printf 'controlling-tty=%s\n' "\$(ps -o tty= -p \$\$ | tr -d ' ')" >> "\$AGENT_LOG"
printf 'parent=%s\n' "\$(ps -o comm= -p \$PPID)" >> "\$AGENT_LOG"
STUB

cat > "$tmp/bin/editor-stub" <<STUB
#!$BASH
printf '%s\n' "\$*" >> "\$EDITOR_LOG"
STUB

cat > "$tmp/bin/obsidian" <<STUB
#!$BASH
printf '%s\n' "\$*" >> "\$OBSIDIAN_LOG"
STUB

cat > "$tmp/bin/xdg-open" <<STUB
#!$BASH
printf '%s\n' "\$*" >> "\$XDG_LOG"
STUB

cat > "$tmp/bin/xdg-mime" <<STUB
#!$BASH
printf '%s\n' "\$*" >> "\$XDG_LOG"
exit 1
STUB

chmod +x "$tmp/bin"/*
printf '#!%s\n%s\n' "$(command -v bash)" "$script" > "$tmp/projects"
chmod +x "$tmp/projects"

export DMS_LOG="$tmp/dms.log"
export NIX_LOG="$tmp/nix.log"
export TERMINAL_LOG="$tmp/terminal.log"
export AGENT_LOG="$tmp/agent.log"
export EDITOR_LOG="$tmp/editor.log"
export OBSIDIAN_LOG="$tmp/obsidian.log"
export XDG_LOG="$tmp/xdg.log"

reset_logs() {
  : > "$DMS_LOG"
  : > "$NIX_LOG"
  : > "$TERMINAL_LOG"
  : > "$AGENT_LOG"
  : > "$EDITOR_LOG"
  : > "$OBSIDIAN_LOG"
  : > "$XDG_LOG"
}

run_picker() {
  reset_logs
  PATH="$tmp/bin:$PATH" PICKER_ACTION="$1" PICKER_REPO="$2" "$tmp/projects"
}

wait_for_log() {
  local log="$1" pattern="$2" attempt
  for attempt in $(seq 1 50); do
    if grep -aqF -- "$pattern" "$log"; then
      return 0
    fi
    sleep 0.05
  done
  return 1
}

run_picker 'Open in editor' "$repos/alpha"

grep -aqF 'alpha  [no-git]  no commits' "$DMS_LOG" || fail "repository list is missing alpha with branch and commit metadata"
grep -aqF 'beta  [no-git]  no commits' "$DMS_LOG" || fail "repository list is missing beta with branch and commit metadata"

for action in 'Open in editor' 'Open terminal' 'Start agent' 'Open Obsidian vault' 'Cancel'; do
  grep -aqx -- "$action" "$DMS_LOG" || fail "action list is missing: $action"
done

grep -aqF 'develop -c true' "$NIX_LOG" || fail "the picker did not probe the repository devshell"
grep -aqF "develop -c editor-stub -n $repos/alpha" "$NIX_LOG" || fail "the chosen action did not run through nix develop -c"
grep -aqF -- "-n $repos/alpha" "$EDITOR_LOG" || fail "the editor was not started in the selected repository"

run_picker 'Start agent' "$repos/alpha"

grep -aqF "develop -c ghostty --working-directory=$repos/alpha -e opencode $repos/alpha" "$NIX_LOG" \
  || fail "the agent was not launched through the configured terminal"
grep -aqF -- "--working-directory=$repos/alpha -e opencode $repos/alpha" "$TERMINAL_LOG" \
  || fail "the terminal host did not receive the agent command and repository"
grep -aqx "argv=$repos/alpha" "$AGENT_LOG" || fail "the agent was not started in the selected repository"
grep -aqx 'stdin-tty=yes' "$AGENT_LOG" || fail "the agent has no stdin terminal"
grep -aqx 'stdout-tty=yes' "$AGENT_LOG" || fail "the agent has no stdout terminal"
grep -aqE '^controlling-tty=pts/[0-9]+$' "$AGENT_LOG" || fail "the agent has no controlling terminal"
if grep -aqx 'parent=projects' "$AGENT_LOG"; then
  fail "the agent is a direct child of the picker instead of the terminal"
fi

run_picker 'Open Obsidian vault' "$repos/alpha project #1"

wait_for_log "$XDG_LOG" "obsidian://open?path=$repos/alpha%20project%20%231" \
  || fail "the Obsidian URI was not fully percent-encoded"
if grep -aqF -- '--new-window' "$XDG_LOG" "$OBSIDIAN_LOG"; then
  fail "the picker used the unsupported obsidian --new-window form"
fi
if grep -aqF 'vault=' "$XDG_LOG" "$OBSIDIAN_LOG"; then
  fail "the picker used the unsupported obsidian vault= form"
fi

run_picker 'Cancel' "$repos/plain"

if grep -aqx 'Open Obsidian vault' "$DMS_LOG"; then
  fail "the picker offered the Obsidian action for a repository without a vault"
fi

run_picker 'Open Obsidian vault' "$repos/nested"

wait_for_log "$XDG_LOG" "obsidian://open?path=$repos/nested/notes" \
  || fail "the nested vault was not resolved to its own directory"

template_copy="$repo_root/../ojuny-template/modules/patches/patch-development.nix"
if [ -f "$template_copy" ]; then
  cmp -s "$source_file" "$template_copy" \
    || fail "the template pre-included copy differs from the registry module"
fi

if PATH="$tmp/empty" "$tmp/projects" >"$tmp/nodms.out" 2>&1; then
  fail "projects should refuse to start without dms"
fi
grep -qF 'dms is required' "$tmp/nodms.out" || fail "the missing-dms error was not printed"

printf 'ok: the project picker lists repositories and actions, launches the agent and editor in the devshell, and resolves and encodes Obsidian vaults\n'
