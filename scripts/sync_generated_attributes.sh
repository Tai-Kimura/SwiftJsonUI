#!/bin/bash
#
# Sync the generated typed-attribute extraction structs from the
# jsonui-cli attr-codegen emitter into the SwiftUI Dynamic runtime.
#
#   JSONUI_CLI_PATH=/path/to/jsonui-cli ./scripts/sync_generated_attributes.sh
#
# - Source of truth: $JSONUI_CLI_PATH/shared/core/attribute_definitions.json
# - Emitter:         jui generate attr-bindings --lang swift
#                    (build/attr_codegen/swift/, all files carry an
#                    `@generated` header — DO NOT EDIT BY HAND)
# - Destination:     Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic/Generated/Attributes/
#
# The generated files ARE committed (the library must build without the
# cli checkout); rerun this script after attribute_definitions.json
# changes and commit the diff.

set -euo pipefail

if [ -z "${JSONUI_CLI_PATH:-}" ]; then
    echo "error: set JSONUI_CLI_PATH to a jsonui-cli checkout" >&2
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$REPO_ROOT/Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic/Generated/Attributes"
SRC="$JSONUI_CLI_PATH/build/attr_codegen/swift"

echo "Generating (jui generate attr-bindings --lang swift)..."
(cd "$JSONUI_CLI_PATH" && PYTHONPATH=jui_tools python3 -c \
    "from jui_cli.cli import main; main(['generate', 'attr-bindings', '--lang', 'swift'])")

if [ ! -d "$SRC" ]; then
    echo "error: emitter output not found: $SRC" >&2
    exit 1
fi

mkdir -p "$DEST"
# -L: attribute_definitions.json lives behind symlinks in the cli tree;
# always materialize regular files here.
rsync -aL --delete --include='*.swift' --exclude='*' "$SRC/" "$DEST/"

echo "Synced $(ls "$DEST" | wc -l | tr -d ' ') files into ${DEST#$REPO_ROOT/}"
