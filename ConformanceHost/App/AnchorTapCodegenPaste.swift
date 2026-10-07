//
//  AnchorTapCodegenPaste.swift
//  ConformanceHost
//
//  What `sjui build` emits for ProbeLayouts/probe_anchor_tap.json, from the
//  sjui_tools of jsonui-cli v1.9.17 (AnchorTapPaste17), v1.9.18
//  (AnchorTapPaste18) and v1.9.19 (AnchorTapPaste19), the body's sections
//  pasted unchanged but for the row g's text, which the build wrote as a
//  StringManager key this host has no table for; the Data struct is the one
//  all three emit (identical), renamed. Kept as the measured contrast of
//  AnchorTapProbeView:
//    - 17 and 18 merge f's card into its button (ticket sjui-a-tappable-
//      elements-anchor-inside-its-tap-target-moves-the-tap-point-off-it;
//      18 also moves the tap point onto the card);
//    - 19 writes every tap after the margin, so the tap's receiver and a
//      combined tap's id take the margin in (ticket sjui-a-combined-taps-id-
//      box-takes-its-margin-in).
//

import SwiftUI
import SwiftJsonUI


struct AnchorTapPasteData {
    // Data properties from JSON
    var hit: String = ""
    var onCard_m: (() -> Void)? = nil
    var onBtn_m: (() -> Void)? = nil
    var onCard_n: (() -> Void)? = nil
    var onBtn_n: (() -> Void)? = nil
    var onBtn_q: (() -> Void)? = nil
    var onBtn_s: (() -> Void)? = nil
    var onCard_f: (() -> Void)? = nil
    var onBtn_f: (() -> Void)? = nil
    var fVisibility: String = "visible".localized()
    var fUrl: String? = nil
    var onBtn_g: (() -> Void)? = nil
    var onBtn_h: (() -> Void)? = nil

    // Update properties from dictionary
    mutating func update(dictionary: [String: Any]) {
        if let value = dictionary["hit"] {
            if let stringValue = value as? String {
                self.hit = stringValue
            }
        }
        if let value = dictionary["onCard_m"] {
            if let typedValue = value as? (() -> Void)? {
                self.onCard_m = typedValue
            }
        }
        if let value = dictionary["onBtn_m"] {
            if let typedValue = value as? (() -> Void)? {
                self.onBtn_m = typedValue
            }
        }
        if let value = dictionary["onCard_n"] {
            if let typedValue = value as? (() -> Void)? {
                self.onCard_n = typedValue
            }
        }
        if let value = dictionary["onBtn_n"] {
            if let typedValue = value as? (() -> Void)? {
                self.onBtn_n = typedValue
            }
        }
        if let value = dictionary["onBtn_q"] {
            if let typedValue = value as? (() -> Void)? {
                self.onBtn_q = typedValue
            }
        }
        if let value = dictionary["onBtn_s"] {
            if let typedValue = value as? (() -> Void)? {
                self.onBtn_s = typedValue
            }
        }
        if let value = dictionary["onCard_f"] {
            if let typedValue = value as? (() -> Void)? {
                self.onCard_f = typedValue
            }
        }
        if let value = dictionary["onBtn_f"] {
            if let typedValue = value as? (() -> Void)? {
                self.onBtn_f = typedValue
            }
        }
        if let value = dictionary["fVisibility"] {
            if let stringValue = value as? String {
                self.fVisibility = stringValue
            }
        }
        if let value = dictionary["fUrl"] {
            if let typedValue = value as? String? {
                self.fUrl = typedValue
            }
        }
        if let value = dictionary["onBtn_g"] {
            if let typedValue = value as? (() -> Void)? {
                self.onBtn_g = typedValue
            }
        }
        if let value = dictionary["onBtn_h"] {
            if let typedValue = value as? (() -> Void)? {
                self.onBtn_h = typedValue
            }
        }
    }

