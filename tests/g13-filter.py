#!/usr/bin/env python3
"""Compile and test the G13 stick filter embedded in the patch module.

The filter is a Nix string, so this check extracts the Python, compiles it, and
executes it with a stub ``evdev`` module. The unit tests cover the suppression
rules, the repeat handling, and the release events written during teardown.
"""

from __future__ import annotations

import contextlib
import io
import sys
import types
from pathlib import Path


MARKER = 'filterSource = pkgs.writeText "g13-filter.py" '
KEY_F13 = 183
KEY_F14 = 184
KEY_F15 = 185
KEY_F16 = 186
EV_KEY = 1


def extract(source: Path) -> str:
    lines = source.read_text(encoding="utf-8").splitlines()
    start = None
    for index, line in enumerate(lines):
        if MARKER in line and line.rstrip().endswith("''"):
            start = index + 1
            break
    if start is None:
        raise SystemExit(f"g13-filter: filter block not found in {source}")

    end = None
    for index in range(start, len(lines)):
        if lines[index].strip() == "'';":
            end = index
            break
    if end is None:
        raise SystemExit(f"g13-filter: filter block end not found in {source}")

    body = lines[start:end]
    indent = len(body[0]) - len(body[0].lstrip())
    script = []
    for line in body:
        script.append(line[indent:] if line.startswith(" " * indent) else line.lstrip())
    return "\n".join(script) + "\n"


def load_filter(source: Path) -> tuple[str, dict, types.SimpleNamespace]:
    text = extract(source)
    compile(text, str(source), "exec")

    ecodes = types.SimpleNamespace(
        EV_KEY=EV_KEY,
        EV_SYN=0,
        KEY_F13=KEY_F13,
        KEY_F14=KEY_F14,
        KEY_F15=KEY_F15,
        KEY_F16=KEY_F16,
    )
    stub = types.ModuleType("evdev")
    stub.ecodes = ecodes
    previous = sys.modules.get("evdev")
    sys.modules["evdev"] = stub
    namespace: dict = {"__name__": "g13_filter_under_test"}
    try:
        exec(compile(text, str(source), "exec"), namespace)
    finally:
        if previous is None:
            sys.modules.pop("evdev", None)
        else:
            sys.modules["evdev"] = previous
    return text, namespace, ecodes


def event(code: int, value: int) -> types.SimpleNamespace:
    return types.SimpleNamespace(type=EV_KEY, code=code, value=value)


class StopLoop(Exception):
    pass


class FakeTime:
    def __init__(self) -> None:
        self.sleeps = 0

    def monotonic(self) -> float:
        return 0.0

    def sleep(self, seconds: float) -> None:
        self.sleeps += 1
        raise StopLoop


class FakeSource:
    name = "G13"

    def __init__(self, events: list[types.SimpleNamespace]) -> None:
        self.events = events
        self.grabbed = False
        self.closed = False

    def grab(self) -> None:
        self.grabbed = True

    def ungrab(self) -> None:
        self.grabbed = False

    def close(self) -> None:
        self.closed = True

    def read(self):
        for item in self.events:
            yield item
        raise OSError("device disconnected")


class FakeOutput:
    def __init__(self) -> None:
        self.events: list[types.SimpleNamespace] = []
        self.writes: list[tuple[int, int, int]] = []
        self.synced = 0
        self.closed = False

    def write_event(self, item: types.SimpleNamespace) -> None:
        self.events.append(item)

    def write(self, etype: int, code: int, value: int) -> None:
        self.writes.append((etype, code, value))

    def syn(self) -> None:
        self.synced += 1

    def close(self) -> None:
        self.closed = True


def fake_evdev(
    ecodes: types.SimpleNamespace,
    source: FakeSource | None = None,
    output: FakeOutput | None = None,
    create_error: OSError | None = None,
) -> types.ModuleType:
    module = types.ModuleType("evdev")
    module.ecodes = ecodes
    module.list_devices = lambda: ["/dev/input/event26"]
    module.InputDevice = lambda path: source

    class UInput:
        @staticmethod
        def from_device(device, name=None):
            if create_error is not None:
                raise create_error
            return output

    module.UInput = UInput
    return module


