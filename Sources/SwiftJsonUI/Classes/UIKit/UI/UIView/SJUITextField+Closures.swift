//
//  SJUITextField+Closures.swift
//  SwiftJsonUI
//
//  Created by Claude on 2026/01/14.
//

import UIKit

// Associated Object Key
private var TextFieldDelegateProxyKey: UInt8 = 0

public extension SJUITextField {

    // MARK: - Delegate Proxy

    /// プロキシを取得または作成
    private var delegateProxy: SJUITextFieldDelegateProxy {
        if let proxy = objc_getAssociatedObject(self, &TextFieldDelegateProxyKey) as? SJUITextFieldDelegateProxy {
            return proxy
        }
        let proxy = SJUITextFieldDelegateProxy()
        objc_setAssociatedObject(self, &TextFieldDelegateProxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.delegate = proxy
        self.addTarget(proxy, action: #selector(SJUITextFieldDelegateProxy.handleTextChange(_:)), for: .editingChanged)
        return proxy
    }

    // MARK: - Chainable Closure Setters

    /// 編集開始時のハンドラを設定
    @discardableResult
    func onBeginEditing(_ handler: @escaping (UITextField) -> Void) -> Self {
        delegateProxy.didBeginEditing = handler
        return self
    }

    /// 編集終了時のハンドラを設定
    @discardableResult
    func onEndEditing(_ handler: @escaping (UITextField) -> Void) -> Self {
        delegateProxy.didEndEditing = handler
        return self
    }

    /// テキスト変更時のハンドラを設定（editingChanged イベント）
    @discardableResult
    func onTextChange(_ handler: @escaping (UITextField) -> Void) -> Self {
        delegateProxy.textDidChange = handler
        return self
    }

    /// バックスペース削除時のハンドラを設定
    @discardableResult
    func onDeleteBackward(_ handler: @escaping (UITextField) -> Void) -> Self {
        delegateProxy.didDeleteBackward = handler
        return self
    }

    /// Returnキー押下時のハンドラを設定
    @discardableResult
    func onShouldReturn(_ handler: @escaping (UITextField) -> Bool) -> Self {
        delegateProxy.shouldReturn = handler
        return self
    }

    /// 文字入力時のハンドラを設定（入力を許可するかどうかを返す）
    @discardableResult
    func onShouldChangeCharacters(_ handler: @escaping (UITextField, NSRange, String) -> Bool) -> Self {
        delegateProxy.shouldChangeCharacters = handler
        return self
    }

    /// クリアボタン押下時のハンドラを設定
    @discardableResult
    func onShouldClear(_ handler: @escaping (UITextField) -> Bool) -> Self {
        delegateProxy.shouldClear = handler
        return self
    }

    /// 編集開始を許可するかのハンドラを設定
    @discardableResult
    func onShouldBeginEditing(_ handler: @escaping (UITextField) -> Bool) -> Self {
        delegateProxy.shouldBeginEditing = handler
        return self
    }

    /// 編集終了を許可するかのハンドラを設定
    @discardableResult
    func onShouldEndEditing(_ handler: @escaping (UITextField) -> Bool) -> Self {
        delegateProxy.shouldEndEditing = handler
        return self
    }

    /// 選択範囲変更時のハンドラを設定 (iOS 13+)
    @discardableResult
    func onChangeSelection(_ handler: @escaping (UITextField) -> Void) -> Self {
        delegateProxy.didChangeSelection = handler
        return self
    }
}
