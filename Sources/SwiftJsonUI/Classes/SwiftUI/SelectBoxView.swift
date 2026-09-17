//
//  SelectBoxView.swift
//  SwiftJsonUI
//
//  SwiftUI implementation of SelectBox
//

import SwiftUI

// MARK: - UIKit DatePicker wrapper for minuteInterval support
struct UIKitDatePicker: UIViewRepresentable {
    @SwiftUI.Binding var selection: Date
    let datePickerMode: UIDatePicker.Mode
    let minuteInterval: Int
    let minimumDate: Date?
    let maximumDate: Date?
    var preferredStyle: UIDatePickerStyle = .wheels

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = datePickerMode
        picker.preferredDatePickerStyle = preferredStyle
        picker.minuteInterval = minuteInterval
        picker.minimumDate = minimumDate
        picker.maximumDate = maximumDate
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.date = selection
        uiView.minuteInterval = minuteInterval
        uiView.minimumDate = minimumDate
        uiView.maximumDate = maximumDate
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: UIKitDatePicker

        init(_ parent: UIKitDatePicker) {
            self.parent = parent
        }

        @objc func dateChanged(_ sender: UIDatePicker) {
            parent.selection = sender.date
        }
    }
}

public struct SelectBoxView: View {
    @Environment(\.selectBoxScrollProxy) private var scrollProxy
    
    let id: String
    let prompt: String?
    let fontSize: CGFloat
    let fontColor: Color
    /// The label font, resolved from `font` + `fontSize` at init.
    ///
    /// The label used to hard-wire `.font(.system(size: fontSize))`, which
    /// sits *inside* the view — so a `.font()` applied from outside was
    /// always overridden and a declared `font` did nothing. The name has to
    /// come in as a parameter for the modifier to be able to honour it.
    let labelFont: Font
    let hintColor: Color
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let selectItemType: SelectItemType
    let items: [String]
    let datePickerMode: DatePickerMode
    let datePickerStyle: DatePickerStyle
    let dateStringFormat: String
    let minimumDate: Date?
    let maximumDate: Date?
    let minuteInterval: Int
    let initialSelectedIndex: Int?
    let initialSelectedDate: Date?
    let padding: EdgeInsets?
    /// `caretAttributes`, or nil when the layout did not declare the object.
    /// Nil keeps the fixed 12pt gray chevron this view has always drawn, so
    /// no existing layout moves.
    let caret: CaretAttributes?
    let onValueChange: ((String) -> Void)?
    var selectedIndexBinding: SwiftUI.Binding<Int>?

    /// The closed-state caret, declared by `SelectBox.caretAttributes`.
    ///
    /// The object was UIKit-only (SJUISelectBox) until jsonui-cli 1.8.101;
    /// the SSoT now declares it for every face, with one rule: absent means
    /// the face keeps its native indicator, present means the face draws the
    /// caret itself from these keys. Every key is optional — `{"rightMargin":
    /// 12}` alone moves the default chevron off the trailing edge, which is
    /// the request the promotion started from.
    ///
    /// `rightMargin` is measured from the select's trailing edge to the
    /// caret's trailing edge, and defaults to 0 — the UIKit contract, where
    /// the caret is a subview pinned to the right edge regardless of the
    /// label's inset. That is why the label inset does not apply to the
    /// caret once this object is present (see `contentInsets`).
    public struct CaretAttributes: Equatable {
        /// Asset name. Nil draws the default glyph (`chevron.down`).
        public var src: String?
        /// The caret's box. Nil keeps the glyph's own size on that axis.
        public var width: CGFloat?
        public var height: CGFloat?
        /// Applies to the default glyph, and to a template `src`. A
        /// full-colour asset keeps its colours — the rendering mode is the
        /// asset's, not forced here.
        public var tintColor: Color?
        /// Fills the caret's box (width × height), not the select.
        public var background: Color?
        public var rightMargin: CGFloat?

        public init(
            src: String? = nil,
            width: CGFloat? = nil,
            height: CGFloat? = nil,
            tintColor: Color? = nil,
            background: Color? = nil,
            rightMargin: CGFloat? = nil
        ) {
            self.src = src
            self.width = width
            self.height = height
            self.tintColor = tintColor
            self.background = background
            self.rightMargin = rightMargin
        }
    }

    @State private var isPresented = false
    @State private var selectedIndex: Int? = nil
    @State private var selectedText = ""
    @State private var selectedDate = Date()
    @State private var dateText = ""
    @State private var selectBoxFrame: CGRect = .zero
    @StateObject private var sheetResponder = SelectBoxSheetResponder.shared
    
    public enum SelectItemType {
        case normal
        case date
    }
    
    public enum DatePickerMode {
        case date
        case time
        case dateTime
    }
    
    public enum DatePickerStyle {
        case automatic
        case wheel
        case compact
        case graphical
    }
    
