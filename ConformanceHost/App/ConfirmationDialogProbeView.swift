//
//  ConfirmationDialogProbeView.swift
//  ConformanceHost
//
//  Confirmation-dialog measurement probe — NOT part of the conformance
//  suite. Launch the app with `-confirmationDialogProbe`.
//
//  THE QUESTION. A layout can declare `confirmationDialog` and nothing
//  else, and a consumer reported that on iPad the cancel button is not
//  drawn — leaving only the destructive action visible. The reasoning is
//  that `.confirmationDialog` is presented as a popover in a regular size
//  class, and UIKit omits a popover's cancel because dismissing by tapping
//  outside is supposed to replace it.
//
//  THAT REASONING WAS NEVER MEASURED. It is stated in the report as an
//  inference, and it has already been given to an end user as fact. So the
//  probe has to be able to answer NO: if the cancel is drawn on iPad, the
//  ticket is withdrawn and the consumer owes their user a correction.
//
//  SHAPE. Two arms over identical button sets, so the difference — if any —
//  belongs to the presentation and not to what was declared:
//
//    arm C  .confirmationDialog  destructive + cancel
//    arm A  .alert               destructive + cancel   (control)
//
//  The alert arm is what makes a null result readable. `.alert` is
//  documented to draw every button in both idioms, so an arm that loses its
//  cancel there means the probe, not the API, is what is broken.
//
//  The horizontal size class is published as its own element, because
//  "iPad" and "regular" are not the same claim: an iPad running a
//  multitasking slide-over is compact, and a test that assumed the device
//  implies the class would report on the wrong condition.
//
//  The probe asserts nothing. ConfirmationDialogProbeUITests records.
//

import SwiftUI

struct ConfirmationDialogProbeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var dialogShown = false
    @State private var alertShown = false

    private var sizeClassName: String {
        switch horizontalSizeClass {
        case .regular: return "regular"
        case .compact: return "compact"
        default: return "unknown"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Read by the test before anything is presented, so a run on a
            // device that turned out to be compact is identifiable as such
            // rather than being reported as an iPad result.
            Text(sizeClassName)
                .accessibilityIdentifier("probe_size_class")

            Button("open dialog") { dialogShown = true }
                .accessibilityIdentifier("probe_open_dialog")

            Button("open alert") { alertShown = true }
                .accessibilityIdentifier("probe_open_alert")
        }
        .padding()
        .confirmationDialog("Delete this?",
                            isPresented: $dialogShown,
                            titleVisibility: .visible) {
            Button("probe_destructive", role: .destructive) { }
            Button("probe_cancel", role: .cancel) { }
        }
        .alert("Delete this?", isPresented: $alertShown) {
            Button("probe_destructive", role: .destructive) { }
            Button("probe_cancel", role: .cancel) { }
        }
    }
}
