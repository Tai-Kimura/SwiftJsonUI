#!/bin/bash
#
# Boots the CI test simulator, with a limit on each attempt and every
# attempt's seconds and outcome printed, and prints the UDID that booted as
# its last line of stdout (everything else goes to stderr).
#
#   DEST_ID=$(bash scripts/ci_boot_simulator.sh UDID OS_MAJOR LIMIT_SECONDS)
#
# Why: run 36085845499's Xcode 26.3 leg waited 600 s on "Waiting on
# BackBoard" booting the device it had picked (listed Shutdown, under the
# iOS 26.0 runtime), and the same device booted in earlier runs on the same
# runner image. So the boot sometimes stalls; which remedy works is not
# known yet, and the attempts below try them in order and say which one did:
#   1. boot the device as picked;
#   2. shut it down, erase it, boot it again;
#   3. create a new device of the same type on the newest iOS OS_MAJOR
#      runtime installed, and boot that.
# All three failing exits 1 with the attempts named.

set -u

udid=$1
os_major=$2
limit=$3

log() { echo "$@" >&2; }

# Runs `simctl bootstatus -b` on a device for at most `limit` seconds.
boot_within_limit() {
  local id=$1 start pid
  start=$(date +%s)
  xcrun simctl bootstatus "$id" -b >&2 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    sleep 2
    if [ $(( $(date +%s) - start )) -ge "$limit" ]; then
      kill "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      LAST_SECONDS=$(( $(date +%s) - start ))
      LAST_OUTCOME="did not finish booting in ${limit} s"
      return 1
    fi
  done
  if wait "$pid"; then
    LAST_SECONDS=$(( $(date +%s) - start ))
    LAST_OUTCOME="booted"
    return 0
  fi
  LAST_SECONDS=$(( $(date +%s) - start ))
  LAST_OUTCOME="simctl bootstatus failed"
  return 1
}

report() {
  log "boot attempt $1 ($2): ${LAST_OUTCOME} after ${LAST_SECONDS} s"
}

# The picked device's type, from simctl's JSON (a device's name need not be
# its type's).
device_type=$(xcrun simctl list devices -j | python3 -c '
import json, sys
udid = sys.argv[1]
for devices in json.load(sys.stdin)["devices"].values():
    for d in devices:
        if d["udid"] == udid:
            print(d.get("deviceTypeIdentifier", ""))
' "$udid")

if boot_within_limit "$udid"; then
  report 1 "$udid as picked"
  echo "$udid"
  exit 0
fi
report 1 "$udid as picked"

xcrun simctl shutdown "$udid" >&2 2>&1 || true
xcrun simctl erase "$udid" >&2 2>&1 || true
if boot_within_limit "$udid"; then
  report 2 "$udid after shutdown + erase"
  echo "$udid"
  exit 0
fi
report 2 "$udid after shutdown + erase"
xcrun simctl shutdown "$udid" >&2 2>&1 || true

# The newest available iOS OS_MAJOR runtime.
runtime=$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
major = sys.argv[1]
found = [(tuple(int(x) for x in r["version"].split(".")), r["identifier"])
         for r in json.load(sys.stdin)["runtimes"]
         if r.get("platform") == "iOS" and r.get("isAvailable")
         and r["version"].split(".")[0] == major]
print(max(found)[1] if found else "")
' "$os_major")
if [ -z "$runtime" ] || [ -z "$device_type" ]; then
  log "::error::the simulator did not boot in 2 attempts, and no iOS ${os_major} runtime or device type to create a new one (runtime='${runtime}', type='${device_type}')"
  exit 1
fi
fresh=$(xcrun simctl create "ci-fresh-${os_major}" "$device_type" "$runtime" 2>&1) || {
  log "::error::the simulator did not boot in 2 attempts, and simctl create failed: $fresh"
  exit 1
}
if boot_within_limit "$fresh"; then
  report 3 "new ${device_type} ${fresh} on ${runtime}"
  echo "$fresh"
  exit 0
fi
report 3 "new ${device_type} ${fresh} on ${runtime}"
log "::error::the simulator did not boot in 3 attempts — see the attempts above"
xcrun simctl list devices booted >&2 || true
exit 1
