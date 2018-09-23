//
//  SJUIViewController.swift
//  SwiftJsonUI
//
//  Created by 木村太一朗 on 2018/09/12.
//  Copyright © 2018年 TANOSYS, LLC. All rights reserved.
//

import UIKit
import SafariServices

@objcMembers
open class SJUIViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, SJUITextViewDelegate, ViewHolder {
    
    public var _views = [String:UIView]()
    
    open func hideKeyboard() {
        for view in _views.values {
            if view.isFirstResponder {
                view.resignFirstResponder()
                break
            }
        }
        for vc in self.childViewControllers {
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
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if DEBUG
        NotificationCenter.default.addObserver(self, selector: #selector(SJUIViewController.layoutFileDidChanged), name: NSNotification.Name(rawValue: "layoutFileDidChanged"), object: nil)
        #endif
    }
    #if DEBUG
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    #endif
    
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
}

