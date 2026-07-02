#!/bin/bash
#
# collect_results.sh — pull conformance output from the staging directory
# (written by the UITest run) into $CONFORMANCE_DIR:
#
#   <staging>/results/ios.results.json  -> $CONFORMANCE_DIR/results/ios.results.json
#   <staging>/artifacts/ios/*.png       -> $CONFORMANCE_DIR/artifacts/ios/
#
# Required environment:
#   CONFORMANCE_DIR       destination conformance directory
# Optional:
#   CONFORMANCE_STAGING   staging dir (default: /tmp/jsonui-conformance-ios)
#
set -euo pipefail

STAGING="${CONFORMANCE_STAGING:-/tmp/jsonui-conformance-ios}"

if [[ -z "${CONFORMANCE_DIR:-}" ]]; then
    echo "error: CONFORMANCE_DIR is not set" >&2
    exit 1
fi

RESULTS_SRC="$STAGING/results/ios.results.json"
if [[ ! -f "$RESULTS_SRC" ]]; then
    echo "error: $RESULTS_SRC not found — did the UITest run complete?" >&2
    echo "hint: check the xcodebuild log / .xcresult for early failures" >&2
    exit 1
fi

mkdir -p "$CONFORMANCE_DIR/results" "$CONFORMANCE_DIR/artifacts/ios"
cp "$RESULTS_SRC" "$CONFORMANCE_DIR/results/ios.results.json"

SHOT_COUNT=0
if compgen -G "$STAGING/artifacts/ios/*.png" > /dev/null; then
    rsync -a "$STAGING/artifacts/ios/" "$CONFORMANCE_DIR/artifacts/ios/"
    SHOT_COUNT=$(ls "$STAGING/artifacts/ios" | wc -l | tr -d ' ')
fi

python3 - "$CONFORMANCE_DIR/results/ios.results.json" <<'EOF'
import json, sys, collections
data = json.load(open(sys.argv[1]))
counts = collections.Counter(r["status"] for r in data["results"])
print(f"collected ios.results.json: {len(data['results'])} results "
      f"({', '.join(f'{k}={v}' for k, v in sorted(counts.items()))})")
EOF
echo "collected $SHOT_COUNT screenshots -> $CONFORMANCE_DIR/artifacts/ios/"
