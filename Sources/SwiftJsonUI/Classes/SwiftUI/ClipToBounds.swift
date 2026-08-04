//
//  ClipToBounds.swift
//  SwiftJsonUI
//
//  `clipToBounds` — a conditional `.clipped()`.
//
//  SwiftUI has no conditional modifier, and the `View.if` helper that would
//  express one is module-internal, so generated code had no way to write
//  "clip only when this is true". Codegen worked around it by deciding at
//  build time, which silently made the bound form clip unconditionally (Ruby
//  truthiness: the string "@{x}" is truthy). This is the public seam both
//  render paths call instead.
//

import SwiftUI

public extension View {
    /// Clips to bounds when `enabled`, and leaves the view untouched
    /// otherwise.
    ///
    /// Taking the flag as a parameter rather than branching at the call site
    /// is what lets a *bound* `clipToBounds` work: the value is resolved at
    /// render time, so `@{shouldClip}` toggles with the data instead of
    /// freezing at whatever the generator saw.
    @ViewBuilder
    func clipToBounds(_ enabled: Bool) -> some View {
        if enabled {
            self.clipped()
        } else {
            self
        }
    }
}