    // Convert properties to dictionary for Dynamic mode
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties
        dict["hit"] = hit
        if let value = onCard_m {
            dict["onCard_m"] = value
        }
        if let value = onBtn_m {
            dict["onBtn_m"] = value
        }
        if let value = onCard_n {
            dict["onCard_n"] = value
        }
        if let value = onBtn_n {
            dict["onBtn_n"] = value
        }
        if let value = onBtn_q {
            dict["onBtn_q"] = value
        }
        if let value = onBtn_s {
            dict["onBtn_s"] = value
        }
        if let value = onCard_f {
            dict["onCard_f"] = value
        }
        if let value = onBtn_f {
            dict["onBtn_f"] = value
        }
        dict["fVisibility"] = fVisibility
        if let value = fUrl {
            dict["fUrl"] = value
        }
        if let value = onBtn_g {
            dict["onBtn_g"] = value
        }
        if let value = onBtn_h {
            dict["onBtn_h"] = value
        }
        
        return dict
    }

    #if DEBUG
    // Convert properties to binding dictionary for Dynamic mode reactivity
    // SwiftUI.Binding<T> values enable automatic re-rendering on changes
    func toDictionary(binding dataBinding: SwiftUI.Binding<AnchorTapPasteData>) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Data properties as SwiftUI.Binding for reactivity
        dict["hit"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.hit },
            set: { dataBinding.wrappedValue.hit = $0 }
        )
        if let onCard_m = onCard_m {
            dict["onCard_m"] = onCard_m
        }
        if let onBtn_m = onBtn_m {
            dict["onBtn_m"] = onBtn_m
        }
        if let onCard_n = onCard_n {
            dict["onCard_n"] = onCard_n
        }
        if let onBtn_n = onBtn_n {
            dict["onBtn_n"] = onBtn_n
        }
        if let onBtn_q = onBtn_q {
            dict["onBtn_q"] = onBtn_q
        }
        if let onBtn_s = onBtn_s {
            dict["onBtn_s"] = onBtn_s
        }
        if let onCard_f = onCard_f {
            dict["onCard_f"] = onCard_f
        }
        if let onBtn_f = onBtn_f {
            dict["onBtn_f"] = onBtn_f
        }
        dict["fVisibility"] = SwiftUI.Binding<String>(
            get: { dataBinding.wrappedValue.fVisibility },
            set: { dataBinding.wrappedValue.fVisibility = $0 }
        )
        if fUrl != nil {
            dict["fUrl"] = SwiftUI.Binding<String>(
                get: { dataBinding.wrappedValue.fUrl ?? "" },
                set: { dataBinding.wrappedValue.fUrl = $0 }
            )
        }
        if let onBtn_g = onBtn_g {
            dict["onBtn_g"] = onBtn_g
        }
        if let onBtn_h = onBtn_h {
            dict["onBtn_h"] = onBtn_h
        }
        
        return dict
    }
    #endif
}

// ══ END AUTO-GENERATED — DO NOT APPEND BELOW THIS LINE ══


struct AnchorTapPaste17: View {
    @SwiftUI.Binding var data: AnchorTapPasteData

    var body: some View {
        AnyView(section0())
    }

