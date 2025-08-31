//
//  DoubleExtension.swift
//  Created by Taichiro Kimura on 2016/06/15.
//

import UIKit

public extension Double {
    
    var toDate: Date {
        get {
            return Date(timeIntervalSince1970: TimeInterval(self))
        }
    }
    
    var kiloByte: Double {
        get {
            return self/1024
        }
    }
    
    var megaByte: Double {
        get {
            return self/1024/1024
        }
    }
    
    var gigaByte: Double {
        get {
            return self/1024/1024/1024
        }
    }
    
    func toDateString(format: String = "yyyy/MM/dd", locale: Locale? = nil) -> String {
        let date = Date(timeIntervalSince1970: self)
        let formatter = DateFormatter()
        if let locale = locale {
            formatter.locale = locale
            formatter.setLocalizedDateFormatFromTemplate(format)
        } else {
            formatter.dateFormat = format
        }
        return formatter.string(from: date)
    }
    
    func toDateTimeString(format: String = "yyyy年MM月dd日 HH:mm:ss", locale: Locale? = nil) -> String {
        let date = Date(timeIntervalSince1970: self)
        let formatter = DateFormatter()
        if let locale = locale {
            formatter.locale = locale
            formatter.setLocalizedDateFormatFromTemplate(format)
        } else {
            formatter.dateFormat = format
        }
        return formatter.string(from: date)
    }

}

