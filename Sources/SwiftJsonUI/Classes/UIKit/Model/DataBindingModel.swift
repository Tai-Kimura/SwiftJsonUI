//
//  DataBindingModel.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/28.

import UIKit

public protocol  DataBindingModel {
    subscript(key: String) -> Any? { get set }
}
