#!/usr/bin/env python3
"""Run the agent CLI option scanner against a comment fixture.

The scanner must read only Nix comments. Prose and Python strings that mention
@option are not options, while a block or line comment directly above an
assignment is.
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path


def extract(source: Path) -> str:
    lines = source.read_text(encoding="utf-8").splitlines()
    start = None
    for index, line in enumerate(lines):
        if line.rstrip().endswith("text = ''"):
            start = index + 1
            break
    if start is None:
        raise SystemExit(f"option-scan: text block not found in {source}")

    end = None
    for index in range(start, len(lines)):
        if lines[index].strip() == "'';":
            end = index
            break
    if end is None:
        raise SystemExit(f"option-scan: text block end not found in {source}")

    indent = len(lines[start]) - len(lines[start].lstrip())
    script = []
    for line in lines[start:end]:
        script.append(line[indent:] if line.startswith(" " * indent) else line.lstrip())
    text = "\n".join(script) + "\n"
    text = text.replace("GUIDE = ${builtins.toJSON guide}", 'GUIDE = ""')
    text = text.replace("DEFAULT_FLAKE = ${builtins.toJSON flakeRoot}", 'DEFAULT_FLAKE = "/"')
    return text


FIXTURE = """\
/*
  @menu
  displayname = "Fixture";
*/

{
  guide = ''
    An @option comment belongs directly above the assignment it controls.
  '';

  message = "@option is not an option in a string";

  /* @option widget = "switch"; label = "Block option"; */
  blockOption = true;

  # @option widget = "switch"; label = "Line option";
  lineOption = false;
}
"""


def main(argv: list[str]) -> int:
    source = Path(argv[1]) if len(argv) > 1 else Path("modules/patches/patch-ojuny-agent.nix")
    if not source.is_file():
        print(f"option-scan: not a file: {source}")
        return 2

    text = extract(source)
    prefix = text.split('if __name__ == "__main__":', 1)[0]
    namespace: dict[str, object] = {"__name__": "option-scan"}
    exec(compile(prefix, str(source), "exec"), namespace)
    option_rows = namespace["option_rows"]

    with tempfile.TemporaryDirectory() as directory:
        fixture = Path(directory) / "page.nix"
        fixture.write_text(FIXTURE, encoding="utf-8")
        rows = option_rows(fixture)

    if len(rows) != 2:
        print(f"option-scan: expected 2 rows, got {len(rows)}: {rows}")
        return 1
    if rows[0]["line"] != 13 or rows[0]["assignment"] != "blockOption = true;":
        print(f"option-scan: block comment row is wrong: {rows[0]}")
        return 1
    if rows[1]["line"] != 16 or rows[1]["assignment"] != "lineOption = false;":
        print(f"option-scan: line comment row is wrong: {rows[1]}")
        return 1
    if not rows[0]["annotation"].startswith("@option"):
        print(f"option-scan: block annotation is wrong: {rows[0]}")
        return 1
    if "@option" not in rows[1]["annotation"]:
        print(f"option-scan: line annotation is wrong: {rows[1]}")
        return 1

    print("option-scan: prose and strings are ignored, real comments are listed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
