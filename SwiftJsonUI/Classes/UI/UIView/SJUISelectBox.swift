//
//  SJUISelectBox.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2018/05/29.

import UIKit

open class SJUISelectBox: SJUIView, SheetViewDelegate {
    
    public static var currentLocale: Locale? = nil
    
    public static var defaultReferenceViewId: String?
    
    override open class var viewClass: SJUIView.Type {
        get {
            return SJUISelectBox.self
        }
    }
    
    
    static let defaultCaretWidth: CGFloat = 39.0
    public static var defaultCaretImageName = "Triangle"
    public static var defaultLabelPadding = UIEdgeInsets.init(top: 0, left: 10.0, bottom: 0, right: 10.0)
    
    private var _type: SelectItemType = .normal
    public var type: SelectItemType {
        get {
            return _type
        }
    }
    private var _caret: SJUIImageView!
    public var caret: SJUIImageView {
        get {
            return _caret
        }
    }
    private var _divider: SJUIView!
    public var divider: SJUIView {
        get {
            return _divider
        }
    }
    private var _label: SJUILabel!
    public var label: SJUILabel {
        get {
            return _label
        }
    }
    
    open var items = [String]() {
        didSet {
            if self.hasPrompt {
                items.insert(prompt!, at: 0)
            }
        }
    }
    
    private var _selectedIndex: Int?
    
    open var selectedIndex: Int? {
        get {
            return _selectedIndex
        }
        
        set {
            if let index = newValue {
                self.didPickItem(row: index, inComponent: 0)
            } else {
                self.label.selected = !hasPrompt
                self.label.applyAttributedText(hasPrompt ? items[0] : "")
            }
        }
    }
    
    public var maximumDate: Date?
    public var minimumDate: Date?
    
    private var _selectedDate: Date?
    
    open var selectedDate: Date? {
        get {
            return _selectedDate
        }
        
        set {
            if let date = newValue {
                self.didPickDate(date)
            } else {
                self.label.selected = !hasPrompt
                self.label.applyAttributedText(prompt ?? "")
            }
        }
    }
    
    public var hasPrompt: Bool {
        get {
            return _prompt != nil
        }
    }
    
    private var _prompt: String?
    
    public var prompt: String? {
        get {
            return _prompt
        }
    }
    
    public var includePromptWhenDataBinding = false
    
    public var dateStringFormat: String = "yyyy/MM/dd"
    
    public var locale: Locale? = nil
    
    public var datePickerMode = UIDatePicker.Mode.date
    
    private var canBack = false
    
    public weak var selectBoxDelegate: UISelectBoxDelegate?
    
