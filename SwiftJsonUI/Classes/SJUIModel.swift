//
//  SJUIModel.swift
//  SwiftJsonUI
//
//  Created by 木村太一朗 on 2018/09/12.
//  Copyright © 2018年 TANOSYS, LLC. All rights reserved.
//

import UIKit

@objcMembers
open class SJUIModel: NSObject {
    
    open var _json: JSON
    
    public var selected: Bool = false
    
    public init(json: JSON) {
        _json = json
    }
    
}
