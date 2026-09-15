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
# Which iOS runtime to draw on. Unset keeps the historical "newest wins".
#
# 🔻 "NEWEST WINS" IS NOT A PIN, AND IT HAS ALREADY MOVED ON ITS OWN.
# `simctl` lists every runtime INSTALLED on the machine, not the ones the
# selected Xcode came with, and the GitHub runner image installs new ones as it
# is updated. The committed iOS results record the consequence: the runner
# version oscillates 18.6 -> 26.2 -> 18.6 across four bakes (05d0fde0,
# 761cc64c, 290f96a7) while the workflow's Xcode pin never changed. At one
# point the two iOS lanes disagreed with each other in the same tree --
# results/ios said ios-18.6 while codegen/ios said ios-26.2 -- and
# `gate --parity` compares exactly those two sets of pictures.
#
# A runtime change re-renders every fixture, so this is the one input that must
# not drift quietly. Set SIMULATOR_OS to a version prefix ("26", "26.2") and an
# absent match is a HARD FAILURE rather than a fall-through to a neighbour:
# falling through is how an unpinned runtime looked like a pin for months.
SIMULATOR_OS="${SIMULATOR_OS:-}"

# Resolve the name to one concrete device, so the status-bar override below
# and the test run target the same simulator. Passing a name to xcodebuild
# leaves that ambiguous — several runtimes ship a device with the same name —
# and the override could only ever find an already-BOOTED one, which on a
# fresh CI runner is none of them. The result was an unfrozen clock in every
# screenshot: measured run-to-run dHash distance 7-16 across all 490 iOS
# fixtures, i.e. a baseline that could never be met twice.
if [[ -z "${SIMULATOR_UDID:-}" ]]; then
    SIMULATOR_UDID="$(xcrun simctl list -j devices available 2>/dev/null | python3 -c '
import json, re, sys

name = sys.argv[1]
want = sys.argv[2] if len(sys.argv) > 2 else ""
# A prefix, compared component-wise: "26" accepts 26.2, "26.2" does not accept
# 26.10. String startswith would, which is the sort of near-miss that makes a
# pin look honoured while it is not.
want_parts = tuple(int(n) for n in re.findall(r"\d+", want)) if want else ()
best = None
for runtime, devices in json.load(sys.stdin).get("devices", {}).items():
    if "SimRuntime.iOS" not in runtime:
        continue
    version = tuple(int(n) for n in re.findall(r"\d+", runtime.rsplit(".", 1)[-1]))
    if want_parts and version[: len(want_parts)] != want_parts:
        continue
    for device in devices:
        if device.get("name") != name or not device.get("isAvailable", True):
            continue
        # Newest MATCHING runtime wins. With SIMULATOR_OS unset that is the
        # historical behaviour; with it set the candidates were already
        # filtered, so "newest" only ever ranges inside the pin.
        if best is None or version > best[0]:
            best = (version, device["udid"])
print(best[1] if best else "")
' "$SIMULATOR_NAME" "$SIMULATOR_OS" || true)"
fi

if [[ -n "$SIMULATOR_OS" && -z "${SIMULATOR_UDID:-}" ]]; then
    # Deliberately fatal. The fall-through below picks SOME simulator, which is
    # right when nothing was asked for and wrong when something was: drawing a
    # baseline on a runtime nobody chose is the failure this pin exists to stop.
    echo "error: SIMULATOR_OS=$SIMULATOR_OS was requested but no available" >&2
    echo "       '$SIMULATOR_NAME' runs it. Installed iOS runtimes:" >&2
    xcrun simctl list runtimes 2>/dev/null | grep -i "iOS" >&2 || true
    exit 1
fi

if [[ -n "${SIMULATOR_UDID:-}" ]]; then
    DESTINATION="platform=iOS Simulator,id=$SIMULATOR_UDID"
else
    echo "warning: no simulator named '$SIMULATOR_NAME' resolved — falling back to name matching" >&2
    DESTINATION="platform=iOS Simulator,name=$SIMULATOR_NAME"
fi
# HOST_MODE=codegen renders fixtures through the sjui-GENERATED views
# (scripts/generate_codegen_host.rb output) instead of DynamicView, and
# lands output in codegen-suffixed locations so a parity comparison never
# clobbers the dynamic artifacts. Default: dynamic.
HOST_MODE="${HOST_MODE:-dynamic}"
if [[ "$HOST_MODE" == "codegen" ]]; then
    STAGING="${CONFORMANCE_STAGING:-/tmp/jsonui-conformance-ios-codegen}"
else
    STAGING="${CONFORMANCE_STAGING:-/tmp/jsonui-conformance-ios}"
fi
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
if [[ -n "$STATUS_BAR_UDID" ]]; then
    # The override only sticks on a booted device, and `simctl boot` is a
    # no-op error when it already is.
    xcrun simctl boot "$STATUS_BAR_UDID" >/dev/null 2>&1 || true
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
# 🔻 FORWARD EVERY CONFORMANCE_* THE CALLER SET, DERIVED — NOT A NAMED LIST.
# The convention is "caller sets CONFORMANCE_X, this script re-exports it as
# TEST_RUNNER_CONFORMANCE_X", and with a hand-kept list a NEW variable is
# simply dropped: measured 2026-09-15, CONFORMANCE_WEB_PROBE was set exactly
# per the convention and never reached the runner, so the diagnostic it gated
# silently did not run. Nothing said so — the only signal was an output file
# that never appeared. The explicit exports below stay for the ones that are
# transformed rather than passed through.
for _conf_var in ${!CONFORMANCE_*}; do
    export "TEST_RUNNER_$_conf_var=${!_conf_var}"
done
# Conservation, the other direction: every CONFORMANCE_* must now have a
# TEST_RUNNER_ twin. A forwarding loop that silently forwards nothing looks
# exactly like a run with no variables set.
for _conf_var in ${!CONFORMANCE_*}; do
    if ! printenv "TEST_RUNNER_$_conf_var" >/dev/null; then
        echo "error: $_conf_var was not forwarded to the runner" >&2
        exit 1
    fi
done
unset _conf_var
if [[ -n "${CONFORMANCE_FILTER:-}" ]]; then
    export TEST_RUNNER_CONFORMANCE_FILTER="$CONFORMANCE_FILTER"
fi
if [[ "$HOST_MODE" == "codegen" ]]; then
    export TEST_RUNNER_CONFORMANCE_HOST_MODE="codegen"
fi

set -x
xcodebuild test \
    -project "$HOST_DIR/ConformanceHost.xcodeproj" \
    -scheme ConformanceHost \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -parallel-testing-enabled NO \
    -test-timeouts-enabled NO \
    2>&1 | tee "$STAGING/xcodebuild.log" | tail -40
set +x
# 🔻 THE FULL LOG, BECAUSE `tail -40` DISCARDS THE REASON. A compile error, a
# per-fixture diagnostic, anything the runner prints — all of it lived only in
# the last forty lines, so a 45-minute run had to finish before its own failure
# could be read, and a diagnostic printed mid-run could not be read at all.
echo "[conformance] full xcodebuild log: $STAGING/xcodebuild.log"

CONFORMANCE_STAGING="$STAGING" HOST_MODE="$HOST_MODE" "$HOST_DIR/scripts/collect_results.sh"
