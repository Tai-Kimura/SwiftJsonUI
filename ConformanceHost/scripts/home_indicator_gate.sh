#!/bin/bash
# home_indicator_gate.sh — run by run_conformance.sh after the tests and
# before collect_results.sh. Exits non-zero, so nothing is collected, when a
# screenshot still shows the simulator's home indicator after being taken
# again.
#
# Environment (set by run_conformance.sh): STAGING, HOST_DIR, DESTINATION,
# DERIVED_DATA, and SIMULATOR_UDID. The udid is what gets rebooted. When it is
# empty it is taken from DESTINATION: its `id=`, or, for `name=`, the one
# booted simulator of that name. Two booted ones of that name (another run's)
# are not guessed between: nothing is rebooted and the run stops.
#
# 🔻 THE HOME INDICATOR, CHECKED BEFORE ANYTHING IS COLLECTED. The baselines
# never show it, and a screenshot that does differs from its baseline only
# there. It comes and goes with the simulator, not with the fixture (2026-10-05:
# 178 of 178 on a simulator booted for two days, 0 after a reboot, and 80 in a
# row for six minutes of a run started right after one). So every screenshot
# the results name is read (scripts/home_indicator.swift); the fixtures that
# show it are taken again on a rebooted simulator, their entries and files
# replace the first ones, and the run stops here, before collect, if any still
# shows it. The counts are printed on one line either way.
set -euo pipefail
: "${STAGING:?}" "${HOST_DIR:?}" "${DESTINATION:?}" "${DERIVED_DATA:?}"

home_indicator_list() { # <staging> <out-list> [ids-file]: the screenshots the results name
    python3 - "$1" "$2" "${3:-}" <<'EOF'
import json, os, sys
staging, out, only = sys.argv[1], sys.argv[2], sys.argv[3]
keep = set(open(only).read().split()) if only else None
results = json.load(open(os.path.join(staging, "results", "ios.results.json")))["results"]
with open(out, "w") as fh:
    for e in results:
        if e.get("screenshot") and (keep is None or e["id"] in keep):
            fh.write(f'{e["id"]}\t{os.path.join(staging, e["screenshot"])}\n')
EOF
}
home_indicator_check() { # <list> -> ids that show it, one per line, on stdout
    cut -f2 "$1" > "$1.paths"
    xcrun swift "$HOST_DIR/scripts/home_indicator.swift" "$1.paths" > "$1.out" || return 2
    python3 - "$1" "$1.out" <<'EOF'
import sys
by_path = dict(reversed(l.rstrip("\n").split("\t", 1)) for l in open(sys.argv[1]) if l.strip())
for l in open(sys.argv[2]):
    if l.startswith("HOME_INDICATOR "):
        print(by_path[l[len("HOME_INDICATOR "):].rstrip("\n")])
EOF
}
HI_DIR="$STAGING/home-indicator"
mkdir -p "$HI_DIR"
home_indicator_list "$STAGING" "$HI_DIR/all.tsv"
home_indicator_check "$HI_DIR/all.tsv" > "$HI_DIR/found.txt" || { echo "error: home indicator check could not run" >&2; exit 1; }
HI_CHECKED=$(wc -l < "$HI_DIR/all.tsv" | tr -d ' ')
HI_FOUND=$(grep -c . "$HI_DIR/found.txt" || true)
HI_STILL=0
HI_RETAKEN=0
if [[ "$HI_FOUND" -gt 0 ]]; then
    sed 's/^/HOME_INDICATOR /' "$HI_DIR/found.txt"
    if [[ -z "${SIMULATOR_UDID:-}" ]]; then
        SIMULATOR_UDID="$(python3 - "$DESTINATION" <<'EOF'
import json, subprocess, sys
fields = dict(kv.split("=", 1) for kv in sys.argv[1].split(",") if "=" in kv)
if fields.get("id"):
    print(fields["id"]); sys.exit(0)
