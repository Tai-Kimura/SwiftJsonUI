//
//  Logger.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/23.

import Foundation


open class Logger {
    open class func debug(_ items: Any...) {
        #if DEBUG
        log(items)
        #endif
    }
    
    open class func log(_ items: Any...) {
        print(items)
    }
}
