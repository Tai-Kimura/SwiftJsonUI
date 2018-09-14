//
//  SJUITableView.swift
//  SwiftJsonUI
//
//  Created by 木村太一朗 on 2018/09/13.
//  Copyright © 2018年 TANOSYS, LLC. All rights reserved.
//

import UIKit

open class SJUITableView: UITableView {

    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUITableView {
        let t = SJUITableView()
        t.separatorStyle = UITableViewCellSeparatorStyle.none
        if let background = UIColor.findColorByJSON(attr: attr["background"]) {
            t.backgroundColor = background
        }
        t.showsVerticalScrollIndicator = false
        t.showsHorizontalScrollIndicator = false
        return t
    }

}
