#!/usr/bin/env python3
"""Check the G13 bind shape and its menu surface.

Bank 1 rows keep the physical `subcat` as their only G13 key label. The rows
feed the dedicated `g13` DMS cheatsheet and a generated Mango bind fragment
sourced through `desktop.ojuny.mango.source`; they must not be injected into
the regular `desktop.ojuny.mango.binds` tables.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


BANK_START = re.compile(r"ojuny\.patch\.logitech-g13\.bindings\.bank1\s*=\s*\[")
REGULAR_BINDS = re.compile(r"desktop\.ojuny\.mango\.binds\.(?:common|default|movement|groups|resize)\s*=")
SOURCE_WIRING = re.compile(r"desktop\.ojuny\.mango\.source\s*=\s*lib\.mkAfter\s*\[\s*mangoBindsFile\s*\]\s*;")
FRAGMENT = re.compile(r'pkgs\.writeText "ojuny-g13-binds\.toml"')
CHEATSHEET_PROVIDER = re.compile(r'provider\s*=\s*"g13";')
CHEATSHEET_KEY = re.compile(r"key\s*=\s*row\.subcat;")
CHEATSHEET_ROWS = re.compile(r"allRows\s*=\s*lib\.concatMap\s*\(\s*bank:\s*bank\.rows\s*\)\s*banks;")
STICK_SCRIPT = re.compile(r"stickScript\s*=\s*pkgs\.writeShellApplication")
STICK_NAME = re.compile(r'name\s*=\s*"ojuny-g13-stick";')
STICK_BIND = re.compile(r'stickBind\s*=\s*row:[\s\S]{0,200}?modeBind row "spawn"')
STICK_LOCKOUT_MS = re.compile(r"lockout_ms=300\b")
STICK_LOCKOUT_NS = re.compile(r"lockout_ns=\$\(\(lockout_ms \* 1000000\)\)")
STICK_DISPATCH = re.compile(r'exec mmsg dispatch "\$1,\$2"')
STICK_DISPATCH_PLAIN = re.compile(r'exec mmsg dispatch "\$1"')
STICK_CALL = '${stickScript}/bin/ojuny-g13-stick ${dispatcher}'
OPTIONAL_STICK = re.compile(r'optionalStickBind "stick-')
OPTIONAL_STICK_WRONG = re.compile(r'optionalStickBind "(?:thumb-|g)')
OPTIONAL_MODE_STICK = re.compile(r'optionalModeBind "stick-')
OPTIONAL_MODE_THUMB = re.compile(r'optionalModeBind "thumb-')
REQUIRED_STRINGS = ("dispatcher", "description", "group")
REQUIRED_LISTS = ("modifier", "keys")
WINDOW_ROWS = {"g4", "g5", "g6", "g7"}


class ValidationError(Exception):
    pass


def bank_rows(text: str) -> list[str]:
    marker = BANK_START.search(text)
    if marker is None:
        raise SystemExit("g13-binds: bank1 list not found")

    rows = []
    depth = 0
    start = None
    in_string = False
    escaped = False
    for index in range(marker.end(), len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            if depth == 0:
                start = index + 1
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0 and start is not None:
                rows.append(text[start:index])
                start = None
        elif char == "]" and depth == 0:
            break

    if depth != 0:
        raise SystemExit("g13-binds: unterminated bank1 row")
    if not rows:
        raise SystemExit("g13-binds: bank1 has no rows")
    return rows


def string_field(row: str, name: str) -> str | None:
    match = re.search(rf"\b{name}\s*=\s*\"([^\"]*)\"", row)
    return match.group(1) if match else None


def list_field(row: str, name: str) -> str | None:
    match = re.search(rf"\b{name}\s*=\s*\[([^\]]*)\]", row)
    return match.group(1) if match else None


def int_field(row: str, name: str) -> str | None:
    match = re.search(rf"\b{name}\s*=\s*(-?\d+)\s*;", row)
    return match.group(1) if match else None


def row_errors(rows: list[str]) -> list[str]:
    errors = []
    seen = {}

    for number, row in enumerate(rows, start=1):
        key = string_field(row, "key")
        label = key if key else f"row {number}"
        subcat = string_field(row, "subcat")

        if subcat is None or subcat == "":
            errors.append(f"{label}: missing subcat")
        elif subcat in seen:
            errors.append(f"{label}: duplicate subcat {subcat!r} (also row {seen[subcat]})")
        else:
            seen[subcat] = number

        if string_field(row, "displayKey") is not None:
            errors.append(f"{label}: must not have displayKey")

        group = string_field(row, "group")
        if group is None:
            errors.append(f"{label}: missing group")
        elif not group.strip():
            errors.append(f"{label}: empty group")
        elif group == "Window":
            errors.append(f"{label}: group must be 'Windows', not 'Window'")
        elif key in WINDOW_ROWS and group != "Windows":
            errors.append(f"{label}: window row must use group 'Windows'")

        for name in REQUIRED_STRINGS:
            if name == "group":
                continue
            value = string_field(row, name)
            if value is None or value == "":
                errors.append(f"{label}: missing {name}")
        for name in REQUIRED_LISTS:
            if list_field(row, name) is None:
                errors.append(f"{label}: missing {name}")
        if list_field(row, "keys") == "":
            errors.append(f"{label}: keys is empty")
        if int_field(row, "repeats") is None:
            errors.append(f"{label}: missing repeats")

    return errors


def module_errors(text: str, rows: list[str]) -> list[str]:
    errors = row_errors(rows)

    if "displayKey" in text:
        errors.append("module must not define displayKey")
    if REGULAR_BINDS.search(text):
        errors.append("module must not inject G13 rows into desktop.ojuny.mango.binds")
    if not SOURCE_WIRING.search(text):
        errors.append("missing desktop.ojuny.mango.source wiring for mangoBindsFile")
    if not FRAGMENT.search(text):
        errors.append("missing generated ojuny-g13-binds.toml fragment")
    if '"[bind.${mode}]' not in text:
        errors.append("bind fragment must define [bind.<mode>] tables")
    if not CHEATSHEET_PROVIDER.search(text):
        errors.append("cheatsheet must use provider g13")
    if not CHEATSHEET_KEY.search(text):
        errors.append("cheatsheet must use key = row.subcat")
    if not CHEATSHEET_ROWS.search(text):
        errors.append("cheatsheet must cover all bank rows through allRows")

    if not STICK_SCRIPT.search(text):
        errors.append("missing stickScript writeShellApplication")
    if not STICK_NAME.search(text):
        errors.append('stick script must be named "ojuny-g13-stick"')
    if "ojuny-g13-stick.last" not in text:
        errors.append("stick script must use the ojuny-g13-stick.last state file")
    if not STICK_LOCKOUT_MS.search(text):
        errors.append("stick script must define lockout_ms=300")
    if not STICK_LOCKOUT_NS.search(text):
        errors.append("stick script must convert the 300 ms lockout to nanoseconds")
    if not STICK_DISPATCH.search(text):
        errors.append('stick script must dispatch with mmsg dispatch "$1,$2"')
    if not STICK_DISPATCH_PLAIN.search(text):
        errors.append('stick script must dispatch the plain dispatcher when args are empty')
    if not STICK_BIND.search(text):
        errors.append("stickBind must call modeBind with spawn")
    if STICK_CALL not in text:
        errors.append("stick binds must call ${stickScript}/bin/ojuny-g13-stick")
    if len(OPTIONAL_STICK.findall(text)) != 16:
        errors.append("all 16 stick rows must use optionalStickBind")
    if OPTIONAL_STICK_WRONG.search(text):
        errors.append("optionalStickBind must not wrap thumb or G rows")
    if OPTIONAL_MODE_STICK.search(text):
        errors.append("stick rows must not use optionalModeBind directly")
    if len(OPTIONAL_MODE_THUMB.findall(text)) != 6:
        errors.append("thumb rows must stay on optionalModeBind")

    return errors


def expect_failure(name: str, rows: list[str]) -> None:
    if not row_errors(rows):
        raise SystemExit(f"g13-binds: {name} should have failed validation")


def main(argv: list[str]) -> int:
    root = Path(__file__).resolve().parent.parent
    source = Path(argv[1]) if len(argv) > 1 else root / "modules/patches/patch-logitech-g13.nix"
    if not source.is_file():
        print(f"g13-binds: not a file: {source}", file=sys.stderr)
        return 2

    text = source.read_text(encoding="utf-8")
    rows = bank_rows(text)
    errors = module_errors(text, rows)
    if errors:
        for line in errors:
            print(f"g13-binds: {line}", file=sys.stderr)
        return 1

    good = (
        '{ key = "g1"; label = "x"; subcat = "G1"; '
        'modifier = [ "SUPER" ]; keys = [ "A" ]; dispatcher = "x"; args = ""; '
        'description = "x"; group = "Scratchpad"; repeats = 0; }'
    )
    expect_failure("missing subcat", [good.replace('subcat = "G1"; ', "")])
    expect_failure("displayKey present", [good.replace('subcat = "G1"; ', 'subcat = "G1"; displayKey = "G1"; ')])
    expect_failure("singular Window group", [good.replace('group = "Scratchpad"', 'group = "Window"')])

    print(f"g13-binds: {len(rows)} rows valid and bound through g13 + mango source in {source.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
