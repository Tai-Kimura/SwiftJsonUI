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
public class SJUIViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, SJUITextViewDelegate, ViewHolder {
    
    public var _views = [String:UIView]()
    
    public func hideKeyboard() {
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
    
    public func returnNumberPad() {
        hideKeyboard()
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        
    }
    
    public func textViewDidChangeFrame(textView: SJUITextView) {
        
    }
}

