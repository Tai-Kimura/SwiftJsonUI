//
//  EditingInsideScrollView.swift
//  SwiftJsonUI
//
//  Whether a text input inside a given ScrollView is being edited, from
//  UIKit's begin / end editing notifications. AdvancedKeyboardAvoidingScrollView
//  grows its bottom inset from the moment editing begins, not from
//  keyboardWillShow: SwiftUI scrolls the focused field into the safe region
//  as the keyboard comes up, and when the inset grew after that scroll (the
//  order of the two keyboardWillShow observers is not fixed) the field
//  stopped short of `additionalPadding` and was never scrolled again
//  (conformance-mobile run 38339290220, Xcode 26.3 / iOS 26.2: 7pt short on
//  one of two launches). Editing begins before the keyboard is announced, so
//  the inset is in place when SwiftUI scrolls.
//

#if canImport(UIKit)
import Combine
import SwiftUI
import UIKit

/// The UIScrollView a SwiftUI ScrollView draws with, held weakly.
final class EnclosingScrollViewBox {
    weak var scrollView: UIScrollView?
}

/// A view placed in a ScrollView's content that finds the UIScrollView it
/// sits in. Draws nothing and is hidden from accessibility.
struct EnclosingScrollViewReader: UIViewRepresentable {
    let box: EnclosingScrollViewBox

    func makeUIView(context: Context) -> Marker {
        let view = Marker()
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true
        view.box = box
        return view
    }

    func updateUIView(_ uiView: Marker, context: Context) {
        uiView.box = box
        uiView.capture()
    }

    final class Marker: UIView {
        weak var box: EnclosingScrollViewBox?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            capture()
        }

        func capture() {
            var view = superview
            while let current = view {
                if let scrollView = current as? UIScrollView {
                    box?.scrollView = scrollView
                    return
                }
                view = current.superview
            }
        }
    }
}

enum EditingInsideScrollView {
    /// Begin / end editing of every UITextField (SwiftUI's TextField and
    /// SecureField) and UITextView (TextEditor): `true` on begin, `false` on
    /// end, with the input that sent it.
    /// One publisher for every ScrollView, so a redraw does not subscribe anew.
    static let changes: AnyPublisher<(input: UIView, editing: Bool), Never> = {
        let center = NotificationCenter.default
        let names: [(Notification.Name, Bool)] = [
            (UITextField.textDidBeginEditingNotification, true),
            (UITextField.textDidEndEditingNotification, false),
            (UITextView.textDidBeginEditingNotification, true),
            (UITextView.textDidEndEditingNotification, false),
        ]
        return Publishers.MergeMany(names.map { name, editing in
            center.publisher(for: name).compactMap { note -> (input: UIView, editing: Bool)? in
                (note.object as? UIView).map { (input: $0, editing: editing) }
            }
        })
        .eraseToAnyPublisher()
    }()

    /// Whether `input` sits inside `scrollView` (and is not the scroll view
    /// itself — a UITextView is one).
    static func isInside(_ input: UIView, _ scrollView: UIScrollView?) -> Bool {
        guard let scrollView, input !== scrollView else { return false }
        return input.isDescendant(of: scrollView)
    }
}
#endif
