//
//  PagerIdentityProbeView.swift
//  ConformanceHost
//
//  A pager's page is known by its place, not by the change-tracking cellId.
//  Five pages (keys p0…p4) in a paging Collection with cellIdProperty and
//  autoChangeTrackingId; every page change rewrites the title of the page two
//  ahead — off screen — so that page's enriched cellId changes during the
//  swipe. With the cellId as the page's identity SwiftUI removed and
//  re-inserted that page mid-animation and the paging TabView stopped between
//  two pages (jsonui-cli ticket sjui-paging-collection-uses-change-tracking-
//  cellid-as-page-identity-and-stops-mid-swipe: 16 of 41 swipes on a
//  consumer's book screen). PagerIdentityProbeUITests swipes with a mid-way
//  release and reads whether the pager settled on a page. On the Dynamic
//  renderer and — in the codegen host — as sjui generates it
//  (ProbeLayouts/probe_pager_identity.json; this view holds the generated
//  view's data, as an app's ViewModel does). NOT part of the conformance
//  suite; launch with `-pagerIdentityProbe` or `-pagerIdentityProbeCodegen`.
//

import SwiftUI
import SwiftJsonUI

struct PagerIdentityProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_pid_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_pid_pager", "layout": "horizontal", "paging": true, "width": "matchParent", "height": 200, "items": "@{rows}", "currentPage": "@{page}", "onPageChanged": "@{onPageChanged}", "cellIdProperty": "key", "autoChangeTrackingId": true, "sections": [{"cell": "conformance_cell"}]}], "data": [{"name": "rows", "class": "CollectionDataSource", "defaultValue": {"sections": [{"cells": []}]}}, {"name": "page", "class": "Int", "defaultValue": 0}, {"name": "onPageChanged", "class": "((Int) -> Void)?"}]}"##

    @State private var version = 0
    @State private var page = 0
    @State private var cgData = ProbePagerIdentityData()

    /// p0…p4; the page two ahead of `page` carries `version` in its title.
    static func rows(version: Int, page: Int) -> CollectionDataSource {
        var cells: [[String: Any]] = (0..<5).map { ["key": "p\($0)", "title": "P\($0)"] }
        let ahead = (page + 2) % 5
        cells[ahead]["title"] = "P\(ahead) v\(version)"
        var section = CollectionDataSection()
        section.setCells(viewName: "conformance_cell", data: cells)
        return CollectionDataSource(sections: [section])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "pager identity probe (codegen)" : "pager identity probe").accessibilityIdentifier("pid_ready")
            Text("version \(version)").accessibilityIdentifier("pid_version")
            if codegen {
                ProbePagerIdentityGeneratedView(data: $cgData)
                    .onAppear {
                        cgData.rows = Self.rows(version: 0, page: 0)
                        cgData.onPageChanged = { newPage in
                            version += 1
                            cgData.rows = Self.rows(version: version, page: newPage)
                        }
                    }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [
                    "rows": Self.rows(version: version, page: page),
                    "page": $page,
                    "onPageChanged": { (_: Int) in version += 1 } as (Int) -> Void
                ])
            } else {
                Text("did not decode").accessibilityIdentifier("pid_decode_failed")
            }
            Spacer()
        }
    }
}
