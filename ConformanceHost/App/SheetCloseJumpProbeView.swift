//
//  SheetCloseJumpProbeView.swift
//  ConformanceHost
//
//  A field holds the keyboard, the screen is scrolled far from it, a sheet
//  opens and closes: where does the scroll end up? Plain SwiftUI against the
//  library's parts, one at a time. NOT part of the conformance suite. Launch
//  with `-sheetJumpProbe <scroll><sheet>`: scroll `p` plain ScrollView or `a`
//  AdvancedKeyboardAvoidingScrollView, sheet `p` a plain Button with .sheet or
//  `s` SelectBoxView.
//

import SwiftUI
import SwiftJsonUI

struct SheetCloseJumpProbeView: View {
    let arm: String
    @State private var text = ""

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("field", text: $text)
                .frame(height: 44)
                .accessibilityIdentifier("sj_field")
            Color.gray.opacity(0.1).frame(height: 1500)
            Group {
                if arm.hasSuffix("s") {
                    SelectBoxView(id: "sj_box", prompt: "pick", items: ["One", "Two", "Three"])
                        .frame(height: 44)
                        .accessibilityIdentifier("sj_box")
                } else {
                    SheetCloseJumpPlainBox()
                }
            }
            Text("next").frame(height: 44).accessibilityIdentifier("sj_next")
            Color.gray.opacity(0.1).frame(height: 1500)
        }
    }

    var body: some View {
        NavigationStack {
            NavigationLink("go") {
                VStack(spacing: 0) {
                    if arm.hasPrefix("a") {
                        AdvancedKeyboardAvoidingScrollView(.vertical, showsIndicators: true) { content }
                            .accessibilityIdentifier("sj_scroll")
                    } else {
                        ScrollView { content }
                            .accessibilityIdentifier("sj_scroll")
                    }
                    Color.gray.frame(height: 56)
                }
                .navigationTitle("form")
                .navigationBarTitleDisplayMode(.inline)
            }
            .accessibilityIdentifier("sj_go")
        }
    }
}

private struct SheetCloseJumpPlainBox: View {
    @State private var shown = false
    var body: some View {
        Button("pick") { shown = true }
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityIdentifier("sj_box")
            .sheet(isPresented: $shown) {
                NavigationStack {
                    Text("sheet")
                        .navigationBarItems(trailing: Button("Done") { shown = false }.accessibilityIdentifier("sjui_x7q_done"))
                }
                .presentationDetents([.height(250)])
            }
    }
}