    @ViewBuilder private func section0() -> some View {
        VStack(alignment: .leading, spacing: 6) {
                PartialAttributedText(
                    "\(data.hit)",
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_hit")
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_fill_m",
                            view: AnyView(section0_0()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_m",
                            view: AnyView(section0_1()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 8),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(90)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 90, idealHeight: 90, maxHeight: 90, alignment: .topLeading)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onCard_m?()
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_m")
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_fill_n",
                            view: AnyView(section0_2()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_n",
                            view: AnyView(section0_3()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(90)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 90, idealHeight: 90, maxHeight: 90, alignment: .topLeading)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onCard_n?()
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_n")
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_fill_q",
                            view: AnyView(section0_4()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_q",
                            view: AnyView(section0_5()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 8),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(90)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 90, idealHeight: 90, maxHeight: 90, alignment: .topLeading)
                    .cornerRadius(12)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_q")
                ZStack(alignment: .topLeading) {
                    Group {
                        AnyView(section0_6())
                    }
                }
                    .frame(width: 300, height: 40, alignment: .topLeading)
                    .overlay(alignment: .topLeading) {
                        Color.clear
                            .frame(width: 0.5, height: 0.5)
                            .accessibilityElement(children: .ignore)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_box_s")
                HStack(alignment: .center, spacing: 0) {
                        Image("conformance_sample")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .accessibilityHidden(true)
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 10)
                            .accessibilityIdentifier("cg_at_icon_g")
                        PartialAttributedText(
                            "Sign in",
                            textAlignment: .leading
                        )
                            .accessibilityIdentifier("cg_at_label_g")
                }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: 56, idealHeight: 56, maxHeight: 56, alignment: .center)
                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan_2") ?? Color.black)
                    .cornerRadius(4)
                    .padding(.top, 24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onBtn_g?()
                        }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("cg_at_btn_g")
                VStack(alignment: .leading, spacing: 0) {
                        PartialAttributedText(
                            "Tap",
                            textAlignment: .leading
                        )
                            .padding(7)
                            .background(SwiftJsonUIConfiguration.shared.getColor(for: "light_orange") ?? Color.black)
                            .padding(.top, 12)
                            .padding(.leading, 11)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                            data.onBtn_h?()
                                        }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityIdentifier("cg_at_btn_h")
                }
                    .frame(width: 300, height: 50, alignment: .topLeading)
                    .overlay(alignment: .topLeading) {
                        Color.clear
                            .frame(width: 0.5, height: 0.5)
                            .accessibilityElement(children: .ignore)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_box_h")
                AdvancedKeyboardAvoidingScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        AnyView(section0_7())
                        Spacer(minLength: 0)
                    }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 230, idealHeight: 230, maxHeight: 230, alignment: .topLeading)
                    .overlay(alignment: .topLeading) {
                        Color.clear
                            .frame(width: 0.5, height: 0.5)
                            .accessibilityElement(children: .ignore)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_scroll_f")
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_root")
    }

    @ViewBuilder private func section0_0() -> some View {
        Rectangle()
            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan") ?? Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                Color.clear
                    .frame(width: 0.5, height: 0.5)
                    .accessibilityElement(children: .ignore)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_fill_m")
    }

    @ViewBuilder private func section0_1() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_m")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .contentShape(Rectangle())
            .onTapGesture {
                                        data.onBtn_m?()
                                    }
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_m")
    }

    @ViewBuilder private func section0_2() -> some View {
        Rectangle()
            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan") ?? Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                Color.clear
                    .frame(width: 0.5, height: 0.5)
                    .accessibilityElement(children: .ignore)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_fill_n")
    }

    @ViewBuilder private func section0_3() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_n")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .contentShape(Rectangle())
            .onTapGesture {
                                        data.onBtn_n?()
                                    }
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_n")
    }

    @ViewBuilder private func section0_4() -> some View {
        Rectangle()
            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan") ?? Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                Color.clear
                    .frame(width: 0.5, height: 0.5)
                    .accessibilityElement(children: .ignore)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_fill_q")
    }

    @ViewBuilder private func section0_5() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_q")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .contentShape(Rectangle())
            .onTapGesture {
                                        data.onBtn_q?()
                                    }
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_q")
    }

    @ViewBuilder private func section0_6() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_s")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .contentShape(Rectangle())
            .onTapGesture {
                            data.onBtn_s?()
                        }
            .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_s")
    }

    @ViewBuilder private func section0_7() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VisibilityWrapper(data.fVisibility) {
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_image_f",
                            view: AnyView(section0_7_0()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_f",
                            view: AnyView(section0_7_1()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 8),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(200)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 200, idealHeight: 200, maxHeight: 200, alignment: .topLeading)
                    .cornerRadius(12)
                    .padding(.top, 24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                                            data.onCard_f?()
                                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_f")
            }
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .overlay(alignment: .topLeading) {
                Color.clear
                    .frame(width: 0.5, height: 0.5)
                    .accessibilityElement(children: .ignore)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_content_f")
    }

    @ViewBuilder private func section0_7_0() -> some View {
        NetworkImage(
            url: data.fUrl,
            contentMode: .fill
        )
            .accessibilityHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .accessibilityIdentifier("cg_at_image_f")
    }

    @ViewBuilder private func section0_7_1() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_f")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "transparent") ?? Color.black)
            .cornerRadius(15)
            .contentShape(Rectangle())
            .onTapGesture {
                                                        data.onBtn_f?()
                                                    }
            .overlay(alignment: .topLeading) {
                                                        Color.clear
                                                            .frame(width: 0.5, height: 0.5)
                                                            .accessibilityElement(children: .ignore)
                                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_f")
    }
}