    public init(
        id: String = "selectBox",
        prompt: String? = nil,
        fontSize: CGFloat = 16,
        fontColor: Color = .primary,
        // Font family (or "bold") for the label. Same spelling and same
        // resolution rule as TextViewWithPlaceholder and IconLabelView —
        // one convention for one idea.
        fontName: String? = nil,
        // Placeholder colour for the empty state; .gray was hard-wired at
        // every empty-state branch before this parameter existed.
        hintColor: Color = .gray,
        backgroundColor: Color = Color(UIColor.systemGray6),
        cornerRadius: CGFloat = 8,
        // `caretAttributes`. Nil keeps the fixed chevron — see CaretAttributes.
        caret: CaretAttributes? = nil,
        selectItemType: SelectItemType = .normal,
        items: [String] = [],
        datePickerMode: DatePickerMode = .date,
        datePickerStyle: DatePickerStyle = .wheel,
        dateStringFormat: String = "yyyy/MM/dd",
        minimumDate: Date? = nil,
        maximumDate: Date? = nil,
        minuteInterval: Int = 1,
        selectedIndex: Int? = nil,
        selectedIndexBinding: SwiftUI.Binding<Int>? = nil,
        selectedDate: Date? = nil,
        padding: EdgeInsets? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.fontSize = fontSize
        self.fontColor = fontColor
        // "bold" is the weight spelling, not a family — the rule
        // TextViewWithPlaceholder.init and IconLabelView already use.
        if let fontName, fontName != "bold" {
            self.labelFont = .custom(fontName, size: fontSize)
        } else if fontName == "bold" {
            self.labelFont = .system(size: fontSize, weight: .bold)
        } else {
            self.labelFont = .system(size: fontSize)
        }
        self.hintColor = hintColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.caret = caret
        self.selectItemType = selectItemType
        self.items = items
        self.datePickerMode = datePickerMode
        self.datePickerStyle = datePickerStyle
        self.dateStringFormat = dateStringFormat
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.minuteInterval = minuteInterval
        self.initialSelectedIndex = selectedIndex ?? selectedIndexBinding?.wrappedValue
        self.initialSelectedDate = selectedDate
        self.padding = padding
        self.onValueChange = onValueChange
        self.selectedIndexBinding = selectedIndexBinding
    }
    
