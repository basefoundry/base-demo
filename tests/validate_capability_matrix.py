#!/usr/bin/env python3
"""Validate the release-aware Base capability matrix structure and references."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
MATRIX = ROOT / "docs" / "base-capability-matrix.md"
EXPECTED_HEADER = [
    "Capability",
    "Base release",
    "Demo scenario and executable evidence",
    "Platform boundary",
    "Status",
    "Owner",
    "Follow-up",
]
STATUSES = {"Demonstrated", "Intentionally omitted", "Blocked upstream"}
LOCAL_LINK_RE = re.compile(r"\]\(([^)]+)\)")
CODE_SPAN_RE = re.compile(r"`([^`]+)`")


def fail(message: str) -> None:
    print(f"capability matrix validation: {message}", file=sys.stderr)
    raise SystemExit(1)


def cells(line: str) -> list[str]:
    if not line.startswith("|") or not line.endswith("|"):
        return []
    return [cell.strip() for cell in line[1:-1].split("|")]


def is_separator(row: list[str]) -> bool:
    return bool(row) and all(re.fullmatch(r":?-{3,}:?", cell) for cell in row)


def resolve_local_reference(reference: str) -> None:
    parsed = urlparse(reference)
    if parsed.scheme or reference.startswith("#"):
        return
    target = reference.split("#", 1)[0]
    if not target:
        return
    path = (MATRIX.parent / target).resolve()
    if not path.exists():
        fail(f"broken local reference: {reference}")


def main() -> int:
    if not MATRIX.is_file():
        fail(f"missing {MATRIX.relative_to(ROOT)}")
    text = MATRIX.read_text(encoding="utf-8")
    required_markers = (
        "Current Base release: `1.9.0`",
        "Planned Base release: `1.10.0`",
        "## Capability matrix",
        "## Release review checklist",
        "stale",
        "python3 tests/validate_capability_matrix.py",
    )
    for marker in required_markers:
        if marker not in text:
            fail(f"missing required matrix marker: {marker}")

    lines = text.splitlines()
    try:
        start = lines.index("## Capability matrix") + 1
        end = lines.index("## Release review checklist")
    except ValueError as exc:
        fail(f"cannot locate capability table boundaries: {exc}")

    table_lines = [line for line in lines[start:end] if line.startswith("|")]
    if len(table_lines) < 3:
        fail("capability table must contain a header, separator, and at least one row")
    header = cells(table_lines[0])
    if header != EXPECTED_HEADER:
        fail(f"unexpected table header: {header!r}")
    if not is_separator(cells(table_lines[1])):
        fail("capability table is missing its separator row")

    rows = [cells(line) for line in table_lines[2:]]
    for index, row in enumerate(rows, start=1):
        if len(row) != len(EXPECTED_HEADER):
            fail(f"row {index} has {len(row)} columns; expected {len(EXPECTED_HEADER)}")
        if any(not cell for cell in row):
            fail(f"row {index} contains an empty cell")
        status = row[4]
        if status not in STATUSES:
            fail(f"row {index} uses unsupported status {status!r}")
        if status == "Demonstrated" and not CODE_SPAN_RE.search(row[2]):
            fail(f"demonstrated row {index} has no executable code-span evidence")
        for reference in LOCAL_LINK_RE.findall(" | ".join(row)):
            resolve_local_reference(reference)
        for token in CODE_SPAN_RE.findall(" | ".join(row)):
            if "/" in token or token.endswith((".md", ".yml", ".yaml", ".sh", ".py", ".bats")):
                code_path = (ROOT / token).resolve()
                if not code_path.exists():
                    fail(f"broken executable evidence reference: {token}")

    for link_source in (ROOT / "README.md", ROOT / "docs" / "contracts.md", ROOT / ".ai-context" / "overview.md"):
        source = link_source.read_text(encoding="utf-8")
        if "base-capability-matrix.md" not in source:
            fail(f"{link_source.relative_to(ROOT)} does not link the capability matrix")
    print(f"capability matrix validation passed ({len(rows)} rows)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
