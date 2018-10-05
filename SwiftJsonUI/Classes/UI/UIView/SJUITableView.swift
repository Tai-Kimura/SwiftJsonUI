//
//  SJUITableView.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/09/13.
import UIKit

open class SJUITableView: UITableView {
    
    open class var viewClass: SJUITableView.Type {
        get {
            return SJUITableView.self
        }
    }

    open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUITableView {
        let t = viewClass.init()
        t.separatorStyle = UITableViewCellSeparatorStyle.none
        if let background = UIColor.findColorByJSON(attr: attr["background"]) {
            t.backgroundColor = background
        }
        t.showsVerticalScrollIndicator = false
        t.showsHorizontalScrollIndicator = false
        return t
    }

}
