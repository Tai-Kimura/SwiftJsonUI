//
//  SelectBoxView.swift
//  SwiftJsonUI
//
//  SwiftUI implementation of SelectBox
//

import SwiftUI

public struct SelectBoxView: View {
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
    
    @State private var isPresented = false
    @State private var selectedIndex: Int? = nil
    @State private var selectedText = ""
    @State private var selectedDate = Date()
    @State private var dateText = ""
    
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
        dateStringFormat: String = "yyyy/MM/dd"
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
    }
    
    public var body: some View {
        Button(action: {
            isPresented = true
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
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            NavigationView {
                VStack {
                    switch selectItemType {
                    case .normal:
                        Picker("Select", selection: Binding(
                            get: { selectedIndex ?? 0 },
                            set: { newValue in
                                selectedIndex = newValue
                                if items.indices.contains(newValue) {
                                    selectedText = items[newValue]
                                }
                            }
                        )) {
                            ForEach(0..<items.count, id: \.self) { index in
                                Text(items[index]).tag(index)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        
                    case .date:
                        Group {
                            switch datePickerStyle {
                            case .automatic:
                                DatePicker(
                                    "Select Date",
                                    selection: $selectedDate,
                                    displayedComponents: datePickerComponents
                                )
                                .datePickerStyle(.automatic)
                            case .wheel:
                                DatePicker(
                                    "Select Date",
                                    selection: $selectedDate,
                                    displayedComponents: datePickerComponents
                                )
                                .datePickerStyle(.wheel)
                            case .compact:
                                DatePicker(
                                    "Select Date",
                                    selection: $selectedDate,
                                    displayedComponents: datePickerComponents
                                )
                                .datePickerStyle(.compact)
                            case .graphical:
                                DatePicker(
                                    "Select Date",
                                    selection: $selectedDate,
                                    displayedComponents: datePickerComponents
                                )
                                .datePickerStyle(.graphical)
                            }
                        }
                        .labelsHidden()
                        .onChange(of: selectedDate) { newValue in
                            let formatter = DateFormatter()
                            formatter.dateFormat = dateStringFormat
                            dateText = formatter.string(from: newValue)
                        }
                    }
                }
                .navigationBarItems(
                    trailing: Button("Done") { isPresented = false }
                )
            }
            .presentationDetents([.height(sheetHeight)])
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