//
//  ResponsiveDisabledProbeView.swift
//  ConformanceHost
//
//  What XCUITest reads as `isEnabled` on a disabled container with an id,
//  with and without `responsive`. NOT part of the conformance suite. Launch
//  with `-responsiveDisabledProbe`.
//
//  Each row is what `jui build` (sjui_tools, JsonToSwiftUIConverter) emits for
//  `{"type": "View", "id": …, "onClick": "@{onNext}", "enabled": false,
//  "background": "#3366CC", "padding": 8, "child": [{"type": "Label", "text": "Next"}]}`,
//  pasted unchanged but for the function names:
//  - plain_new: without `responsive` — `.disabled` inside, and again after
//    the identifier (the 1.8.43 shape);
//  - resp_old: with `responsive: {"regular": {"maxWidth": 400, "centerHorizontal": true}}`,
//    as jsonui-cli 6ab928bf emits it — `.disabled` only inside the
//    `responsiveN` wrapper, the identifier outside it;
//  - resp_new: the same, as the fix emits it — `.disabled` again after the
//    identifier;
//  - plain_enabled: the control, the plain node with no `enabled`.
//
//  And the shape a node with a tap takes — `onClick` plus a bound `enabled`
//  that resolves false, a Label child, `opacity`: the tap rule combines it
//  into one button (`.combine` + `.isButton`), and `.disabled` lands after
//  the combine, inside the wrapper:
//  - tap_plain: without `responsive`;
//  - tap_resp_old: with it, as 6ab928bf emits it;
//  - tap_resp_new: with it, as the fix emits it.
//

import SwiftUI
import SwiftJsonUI

struct ResponsiveDisabledProbeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private struct ProbeData {
        var onNext: (() -> Void)? = {}
        var nextButtonEnabled: Bool? = false
    }
    private let data = ProbeData()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("responsive disabled probe").accessibilityIdentifier("resp_probe_ready")
            VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        Group {
                            PartialAttributedText(
                                "Next",
                                textAlignment: .leading
                            )
                        }
                    }
                        .padding(8)
                        .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                        .disabled(true)
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("plain_new")
                        .disabled(true)
            }
            VStack(alignment: .leading, spacing: 0) {
                    responsiveOld {
                        Group {
                            PartialAttributedText(
                                "Next",
                                textAlignment: .leading
                            )
                        }
                    }
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("resp_old")
            }
            VStack(alignment: .leading, spacing: 0) {
                    responsiveNew {
                        Group {
                            PartialAttributedText(
                                "Next",
                                textAlignment: .leading
                            )
                        }
                    }
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("resp_new")
                        .disabled(true)
            }
            VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        Group {
                            PartialAttributedText(
                                "Next",
                                textAlignment: .leading
                            )
                        }
                    }
                        .padding(8)
                        .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("plain_enabled")
            }
            VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        Group {
                            PartialAttributedText(
                                "Next",
                                textAlignment: .leading
                            )
                        }
                    }
                        .opacity(0.9)
                        .contentShape(Rectangle())
                        .onTapGesture {
                                data.onNext?()
                            }
                        .overlay(alignment: .topLeading) {
                                Color.clear
                                    .frame(width: 0.5, height: 0.5)
                                    .accessibilityElement(children: .ignore)
                            }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isButton)
                        .disabled(!((data.nextButtonEnabled ?? false)))
                        .accessibilityIdentifier("tap_plain")
                        .disabled(!((data.nextButtonEnabled ?? false)))
            }
            VStack(alignment: .leading, spacing: 0) {
                    responsiveTap {
                        Group {
                            PartialAttributedText(
                                "Next",
                                textAlignment: .leading
                            )
                        }
                    }
                        .accessibilityIdentifier("tap_resp_old")
            }
            VStack(alignment: .leading, spacing: 0) {
                    responsiveTap {
                        Group {
                            PartialAttributedText(
                                "Next",
                                textAlignment: .leading
                            )
                        }
                    }
                        .accessibilityIdentifier("tap_resp_new")
                        .disabled(!((data.nextButtonEnabled ?? false)))
            }
        }
    }

    @ViewBuilder private func responsiveTap<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        if horizontalSizeClass == .regular {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: 400, alignment: .center)
            .opacity(0.9)
            .contentShape(Rectangle())
            .onTapGesture {
            data.onNext?()
        }
            .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 0.5, height: 0.5)
                .accessibilityElement(children: .ignore)
        }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .disabled(!((data.nextButtonEnabled ?? false)))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .opacity(0.9)
            .contentShape(Rectangle())
            .onTapGesture {
            data.onNext?()
        }
            .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 0.5, height: 0.5)
                .accessibilityElement(children: .ignore)
        }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .disabled(!((data.nextButtonEnabled ?? false)))
        }
    }

    @ViewBuilder private func responsiveOld<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        if horizontalSizeClass == .regular {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: 400, alignment: .center)
            .padding(8)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
            .disabled(true)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(8)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
            .disabled(true)
        }
    }

    @ViewBuilder private func responsiveNew<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        if horizontalSizeClass == .regular {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: 400, alignment: .center)
            .padding(8)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
            .disabled(true)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(8)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
            .disabled(true)
        }
    }
}
