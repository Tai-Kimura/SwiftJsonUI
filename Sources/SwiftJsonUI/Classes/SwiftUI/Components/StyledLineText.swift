//
//  StyledLineText.swift
//  SwiftJsonUI
//
//  The Double/Thick faces of `underline` / `strikethrough` come from
//  NSUnderlineStyle, and SwiftUI's Text cannot draw them — Text.LineStyle
//  has solid/dot/dash patterns only. This representable bridges a UILabel
//  with the NSAttributedString the vocabulary was defined for, so the two
//  values render exactly, not approximately. Used only when a decoration
//  declares Double or Thick; every other face stays on the SwiftUI path.
//

import SwiftUI
import UIKit

public struct StyledLineText: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    let underline: TextDecoration?
    let strikethrough: TextDecoration?
    let textAlignment: NSTextAlignment
    let numberOfLines: Int

    public init(
        text: String,
        font: UIFont,
        textColor: UIColor,
        underline: TextDecoration? = nil,
        strikethrough: TextDecoration? = nil,
        textAlignment: NSTextAlignment = .natural,
        numberOfLines: Int = 0
    ) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.underline = underline
        self.strikethrough = strikethrough
        self.textAlignment = textAlignment
        self.numberOfLines = numberOfLines
    }

    private static func nsStyle(_ style: TextDecoration.LineStyle) -> NSUnderlineStyle? {
        switch style {
        case .single: return .single
        case .double: return .double
        case .thick: return .thick
        case .none: return nil
        }
    }

    private func attributed() -> NSAttributedString {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        if let underline, let style = Self.nsStyle(underline.lineStyle) {
            attrs[.underlineStyle] = style.rawValue
            if let color = underline.color {
                attrs[.underlineColor] = UIColor(color)
            }
            if let offset = underline.lineOffset {
                attrs[.baselineOffset] = offset
            }
        }
        if let strikethrough, let style = Self.nsStyle(strikethrough.lineStyle) {
            attrs[.strikethroughStyle] = style.rawValue
            if let color = strikethrough.color {
                attrs[.strikethroughColor] = UIColor(color)
            }
        }
        return NSAttributedString(string: text, attributes: attrs)
    }

    public func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = numberOfLines
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }

    public func updateUIView(_ label: UILabel, context: Context) {
        label.attributedText = attributed()
        label.textAlignment = textAlignment
        label.numberOfLines = numberOfLines
    }

    @available(iOS 16.0, *)
    public func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UILabel,
        context: Context
    ) -> CGSize? {
        let width = proposal.width ?? .greatestFiniteMagnitude
        return uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
}
