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
#   CONFORMANCE_STAGING   the run's staging dir (run_conformance.sh passes
#                         it; a run makes its own, so there is no default)
#
set -euo pipefail

HOST_MODE="${HOST_MODE:-dynamic}"
if [[ "$HOST_MODE" == "codegen" ]]; then
    # codegen host output: never clobbers the dynamic results/artifacts —
    # results go under codegen/ (outside results/, which the report treats
    # as the per-platform dynamic truth) and artifacts under ios-codegen/
    # (the directory `jui conformance parity` reads).
    RESULTS_DEST_REL="codegen/ios.results.json"
    ARTIFACTS_DEST_REL="artifacts/ios-codegen"
else
    RESULTS_DEST_REL="results/ios.results.json"
    ARTIFACTS_DEST_REL="artifacts/ios"
fi

if [[ -z "${CONFORMANCE_DIR:-}" ]]; then
    echo "error: CONFORMANCE_DIR is not set" >&2
    exit 1
fi
# No default: the staging was one fixed /tmp path, and a run now makes its
# own (run_conformance.sh). A default here would read whichever run last
# used the old path — the collision this replaced.
if [[ -z "${CONFORMANCE_STAGING:-}" ]]; then
    echo "error: CONFORMANCE_STAGING is not set — the run's staging dir (run_conformance.sh passes it)" >&2
    exit 1
fi
STAGING="$CONFORMANCE_STAGING"
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
