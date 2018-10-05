//
//  DoubleExtension.swift
//  Created by Taichiro Kimura on 2016/06/15.
//

import UIKit

public extension Double {
    
    public var toDate: Date {
        get {
            return Date(timeIntervalSince1970: TimeInterval(self))
        }
    }
    
    public var kiloByte: Double {
        get {
            return self/1024
        }
    }
    
    public var megaByte: Double {
        get {
            return self/1024/1024
        }
    }
    
    public var gigaByte: Double {
        get {
            return self/1024/1024/1024
        }
    }
    
    public func toDateString(format: String = "yyyy/MM/dd") -> String {
        let date = Date(timeIntervalSince1970: self)
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    public func toDateTimeString(format: String = "yyyy年MM月dd日 HH:mm:ss") -> String {
        let date = Date(timeIntervalSince1970: self)
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

}

