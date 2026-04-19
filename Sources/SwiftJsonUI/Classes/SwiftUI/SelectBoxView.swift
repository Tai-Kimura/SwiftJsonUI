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
    let onValueChange: ((String) -> Void)?
    var selectedIndexBinding: SwiftUI.Binding<Int>?

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
        backgroundColor: Color = Color(UIColor.systemGray6),
        cornerRadius: CGFloat = 8,
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
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
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
                        let anchorY = 1.0 - (totalOffsetFromBottom / UIScreen.main.bounds.height)
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
                                .foregroundColor(dateText.isEmpty ? .gray : fontColor)
                        } else {
                            Text(dateText)
                                .foregroundColor(fontColor)
                        }
                    case .normal:
                        if let prompt = prompt {
                            Text(selectedText.isEmpty ? prompt : selectedText)
                                .foregroundColor(selectedText.isEmpty ? .gray : fontColor)
                        } else {
                            Text(selectedText)
                                .foregroundColor(fontColor)
                        }
                    }
                }
                .font(.system(size: fontSize))
                
                Spacer()
                
                // Caret icon
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
            }
            .padding(padding ?? EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
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
            NavigationView {
                VStack {
                    switch selectItemType {
                    case .normal:
                        Picker("Select", selection: SwiftUI.Binding<Int>(
                            get: { selectedIndex ?? 0 },
                            set: { newValue in
                                selectedIndex = newValue
                                selectedIndexBinding?.wrappedValue = newValue
                                if items.indices.contains(newValue) {
                                    selectedText = items[newValue]
                                    onValueChange?(items[newValue])
                                }
                            }
                        )) {
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
                            let anchorY = 1.0 - (totalOffsetFromBottom / UIScreen.main.bounds.height)
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