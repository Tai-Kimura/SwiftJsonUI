//
//  SJUITextFieldDelegateProxy.swift
//  SwiftJsonUI
//
//  Created by Claude on 2026/01/14.
//

import UIKit

/// UITextFieldDelegate + SJUITextFieldDelegate のクロージャを保持するプロキシクラス
@MainActor
public class SJUITextFieldDelegateProxy: NSObject, UITextFieldDelegate, SJUITextFieldDelegate {

    // MARK: - Closure Properties

    public var didBeginEditing: ((UITextField) -> Void)?
    public var didEndEditing: ((UITextField) -> Void)?
    public var didChangeSelection: ((UITextField) -> Void)?
    public var shouldBeginEditing: ((UITextField) -> Bool)?
    public var shouldEndEditing: ((UITextField) -> Bool)?
    public var shouldReturn: ((UITextField) -> Bool)?
    public var shouldChangeCharacters: ((UITextField, NSRange, String) -> Bool)?
    public var shouldClear: ((UITextField) -> Bool)?

    /// SJUITextFieldDelegate - バックスペース削除時
    public var didDeleteBackward: ((UITextField) -> Void)?

    /// テキスト変更用（editingChanged イベント）
    public var textDidChange: ((UITextField) -> Void)?

    // MARK: - UITextFieldDelegate

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        didBeginEditing?(textField)
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        didEndEditing?(textField)
    }

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        shouldBeginEditing?(textField) ?? true
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        shouldEndEditing?(textField) ?? true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        shouldReturn?(textField) ?? true
    }

    public func textField(_ textField: UITextField,
                          shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
        shouldChangeCharacters?(textField, range, string) ?? true
    }

    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        shouldClear?(textField) ?? true
    }

    @available(iOS 13.0, *)
    public func textFieldDidChangeSelection(_ textField: UITextField) {
        didChangeSelection?(textField)
    }

    // MARK: - SJUITextFieldDelegate

    public func textFieldDidDeleteBackward(textField: UITextField) {
        didDeleteBackward?(textField)
    }

    // MARK: - editingChanged Handler

    @objc public func handleTextChange(_ textField: UITextField) {
        textDidChange?(textField)
    }
}
