//
//  NetworkImageRetryProbeView.swift
//  ConformanceHost
//
//  Launched with `-networkImageRetryProbe <url>`: one 100 × 100 NetworkImage
//  (`nw_retry_image`) of the URL. NetworkImageRetryProbeUITests serves it
//  from a local server that fails the first three requests (the load and its
//  two retries), so the failed image shows, and the test taps it (ticket
//  sjui-networkimage-retry-tap-blocked-by-failed-mark).
//

import SwiftUI
import SwiftJsonUI

struct NetworkImageRetryProbeView: View {
    let url: String

    var body: some View {
        VStack(spacing: 8) {
            Text("network image retry probe").accessibilityIdentifier("nw_retry_ready")
            NetworkImage(url: url, contentMode: .fit)
                .frame(width: 100, height: 100)
                .accessibilityIdentifier("nw_retry_image")
        }
        .padding()
    }
}
