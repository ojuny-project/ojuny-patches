#!/usr/bin/env python3
"""Compile the embedded ojuny-agent-cli Python and reject doubled escapes.

The CLI lives inside a Nix indented string, which does not process backslash
escapes. A doubled escape reaches Python as two characters and either fails the
compile or changes a regex. This check runs the same compile gate as the build
and rejects a doubled backslash inside a raw string literal.
"""

from __future__ import annotations

import io
import sys
import tokenize
from pathlib import Path


def extract(source: Path) -> str:
    lines = source.read_text(encoding="utf-8").splitlines()
    start = None
    for index, line in enumerate(lines):
        if line.rstrip().endswith("text = ''"):
            start = index + 1
            break
    if start is None:
        raise SystemExit(f"embedded-python: text block not found in {source}")

    end = None
    for index in range(start, len(lines)):
        if lines[index].strip() == "'';":
            end = index
            break
    if end is None:
        raise SystemExit(f"embedded-python: text block end not found in {source}")

    body = lines[start:end]
    indent = len(body[0]) - len(body[0].lstrip())
    script = []
    for line in body:
        script.append(line[indent:] if line.startswith(" " * indent) else line.lstrip())
    text = "\n".join(script) + "\n"
    text = text.replace("GUIDE = ${builtins.toJSON guide}", 'GUIDE = ""')
    text = text.replace("DEFAULT_FLAKE = ${builtins.toJSON flakeRoot}", 'DEFAULT_FLAKE = "/"')
    return text


def raw_doubled_escapes(text: str) -> list[int]:
    lines = []
    tokens = tokenize.generate_tokens(io.StringIO(text).readline)
    for token in tokens:
        if token.type != tokenize.STRING:
            continue
        prefix = token.string.split(token.string[-1], 1)[0].lower()
        if "r" in prefix and "\\\\" in token.string:
            lines.append(token.start[0])
    return lines


def main(argv: list[str]) -> int:
    source = Path(argv[1]) if len(argv) > 1 else Path("modules/patches/patch-ojuny-agent.nix")
    if not source.is_file():
        print(f"embedded-python: not a file: {source}", file=sys.stderr)
        return 2

    text = extract(source)
    try:
        compile(text, str(source), "exec")
    except SyntaxError as error:
        print(f"embedded-python: {source}:{error.lineno}: {error.msg}", file=sys.stderr)
        return 1

    doubled = raw_doubled_escapes(text)
    if doubled:
        for line in doubled:
            print(f"embedded-python: {source}:{line}: doubled backslash in a raw string", file=sys.stderr)
        return 1

    print(f"embedded-python: {source.name} compiles and has no doubled raw-string escapes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
