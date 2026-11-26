#!/usr/bin/env python3
"""Check the read-only, ask and deny classes in the agent patch."""

import pathlib
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

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