struct AnchorTapPaste18: View {
    @SwiftUI.Binding var data: AnchorTapPasteData

    var body: some View {
        AnyView(section0())
    }

    @ViewBuilder private func section0() -> some View {
        VStack(alignment: .leading, spacing: 6) {
                PartialAttributedText(
                    "\(data.hit)",
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_hit")
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_fill_m",
                            view: AnyView(section0_0()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_m",
                            view: AnyView(section0_1()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 8),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(90)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 90, idealHeight: 90, maxHeight: 90, alignment: .topLeading)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onCard_m?()
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_m")
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_fill_n",
                            view: AnyView(section0_2()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_n",
                            view: AnyView(section0_3()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(90)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 90, idealHeight: 90, maxHeight: 90, alignment: .topLeading)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onCard_n?()
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_n")
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_fill_q",
                            view: AnyView(section0_4()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_q",
                            view: AnyView(section0_5()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 8),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(90)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 90, idealHeight: 90, maxHeight: 90, alignment: .topLeading)
                    .cornerRadius(12)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_q")
                ZStack(alignment: .topLeading) {
                    Group {
                        AnyView(section0_6())
                    }
                }
                    .frame(width: 300, height: 40, alignment: .topLeading)
                    .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_box_s")
                HStack(alignment: .center, spacing: 0) {
                        Image("conformance_sample")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .accessibilityHidden(true)
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 10)
                            .accessibilityIdentifier("cg_at_icon_g")
                        PartialAttributedText(
                            "Sign in",
                            textAlignment: .leading
                        )
                            .accessibilityIdentifier("cg_at_label_g")
                }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: 56, idealHeight: 56, maxHeight: 56, alignment: .center)
                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan_2") ?? Color.black)
                    .cornerRadius(4)
                    .padding(.top, 24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onBtn_g?()
                        }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("cg_at_btn_g")
                VStack(alignment: .leading, spacing: 0) {
                        PartialAttributedText(
                            "Tap",
                            textAlignment: .leading
                        )
                            .padding(7)
                            .background(SwiftJsonUIConfiguration.shared.getColor(for: "light_orange") ?? Color.black)
                            .padding(.top, 12)
                            .padding(.leading, 11)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                            data.onBtn_h?()
                                        }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityIdentifier("cg_at_btn_h")
                }
                    .frame(width: 300, height: 50, alignment: .topLeading)
                    .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_box_h")
                AdvancedKeyboardAvoidingScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        AnyView(section0_7())
                        Spacer(minLength: 0)
                    }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 230, idealHeight: 230, maxHeight: 230, alignment: .topLeading)
                    .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_scroll_f")
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_root")
    }

    @ViewBuilder private func section0_0() -> some View {
        Rectangle()
            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan") ?? Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_fill_m")
    }

    @ViewBuilder private func section0_1() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_m")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .contentShape(Rectangle())
            .onTapGesture {
                                        data.onBtn_m?()
                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_m")
    }

    @ViewBuilder private func section0_2() -> some View {
        Rectangle()
            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan") ?? Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_fill_n")
    }

    @ViewBuilder private func section0_3() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_n")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .contentShape(Rectangle())
            .onTapGesture {
                                        data.onBtn_n?()
                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_n")
    }

    @ViewBuilder private func section0_4() -> some View {
        Rectangle()
            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan") ?? Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_fill_q")
    }

    @ViewBuilder private func section0_5() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_q")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .contentShape(Rectangle())
            .onTapGesture {
                                        data.onBtn_q?()
                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_q")
    }

    @ViewBuilder private func section0_6() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_s")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
            .contentShape(Rectangle())
            .onTapGesture {
                            data.onBtn_s?()
                        }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_s")
    }

    @ViewBuilder private func section0_7() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VisibilityWrapper(data.fVisibility) {
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_image_f",
                            view: AnyView(section0_7_0()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_f",
                            view: AnyView(section0_7_1()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 8),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(200)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 200, idealHeight: 200, maxHeight: 200, alignment: .topLeading)
                    .cornerRadius(12)
                    .padding(.top, 24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                                            data.onCard_f?()
                                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_f")
            }
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_content_f")
    }

    @ViewBuilder private func section0_7_0() -> some View {
        NetworkImage(
            url: data.fUrl,
            contentMode: .fill
        )
            .accessibilityHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .accessibilityIdentifier("cg_at_image_f")
    }

    @ViewBuilder private func section0_7_1() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_f")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "transparent") ?? Color.black)
            .cornerRadius(15)
            .overlay(alignment: .topLeading) {
                                                        Color.clear
                                                            .frame(width: 0.5, height: 0.5)
                                                            .accessibilityElement(children: .ignore)
                                                    }
            .contentShape(Rectangle())
            .onTapGesture {
                                                        data.onBtn_f?()
                                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_f")
    }
}


