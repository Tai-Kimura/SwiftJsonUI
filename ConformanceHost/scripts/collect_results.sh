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

HOST_MODE="${HOST_MODE:-dynamic}"
if [[ "$HOST_MODE" == "codegen" ]]; then
    # codegen host output: never clobbers the dynamic results/artifacts —
    # results go under codegen/ (outside results/, which the report treats
    # as the per-platform dynamic truth) and artifacts under ios-codegen/
    # (the directory `jui conformance parity` reads).
    STAGING="${CONFORMANCE_STAGING:-/tmp/jsonui-conformance-ios-codegen}"
    RESULTS_DEST_REL="codegen/ios.results.json"
    ARTIFACTS_DEST_REL="artifacts/ios-codegen"
else
    STAGING="${CONFORMANCE_STAGING:-/tmp/jsonui-conformance-ios}"
    RESULTS_DEST_REL="results/ios.results.json"
    ARTIFACTS_DEST_REL="artifacts/ios"
fi

if [[ -z "${CONFORMANCE_DIR:-}" ]]; then
    echo "error: CONFORMANCE_DIR is not set" >&2
    exit 1
fi
RESULTS_DEST="$CONFORMANCE_DIR/$RESULTS_DEST_REL"
ARTIFACTS_DEST="$CONFORMANCE_DIR/$ARTIFACTS_DEST_REL"

RESULTS_SRC="$STAGING/results/ios.results.json"
if [[ ! -f "$RESULTS_SRC" ]]; then
    echo "error: $RESULTS_SRC not found — did the UITest run complete?" >&2
    echo "hint: check the xcodebuild log / .xcresult for early failures" >&2
    exit 1
fi

mkdir -p "$(dirname "$RESULTS_DEST")" "$ARTIFACTS_DEST"
cp "$RESULTS_SRC" "$RESULTS_DEST"

SHOT_COUNT=0
if compgen -G "$STAGING/artifacts/ios/*.png" > /dev/null; then
    rsync -a "$STAGING/artifacts/ios/" "$ARTIFACTS_DEST/"
    SHOT_COUNT=$(ls "$STAGING/artifacts/ios" | wc -l | tr -d ' ')
fi

python3 - "$RESULTS_DEST" <<'EOF'
import json, sys, collections
data = json.load(open(sys.argv[1]))
counts = collections.Counter(r["status"] for r in data["results"])
print(f"collected {sys.argv[1].rsplit('/', 1)[-1]}: {len(data['results'])} results "
      f"({', '.join(f'{k}={v}' for k, v in sorted(counts.items()))})")
EOF
echo "collected $SHOT_COUNT screenshots -> $ARTIFACTS_DEST/"
