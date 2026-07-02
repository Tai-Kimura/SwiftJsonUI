#!/bin/bash
#
# run_conformance.sh — build & run the full iOS conformance suite headless
# and collect results into $CONFORMANCE_DIR.
#
# Required environment:
#   CONFORMANCE_DIR   conformance directory (fixtures/, manifest.json;
#                     results/ and artifacts/ are written back here)
#
# Optional environment:
#   SIMULATOR_NAME       simulator device name    (default: iPhone 16 Pro)
#   SIMULATOR_UDID       simulator UDID — takes precedence over SIMULATOR_NAME
#                        (use when several devices share a name)
#   CONFORMANCE_STAGING  staging dir for raw test output
#                        (default: /tmp/jsonui-conformance-ios)
#   CONFORMANCE_FILTER   substring filter on fixture ids — everything else is
#                        reported as skipped ("not executed in this run")
#   SKIP_BUILD=1         reuse the last build (test-without-building)
#
# Prerequisites: scripts/sync_fixtures.sh + scripts/generate_project.rb.
#
set -euo pipefail

HOST_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16 Pro}"
if [[ -n "${SIMULATOR_UDID:-}" ]]; then
    DESTINATION="platform=iOS Simulator,id=$SIMULATOR_UDID"
else
    DESTINATION="platform=iOS Simulator,name=$SIMULATOR_NAME"
fi
STAGING="${CONFORMANCE_STAGING:-/tmp/jsonui-conformance-ios}"
DERIVED_DATA="${DERIVED_DATA:-$HOST_DIR/build/DerivedData}"

if [[ -z "${CONFORMANCE_DIR:-}" ]]; then
    echo "error: CONFORMANCE_DIR is not set" >&2
    exit 1
fi
if [[ ! -d "$HOST_DIR/ConformanceHost.xcodeproj" ]]; then
    echo "error: project not generated — run scripts/generate_project.rb first" >&2
    exit 1
fi

rm -rf "$STAGING"
mkdir -p "$STAGING"

XCODEBUILD_ACTION=test
if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    XCODEBUILD_ACTION=test-without-building
fi

set -x
xcodebuild "$XCODEBUILD_ACTION" \
    -project "$HOST_DIR/ConformanceHost.xcodeproj" \
    -scheme ConformanceHost \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -parallel-testing-enabled NO \
    -test-timeouts-enabled NO \
    TEST_RUNNER_CONFORMANCE_STAGING_DIR="$STAGING" \
    ${CONFORMANCE_FILTER:+TEST_RUNNER_CONFORMANCE_FILTER="$CONFORMANCE_FILTER"} \
    2>&1 | tail -40
set +x

CONFORMANCE_STAGING="$STAGING" "$HOST_DIR/scripts/collect_results.sh"
