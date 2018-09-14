//
//  IntExtension.swift
//  WarranteeNow
//
//  Created by 木村太一朗 on 2017/08/31.
//  Copyright © 2017年 WARRANTEE.INC,. All rights reserved.
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

