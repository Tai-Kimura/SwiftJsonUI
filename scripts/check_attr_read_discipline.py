#!/usr/bin/env python3
"""Renderer-SSoT read-discipline gate for the SwiftUI Dynamic tree.

Two gates, one allowlist, one ratchet.

  raw-read      No `rawData[...]` dictionary reads and no unlisted
                `rawAttribute("key")` passthroughs anywhere under
                `Dynamic/` (`Generated/` excluded — it is emitted).
  binding-slot  No hand-written decode slot in `DynamicComponent.swift`
                for an attribute the SSoT declares binding-capable. The
                canonical reader is the generated `AttrValue<T>`
                extraction; a hand-written slot in front of it is how
                `TextField.secure: "@{x}"` ended up rendering a
                plaintext password field (plan 49, lane F).

The allowlist IS the ratchet. It is compared as a SET, not a count:

  * a violation missing from the allowlist  -> fail (new violation)
  * an allowlist entry with no violation    -> fail (fixed; delete the row)

Pinning a count instead would let one fix pay for one regression. Every
row carries `owner` / `plan` / `reason` so a frozen row states who
resolves it and why it is frozen — an unattributed freeze is how a
temporary exception becomes permanent.

The binding-capable attribute list is read from the VENDORED generated
tables, not from a copy of `attribute_definitions.json`. Those tables are
already sha256-verified against the jsonui-cli manifest by the
`vendored-attr-guard` job, so the gate's input cannot drift from the
SSoT. A second vendored copy would be a second truth that nothing checks.

Usage: scripts/check_attr_read_discipline.py [--json]
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DYNAMIC = REPO_ROOT / "Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic"
GENERATED = DYNAMIC / "Generated"
COMPONENT = DYNAMIC / "DynamicComponent.swift"
ALLOWLIST = REPO_ROOT / "scripts/attr_read_allowlist.json"

REQUIRED_FIELDS = ("owner", "plan", "reason")

RAW_DATA = re.compile(r'rawData\[\s*(?:"([^"]+)"|([A-Za-z_][A-Za-z0-9_.]*))\s*\]')
RAW_ATTRIBUTE = re.compile(r'rawAttribute\(\s*"([^"]+)"\s*\)')
#: `public let alignBottom: AttrValue<Bool>?` in the generated tables. The
#: `AttrValue` wrapper is emitted for exactly the binding-capable
#: attributes, so its presence IS the SSoT's `binding` declaration.
BINDING_DECL = re.compile(r'\blet\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*AttrValue<')
#: A stored property on `DynamicComponent` — the hand-written decode slot.
SLOT_DECL = re.compile(r"^\s+(?:public\s+)?(?:let|var)\s+([A-Za-z_][A-Za-z0-9_]*)\s*:", re.M)


def _code_lines(path: Path):
    """(line number, source) for lines that are not pure comments.

    Doc comments in `DynamicBindingHelper.swift` quote `rawData["text"]`
    as the very thing they tell you not to write. Counting those makes
    the gate report its own documentation, so comment-only lines are
    dropped. Trailing comments still count: the code before them is real.
    """
    out = []
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        stripped = line.lstrip()
        if stripped.startswith("//") or stripped.startswith("*"):
            continue
        out.append((number, line))
    return out


def _swift_sources():
    for path in sorted(DYNAMIC.rglob("*.swift")):
        if GENERATED in path.parents:
            continue
        yield path


def find_raw_reads() -> list[dict]:
    """Every `rawData[...]` / `rawAttribute("...")` read outside Generated/."""
    findings = []
    for path in _swift_sources():
        rel = path.relative_to(DYNAMIC).as_posix()
        for number, line in _code_lines(path):
            for match in RAW_DATA.finditer(line):
                literal, dynamic = match.group(1), match.group(2)
                findings.append(
                    {
                        "gate": "raw-read",
                        "file": rel,
                        "kind": "rawData",
                        # A computed key cannot be named, so it is keyed by
                        # the identifier used — enough to pin one site.
                        "key": literal if literal is not None else f"<{dynamic}>",
                        "line": number,
                    }
                )
            for match in RAW_ATTRIBUTE.finditer(line):
                findings.append(
                    {
                        "gate": "raw-read",
                        "file": rel,
                        "kind": "rawAttribute",
                        "key": match.group(1),
                        "line": number,
                    }
                )
    return findings


def binding_attributes() -> set[str]:
    """Attributes the SSoT declares binding-capable, per the vendored tables."""
    names: set[str] = set()
    for path in sorted(GENERATED.rglob("*.swift")):
        names.update(BINDING_DECL.findall(path.read_text()))
    return names


def find_binding_slots() -> list[dict]:
    """Hand-written decode slots for binding-capable attributes."""
    declared = binding_attributes()
    slots = set(SLOT_DECL.findall(COMPONENT.read_text()))
    rel = COMPONENT.relative_to(DYNAMIC).as_posix()
    return [
        {"gate": "binding-slot", "file": rel, "attribute": name}
        for name in sorted(slots & declared)
    ]


def identity(entry: dict) -> tuple:
    """What makes two findings the same violation.

    Line numbers are deliberately excluded: moving a read down a file is
    not a new violation, and pinning lines would make the allowlist churn
    on every unrelated edit.
    """
    if entry["gate"] == "raw-read":
        return ("raw-read", entry["file"], entry["kind"], entry["key"])
    return ("binding-slot", entry["attribute"])


def load_allowlist() -> tuple[dict[tuple, dict], list[str]]:
    if not ALLOWLIST.exists():
        return {}, [f"allowlist not found: {ALLOWLIST.relative_to(REPO_ROOT)}"]
    data = json.loads(ALLOWLIST.read_text())
    errors: list[str] = []
    rows: dict[tuple, dict] = {}
    for entry in data.get("entries", []):
        missing = [f for f in REQUIRED_FIELDS if not entry.get(f)]
        if missing:
            errors.append(
                f"allowlist row {entry!r} is missing required field(s): "
                f"{', '.join(missing)}"
            )
            continue
        rows[identity(entry)] = entry
    return rows, errors


def main(argv: list[str]) -> int:
    as_json = "--json" in argv

    findings = find_raw_reads() + find_binding_slots()
    allowed, errors = load_allowlist()

    seen = {identity(f): f for f in findings}
    new = [seen[k] for k in sorted(seen.keys() - allowed.keys())]
    stale = [allowed[k] for k in sorted(allowed.keys() - seen.keys())]

    if as_json:
        json.dump(
            {
                "findings": len(seen),
                "allowlisted": len(allowed),
                "new": new,
                "stale": stale,
                "errors": errors,
            },
            sys.stdout,
            indent=2,
            sort_keys=True,
        )
        sys.stdout.write("\n")
        return 1 if (new or stale or errors) else 0

    for error in errors:
        print(f"FAIL: {error}", file=sys.stderr)

    for entry in new:
        if entry["gate"] == "raw-read":
            print(
                f"FAIL: unlisted raw read {entry['kind']}(\"{entry['key']}\") "
                f"in {entry['file']}:{entry['line']} — go through the generated "
                f"typed extraction, or add an allowlist row with owner/plan/reason",
                file=sys.stderr,
            )
        else:
            print(
                f"FAIL: hand-written decode slot for binding-capable attribute "
                f"'{entry['attribute']}' in {entry['file']} — the canonical "
                f"reader is AttrValue<T>; a slot in front of it drops the "
                f"binding form",
                file=sys.stderr,
            )

    for entry in stale:
        label = entry.get("key") or entry.get("attribute")
        print(
            f"FAIL: allowlist row for '{label}' "
            f"({entry.get('file', '?')}) no longer matches any violation — "
            f"it was fixed, so delete the row",
            file=sys.stderr,
        )

    if new or stale or errors:
        return 1

    print(
        f"OK: {len(seen)} read-discipline violations, all allowlisted with "
        f"owner/plan/reason ({len(allowed)} rows, exact match)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