def run_filter(namespace: dict, evdev_module: types.ModuleType) -> FakeTime:
    namespace["evdev"] = evdev_module
    namespace["time"] = FakeTime()
    try:
        namespace["run"]()
    except StopLoop:
        pass
    return namespace["time"]


def test_first_press_forwarded(namespace: dict, ecodes: types.SimpleNamespace) -> None:
    stick = namespace["StickFilter"]()
    assert stick.handle(event(KEY_F13, 1), 0.0) is True
    assert stick.pressed == {KEY_F13}
    assert stick.releases() == [(KEY_F13, 0)]


def test_direction_blocked_within_lockout(namespace: dict, ecodes: types.SimpleNamespace) -> None:
    stick = namespace["StickFilter"]()
    assert stick.handle(event(KEY_F13, 1), 0.0) is True
    assert stick.handle(event(KEY_F14, 1), 0.1) is False
    assert stick.suppressed == {KEY_F14}
    assert stick.pressed == {KEY_F13}
    assert stick.releases() == [(KEY_F13, 0)]


def test_suppressed_repeat_blocked(namespace: dict, ecodes: types.SimpleNamespace) -> None:
    stick = namespace["StickFilter"]()
    stick.handle(event(KEY_F13, 1), 0.0)
    stick.handle(event(KEY_F14, 1), 0.1)
    assert stick.handle(event(KEY_F14, 2), 0.2) is False
    assert stick.handle(event(KEY_F13, 2), 0.2) is True


def test_accepted_release_forwarded(namespace: dict, ecodes: types.SimpleNamespace) -> None:
    stick = namespace["StickFilter"]()
    stick.handle(event(KEY_F13, 1), 0.0)
    assert stick.handle(event(KEY_F13, 0), 0.1) is True
    assert stick.pressed == set()
    assert stick.releases() == []


def test_suppressed_release_blocked(namespace: dict, ecodes: types.SimpleNamespace) -> None:
    stick = namespace["StickFilter"]()
    stick.handle(event(KEY_F13, 1), 0.0)
    stick.handle(event(KEY_F14, 1), 0.1)
    assert stick.handle(event(KEY_F14, 0), 0.2) is False
    assert stick.suppressed == set()
    assert stick.pressed == {KEY_F13}


def test_direction_accepted_after_lockout(namespace: dict, ecodes: types.SimpleNamespace) -> None:
    stick = namespace["StickFilter"]()
    stick.handle(event(KEY_F13, 1), 0.0)
    assert stick.handle(event(KEY_F14, 1), 0.31) is True
    assert stick.pressed == {KEY_F13, KEY_F14}
    assert stick.releases() == [(KEY_F13, 0), (KEY_F14, 0)]


def test_teardown_releases_forwarded_key(namespace: dict, ecodes: types.SimpleNamespace) -> None:
    source = FakeSource([event(KEY_F13, 1)])
    output = FakeOutput()
    with contextlib.redirect_stderr(io.StringIO()):
        run_filter(namespace, fake_evdev(ecodes, source=source, output=output))
    assert (EV_KEY, KEY_F13, 0) in output.writes
    assert output.synced == 1
    assert output.closed is True
    assert source.grabbed is False
    assert source.closed is True


def test_uinput_failure_does_not_grab(namespace: dict, ecodes: types.SimpleNamespace) -> None:
    source = FakeSource([])
    errors = io.StringIO()
    with contextlib.redirect_stderr(errors):
        run_filter(
            namespace,
            fake_evdev(ecodes, source=source, create_error=OSError("cannot create")),
        )
    assert source.grabbed is False
    assert source.closed is True
    assert "uinput unavailable: cannot create" in errors.getvalue()


def main(argv: list[str]) -> int:
    root = Path(__file__).resolve().parent.parent
    source = Path(argv[1]) if len(argv) > 1 else root / "modules/patches/patch-logitech-g13.nix"
    if not source.is_file():
        print(f"g13-filter: not a file: {source}", file=sys.stderr)
        return 2

    text, namespace, ecodes = load_filter(source)
    assert "name=\"G13 Filtered\"" in text
    tests = [value for name, value in sorted(globals().items()) if name.startswith("test_")]
    for test in tests:
        test(namespace, ecodes)

    print(f"g13-filter: {source.name} compiles and {len(tests)} tests pass")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
