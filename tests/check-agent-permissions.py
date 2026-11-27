#!/usr/bin/env python3
"""Check the read-only, ask and deny classes in the agent patch."""

import pathlib
import re
import sys


def main():
    path = pathlib.Path(sys.argv[1])
    text = path.read_text()
    errors = []

    if text.count('(allow "webfetch" "*")') != 2:
        errors.append("webfetch must be allowed for both agents")
    if text.count('(allow "websearch" "*")') != 2:
        errors.append("websearch must be allowed for both agents")
    if '(deny "webfetch" "*")' in text:
        errors.append("webfetch must not be denied")
    if '(deny "websearch" "*")' in text:
        errors.append("websearch must not be denied")
    if '(ask "webfetch" "*")' in text:
        errors.append("webfetch must not ask")
    if '(ask "websearch" "*")' in text:
        errors.append("websearch must not ask")
    if '"scope": "configuration"' not in text:
        errors.append("agent status must be labelled as configuration")
    if "an open session keeps its stored agent" not in text:
        errors.append("agent status must explain the session switch")

    def first(needle):
        index = text.find(needle)
        if index < 0:
            errors.append(f"missing rule {needle}")
        return index

    if not re.search(r'fileRules = action: \[\s*\(ask action', text):
        errors.append("fileRules must start with an ask so the edit tool stays available")
    if '(ask action "**")' not in text:
        errors.append("fileRules must ask for the relative path form")
    file_ask = first('(ask action "${flakeRoot}/**")')
    file_lock = first('(deny action "**/flake.lock")')
    if 0 <= file_lock < file_ask:
        errors.append("generated-file denies must come after the flake ask")

    if not re.search(r'agentShell = \[\s*\(ask "shell" "\*"\)\s*\]\s*\+\+ dangerousShell', text):
        errors.append("agentShell must start with the catch-all ask")
    if not re.search(r'assistShell = \[\s*\(ask "shell" "\*"\)\s*\]\s*\+\+ dangerousShell', text):
        errors.append("assistShell must start with the catch-all ask")

    for generated in (
        "modules/07-system/00-hardware.nix",
        "modules/facter.json",
        "modules/backend/00-hardware-quirks.nix",
        "modules/01-users/01-user.nix",
        "modules/07-system/00-host.nix",
    ):
        if generated not in text:
            errors.append(f"generated file {generated} is not denied")
        if f"**/{generated}" not in text:
            errors.append(f"generated file {generated} has no relative deny")

    read_env = first('(deny "read" "*.env")')
    read_allow = first('(allow "read" "*")')
    if 0 <= read_env < read_allow:
        errors.append("readRules must allow reads before the secret denies")

    ext_ask = first('(ask "external_directory" "${flakeRoot}/*")')
    ext_deny = first('(deny "external_directory" "*")')
    if 0 <= ext_ask < ext_deny:
        errors.append("external_directory deny must come before the flake ask")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