    public weak var referenceView: UIScrollView?
    
    
    public weak var inView: UIView?
    
    
    required public init(attr: JSON) {
        super.init(frame: CGRect.zero)
        self.clipsToBounds = true
        self._type = SelectItemType(rawValue: attr["selectItemType"].stringValue) ?? .normal
        if let datePickerMode = attr["datePickerMode"].string {
            switch datePickerMode {
            case "date":
                self.datePickerMode = .date
            case "time":
                self.datePickerMode = .time
            case "datetime":
                self.datePickerMode = .dateAndTime
            case "countDown":
                self.datePickerMode = .countDownTimer
            default:
                break
            }
        }
        self.canBack = attr["canBack"].boolValue
        if let prompt = attr["prompt"].string {
            self._prompt = prompt.localized()
        }
        initializeCaret(attr: attr["caretAttributes"])
        initializeDivider(attr: attr["dividerAttributes"])
        initializeLabel(attr: attr["labelAttributes"])
        let gr = UITapGestureRecognizer(target: self, action: #selector(SJUISelectBox.showSheet))
        self.addGestureRecognizer(gr)
        self.canTap = true
        self.isUserInteractionEnabled = true
        self.includePromptWhenDataBinding = attr["includePromptWhenDataBinding"].boolValue
        setInitialValues(attr: attr)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setInitialValues(attr: JSON) {
        switch self.type {
        case .normal:
            _selectedIndex = attr["selectedIndex"].int
        case .date:
            if let format = attr["dateStringFormat"].string {
                dateStringFormat = format
            }
            maximumDate = attr["maximumDate"].string?.toDate(format: dateStringFormat)
            minimumDate = attr["minimumDate"].string?.toDate(format: dateStringFormat)
            _selectedDate = attr["selectedDate"].string?.toDate(format: dateStringFormat)
        }
    }
    
    private func initializeCaret(attr: JSON) {
        let caretWidth = attr["width"].cgFloat ?? SJUISelectBox.defaultCaretWidth
        let imageSrc = attr["src"].string ?? SJUISelectBox.defaultCaretImageName
        let caret = SJUIImageView()
        caret.contentMode = .center
        caret.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(caret)
        let rightConstraint = NSLayoutConstraint(item: caret, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: caret, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: caret, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: caretWidth)
        let heightConstraint = NSLayoutConstraint(item: caret, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0)
        self.addConstraints([rightConstraint,verticalConstraint,heightConstraint])
        caret.addConstraints([widthConstraint])
        if let background = UIColor.findColorByJSON(attr: attr["background"]) {
            caret.backgroundColor = background
        }
        caret.image = UIImage(named: imageSrc)
        self._caret = caret
    }
    
    private func initializeDivider(attr: JSON) {
        let dividerWidth: CGFloat = attr["width"].cgFloat ?? 0
        let divider = SJUIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(divider)
        let rightConstraint = NSLayoutConstraint(item: divider, attribute: .right, relatedBy: .equal, toItem: self.caret, attribute: .left, multiplier: 1.0, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: divider, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: divider, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: dividerWidth)
        let heightConstraint = NSLayoutConstraint(item: divider, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0)
        self.addConstraints([rightConstraint,verticalConstraint,heightConstraint])
        divider.addConstraints([widthConstraint])
        if let background = UIColor.findColorByJSON(attr: attr["background"]) {
            divider.backgroundColor = background
        }
        self._divider = divider
    }
    
    private func initializeLabel(attr: JSON) {
        let l = SJUILabel()
        var edgeInsets = [CGFloat]()
        if let edgeInsetStr = attr["edgeInset"].string {
            let edgeInsetStrs = edgeInsetStr.components(separatedBy: "|")
            for e in edgeInsetStrs {
                if let n = NumberFormatter().number(from: e) {
                    edgeInsets.append(CGFloat(truncating: n))
                }
            }
        } else if let insets = attr["edgeInset"].arrayObject as? [CGFloat] {
            edgeInsets = insets
        }
        switch (edgeInsets.count) {
        case 0:
            l.padding = SJUISelectBox.defaultLabelPadding
        case 1:
            l.padding = UIEdgeInsets.init(top: edgeInsets[0], left: edgeInsets[0], bottom: edgeInsets[0], right: edgeInsets[0])
        case 2:
            l.padding = UIEdgeInsets.init(top: edgeInsets[0], left: edgeInsets[1], bottom: edgeInsets[0], right: edgeInsets[1])
        case 3:
            l.padding = UIEdgeInsets.init(top: edgeInsets[0], left: edgeInsets[1], bottom: edgeInsets[2], right: edgeInsets[1])
        default:
            l.padding = UIEdgeInsets.init(top: edgeInsets[0], left: edgeInsets[1], bottom: edgeInsets[2], right: edgeInsets[3])
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = attr["lineHeightMultiple"].cgFloat != nil ? attr["lineHeightMultiple"].cgFloatValue : attr["lines"].int ?? 1 == 1 ? 1.0 : 1.4
        let size = attr["fontSize"].cgFloat != nil ? attr["fontSize"].cgFloatValue : 16.0
        let name = attr["font"].string ?? SJUIViewCreator.defaultFont
        let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        var attributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: font]
        l.font = font
        l.numberOfLines = attr["lines"].int ?? 1 == 1 ? 1 : attr["lines"].intValue
        l.lineBreakMode = NSLineBreakMode.byWordWrapping
        if let lineBreakMode = attr["lineBreakMode"].string {
            switch (lineBreakMode) {
            case "Char":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byCharWrapping
                l.lineBreakMode = NSLineBreakMode.byCharWrapping
            case "Clip":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byClipping
                l.lineBreakMode = NSLineBreakMode.byClipping
            case "Word":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
                l.lineBreakMode = NSLineBreakMode.byWordWrapping
            case "Head":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingHead
                l.lineBreakMode = NSLineBreakMode.byTruncatingHead
            case "Middle":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
                l.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
            case "Tail":
                paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
                l.lineBreakMode = NSLineBreakMode.byTruncatingTail
            default:
                break
            }
        }
        if let alignment = attr["textAlign"].string {
            switch (alignment) {
            case "Left":
                paragraphStyle.alignment = NSTextAlignment.left
                l.textAlignment = NSTextAlignment.left
            case "Right":
                paragraphStyle.alignment = NSTextAlignment.right
                l.textAlignment = NSTextAlignment.right
            case "Center":
                paragraphStyle.alignment = NSTextAlignment.center
                l.textAlignment = NSTextAlignment.center
            default:
                break
            }
        }
        let color = UIColor.findColorByJSON(attr: attr["fontColor"]) ?? SJUIViewCreator.defaultFontColor
        attributes[NSAttributedString.Key.foregroundColor] = color
        l.highlightAttributes = attributes
        if !attr["hintAttributes"].isEmpty {
            let hintAttr = attr["hintAttributes"]
            let hintSize = hintAttr["fontSize"].cgFloat != nil ? hintAttr["fontSize"].cgFloatValue : size
            let hintName = hintAttr["font"].string != nil ? hintAttr["font"].stringValue : name
            let hintFont = UIFont(name: hintName, size: hintSize) ?? UIFont.systemFont(ofSize: hintSize)
            var hintAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: hintFont, NSAttributedString.Key.foregroundColor: color]
            if let hintColor = UIColor.findColorByJSON(attr: hintAttr["fontColor"]) {
                hintAttributes[NSAttributedString.Key.foregroundColor] = hintColor
            }
            l.attributes = hintAttributes
        } else if let hintColor = UIColor.findColorByJSON(attr: attr["hintColor"]) {
            l.attributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: hintColor]
        } else {
            l.attributes = attributes
        }
        if let prompt = self.prompt {
            l.selected = false
            l.applyAttributedText(prompt)
        }
        l.selected = attr["selected"].boolValue
        l.translatesAutoresizingMaskIntoConstraints = false
        self.insertSubview(l, belowSubview: self.caret)
        let leftConstraint = NSLayoutConstraint(item: l, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: l, attribute: .right, relatedBy: .equal, toItem: self.divider, attribute: .left, multiplier: 1.0, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: l, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: l, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0)
        self.addConstraints([leftConstraint,rightConstraint,verticalConstraint,heightConstraint])
        self._label = l
    }
    
