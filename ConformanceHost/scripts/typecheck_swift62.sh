#!/usr/bin/env bash
#
# typecheck_swift62.sh — optional pre-push check: type-check ConformanceHost
# with a Swift 6.2 compiler, the language version of the CI pin (Xcode 26.3).
#
# Why: conformance-mobile builds the host with Xcode 26.3 (Swift 6.2). Local
# Xcodes are 26.5+ (Swift 6.3+), whose constraint solver checks some
# expressions that 6.2 gives up on. Run 36196156936 failed both iOS jobs with
# "unable to type-check this expression in reasonable time" on an expression
# (a 20-`+` String chain in CanTapCodegenProbeView) that Xcode 26.5/26.6
# checked in ~20 ms, so no local build could have caught it.
#
# What it proves: it FAILS LIKE CI'S XCODE 26.3 ON SWIFT-6.2-ONLY TYPE-CHECK
# FAILURES. Measured: on the tree CI failed on, it reports that same
# expression (CanTapCodegenProbeView.swift:56) as the only error of the 28
# App files, as CI did; after the fix it reports 0. Every run first checks a
# control — that same 20-`+` shape, standalone — and stops if the compiler
# in hand does NOT fail on it (then it is not behaving like Swift 6.2, and a
# green result would mean nothing).
#
# What it does NOT prove:
# - It is not Xcode 26.3. The compiler is the swift.org open-source Swift
#   6.2.4 toolchain (an assertions build), not Apple's Swift 6.2 build.
#   Their type checkers come from the same release, but they are different
#   builds.
# - The SDK is not CI's. CI compiles against iPhoneSimulator 26.2; this uses
#   the iPhoneSimulator SDK of an installed Xcode (checked with 26.5).
#   SwiftUI/UIKit overload sets differ between SDKs, so an expression near
#   the limit can land differently. An SDK built by a newer compiler (27.x)
#   may not load in 6.2 at all; the run says so if it happens.
# - It type-checks; it does not build, link or run anything. No simulator.
# - Times are wall-clock and depend on load. The verdict it gates on is the
#   error count, not the times.
#
# Usage (from anywhere):
#   ConformanceHost/scripts/typecheck_swift62.sh fetch   # once: ~1.7 GB download, ~5.4 GB on disk
#   ConformanceHost/scripts/typecheck_swift62.sh         # check (exit 1 on any type-check error)
#
# Environment:
#   SWIFT62_HOME        toolchain dir (default ~/Library/Caches/SwiftJsonUI/swift-6.2.4-RELEASE);
#                       the check uses $SWIFT62_HOME/usr/bin/swiftc
#   DEVELOPER_DIR       the Xcode whose iPhoneSimulator SDK is used (default: the selected
#                       Xcode). Set it per command; this script never runs xcode-select.
#   THRESHOLD_MS        list functions/expressions slower than this (default 300)
#   SKIP_CONTROL=1      skip the control (the run prints that it was skipped)
#   SWIFT62_PKG         fetch: use this already-downloaded pkg instead of downloading
#                       (the sha256 and signature are checked the same way)
#
# What it checks:
#   - SwiftJsonUI (Sources/) is emitted as a module by the same compiler.
#   - App/ the way scripts/generate_project.rb selects it: dynamic-only, or
#     with CodegenStaging/ when scripts/generate_codegen_host.rb has run.
#   - UITests/ when scripts/sync_fixtures.sh has vendored the driver;
#     otherwise it prints that UITests were not checked.
#   Measured wall time: 2-3 min dynamic-only; 2.5-11 min with CodegenStaging
#   (~1,900 files), depending on machine load.
#
set -euo pipefail

VERSION=6.2.4
PKG="swift-${VERSION}-RELEASE-osx.pkg"
URL="https://download.swift.org/swift-${VERSION}-release/xcode/swift-${VERSION}-RELEASE/${PKG}"
# Measured 2026-09-26 on the pkg fetched from $URL (Developer ID Installer:
# Swift Open Source (V9AUD2URP3), notarized).
PKG_SHA256=9c94637fda8312901a08e572a651c3a18a672689ad867f96c9257b43775159e9
SIGNER="Developer ID Installer: Swift Open Source (V9AUD2URP3)"

HOST_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_DIR="$(cd "$HOST_DIR/.." && pwd)"
SWIFT62_HOME="${SWIFT62_HOME:-$HOME/Library/Caches/SwiftJsonUI/swift-${VERSION}-RELEASE}"
SWIFTC="$SWIFT62_HOME/usr/bin/swiftc"
WORK="$HOST_DIR/build/typecheck-swift62"
THRESHOLD_MS="${THRESHOLD_MS:-300}"

