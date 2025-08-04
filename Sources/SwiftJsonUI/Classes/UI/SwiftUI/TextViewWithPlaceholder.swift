//
//  TextViewWithPlaceholder.swift
//  SwiftJsonUI
//
//  SwiftUI implementation of TextView with placeholder support
//

import SwiftUI

// PreferenceKey for height calculation
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct TextViewWithPlaceholder: View {
    @SwiftUI.Binding var text: String
    let hint: String?
    let hintColor: Color
    let hintFont: Font
    let hideOnFocused: Bool
    let fontSize: CGFloat
    let fontColor: Color
    let font: Font
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let containerInset: EdgeInsets
    let flexible: Bool
    let minHeight: CGFloat?
    let maxHeight: CGFloat?
    
    @FocusState private var isFocused: Bool
    @State private var textHeight: CGFloat = 0
    
    public init(
        text: SwiftUI.Binding<String>,
        hint: String? = nil,
        hintColor: Color = Color.gray.opacity(0.6),
        hintFont: String? = nil,
        hideOnFocused: Bool = true,
        fontSize: CGFloat = 16,
        fontColor: Color = .primary,
        fontName: String? = nil,
        backgroundColor: Color = Color(UIColor.systemBackground),
        cornerRadius: CGFloat = 0,
        containerInset: EdgeInsets = EdgeInsets(top: 8, leading: 5, bottom: 8, trailing: 5),
        flexible: Bool = false,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) {
        self._text = text
        self.hint = hint
        self.hintColor = hintColor
        self.hideOnFocused = hideOnFocused
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.containerInset = containerInset
        self.flexible = flexible
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        
        // hintFontの設定
        if let hintFont = hintFont {
            if hintFont == "bold" {
                self.hintFont = .system(size: fontSize, weight: .bold)
            } else {
                self.hintFont = .custom(hintFont, size: fontSize)
            }
        } else {
            self.hintFont = .system(size: fontSize)
        }
        
        // メインフォントの設定
        if let fontName = fontName {
            if fontName == "bold" {
                self.font = .system(size: fontSize, weight: .bold)
            } else {
                self.font = .custom(fontName, size: fontSize)
            }
        } else {
            self.font = .system(size: fontSize)
        }
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            // ヒント（プレースホルダー）
            if let hint = hint, shouldShowHint {
                Text(hint)
                    .font(hintFont)
                    .foregroundColor(hintColor)
                    .padding(containerInset)
                    .allowsHitTesting(false) // タップイベントを通過させる
            }
            
            if flexible {
                // Flexible mode: 高さを動的に計算
                // 非表示のTextでサイズを計算
                Text(text.isEmpty ? " " : text)
                    .font(font)
                    .padding(containerInset)
                    .opacity(0)
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                    })
                    .onPreferenceChange(HeightPreferenceKey.self) { height in
                        textHeight = height
                    }
                
                // TextEditor
                TextEditor(text: $text)
                    .font(font)
                    .foregroundColor(fontColor)
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
                    .focused($isFocused)
                    .padding(EdgeInsets(top: containerInset.top - 8, 
                                      leading: containerInset.leading - 5, 
                                      bottom: containerInset.bottom - 8, 
                                      trailing: containerInset.trailing - 5))
                    .frame(height: calculateHeight())
            } else {
                // Normal mode: 固定高さ
                TextEditor(text: $text)
                    .font(font)
                    .foregroundColor(fontColor)
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
                    .focused($isFocused)
                    .padding(EdgeInsets(top: containerInset.top - 8, 
                                      leading: containerInset.leading - 5, 
                                      bottom: containerInset.bottom - 8, 
                                      trailing: containerInset.trailing - 5))
            }
        }
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .if(!flexible && minHeight != nil) { view in
            view.frame(height: minHeight)
        }
    }
    
    private func calculateHeight() -> CGFloat {
        var height = textHeight + 20 // パディング分を追加
        
        if let minHeight = minHeight {
            height = max(height, minHeight)
        }
        
        if let maxHeight = maxHeight {
            height = min(height, maxHeight)
        }
        
        return height
    }
    
    private var shouldShowHint: Bool {
        if hideOnFocused && isFocused {
            return false
        }
        return text.isEmpty
    }
}

// Helper extension for conditional modifiers
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview
struct TextViewWithPlaceholder_Previews: PreviewProvider {
    @State static var text1 = ""
    @State static var text2 = "Hello, World!"
    @State static var text3 = ""
    
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Basic with hint")
            TextViewWithPlaceholder(
                text: $text1,
                hint: "Enter your message here...",
                fontSize: 16,
                backgroundColor: Color.gray.opacity(0.1),
                cornerRadius: 8
            )
            .frame(height: 100)
            
            Text("With custom hint color and font")
            TextViewWithPlaceholder(
                text: $text2,
                hint: "Description",
                hintColor: .blue.opacity(0.5),
                hintFont: "bold",
                fontSize: 14,
                fontColor: .blue
            )
            .frame(height: 80)
            
            Text("Flexible height")
            TextViewWithPlaceholder(
                text: $text3,
                hint: "Type here (flexible height)",
                fontSize: 18,
                backgroundColor: Color.yellow.opacity(0.1),
                cornerRadius: 12,
                flexible: true,
                minHeight: 50,
                maxHeight: 150
            )
        }
        .padding()
    }
}