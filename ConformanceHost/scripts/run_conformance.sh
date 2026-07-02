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
#
# Note: always uses the `test` action (incremental rebuild is cheap).
# `test-without-building` would ignore the TEST_RUNNER_* env overrides —
# they are build-settings overrides and only reach the runner when the
# test action evaluates build settings.
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

# Freeze the simulator status bar before capturing screenshots. The
# conformance screenshots are full-page captures that include the status
# bar; a live clock is the single largest source of dHash noise (measured up
# to distance 31 across the suite vs <=6 frozen — see
# conformance/baselines/README.md). Requires a specific device (UDID or a
# uniquely-named booted sim); skipped with a warning otherwise.
STATUS_BAR_UDID="${SIMULATOR_UDID:-}"
if [[ -z "$STATUS_BAR_UDID" ]]; then
    STATUS_BAR_UDID="$(xcrun simctl list devices booted | grep -m1 "$SIMULATOR_NAME" | grep -oE '[0-9A-F-]{36}' || true)"
fi
if [[ -n "$STATUS_BAR_UDID" ]]; then
    xcrun simctl bootstatus "$STATUS_BAR_UDID" -b >/dev/null 2>&1 || true
    xcrun simctl status_bar "$STATUS_BAR_UDID" override \
        --time "9:41" --batteryState charged --batteryLevel 100 \
        --wifiBars 3 --cellularBars 4 --dataNetwork wifi --operatorName "" \
        >/dev/null 2>&1 \
        && echo "status bar frozen (9:41) on $STATUS_BAR_UDID" \
        || echo "warning: could not freeze status bar on $STATUS_BAR_UDID (screenshots may drift)" >&2
else
    echo "warning: no specific simulator resolved — status bar not frozen; screenshot baselines will be noisy" >&2
fi

# TEST_RUNNER_* variables must be *environment variables of the xcodebuild
# process* (not command-line build settings) to be forwarded into the test
# runner's environment.
export TEST_RUNNER_CONFORMANCE_STAGING_DIR="$STAGING"
if [[ -n "${CONFORMANCE_FILTER:-}" ]]; then
    export TEST_RUNNER_CONFORMANCE_FILTER="$CONFORMANCE_FILTER"
fi

set -x
xcodebuild test \
    -project "$HOST_DIR/ConformanceHost.xcodeproj" \
    -scheme ConformanceHost \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -parallel-testing-enabled NO \
    -test-timeouts-enabled NO \
    2>&1 | tail -40
set +x

CONFORMANCE_STAGING="$STAGING" "$HOST_DIR/scripts/collect_results.sh"
