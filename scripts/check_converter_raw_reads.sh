#!/bin/bash
#
# Renderer-SSoT grep gate for the SwiftUI Dynamic converters:
#
# 1. No raw attribute dictionary reads (`rawData[`) may appear in
#    converter bodies — attribute access goes through the generated
#    typed extraction (component.typedAttributes(...)).
# 2. The explicit raw passthrough `component.rawAttribute("key")` is
#    allowed ONLY for the keys pinned below (undeclared legacy /
#    extension keys, or declared keys whose accepted value space is
#    wider than the declared kind — see TypedAttributes.swift).
#
# Mirrors the rjui pilot's consumed-attributes allowlist approach.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONVERTERS_DIR="$REPO_ROOT/Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic/Converters"

# Allowed rawAttribute keys (keep in sync with
# JsonUITypedAttributesRegistry.consumedUndeclaredKeys plus the
# declared-but-wider-shape keys documented in TypedAttributes.swift).
ALLOWED_RAW_KEYS=(
    parent_orientation
    action
    animating
    backgroundColor
    cellHeight
    cellWidth
    colors
    defaultScrollAnchor
    endPoint
    fontStyle
    gradient
    hideSeparator
    lazy
    listStyle
    onItemAppear
    onSrc
    onValueChanged
    range
    selectedIndex
    selectedSegmentTintColor
    selectedTabIndex
    selectedValue
    startPoint
    toggleStyle
)

fail=0

# --- 1. no raw dictionary reads ---
if grep -n 'rawData\[' "$CONVERTERS_DIR"/*.swift; then
    echo "FAIL: raw attribute dictionary reads (rawData[...]) found in converter bodies" >&2
    fail=1
fi

# --- 2. rawAttribute keys must be in the allowlist ---
while IFS= read -r line; do
    key=$(echo "$line" | sed -E 's/.*rawAttribute\("([^"]+)"\).*/\1/')
    allowed=0
    for k in "${ALLOWED_RAW_KEYS[@]}"; do
        [ "$k" = "$key" ] && allowed=1 && break
    done
    if [ "$allowed" -eq 0 ]; then
        echo "FAIL: rawAttribute key '$key' is not in the allowlist: $line" >&2
        fail=1
    fi
done < <(grep -n 'rawAttribute("' "$CONVERTERS_DIR"/*.swift || true)

if [ "$fail" -ne 0 ]; then
    exit 1
fi
echo "OK: converters are free of raw attribute dictionary reads; all rawAttribute keys allowlisted"