struct AnchorTapPaste19: View {
    @SwiftUI.Binding var data: AnchorTapPasteData

    var body: some View {
        AnyView(section0())
    }

    @ViewBuilder private func section0() -> some View {
        VStack(alignment: .leading, spacing: 6) {
                PartialAttributedText(
                    "\(data.hit)",
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_hit")
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_fill_m",
                            view: AnyView(section0_0()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_m",
                            view: AnyView(section0_1()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 8),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(90)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 90, idealHeight: 90, maxHeight: 90, alignment: .topLeading)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onCard_m?()
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_m")
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_fill_n",
                            view: AnyView(section0_2()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_n",
                            view: AnyView(section0_3()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(90)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 90, idealHeight: 90, maxHeight: 90, alignment: .topLeading)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onCard_n?()
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_n")
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_fill_q",
                            view: AnyView(section0_4()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_q",
                            view: AnyView(section0_5()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 8),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(90)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 90, idealHeight: 90, maxHeight: 90, alignment: .topLeading)
                    .cornerRadius(12)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_q")
                ZStack(alignment: .topLeading) {
                    Group {
                        AnyView(section0_6())
                    }
                }
                    .frame(width: 300, height: 40, alignment: .topLeading)
                    .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_box_s")
                HStack(alignment: .center, spacing: 0) {
                        Image("conformance_sample")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .accessibilityHidden(true)
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 10)
                            .accessibilityIdentifier("cg_at_icon_g")
                        PartialAttributedText(
                            "Sign in",
                            textAlignment: .leading
                        )
                            .accessibilityIdentifier("cg_at_label_g")
                }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: 56, idealHeight: 56, maxHeight: 56, alignment: .center)
                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan_2") ?? Color.black)
                    .cornerRadius(4)
                    .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                    .padding(.top, 24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            data.onBtn_g?()
                        }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("cg_at_btn_g")
                VStack(alignment: .leading, spacing: 0) {
                        PartialAttributedText(
                            "Tap",
                            textAlignment: .leading
                        )
                            .padding(7)
                            .background(SwiftJsonUIConfiguration.shared.getColor(for: "light_orange") ?? Color.black)
                            .padding(.top, 12)
                            .padding(.leading, 11)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                            data.onBtn_h?()
                                        }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityIdentifier("cg_at_btn_h")
                }
                    .frame(width: 300, height: 50, alignment: .topLeading)
                    .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_box_h")
                AdvancedKeyboardAvoidingScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        AnyView(section0_7())
                        Spacer(minLength: 0)
                    }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 230, idealHeight: 230, maxHeight: 230, alignment: .topLeading)
                    .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_scroll_f")
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_root")
    }

    @ViewBuilder private func section0_0() -> some View {
        Rectangle()
            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan") ?? Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_fill_m")
    }

    @ViewBuilder private func section0_1() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_m")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .contentShape(Rectangle())
            .onTapGesture {
                                        data.onBtn_m?()
                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_m")
    }

    @ViewBuilder private func section0_2() -> some View {
        Rectangle()
            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan") ?? Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_fill_n")
    }

    @ViewBuilder private func section0_3() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_n")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .contentShape(Rectangle())
            .onTapGesture {
                                        data.onBtn_n?()
                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_n")
    }

    @ViewBuilder private func section0_4() -> some View {
        Rectangle()
            .fill(SwiftJsonUIConfiguration.shared.getColor(for: "pale_cyan") ?? Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_fill_q")
    }

    @ViewBuilder private func section0_5() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_q")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
            .contentShape(Rectangle())
            .onTapGesture {
                                        data.onBtn_q?()
                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_q")
    }

    @ViewBuilder private func section0_6() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_s")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "dark_gray") ?? Color.black)
            .cornerRadius(15)
            .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
            .contentShape(Rectangle())
            .onTapGesture {
                            data.onBtn_s?()
                        }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_s")
    }

    @ViewBuilder private func section0_7() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VisibilityWrapper(data.fVisibility) {
                RelativePositionContainer(
                    children: [
                        RelativeChildConfig(
                            id: "cg_at_image_f",
                            view: AnyView(section0_7_0()),
                            constraints: [
                                RelativePositionConstraint(type: .parentTop, targetId: ""),
                                RelativePositionConstraint(type: .parentLeft, targetId: "")
                            ],
                            margins: .init(),
                            widthMode: .matchParent,
                            heightMode: .matchParent
                        ),
                        RelativeChildConfig(
                            id: "cg_at_btn_f",
                            view: AnyView(section0_7_1()),
                            constraints: [
                                RelativePositionConstraint(type: .parentRight, targetId: ""),
                                RelativePositionConstraint(type: .parentTop, targetId: "")
                            ],
                            margins: EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 8),
                            widthMode: .fixed(30),
                            heightMode: .fixed(30)
                        )
                    ],
                    alignment: .topLeading,
                    backgroundColor: nil,
                    parentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    containerWidthMode: .matchParent,
                    containerHeightMode: .fixed(200)
                )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: 200, idealHeight: 200, maxHeight: 200, alignment: .topLeading)
                    .cornerRadius(12)
                    .overlay(alignment: .topLeading) {
                                            Color.clear
                                                .frame(width: 0.5, height: 0.5)
                                                .accessibilityElement(children: .ignore)
                                        }
                    .padding(.top, 24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                                            data.onCard_f?()
                                        }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_at_card_f")
            }
        }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cg_at_content_f")
    }

    @ViewBuilder private func section0_7_0() -> some View {
        NetworkImage(
            url: data.fUrl,
            contentMode: .fill
        )
            .accessibilityHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .accessibilityIdentifier("cg_at_image_f")
    }

    @ViewBuilder private func section0_7_1() -> some View {
        ZStack(alignment: .center) {
            Group {
                PartialAttributedText(
                    "x".localized(),
                    fontSize: 14,
                    fontColor: SwiftJsonUIConfiguration.shared.getColor(for: "white") ?? Color.black,
                    textAlignment: .leading
                )
                    .accessibilityIdentifier("cg_at_icon_f")
            }
        }
            .frame(width: 30, height: 30, alignment: .center)
            .background(SwiftJsonUIConfiguration.shared.getColor(for: "transparent") ?? Color.black)
            .cornerRadius(15)
            .overlay(alignment: .topLeading) {
                                                        Color.clear
                                                            .frame(width: 0.5, height: 0.5)
                                                            .accessibilityElement(children: .ignore)
                                                    }
            .contentShape(Rectangle())
            .onTapGesture {
                                                        data.onBtn_f?()
                                                    }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cg_at_btn_f")
    }
}
