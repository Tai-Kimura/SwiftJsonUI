//
//  SJUITextViewDelegateProxy.swift
//  SwiftJsonUI
//
//  Created by Claude on 2026/01/14.
//

import UIKit

/// UITextViewDelegate のクロージャを保持するプロキシクラス
@MainActor
public class SJUITextViewDelegateProxy: NSObject, UITextViewDelegate {

    // MARK: - Closure Properties

    public var didBeginEditing: ((UITextView) -> Void)?
    public var didEndEditing: ((UITextView) -> Void)?
    public var didChange: ((UITextView) -> Void)?
    public var didChangeSelection: ((UITextView) -> Void)?
    public var shouldBeginEditing: ((UITextView) -> Bool)?
    public var shouldEndEditing: ((UITextView) -> Bool)?
    public var shouldChangeText: ((UITextView, NSRange, String) -> Bool)?

    // MARK: - UITextViewDelegate

    public func textViewDidBeginEditing(_ textView: UITextView) {
        didBeginEditing?(textView)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        didEndEditing?(textView)
    }

    public func textViewDidChange(_ textView: UITextView) {
        didChange?(textView)
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        didChangeSelection?(textView)
    }

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        shouldBeginEditing?(textView) ?? true
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        shouldEndEditing?(textView) ?? true
    }

    public func textView(_ textView: UITextView,
                         shouldChangeTextIn range: NSRange,
                         replacementText text: String) -> Bool {
        shouldChangeText?(textView, range, text) ?? true
    }
}
