#!/usr/bin/env python3
"""Reject nixshell alias defaults that insert package derivations.

The alias option is a list of package names. The generator turns each name into
nixpkgs#<name>, so a `with pkgs;` scope inserts derivations and fails the option
type.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ALIAS = re.compile(r"ojuny\.apps\.nixshell\.aliases\.\"[^\"]+\"\.packages\s*=\s*with\s+(.*?);")


def main(argv: list[str]) -> int:
    source = Path(argv[1]) if len(argv) > 1 else Path("modules/patches/patch-nixshell.nix")
    if not source.is_file():
        print(f"nixshell-aliases: not a file: {source}", file=sys.stderr)
        return 2

    text = source.read_text(encoding="utf-8")
    lines = text.splitlines()
    violations = 0
    for index, line in enumerate(lines, start=1):
        match = ALIAS.search(line)
        if not match:
            continue
        scope = match.group(1).strip()
        if not scope.startswith("(builtins.mapAttrs"):
            print(f"{source}:{index}: alias packages use `with {scope};` instead of name strings", file=sys.stderr)
            violations += 1

    if violations:
        print(f"nixshell-aliases: {violations} violation(s)", file=sys.stderr)
        return 1

    print(f"nixshell-aliases: all alias defaults map package names to strings in {source.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
