#!/bin/bash
#
# Runs a command (CI's `xcodebuild test`) with all of its output in LOG,
# prints the progress lines while it runs, and stops it BY NAME when it
# hangs, instead of leaving the job to its timeout.
#
#   xcodebuild_watchdog.sh LOG LIMIT_SECONDS AFTER_SUITE_SECONDS -- command...
#
# Why: the CI step used to be `xcodebuild test ... | tee LOG | tail -100`.
# tail prints nothing until its input closes, so when xcodebuild never
# exited the job page held no test line at all and the job was cancelled at
# 60 min (run 36080760768, Xcode 26.3 leg): a hang in the build, in a test,
# and after the suite had finished all looked the same.
#
# It stops the command when either happens first:
#   - LIMIT_SECONDS have passed since it started, or
#   - the suite's closing line ("Test Suite 'All tests' passed|failed") has
#     been in the log for AFTER_SUITE_SECONDS and the command has not exited
#     (xcodebuild has been seen to finish the suite and then not exit).
# Either way it prints the last 80 lines of LOG, the processes that matter
# and the booted simulators, kills the command and exits 1 with the form
# named. Otherwise it exits with the command's own status.

set -u

log=$1
limit=$2
after_suite=$3
shift 3
[ "${1:-}" = "--" ] && shift

: > "$log"
"$@" > "$log" 2>&1 &
pid=$!

# What the job page shows while it runs: the suite boundaries, the arms that
# failed or skipped, the tests' own bracketed prints and the verdict lines.
progress='^Test Suite |^Test Case .*(failed|skipped) \(|^\[[A-Za-z]+\] |error:|^\*\* [A-Z ]+ \*\*'
shown=0
show_new_lines() {
  # Only whole lines: the last one may still be being written.
  local complete
  complete=$(wc -l < "$log" | tr -d ' ')
  if [ "$complete" -gt "$shown" ]; then
    sed -n "$((shown + 1)),${complete}p" "$log" | grep -E "$progress" || true
    shown=$complete
  fi
}

start=$(date +%s)
suite_closed_at=
form=
while kill -0 "$pid" 2>/dev/null; do
  sleep 5
  show_new_lines
  now=$(date +%s)
  if [ -z "$suite_closed_at" ] && grep -q -E "^Test Suite 'All tests' (passed|failed)" "$log"; then
    suite_closed_at=$now
  fi
  if [ -n "$suite_closed_at" ] && [ $((now - suite_closed_at)) -ge "$after_suite" ]; then
    form="the suite finished but the command did not exit within ${after_suite} s"
    break
  fi
  if [ $((now - start)) -ge "$limit" ]; then
    form="hung after $((limit / 60)) min ($((now - start)) s)"
    break
  fi
done

if [ -n "$form" ]; then
  echo "::group::last 80 lines of $log"
  tail -n 80 "$log"
  echo "::endgroup::"
  echo "processes:"
  ps -axo pid,etime,command | grep -E 'xcodebuild|simctl|XCTest|xctest|launchd_sim' | grep -v -E 'grep|xcodebuild_watchdog' || true
  echo "booted simulators:"
  xcrun simctl list devices booted 2>&1 || true
  # Its direct children too: killing only the parent leaves them running.
  pkill -P "$pid" 2>/dev/null
  kill "$pid" 2>/dev/null
  sleep 5
  pkill -9 -P "$pid" 2>/dev/null
  kill -9 "$pid" 2>/dev/null
  echo "::error::$form — last lines above"
  exit 1
fi

wait "$pid"
status=$?
show_new_lines
exit "$status"
