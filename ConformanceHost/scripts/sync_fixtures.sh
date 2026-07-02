#!/bin/bash
#
# sync_fixtures.sh — copy conformance fixtures + manifest into the host app
# resources and vendor the jsonui-test-runner iOS driver sources into the
# UITest target.
#
# Required environment:
#   CONFORMANCE_DIR          conformance directory produced by
#                            `jui conformance generate`
#                            (contains fixtures/, manifest.json)
#   JSONUI_TEST_RUNNER_PATH  path to a jsonui-test-runner checkout, or
#                            directly to its drivers/ios directory
#
# Everything this script writes is gitignored (Resources/, UITests/Vendor/).
# Run scripts/generate_project.rb after syncing so the Xcode project picks up
# the vendored sources.
#
set -euo pipefail

HOST_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -z "${CONFORMANCE_DIR:-}" ]]; then
    echo "error: CONFORMANCE_DIR is not set" >&2
    exit 1
fi
if [[ ! -f "$CONFORMANCE_DIR/manifest.json" ]]; then
    echo "error: $CONFORMANCE_DIR/manifest.json not found — run 'jui conformance generate' first" >&2
    exit 1
fi
if [[ -z "${JSONUI_TEST_RUNNER_PATH:-}" ]]; then
    echo "error: JSONUI_TEST_RUNNER_PATH is not set" >&2
    exit 1
fi

DRIVER_SRC="$JSONUI_TEST_RUNNER_PATH"
if [[ -d "$DRIVER_SRC/drivers/ios/Sources/JsonUITestRunner" ]]; then
    DRIVER_SRC="$DRIVER_SRC/drivers/ios/Sources/JsonUITestRunner"
elif [[ -d "$DRIVER_SRC/Sources/JsonUITestRunner" ]]; then
    DRIVER_SRC="$DRIVER_SRC/Sources/JsonUITestRunner"
else
    echo "error: JsonUITestRunner sources not found under $JSONUI_TEST_RUNNER_PATH" >&2
    exit 1
fi

# --- fixtures + manifest -> Resources/ (bundled into app and UITest bundle)
rm -rf "$HOST_DIR/Resources/fixtures"
mkdir -p "$HOST_DIR/Resources"
rsync -a --delete "$CONFORMANCE_DIR/fixtures/" "$HOST_DIR/Resources/fixtures/"
cp "$CONFORMANCE_DIR/manifest.json" "$HOST_DIR/Resources/manifest.json"

# --- driver sources -> UITests/Vendor/JsonUITestRunner
rm -rf "$HOST_DIR/UITests/Vendor/JsonUITestRunner"
mkdir -p "$HOST_DIR/UITests/Vendor"
rsync -a "$DRIVER_SRC/" "$HOST_DIR/UITests/Vendor/JsonUITestRunner/"

# --- apply local driver patches, if any (committed under scripts/driver-patches)
PATCH_DIR="$HOST_DIR/scripts/driver-patches"
if [[ -d "$PATCH_DIR" ]]; then
    for patch in "$PATCH_DIR"/*.patch; do
        [[ -e "$patch" ]] || continue
        echo "applying driver patch: $(basename "$patch")"
        patch -p1 -d "$HOST_DIR/UITests/Vendor/JsonUITestRunner" < "$patch"
    done
fi

FIXTURE_COUNT=$(find "$HOST_DIR/Resources/fixtures" -name '*.layout.json' | wc -l | tr -d ' ')
DRIVER_COUNT=$(find "$HOST_DIR/UITests/Vendor/JsonUITestRunner" -name '*.swift' | wc -l | tr -d ' ')
echo "synced: $FIXTURE_COUNT fixture layouts, manifest.json, $DRIVER_COUNT driver sources"
