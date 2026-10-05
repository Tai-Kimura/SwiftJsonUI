//
//  LeafAccessibilityIdentifier.swift
//  SwiftJsonUI
//
//  Where a composite leaf's layout id goes.
//
//  A component drawn as several SwiftUI views — a TextField with its clear
//  button or styled placeholder overlay, a TextView with its hint — took the
//  layout id on the composite as a whole, bare. SwiftUI hands an identifier
//  on a view that is not an accessibility element to EVERY element inside it,
//  so the button, the placeholder and the hint each carried the field's id:
//  a test driver's tap pressed the clear button, an empty TextView read as its
//  hint (ticket sjui-a-composite-leaf-gives-its-id-to-every-element-inside).
//  Hiding those parts (`.accessibilityHidden`) does not hold: measured
//  (XCUITest, iOS 26.5), under an ancestor that is an explicit accessibility
//  container — every Dynamic container with an id, every generated root — a
//  hidden part is found with the id again. The id goes on the input itself
//  instead, before any overlay is added, and nothing else in the composite
//  carries it.
//

import SwiftUI

public extension View {
    /// `.accessibilityIdentifier(id)` when there is one.
    @ViewBuilder
    func leafAccessibilityIdentifier(_ id: String?) -> some View {
        if let id, !id.isEmpty {
            self.accessibilityIdentifier(id)
        } else {
            self
        }
    }
}