    public var body: some View {
        Button(action: {
            // Show sheet immediately
            isPresented = true
            
            // If we have a scrollProxy, handle scrolling after sheet presentation
            if let proxy = scrollProxy {
                // Notify sheet responder to trigger padding
                sheetResponder.sheetWillPresent(id: id, height: sheetHeight)
                
                // Wait for sheet to be fully presented before scrolling
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        // Calculate anchor position based on sheet height and actual SelectBox height
                        // Position SelectBox just above the sheet with 20pt margin
                        let selectBoxHeight = selectBoxFrame.height > 0 ? selectBoxFrame.height : 50.0
                        let margin: CGFloat = 20.0
                        let totalOffsetFromBottom = sheetHeight + selectBoxHeight + margin
                        // The anchor is a fraction of the visible area. Against the display it is
                            // wrong by exactly the amount the window is smaller than the screen.
                            let visibleHeight = SJUIWindowMetrics.bounds().height
                            let anchorY = visibleHeight > 0
                                ? 1.0 - (totalOffsetFromBottom / visibleHeight)
                                : 0.5
                        proxy.scrollTo(id, anchor: UnitPoint(x: 0.5, y: anchorY))
                    }
                }
            }
        }) {
            HStack {
                // Label text
                Group {
                    switch selectItemType {
                    case .date:
                        if let prompt = prompt {
                            Text(dateText.isEmpty ? prompt : dateText)
                                .foregroundColor(dateText.isEmpty ? hintColor : fontColor)
                        } else {
                            Text(dateText)
                                .foregroundColor(fontColor)
                        }
                    case .normal:
                        if let prompt = prompt {
                            Text(selectedText.isEmpty ? prompt : selectedText)
                                .foregroundColor(selectedText.isEmpty ? hintColor : fontColor)
                        } else {
                            Text(selectedText)
                                .foregroundColor(fontColor)
                        }
                    }
                }
                .font(labelFont)

                Spacer()

                // Caret icon
                caretView
            }
            .padding(contentInsets)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(.plain)
        .id(id) // Important: Set ID for ScrollViewReader to find this view
        .onAppear {
            // Initialize selectedIndex and selectedText from initial value
            if let initialIndex = initialSelectedIndex, items.indices.contains(initialIndex) {
                selectedIndex = initialIndex
                selectedText = items[initialIndex]
            }
            // Initialize selectedDate and dateText from initial value
            if let initialDate = initialSelectedDate {
                selectedDate = initialDate
                let formatter = DateFormatter()
                formatter.dateFormat = dateStringFormat
                dateText = formatter.string(from: initialDate)
            }
        }
        // Sync internal @State with external bindings when the parent
        // ViewModel mutates the source-of-truth (e.g. clear/reset buttons).
        // Without these the @State only updates via .onAppear, so post-mount
        // changes to the binding would leave the displayed text stale.
        .onChange(of: selectedIndexBinding?.wrappedValue) { _, newIndex in
            if let newIndex, items.indices.contains(newIndex) {
                selectedIndex = newIndex
                selectedText = items[newIndex]
            } else {
                selectedIndex = nil
                selectedText = ""
            }
        }
        .onChange(of: initialSelectedDate) { _, newDate in
            if let newDate {
                selectedDate = newDate
                let formatter = DateFormatter()
                formatter.dateFormat = dateStringFormat
                dateText = formatter.string(from: newDate)
            } else {
                dateText = ""
            }
        }
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        selectBoxFrame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                        selectBoxFrame = newFrame
                    }
            }
        )
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                VStack {
                    switch selectItemType {
                    case .normal:
                        // When a prompt is supplied, insert it as the first
                        // wheel item with tag -1. Selecting it clears the
                        // selection (selectedText = "") so the button face
                        // reverts to the prompt placeholder. The default
                        // wheel position is -1 (unselected) when no item has
                        // been picked yet, otherwise the current index.
                        Picker("Select", selection: SwiftUI.Binding<Int>(
                            get: { selectedIndex ?? (prompt != nil ? -1 : 0) },
                            set: { newValue in
                                if newValue == -1 {
                                    // Prompt option picked → revert to unselected.
                                    selectedIndex = nil
                                    selectedText = ""
                                    selectedIndexBinding?.wrappedValue = -1
                                    onValueChange?("")
                                } else {
                                    selectedIndex = newValue
                                    selectedIndexBinding?.wrappedValue = newValue
                                    if items.indices.contains(newValue) {
                                        selectedText = items[newValue]
                                        onValueChange?(items[newValue])
                                    }
                                }
                            }
                        )) {
                            if let prompt = prompt {
                                Text(prompt)
                                    .foregroundColor(.gray)
                                    .tag(-1)
                            }
                            ForEach(0..<items.count, id: \.self) { index in
                                Text(items[index]).tag(index)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .accessibilityIdentifier("sjui_x7q_picker")
                        // Encode items array for test automation (enables index-based selection)
                        .accessibilityValue(items.joined(separator: "|||"))
                        
                    case .date:
                        Group {
                            if minuteInterval > 1 {
                                // Use UIKit DatePicker for minuteInterval support (all styles)
                                UIKitDatePicker(
                                    selection: $selectedDate,
                                    datePickerMode: uiKitDatePickerMode,
                                    minuteInterval: minuteInterval,
                                    minimumDate: minimumDate,
                                    maximumDate: maximumDate,
                                    preferredStyle: uiKitDatePickerStyle
                                )
                            } else {
                                switch datePickerStyle {
                                case .automatic:
                                    if let min = minimumDate, let max = maximumDate {
                                        DatePicker(
                                            "Select Date",
                                            selection: $selectedDate,
                                            in: min...max,
                                            displayedComponents: datePickerComponents
                                        )
                                        .datePickerStyle(.automatic)
                                    } else {
                                        DatePicker(
                                            "Select Date",
                                            selection: $selectedDate,
                                            displayedComponents: datePickerComponents
                                        )
                                        .datePickerStyle(.automatic)
                                    }
                                case .wheel:
                                    UIKitDatePicker(
                                        selection: $selectedDate,
                                        datePickerMode: uiKitDatePickerMode,
                                        minuteInterval: minuteInterval,
                                        minimumDate: minimumDate,
                                        maximumDate: maximumDate
                                    )
                                case .compact:
                                    if let min = minimumDate, let max = maximumDate {
                                        DatePicker(
                                            "Select Date",
                                            selection: $selectedDate,
                                            in: min...max,
                                            displayedComponents: datePickerComponents
                                        )
                                        .datePickerStyle(.compact)
                                    } else {
                                        DatePicker(
                                            "Select Date",
                                            selection: $selectedDate,
                                            displayedComponents: datePickerComponents
                                        )
                                        .datePickerStyle(.compact)
                                    }
                                case .graphical:
                                    if let min = minimumDate, let max = maximumDate {
                                        DatePicker(
                                            "Select Date",
                                            selection: $selectedDate,
                                            in: min...max,
                                            displayedComponents: datePickerComponents
                                        )
                                        .datePickerStyle(.graphical)
                                    } else {
                                        DatePicker(
                                            "Select Date",
                                            selection: $selectedDate,
                                            displayedComponents: datePickerComponents
                                        )
                                        .datePickerStyle(.graphical)
                                    }
                                }
                            }
                        }
                        .labelsHidden()
                        .accessibilityIdentifier("sjui_x7q_datePicker")
                        .onChange(of: selectedDate) { _, newValue in
                            let formatter = DateFormatter()
                            formatter.dateFormat = dateStringFormat
                            dateText = formatter.string(from: newValue)
                            onValueChange?(dateText)
                        }
                    }
                }
                .navigationBarItems(
                    trailing: Button("Done") {
                        isPresented = false
                        // Notify sheet responder when dismissing
                        sheetResponder.sheetWillDismiss(id: id)
                    }
                    .accessibilityIdentifier("sjui_x7q_done")
                )
            }
            .presentationDetents([.height(sheetHeight)])
            .onAppear {
                // Also try scrolling when sheet appears, for reliability
                if let proxy = scrollProxy {
                    // Small delay to ensure sheet is visible
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            // Calculate anchor position based on sheet height and actual SelectBox height
                            let selectBoxHeight = selectBoxFrame.height > 0 ? selectBoxFrame.height : 50.0
                            let margin: CGFloat = 20.0
                            let totalOffsetFromBottom = sheetHeight + selectBoxHeight + margin
                            // Same as above: a fraction of the window, not of the display.
                                let visibleHeight = SJUIWindowMetrics.bounds().height
                                let anchorY = visibleHeight > 0
                                    ? 1.0 - (totalOffsetFromBottom / visibleHeight)
                                    : 0.5
                            proxy.scrollTo(id, anchor: UnitPoint(x: 0.5, y: anchorY))
                        }
                    }
                }
            }
            .onDisappear {
                // Notify when sheet disappears (in case of swipe down)
                sheetResponder.sheetWillDismiss(id: id)
            }
        }
    }
    
    /// The inset around label + caret.
    ///
    /// Without `caret` this is the declared padding, or the 12pt the view has
    /// always used. With it the trailing inset is 0: `rightMargin` is defined
    /// from the select's own trailing edge (UIKit pins the caret subview to
    /// the right edge and lets the label carry its own inset), so the caret
    /// has to be positioned by its own margin, not by the label's.
    var contentInsets: EdgeInsets {
        var insets = padding ?? EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        if caret != nil {
            insets.trailing = 0
        }
        return insets
    }

    /// The fixed chevron, or the declared caret.
    ///
    /// The declared form is a box of `width` × `height` (each nil axis keeps
    /// the glyph's size) filled with `background`, holding the glyph tinted
    /// `tintColor` (gray when absent, as before), whose trailing edge sits
    /// `rightMargin` (0 when absent) from the select's trailing edge.
    @ViewBuilder
    private var caretView: some View {
        if let caret {
            caretGlyph(caret)
                .frame(width: caret.width, height: caret.height)
                .background(caret.background ?? Color.clear)
                .padding(.trailing, caret.rightMargin ?? 0)
        } else {
            Image(systemName: "chevron.down")
                .foregroundColor(.gray)
                .font(.system(size: 12))
        }
    }

    @ViewBuilder
    private func caretGlyph(_ caret: CaretAttributes) -> some View {
        if let src = caret.src {
            // The asset's own rendering mode decides whether the tint lands
            // — a template asset takes it, a full-colour one keeps its
            // colours. Forcing `.template` here would recolour the latter.
            Image(src)
                .foregroundColor(caret.tintColor ?? .gray)
        } else {
            Image(systemName: "chevron.down")
                .foregroundColor(caret.tintColor ?? .gray)
                .font(.system(size: 12))
        }
    }

    private var datePickerComponents: DatePickerComponents {
        switch datePickerMode {
        case .date:
            return .date
        case .time:
            return .hourAndMinute
        case .dateTime:
            return [.date, .hourAndMinute]
        }
    }

    private var uiKitDatePickerStyle: UIDatePickerStyle {
        switch datePickerStyle {
        case .automatic:
            return .automatic
        case .wheel:
            return .wheels
        case .compact:
            return .compact
        case .graphical:
            return .inline
        }
    }

    private var uiKitDatePickerMode: UIDatePicker.Mode {
        switch datePickerMode {
        case .date:
            return .date
        case .time:
            return .time
        case .dateTime:
            return .dateAndTime
        }
    }

    private var sheetHeight: CGFloat {
        switch selectItemType {
        case .normal:
            return 250
        case .date:
            switch datePickerStyle {
            case .automatic, .wheel:
                return 250
            case .compact:
                return 200
            case .graphical:
                return 400
            }
        }
    }
}

// MARK: - Preview
struct SelectBoxView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SelectBoxView(
                prompt: "Select Country",
                items: ["Japan", "USA", "Canada", "UK", "France"]
            )
            
            SelectBoxView(
                prompt: "Select Date",
                selectItemType: .date
            )
        }
        .padding()
    }
}