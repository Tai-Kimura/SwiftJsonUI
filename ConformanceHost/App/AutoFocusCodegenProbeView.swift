//
//  AutoFocusCodegenProbeView.swift
//  ConformanceHost
//
//  `autoFocus` (jsonui-cli 2.3.22): the field takes the focus when the
//  screen appears. What sjui_tools emits for a TextField and a TextView,
//  with an id and without one, pasted unchanged by the generator (and a
//  TextField without autoFocus, the control). NOT part of the conformance
//  suite. Launch with `-autoFocusProbe <variant>`.
//

import SwiftUI
import SwiftJsonUI

final class AutoFocusProbeData: ObservableObject {
    @Published var email = ""
    @Published var note = ""
    @Published var emailFieldIsFocused = false
    @Published var noteViewIsFocused = false
    @Published var plainFieldIsFocused = false
}

struct AutoFocusCodegenProbeView: View {
    let variant: String
    var body: some View {
        switch variant {
        case "tfNoId": AutoFocusProbe_tfNoId()
        case "tfId": AutoFocusProbe_tfId()
        case "tvNoId": AutoFocusProbe_tvNoId()
        case "tvId": AutoFocusProbe_tvId()
        case "tfNone": AutoFocusProbe_tfNone()
        default: Text("unknown variant \(variant)")
        }
    }
}

// tfNoId: {"type":"TextField","text":"@{email}","autoFocus":true}
struct AutoFocusProbe_tfNoId: View {
    @StateObject private var data = AutoFocusProbeData()
    @FocusState private var field_0IsFocused: Bool
    var body: some View {
        VStack {
            Text("af_probe_ready").accessibilityIdentifier("af_probe_ready")
            TextField("", text: $data.email)
                .focused($field_0IsFocused)
                .onAppear { DispatchQueue.main.async { field_0IsFocused = true } }
        }
        .padding()
    }
}

// tfId: {"type":"TextField","id":"email_field","text":"@{email}","autoFocus":true}
struct AutoFocusProbe_tfId: View {
    @StateObject private var data = AutoFocusProbeData()
    @FocusState private var emailFieldIsFocused: Bool
    var body: some View {
        VStack {
            Text("af_probe_ready").accessibilityIdentifier("af_probe_ready")
            TextField("", text: $data.email)
                .accessibilityIdentifier("email_field")
                .focused($emailFieldIsFocused)
                .onChange(of: data.emailFieldIsFocused) { _, newValue in
                emailFieldIsFocused = newValue
            }
                .onChange(of: emailFieldIsFocused) { _, newValue in
                data.emailFieldIsFocused = newValue
            }
                .onAppear { DispatchQueue.main.async { emailFieldIsFocused = true } }
        }
        .padding()
    }
}

// tvNoId: {"type":"TextView","text":"@{note}","autoFocus":true}
struct AutoFocusProbe_tvNoId: View {
    @StateObject private var data = AutoFocusProbeData()
    @State private var textView_0IsFocused: Bool = false
    var body: some View {
        VStack {
            Text("af_probe_ready").accessibilityIdentifier("af_probe_ready")
            TextViewWithPlaceholder(
                text: $data.note,
                isFocused: $textView_0IsFocused
            )
                .onAppear { DispatchQueue.main.async { textView_0IsFocused = true } }
        }
        .padding()
    }
}

// tvId: {"type":"TextView","id":"note_view","text":"@{note}","autoFocus":true}
struct AutoFocusProbe_tvId: View {
    @StateObject private var data = AutoFocusProbeData()

    var body: some View {
        VStack {
            Text("af_probe_ready").accessibilityIdentifier("af_probe_ready")
            TextViewWithPlaceholder(
                text: $data.note,
                isFocused: $data.noteViewIsFocused,
                accessibilityIdentifier: "note_view"
            )
                .onAppear { DispatchQueue.main.async { data.noteViewIsFocused = true } }
        }
        .padding()
    }
}

// tfNone: {"type":"TextField","id":"plain_field","text":"@{email}"}
struct AutoFocusProbe_tfNone: View {
    @StateObject private var data = AutoFocusProbeData()
    @FocusState private var plainFieldIsFocused: Bool
    var body: some View {
        VStack {
            Text("af_probe_ready").accessibilityIdentifier("af_probe_ready")
            TextField("", text: $data.email)
                .accessibilityIdentifier("plain_field")
                .focused($plainFieldIsFocused)
                .onChange(of: data.plainFieldIsFocused) { _, newValue in
                plainFieldIsFocused = newValue
            }
                .onChange(of: plainFieldIsFocused) { _, newValue in
                data.plainFieldIsFocused = newValue
            }
        }
        .padding()
    }
}

