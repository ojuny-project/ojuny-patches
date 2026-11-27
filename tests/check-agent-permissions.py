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

    file_ask = first('(ask action "${flakeRoot}/**")')
    file_blanket = first('(deny action "*")')
    if 0 <= file_blanket < file_ask:
        errors.append("fileRules blanket deny must come after the flake ask")

    if not re.search(r"agentShell\s*=\s*dangerousShell", text):
        errors.append("agentShell must put dangerousShell before the catch-all ask")
    if not re.search(r"assistShell\s*=\s*dangerousShell", text):
        errors.append("assistShell must put dangerousShell before the catch-all ask")

    for generated in (
        "modules/07-system/00-hardware.nix",
        "modules/facter.json",
        "modules/backend/00-hardware-quirks.nix",
        "modules/01-users/01-user.nix",
        "modules/07-system/00-host.nix",
    ):
        if generated not in text:
            errors.append(f"generated file {generated} is not denied")

    read_env = first('(deny "read" "*.env")')
    read_allow = first('(allow "read" "*")')
    if 0 <= read_allow < read_env:
        errors.append("readRules must deny secrets before the blanket allow")

    ext_ask = first('(ask "external_directory" "${flakeRoot}/*")')
    ext_deny = first('(deny "external_directory" "*")')
    if 0 <= ext_deny < ext_ask:
        errors.append("external_directory ask must come before the blanket deny")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
