# UI tests on an optimized (Release-like) build

The screen marker — the beacon generated SwiftUI screens carry so a JsonUI UI
test can tell which screen is on display — draws in a DEBUG build, so a
shipped (Release) app never carries it. To run the UI tests on the optimized
code a release ships, make a configuration from Release and turn the marker on
in the app's Info.plist for that configuration only. The key is:

```
com.swiftjsonui.SCREEN_MARKER
```

Android has the same switch as application meta-data
(`com.kotlinjsonui.SCREEN_MARKER`): see KotlinJsonUI's
`Docs/ui-tests-on-release-builds.md`.

## 1. A configuration made from Release

In the project's Info → Configurations, duplicate **Release** (for example
`UITestRelease`) and point the UI-test scheme's Test action at it. It keeps
Release's optimization; SwiftPM compiles SwiftJsonUI in it as Release (`-O`,
no `DEBUG`).

## 2. A user-defined build setting, set in that configuration only

On the app target, add the user-defined setting `JSONUI_SCREEN_MARKER` and give
it `YES` in `UITestRelease`. Leave it unset everywhere else.

## 3. The key in the app's Info.plist

```xml
<key>com.swiftjsonui.SCREEN_MARKER</key>
<string>$(JSONUI_SCREEN_MARKER)</string>
```

Xcode expands it per configuration: `"YES"` in `UITestRelease`, `""` in
Release, so Release — what ships — draws no marker, as before. (With a
generated Info.plist, put the key in a small `Info.plist` named by
`INFOPLIST_FILE`; Xcode merges the two.)

The value reads as on when it is `YES`, `TRUE` or `1` (any case), a plist
boolean true, or a nonzero number; anything else, an empty string or no key is
off.

## Why not a compilation condition

`#if DEBUG || SOMETHING` cannot do this: SwiftPM compiles the package with its
own settings, and the app's `SWIFT_ACTIVE_COMPILATION_CONDITIONS` — on the
target or on the project — does not reach it. Only an `xcodebuild`
command-line override or `-xcconfig` does, which Xcode's own Test action never
passes. (Measured with Xcode 27 RC.)

## Notes

- UIKit-mode screens (`applyScreenMarker`) still draw the marker in DEBUG
  builds only.
- From SwiftJsonUI 10.29.10. Ticket:
  sjui-screenmarker-compiled-out-in-release-blocks-optimized-ui-tests.
- The same key turns on the test bridge (SwiftJsonUI 10.30.0,
  `jsonUITestBridge`): the screen applies a UI test's `initialState` and
  publishes its Data for the `state` assertion. With the key off — a shipped
  build — the bridge applies nothing and publishes nothing, so a test that
  sends an `initialState` fails on the missing receipt rather than running
  against default values.
