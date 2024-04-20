//
//  IntExtension.swift
//  Created by Taichiro Kimura on 2017/08/31.
//

import UIKit

extension Int {
    
    public var priceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
}

