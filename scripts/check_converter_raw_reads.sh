#!/bin/bash
#
# Kept as the entry point the dev-guide and the Swift comments name.
# The check itself lives in check_attr_read_discipline.py, which covers
# the whole Dynamic tree (this script only ever looked at Converters/,
# so `Containers/` and `DynamicModifierHelper.swift` went unread) and
# carries the allowlist as a set with owner/plan/reason per row.

set -euo pipefail
exec python3 "$(dirname "$0")/check_attr_read_discipline.py" "$@"