name = fields.get("name")
devices = json.loads(subprocess.run(["xcrun", "simctl", "list", "-j", "devices", "booted"],
                                    capture_output=True, text=True).stdout or "{}").get("devices", {})
booted = [d["udid"] for ds in devices.values() for d in ds if d.get("name") == name]
print(booted[0] if len(booted) == 1 else "")
EOF
)"
        echo "[home-indicator] simulator to reboot, from DESTINATION ($DESTINATION): ${SIMULATOR_UDID:-none (not exactly one booted)}"
    fi
    if [[ -z "${SIMULATOR_UDID:-}" ]]; then
        echo "[home-indicator] screenshots $HI_CHECKED, with the indicator $HI_FOUND, taken again 0 (no simulator to reboot)" >&2
        exit 1
    fi
    xcrun simctl shutdown "$SIMULATOR_UDID" >/dev/null 2>&1 || true
    xcrun simctl boot "$SIMULATOR_UDID" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$SIMULATOR_UDID" -b >/dev/null 2>&1 || true
    xcrun simctl status_bar "$SIMULATOR_UDID" override \
        --time "9:41" --batteryState charged --batteryLevel 100 \
        --wifiBars 3 --cellularBars 4 --dataNetwork wifi --operatorName "" >/dev/null 2>&1 || true
    RETAKE="$STAGING/retake"
    rm -rf "$RETAKE"; mkdir -p "$RETAKE"
    # The filter matches substrings, so it can take more fixtures than were
    # asked for; only the ones asked for are replaced below.
    TEST_RUNNER_CONFORMANCE_STAGING_DIR="$RETAKE" \
    TEST_RUNNER_CONFORMANCE_FILTER="$(paste -sd, "$HI_DIR/found.txt")" \
    xcodebuild test \
        -project "$HOST_DIR/ConformanceHost.xcodeproj" \
        -scheme ConformanceHost \
        -destination "$DESTINATION" \
        -derivedDataPath "$DERIVED_DATA" \
        -parallel-testing-enabled NO \
        -test-timeouts-enabled NO \
        -only-testing:ConformanceHostUITests/ConformanceUITests \
        > "$STAGING/xcodebuild-retake.log" 2>&1 || true
    python3 - "$STAGING" "$RETAKE" "$HI_DIR/found.txt" > "$HI_DIR/replaced.txt" <<'EOF'
import json, os, shutil, sys
staging, retake, found = sys.argv[1], sys.argv[2], sys.argv[3]
ids = set(open(found).read().split())
main_path = os.path.join(staging, "results", "ios.results.json")
main = json.load(open(main_path))
again = {e["id"]: e for e in json.load(open(os.path.join(retake, "results", "ios.results.json")))["results"]}
replaced = 0
for i, e in enumerate(main["results"]):
    if e["id"] in ids and e["id"] in again and again[e["id"]].get("screenshot"):
        new = again[e["id"]]
        for key in ("screenshot", "frames"):
            if new.get(key):
                dst = os.path.join(staging, new[key])
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy2(os.path.join(retake, new[key]), dst)
        main["results"][i] = new
        replaced += 1
json.dump(main, open(main_path, "w"), indent=2)
print(replaced)
EOF
    home_indicator_list "$STAGING" "$HI_DIR/again.tsv" "$HI_DIR/found.txt"
    home_indicator_check "$HI_DIR/again.tsv" > "$HI_DIR/still.txt" || { echo "error: home indicator check could not run" >&2; exit 1; }
    HI_STILL=$(grep -c . "$HI_DIR/still.txt" || true)
    HI_RETAKEN=$(cat "$HI_DIR/replaced.txt")
fi
echo "[home-indicator] screenshots $HI_CHECKED, with the indicator $HI_FOUND, taken again $HI_RETAKEN, still showing it $HI_STILL"
if [[ "$HI_STILL" -gt 0 ]]; then
    sed 's/^/HOME_INDICATOR still: /' "$HI_DIR/still.txt" >&2
    echo "error: $HI_STILL screenshot(s) still show the home indicator; not collecting" >&2
    exit 1
fi