    @objc open func showSheet() {
        guard let inView = inView else {
            return
        }
        guard self.selectBoxDelegate?.willShowSheet(view: self) ?? true else {
            return
        }
        if let viewController = (selectBoxDelegate as? SJUIViewController) {
            viewController.hideKeyboard()
        }
        switch self.type {
        case .normal:
            SheetView.sharedInstance().showPicker([_selectedIndex ?? 0], withDataSource: [items], forItem: items, inView: inView, canBack: canBack)
        case .date:
            SheetView.sharedInstance().showDatePicker(mode: datePickerMode, date: selectedDate ?? Date(), inView: inView, minimumDate: minimumDate, maximumDate: maximumDate, canBack: false, locale: SJUISelectBox.currentLocale)
        }
        SheetView.sharedInstance().delegate = self
        setScrollOffset()
    }
    
    open func setScrollOffset() {
        guard let referenceView = referenceView  else {
            return
        }
        referenceView.contentInset.bottom = SheetView.sharedInstance()._customView.frame.size.height
        let frame = label.convert(label.bounds, to: referenceView)
        let offsetTop = UIScreen.main.bounds.size.height - SheetView.sharedInstance()._customView.frame.size.height
        let originY = referenceView.frame.origin.y
        let minScrollY = frame.origin.y + frame.size.height + originY - referenceView.contentOffset.y + 20
        if minScrollY > offsetTop {
            referenceView.setContentOffset(CGPoint(x: 0, y: referenceView.contentOffset.y + minScrollY - offsetTop), animated: true)
        }
    }
    
    private func resetScrollViewInset() {
        SheetView.sharedInstance().delegate = nil
        guard let referenceView = referenceView  else {
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            referenceView.contentInset.bottom = 0
        })
    }
    
    open func didPickItem(row: Int, inComponent component: Int) {
        _selectedIndex = row
        let text = items[row]
        label.selected = !hasPrompt || row != 0
        label.applyAttributedText(text)
    }
    
    open func backWithPick(row: Int, forComponent component: Int) {
        resetScrollViewInset()
        didPickItem(row: row, inComponent: component)
        selectBoxDelegate?.didItemSelected(view: self, isBack: true)
    }
    
    open func dismissWithPick(row: Int, forComponent component: Int) {
        resetScrollViewInset()
        didPickItem(row: row, inComponent: component)
        selectBoxDelegate?.didItemSelected(view: self, isBack: false)
    }
    
    open func didPickDate(_ date: Date) {
        _selectedDate = date
        label.selected = true
        label.applyAttributedText(date.timeIntervalSince1970.toDateString(format: dateStringFormat, locale: SJUISelectBox.currentLocale))
    }
    
    open func backWithPickDate(_ date: Date) {
        resetScrollViewInset()
        didPickDate(date)
        selectBoxDelegate?.didItemSelected(view: self, isBack: true)
    }
    
    open func dismissWithPickDate(_ date: Date) {
        resetScrollViewInset()
        didPickDate(date)
        selectBoxDelegate?.didItemSelected(view: self, isBack: false)
    }
    
    override open class func createFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> SJUISelectBox {
        let s = (viewClass as! SJUISelectBox.Type).init(attr: attr)
        s.selectBoxDelegate = target as? UISelectBoxDelegate
        if let inViewId = attr["inView"].string, let inView = views[inViewId] {
            s.inView = inView
        } else if let viewController = target as? UIViewController {
            s.inView = viewController.view
        }
        if let defaultReferenceViewId = SJUISelectBox.defaultReferenceViewId {
            s.referenceView = views[defaultReferenceViewId] as? SJUIScrollView
        } else if let refereceViewId = attr["referenceView"].string {
            s.referenceView = views[refereceViewId] as? SJUIScrollView
        }
        if let dateFormat = attr["dateFormat"].string {
            s.dateStringFormat = dateFormat.localized()
        }
        return s
    }
    
    public enum SelectItemType: String {
        case normal = "Normal"
        case date = "Date"
    }
}

public protocol UISelectBoxDelegate: class {
    func willShowSheet(view: SJUISelectBox) -> Bool
    func didItemSelected(view: SJUISelectBox, isBack: Bool)
}

public extension UISelectBoxDelegate {
    func willShowSheet(view: SJUISelectBox) -> Bool {
        return true
    }
    func didItemSelected(view: SJUISelectBox, isBack: Bool) {
    }
}

