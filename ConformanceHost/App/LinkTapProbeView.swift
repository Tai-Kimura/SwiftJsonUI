//
//  LinkTapProbeView.swift
//  ConformanceHost
//
//  An outer onClick and a Label's links, on iOS (4f ruling on
//  kjui-linkable-label-drops-onclick-and-user-interaction, jsonui-cli 1.9.0):
//  the Label's onClick applies as on any Label, and a tap on a link calls the
//  link only. Measured on Compose (the two coexist); on iOS the question is
//  whether the `.onTapGesture` sjui emits over PartialAttributedText lets a
//  tap on a `.link` run through to the link.
//
//  Two Labels on each path: a detected URL (`linkable`) and a range with its
//  own onClick, each with the Label's onClick. NOT part of the conformance
//  suite. Launch with `-linkTapProbe` and `-ltPath <dynamic|codegen>`:
//  DynamicView over the layout, or what sjui build emits for it (pasted from
//  jsonui-cli 1.9.0's sjui, unchanged). A URL opens through `lt_open_url`'s
//  OpenURLAction where the Label's own does not catch it — the readout counts
//  it either way (`url=`), since the system would leave the app.
//

import SwiftUI
import SwiftJsonUI

final class LinkTapLog: ObservableObject {
    static let shared = LinkTapLog()
    @Published var counts: [String: Int] = [:]
    func bump(_ name: String) { counts[name, default: 0] += 1 }
}

final class LinkTapProbeData: ObservableObject {
    lazy var onUrlLabel: (() -> Void)? = { LinkTapLog.shared.bump("urlLabel") }
    lazy var onRangeLabel: (() -> Void)? = { LinkTapLog.shared.bump("rangeLabel") }
    lazy var onTerms: (() -> Void)? = { LinkTapLog.shared.bump("terms") }
}

struct LinkTapProbeView: View {
    @ObservedObject private var log = LinkTapLog.shared
    @StateObject private var data = LinkTapProbeData()
    private let path = OnClickProbeView.arg("-ltPath", "dynamic")

    static let layout = #"{"type":"View","orientation":"vertical","spacing":12,"width":"matchParent","child":[{"type":"Label","id":"lt_url","width":"matchParent","fontSize":20,"text":"See https://example.com/terms and some plain words","linkable":true,"onClick":"@{onUrlLabel}"},{"type":"Label","id":"lt_range","width":"matchParent","fontSize":20,"text":"Terms of Service and the rest of the text","partialAttributes":[{"range":"Terms of Service","onClick":"@{onTerms}"}],"onClick":"@{onRangeLabel}"}]}"#

    private var layout: DynamicComponent? {
        try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8))
    }

    private var dynamicData: [String: Any] {
        ["onUrlLabel": { LinkTapLog.shared.bump("urlLabel") } as () -> Void,
         "onRangeLabel": { LinkTapLog.shared.bump("rangeLabel") } as () -> Void,
         "onTerms": { LinkTapLog.shared.bump("terms") } as () -> Void]
    }

    private var readout: String {
        log.counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ready").accessibilityIdentifier("lt_ready")
            Text("counts[\(readout)]").font(.system(size: 8)).accessibilityIdentifier("lt_readout")
            Group {
                if path == "codegen" {
                    LinkTapCodegenPaste(data: data)
                } else if let layout {
                    DynamicView(component: layout, viewId: "lt", data: dynamicData)
                } else {
                    Text("layout did not decode").accessibilityIdentifier("lt_decode_failed")
                }
            }
            .environment(\.openURL, OpenURLAction { _ in
                LinkTapLog.shared.bump("url")
                return .handled
            })
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
    }
}

/// What sjui build (jsonui-cli 1.9.0) emits for the layout's two Labels,
/// pasted unchanged; `data` is the generated view's.
struct LinkTapCodegenPaste: View {
    @ObservedObject var data: LinkTapProbeData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PartialAttributedText(
                "See https://example.com/terms and some plain words",
                textAlignment: .leading,
                linkable: true
            )
                .contentShape(Rectangle())
                .onTapGesture {
                data.onUrlLabel?()
            }
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("lt_url")
            PartialAttributedText(
                "Terms of Service and the rest of the text",
                partialAttributes: [
                    PartialAttribute(
                        textPattern: "Terms of Service",
                        onClick: { data.onTerms?() }
                    )
                ],
                textAlignment: .leading
            )
                .contentShape(Rectangle())
                .onTapGesture {
                data.onRangeLabel?()
            }
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("lt_range")
        }
        .font(.system(size: 20))
    }
}
