//
//  SJUIViewController.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/12.

//

import UIKit
import SafariServices

@objcMembers
open class SJUIViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, SJUITextViewDelegate, ViewHolder {
    
    public var _views = [String:UIView]()
    
    private var _safeAreaHandlers = [(UIEdgeInsets) -> Void]()
    
    public var safeAreaHandlers: [(UIEdgeInsets) -> Void] {
        get {
            return _safeAreaHandlers
        }
    }
    
    private var _observers = [ObserverKey:NSKeyValueObservation]()
    
    public var observers: [ObserverKey:NSKeyValueObservation] {
        get {
            return _observers
        }
    }
    
    deinit {
        for observer in _observers.values {
            observer.invalidate()
        }
        _observers.removeAll()
        _safeAreaHandlers.removeAll()
        _views.removeAll()
        #if DEBUG
        NotificationCenter.default.removeObserver(self)
        #endif
    }
    
    open func register(safeAreaHandler: @escaping (UIEdgeInsets) -> Void) {
        _safeAreaHandlers.append(safeAreaHandler)
    }
    
    open func hideKeyboard() {
        for view in _views.values {
            if view.isFirstResponder {
                view.resignFirstResponder()
                break
            }
        }
        for vc in self.children {
            if let vc = vc as? SJUIViewController {
                for view in vc._views.values {
                    if view.isFirstResponder {
                        view.resignFirstResponder()
                        break
                    }
                }
            }
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            if _observers[.safeArea] == nil {
                let o = self.view.observe(\.safeAreaInsets, options: [.initial], changeHandler: {[weak self] a, change in
                    if let safeAreaInsets = change.newValue, let safeAreaHandlers = self?._safeAreaHandlers {
                        DispatchQueue.main.async(execute: {
                            for safeAreaHandler in safeAreaHandlers {
                                safeAreaHandler(safeAreaInsets)
                            }
                        })
                    }
                })
                _observers[.safeArea] = o
            }
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if DEBUG
        NotificationCenter.default.addObserver(self, selector: #selector(SJUIViewController.layoutFileDidChanged), name: NSNotification.Name(rawValue: "layoutFileDidChanged"), object: nil)
        #endif
    }
    
    #if DEBUG
    open func layoutFileDidChanged() {
        Logger.debug("View Did Changed")
        SJUIViewCreator.cleanStyleCache()
    }
    #endif
    
    
    
    open func returnNumberPad() {
        hideKeyboard()
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    open func textViewDidChange(_ textView: UITextView) {
        
    }
    
    open func textViewDidChangeFrame(textView: SJUITextView) {
        
    }
    
    
    public enum ObserverKey {
        case safeArea
    }
}

