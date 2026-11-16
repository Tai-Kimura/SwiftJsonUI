//
//  A11yActivationCellNoEq.swift
//  ConformanceHost
//
//  The contrast for the A11yActivation probe's generated cell (cgCellNoEq):
//  the cell sjui build generated from ProbeLayouts/cells/
//  a11y_activation_cell.json — its scaffolded A11yActivationCellView — drawn
//  WITHOUT `.equatable()`, under the same bound stop as the generated
//  Collection (cgListBound). Written by hand on purpose: sjui does not emit
//  that form, so it cannot be generated, and the comparison is what it is for
//  (does the stop reach a cell the Collection draws `.equatable()` after the
//  binding flipped?). The stop around it is drawn as the generated container's
//  (`.allowsHitTesting` + `jsonuiInteractionStopped`), from the probe's
//  `gateOpen`. Compiled only in the codegen host (A11yActivationCellNoEq
//  Default.swift otherwise).
//

import SwiftUI
import SwiftJsonUI

// The codegen half of a Dynamic-mode probe: DEBUG only, with the probe.
#if DEBUG

struct A11yActivationCellNoEq: View {
    @ObservedObject var data: A11yActivationProbeData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CollectionStackView(
                mode: .lazy,
                axis: .horizontal,
                verticalAlignment: .top,
                spacing: 0,
                showsIndicators: true,
                scrollDisabled: false
            ) {
                if let dataSource = data.rowsNoEq, dataSource.sections.count > 0 {
                    let section = dataSource.sections[0]
                    if let cellsData = section.cells?.data {
                        ForEach(Array(cellsData.enumerated()), id: \.offset) { cellIndex, cellData in
                            A11yActivationCellView(data: cellData)
                                .accessibilityIdentifier("cgListBoundNoEq_item_\(cellIndex)")
                        }
                    }
                }
            }
                .frame(width: 200, height: 40)
                .accessibilityIdentifier("cgListBoundNoEq")
        }
            .allowsHitTesting((data.gateOpen ?? false))
            .transformEnvironment(\.jsonuiInteractionStopped) { $0 = $0 || !(data.gateOpen ?? false) }
    }
}
#endif