fetch() {
    if [[ -x "$SWIFTC" ]]; then
        echo "already present: $SWIFTC ($("$SWIFTC" --version 2>&1 | head -1))"
        return 0
    fi
    local tmp="$SWIFT62_HOME.download"
    rm -rf "$tmp"
    mkdir -p "$tmp"
    if [[ -n "${SWIFT62_PKG:-}" ]]; then
        echo "using the already-downloaded $SWIFT62_PKG"
        cp "$SWIFT62_PKG" "$tmp/$PKG"
    else
        echo "downloading $URL"
        curl -fL --retry 3 -o "$tmp/$PKG" "$URL"
    fi
    local sum
    sum=$(shasum -a 256 "$tmp/$PKG" | cut -d' ' -f1)
    if [[ "$sum" != "$PKG_SHA256" ]]; then
        echo "error: sha256 $sum != expected $PKG_SHA256" >&2
        exit 2
    fi
    local sig
    sig=$(pkgutil --check-signature "$tmp/$PKG")
    if ! grep -qF "$SIGNER" <<<"$sig" || ! grep -q "Notarization: trusted" <<<"$sig"; then
        echo "error: unexpected signature:" >&2
        echo "$sig" >&2
        exit 2
    fi
    echo "sha256 and signature ok; expanding (not installing)"
    pkgutil --expand-full "$tmp/$PKG" "$tmp/x"
    local payload
    payload=$(find "$tmp/x" -maxdepth 2 -type d -name Payload | head -1)
    [[ -x "$payload/usr/bin/swiftc" ]] || { echo "error: no usr/bin/swiftc in the pkg payload" >&2; exit 2; }
    mkdir -p "$SWIFT62_HOME"
    mv "$payload/usr" "$SWIFT62_HOME/usr"
    rm -rf "$tmp"
    echo "installed to $SWIFT62_HOME: $("$SWIFTC" --version 2>&1 | head -1)"
}

# Type-check one target. $1 name, $2 file list, $3 log, rest: extra swiftc args.
typecheck() {
    local name="$1" list="$2" log="$3"
    shift 3
    local files=()
    while IFS= read -r f; do [[ -n "$f" ]] && files+=("$f"); done < "$list"
    local start rc=0
    start=$(date +%s)
    "$SWIFTC" -typecheck -sdk "$SDK" -target arm64-apple-ios17.0-simulator -swift-version 5 -Onone -DDEBUG \
        -module-cache-path "$WORK/module-cache" -I "$WORK/module" \
        -continue-building-after-errors \
        -Xfrontend -warn-long-expression-type-checking="$THRESHOLD_MS" \
        -Xfrontend -warn-long-function-bodies="$THRESHOLD_MS" \
        "$@" "${files[@]}" > "$log" 2>&1 || rc=$?
    local errors
    errors=$(grep -cE '^/.*: error: ' "$log" || true)
    echo "$name: ${#files[@]} files, errors=$errors, rc=$rc, $(( $(date +%s) - start ))s (log: $log)"
    grep -E '^/.*: error: ' "$log" | sed -E "s#^$REPO_DIR/##; s#^$HOST_DIR/##" | sort -u | sed 's/^/  /' || true
    local slow
    slow=$(grep -E "^/.*: warning: .* took [0-9]+ms to type-check" "$log" \
        | sed -E "s#^$REPO_DIR/##; s#^$HOST_DIR/##; s/: warning: /: /" \
        | awk '{ for (i = 1; i <= NF; i++) if ($i == "took") { ms = $(i + 1); sub("ms", "", ms); print ms "\t" $0 } }' \
        | sort -rn | cut -f2- || true)
    echo "  over ${THRESHOLD_MS} ms: $(grep -c . <<<"$slow" || true)"
    if [[ -n "$slow" ]]; then
        sed 's/^/    /' <<<"$slow"
    fi
    TOTAL_ERRORS=$(( TOTAL_ERRORS + errors + (rc != 0 && errors == 0 ? 1 : 0) ))
}

