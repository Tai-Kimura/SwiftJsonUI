//
//  SheetView.swift
//  SwiftJsonUI
//  Created by Taichiro Kimura on 2016/01/15.
import UIKit
@objc public protocol SheetViewDelegate {
    @objc optional func didPickItem(row: Int, inComponent component: Int)
    @objc optional func didPickDate(_ date: Date)
    @objc optional func dismissWithPick(row: Int, forComponent component: Int)
    @objc optional func backWithPick(row: Int, forComponent component: Int)
    @objc optional func dismissWithPickDate(_ date: Date)
    @objc optional func backWithPickDate(_ date: Date)
}
open class SheetView: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    public static var font: UIFont = UIFont.systemFont(ofSize: 20.0)
    public static var textColor: UIColor = UIColor.black
    public static var backgroundColor = UIColor.colorWithHexString("000000", alpha: 0.2)
    public static var selectBtnColor = SJUIViewCreator.defaultFontColor
    public static var backBtnColor = SJUIViewCreator.defaultFontColor
    public static var lineColor = UIColor.lightGray
    public static var selectBtnTitle = "選択"
    public static var backBtnTitle = "前へ"
    fileprivate static let instance = SheetView()
    fileprivate var _view: UIView!
    public var _customView: UIView!
    fileprivate var _pickerView: UIPickerView!
    fileprivate var _datePicker: UIDatePicker!
    fileprivate var _itemNames: [String] = Array<String>()
    fileprivate var _backBtn: UIButton!
    fileprivate var _selectBtn: UIButton!
    public weak var delegate: SheetViewDelegate?
    public var pickerSource: [[Any]] = Array<[Any]>()
    fileprivate override init() {
    }
    public class func sharedInstance() -> SheetView {
        if (instance._view == nil) {
            instance._view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
            instance._view!.backgroundColor = backgroundColor
            let r = UITapGestureRecognizer(target: self, action: #selector(SheetView.backgroundTapped))
            instance._view.addGestureRecognizer(r)
            instance._customView = instance.createPickerView()
            var frame = instance._customView.frame
            frame.origin.y = UIScreen.main.bounds.height + 100.0
            instance._customView.frame = frame
            instance._view.addSubview(instance._customView)
        }
        return instance
    }
    public func createPickerView() -> UIView {
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 300.0))
        customView.backgroundColor = UIColor.white
        _pickerView = UIPickerView(frame: CGRect(x: 0, y: 20.0, width: UIScreen.main.bounds.size.width, height: 280.0))
        _pickerView.delegate = self
        _pickerView.dataSource = self
        _datePicker = UIDatePicker()
        _datePicker.calendar = getCalendar()
        _datePicker.datePickerMode = UIDatePicker.Mode.date
        if #available(iOS 14.0, *) {
            _datePicker.tintColor = SheetView.textColor
            _datePicker.preferredDatePickerStyle = .wheels
            _datePicker.frame = CGRect(x: 0, y: 20.0, width: UIScreen.main.bounds.width, height: 280.0)
        } else {
            _datePicker.setValue(SheetView.textColor, forKeyPath: "textColor")
            if #available(iOS 13.0, *) {
                _datePicker.setValue(false, forKey: "highlightsToday")
            }
        }
        _datePicker.addTarget(self, action: #selector(SheetView.dateChanged), for: UIControl.Event.valueChanged)
        let lineView = UIView(frame: CGRect(x: 0, y: 40.0, width: customView.frame.size.width, height: 1.0))
        lineView.backgroundColor = SheetView.lineColor
        _selectBtn = UIButton(frame: CGRect(x: customView.frame.size.width - 70.0, y: 0, width: 70.0, height: 40.0))
        _selectBtn.setTitleColor(SheetView.selectBtnColor, for: UIControl.State())
        _selectBtn.setTitle(SheetView.selectBtnTitle, for: UIControl.State())
        _selectBtn.addTarget(self, action: #selector(SheetView.selected), for: UIControl.Event.touchDown)
        _backBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 70.0, height: 40.0))
        _backBtn.setTitleColor(SheetView.backBtnColor, for: UIControl.State())
        _backBtn.setTitle(SheetView.backBtnTitle, for: UIControl.State())
        _backBtn.addTarget(self, action: #selector(SheetView.back), for: UIControl.Event.touchDown)
        _backBtn.isHidden = true
        let bgView = UIView(frame: CGRect(x: 0, y: 0, width: customView.frame.size.width, height: 40.0))
        bgView.backgroundColor = UIColor.white
        bgView.addSubview(_selectBtn)
        bgView.addSubview(_backBtn)
        customView.addSubview(_pickerView)
        customView.addSubview(_datePicker)
        customView.addSubview(bgView)
        customView.addSubview(lineView)
        return customView
    }
    public func setSelectBtnTitle(_ title: String) {
        _selectBtn.setTitle(title, for: UIControl.State())
    }
    public func showPicker(_ selectRows:[Int], withDataSource datasource:[[Any]], forItem itemNames: [String], inView mainView: UIView, canBack: Bool = false, duration: TimeInterval = 0.3, completion: ((Bool) -> Void)? = nil) {
        _pickerView.alpha = 1.0
        _datePicker.alpha = 0
        _itemNames = itemNames
        _selectBtn.setTitleColor(SheetView.selectBtnColor, for: UIControl.State())
        _selectBtn.setTitle(SheetView.selectBtnTitle, for: UIControl.State())
        _backBtn.setTitleColor(SheetView.backBtnColor, for: UIControl.State())
        _backBtn.setTitle(SheetView.backBtnTitle, for: UIControl.State())
        _backBtn.isHidden = !canBack
        self.pickerSource = datasource
        self._pickerView.reloadAllComponents()
        for i in 0 ..< selectRows.count {
            let row = selectRows[i]
            _pickerView.selectRow(row, inComponent: i, animated: false)
        }
        self.show(mainView, duration: duration, completion: completion)
    }
    public func showDatePicker(mode: UIDatePicker.Mode, date: Date, inView mainView: UIView, minimumDate: Date? = nil, maximumDate: Date? = nil, duration: TimeInterval = 0.3, canBack: Bool = false, completion: ((Bool) -> Void)? = nil, locale: Locale? = nil) {
        _pickerView.alpha = 0
        _datePicker.alpha = 1.0
        _datePicker.datePickerMode = mode
        _selectBtn.setTitleColor(SheetView.selectBtnColor, for: UIControl.State())
        _selectBtn.setTitle(SheetView.selectBtnTitle, for: UIControl.State())
        _backBtn.setTitleColor(SheetView.backBtnColor, for: UIControl.State())
        _backBtn.setTitle(SheetView.backBtnTitle, for: UIControl.State())
        _backBtn.isHidden = !canBack
        _datePicker.date = date
        self._datePicker.locale = locale
        _datePicker.minimumDate = minimumDate
        _datePicker.maximumDate = maximumDate
        self.show(mainView, duration: duration, completion: completion)
    }
    public func show(_ mainView: UIView, duration: TimeInterval = 0.3, completion: ((Bool) -> Void)? = nil) {
        if let _ = _view.superview {
            return
        }
        DispatchQueue.main.async(execute: {
            mainView.addSubview(self._view)
            UIView.animate(withDuration: duration, animations: {
                var frame = self._customView.frame
                frame.origin.y = self._view.frame.height - frame.size.height
                self._customView.frame = frame
            }, completion: completion)
        })
    }
    public func dismiss(isBack back: Bool = false, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        if (_view.superview == nil){
            return
        }
        DispatchQueue.main.async(execute: {
            for i in 0 ..< self.pickerSource.count {
                if back {
                    self.delegate?.backWithPick?(row: self._pickerView.selectedRow(inComponent: i), forComponent: i)
                } else {
                    self.delegate?.dismissWithPick?(row: self._pickerView.selectedRow(inComponent: i), forComponent: i)
                }
            }
            if self._datePicker.alpha != 0 {
                if back {
                    self.delegate?.backWithPickDate?(self._datePicker.date)
                } else {
                    self.delegate?.dismissWithPickDate?(self._datePicker.date)
                }
            }
            self.delegate = nil
            self.pickerSource = Array<[Any]>()
            UIView.animate(withDuration: duration, animations: {
                var frame = self._customView.frame
                frame.origin.y = self._view.frame.height
                self._customView.frame = frame
            }, completion: { finish in
                self._view.removeFromSuperview()
                completion?()
            })
        })
    }
    @objc public class func backgroundTapped() {
        instance.dismiss(isBack: true)
    }
    //MARK: UIPickerViewDelegate
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickerSource.count
    }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component < pickerSource.count {
            return pickerSource[component].count
        }
        return 0
    }
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = view as? UILabel
        if (label == nil) {
            label = UILabel(frame: CGRect(x: 0,y: 0,width: pickerView.rowSize(forComponent: component).width, height: pickerView.rowSize(forComponent: component).height))
            label?.textAlignment = NSTextAlignment.center
        }
        label?.font = SheetView.font
        label?.textColor = SheetView.textColor
        if pickerSource.count > component && pickerSource[component].count > row {
            let dataSource = pickerSource[component][row]
            if let text = dataSource as? String {
                label?.text = text
            }
        }
        return label!
    }
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.didPickItem?(row: row, inComponent: component)
    }
    @objc public func dateChanged() {
        delegate?.didPickDate?(_datePicker.date)
    }
    @objc public func selected() {
        dismiss()
    }
    @objc public func back() {
        dismiss(isBack: true)
    }
    open func getCalendar() -> Calendar {
        return Calendar(identifier: Calendar.Identifier.gregorian)
    }
}
