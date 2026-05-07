//
//  SJUITextView+Closures.swift
//  SwiftJsonUI
//
//  Created by Claude on 2026/01/14.
//

import UIKit

// Associated Object Key
private var TextViewDelegateProxyKey: UInt8 = 0

public extension SJUITextView {

    // MARK: - Delegate Proxy

    /// プロキシを取得または作成
    private var delegateProxy: SJUITextViewDelegateProxy {
        if let proxy = objc_getAssociatedObject(self, &TextViewDelegateProxyKey) as? SJUITextViewDelegateProxy {
            return proxy
        }
        let proxy = SJUITextViewDelegateProxy()
        objc_setAssociatedObject(self, &TextViewDelegateProxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.delegate = proxy
        return proxy
    }

    // MARK: - Chainable Closure Setters

    /// 編集開始時のハンドラを設定
    @discardableResult
    func onBeginEditing(_ handler: @escaping (UITextView) -> Void) -> Self {
        delegateProxy.didBeginEditing = handler
        return self
    }

    /// 編集終了時のハンドラを設定
    @discardableResult
    func onEndEditing(_ handler: @escaping (UITextView) -> Void) -> Self {
        delegateProxy.didEndEditing = handler
        return self
    }

    /// テキスト変更時のハンドラを設定
    @discardableResult
    func onTextChange(_ handler: @escaping (UITextView) -> Void) -> Self {
        delegateProxy.didChange = handler
        return self
    }

    /// 選択範囲変更時のハンドラを設定
    @discardableResult
    func onChangeSelection(_ handler: @escaping (UITextView) -> Void) -> Self {
        delegateProxy.didChangeSelection = handler
        return self
    }

    /// テキスト変更を許可するかのハンドラを設定
    @discardableResult
    func onShouldChangeText(_ handler: @escaping (UITextView, NSRange, String) -> Bool) -> Self {
        delegateProxy.shouldChangeText = handler
        return self
    }

    /// 編集開始を許可するかのハンドラを設定
    @discardableResult
    func onShouldBeginEditing(_ handler: @escaping (UITextView) -> Bool) -> Self {
        delegateProxy.shouldBeginEditing = handler
        return self
    }

    /// 編集終了を許可するかのハンドラを設定
    @discardableResult
    func onShouldEndEditing(_ handler: @escaping (UITextView) -> Bool) -> Self {
        delegateProxy.shouldEndEditing = handler
        return self
    }
}