check() {
    if [[ ! -x "$SWIFTC" ]]; then
        echo "error: no Swift $VERSION toolchain at $SWIFT62_HOME — run: $0 fetch" >&2
        exit 2
    fi
    local version
    version=$("$SWIFTC" --version 2>&1 | head -1)
    [[ "$version" == *"Swift version 6.2"* ]] || { echo "error: $SWIFTC is not Swift 6.2: $version" >&2; exit 2; }
    SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
    echo "compiler: $version"
    echo "sdk:      $SDK (CI compiles against iPhoneSimulator 26.2 — see the header)"
    mkdir -p "$WORK"

    # ---- control: the compiler in hand must fail where Swift 6.2 fails
    if [[ "${SKIP_CONTROL:-}" == 1 ]]; then
        echo "control:  SKIPPED (SKIP_CONTROL=1) — nothing shows this compiler behaves like Swift 6.2"
    else
        cat > "$WORK/Swift62Control.swift" <<'EOF'
import Foundation

// The readout shape ConformanceHost shipped in SwiftJsonUI 44f69c6: 21
// strings joined by 20 `+`, one operand a closure-bearing call. Swift 6.2
// cannot type-check it; Swift 6.3 checks it in ~20 ms.
struct Swift62Control {
    var counts: [String: Int] = [:]
    var a = "", b = "", c = "", d = ""
    var e = false, f = false, g = false, h = false
    var readout: String {
        "counts[" + counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",") + "] " +
            "radios[" + "a=\(a)" + "," + "b=\(b)" + "," + "c=\(c)" + "," + "d=\(d)" + "] " +
            "checks[" + "e=\(e)" + "," + "f=\(f)" + "," + "g=\(g)" + "," + "h=\(h)" + "]"
    }
}
EOF
        local start
        start=$(date +%s)
        if "$SWIFTC" -typecheck -sdk "$SDK" -target arm64-apple-ios17.0-simulator -parse-as-library \
                -module-cache-path "$WORK/module-cache" "$WORK/Swift62Control.swift" > "$WORK/control.log" 2>&1; then
            echo "error: control type-checked — this compiler does not fail where Swift 6.2 does," >&2
            echo "       so a green run would say nothing about the CI pin. (log: $WORK/control.log)" >&2
            exit 3
        fi
        if ! grep -q 'unable to type-check this expression in reasonable time' "$WORK/control.log"; then
            echo "error: control failed for another reason (SDK not loadable by Swift 6.2?):" >&2
            grep -E 'error:' "$WORK/control.log" | head -5 >&2
            exit 3
        fi
        echo "control:  fails as Swift 6.2 does ($(( $(date +%s) - start ))s)"
    fi

    # ---- SwiftJsonUI module, emitted by the same compiler
    local srclist="$WORK/sources.txt"
    find "$REPO_DIR/Sources" -name '*.swift' | sort > "$srclist"
    local srcs=()
    while IFS= read -r f; do srcs+=("$f"); done < "$srclist"
    rm -rf "$WORK/module"
    mkdir -p "$WORK/module"
    if ! "$SWIFTC" -emit-module -module-name SwiftJsonUI -parse-as-library -swift-version 5 -Onone -DDEBUG \
            -sdk "$SDK" -target arm64-apple-ios17.0-simulator -module-cache-path "$WORK/module-cache" \
            -emit-module-path "$WORK/module/SwiftJsonUI.swiftmodule" \
            -experimental-skip-non-inlinable-function-bodies -enable-testing \
            "${srcs[@]}" > "$WORK/module.log" 2>&1; then
        echo "error: SwiftJsonUI did not compile with Swift $VERSION:" >&2
        grep -E 'error:' "$WORK/module.log" | head -10 >&2
        exit 1
    fi
    echo "module:   SwiftJsonUI from ${#srcs[@]} files"

    TOTAL_ERRORS=0

    # ---- App: the selection scripts/generate_project.rb makes
    local applist="$WORK/app.txt" mode="dynamic-only"
    find "$HOST_DIR/App" -name '*.swift' | sort > "$applist"
    if [[ -f "$HOST_DIR/CodegenStaging/CodegenFixtureRegistry.swift" ]]; then
        mode="with CodegenStaging"
        grep -v '/CodegenFixtureRegistryDefault\.swift$' "$applist" > "$applist.tmp" || true
        { cat "$applist.tmp"
          for d in View Data ResourceManager; do
              [[ -d "$HOST_DIR/CodegenStaging/$d" ]] && find "$HOST_DIR/CodegenStaging/$d" -name '*.swift'
          done
          echo "$HOST_DIR/CodegenStaging/CodegenFixtureRegistry.swift"
        } | sort > "$applist"
        rm -f "$applist.tmp"
    fi
    typecheck "App ($mode)" "$applist" "$WORK/app.log" -module-name ConformanceHost

    # ---- UITests: only when the driver has been vendored
    if [[ -n "$(find "$HOST_DIR/UITests/Vendor/JsonUITestRunner" -name '*.swift' 2>/dev/null | head -1)" ]]; then
        local platform
        platform="$(cd "$SDK/../.." && pwd)"
        find "$HOST_DIR/UITests" -name '*.swift' | sort > "$WORK/uitests.txt"
        typecheck "UITests" "$WORK/uitests.txt" "$WORK/uitests.log" -module-name ConformanceHostUITests \
            -F "$platform/Library/Frameworks" -I "$platform/usr/lib"
    else
        echo "UITests:  NOT CHECKED — UITests/Vendor/JsonUITestRunner is empty (run scripts/sync_fixtures.sh)"
    fi

    if (( TOTAL_ERRORS > 0 )); then
        echo "FAIL: $TOTAL_ERRORS type-check error(s) under Swift $VERSION"
        exit 1
    fi
    echo "OK: 0 type-check errors under Swift $VERSION"
}

case "${1:-check}" in
    fetch) fetch ;;
    check) check ;;
    *) echo "usage: $0 [fetch|check]" >&2; exit 2 ;;
esac
