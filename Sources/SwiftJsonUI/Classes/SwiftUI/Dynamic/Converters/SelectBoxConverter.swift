//
//  SelectBoxConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of selectbox_converter.rb
//  Creates SelectBoxView matching tool-generated code exactly.
//
//  Modifier order (matches selectbox_converter.rb):
//    1. SelectBoxView(...) creation
//       - id, prompt, fontSize, fontColor, backgroundColor, cornerRadius, caret
//       - selectItemType, items (normal) OR datePickerMode/datePickerStyle/dateStringFormat/
//         minimumDate/maximumDate/minuteInterval/selectedDate (date)
//       - selectedIndex, padding, onValueChange (the pick: onValueChange,
//         then onClick)
//    2. (no .onChange: onValueChange is the user's pick only)
//    3. apply_frame_constraints + apply_frame_size
//    4. .overlay (border)
//    5. apply_margins
//    6. .opacity / .hidden
//    7. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct SelectBoxConverter {

    /// onValueChange's call for a pick, by the closure the data holds for it
    /// (4f's ruling on control-onclick-is-called-differently-on-every-path,
    /// 1.9.0; selectbox_converter.rb's pick_invocation reads the same from the
    /// declaration): `(String)` — the picked item, even with selectedIndex
    /// bound; `(String, Int)` — the viewId and the index; `(String, String)` —
    /// the viewId and the item; `(Int)` — the index; `()` — nothing. `index`
    /// is the item's place in `items` (the bound selectedIndex once
    /// SelectBoxView has written it), -1 for the prompt. A date has none: a
    /// handler taking an Int is not called for it, and is named once in DEBUG
    /// (4f's ruling, 1.9.0; the build names it too —
    /// BindingValidatorCore.date_pick_handler_problem — and sjui writes an
    /// `// ERROR:` comment where the call would be).
    ///
    /// It was `callWithValue` with the index where selectedIndex is bound and
    /// the item otherwise, which tries `(String, T)`, `(T)`, `()`: a
    /// `(String)` handler over a bound index, a `(String, String)` one over a
    /// bound index and a `(String, Int)` one over anything else were not
    /// called.
    static func reportPick(_ handler: String, id: String, picked: String, index: Int?, data: [String: Any]) {
        guard let name = DynamicEventHelper.handlerName(from: handler) else { return }
        switch data[name] {
        case let call as (String) -> Void: call(picked)
        case let call as (String, String) -> Void: call(id, picked)
        case let call as (String, Int) -> Void:
            if let index { call(id, index) } else { warnOnce(id: id, handler: name) }
        case let call as (Int) -> Void:
            if let index { call(index) } else { warnOnce(id: id, handler: name) }
        case let call as () -> Void: call()
        default: break
        }
    }

    /// The sentence the build says for the same declaration
    /// (BindingValidatorCore::DATE_PICK_HAS_NO_INDEX).
    static let datePickHasNoIndex = "a date SelectBox has no index: declare onValueChange as (String) or (String, String)"

    /// Hook for tests / apps; defaults to Logger.debug.
    public static var warningHandler: ((String) -> Void)?

    /// One warning per (viewId, handler) per process — a box is re-rendered
    /// and picked again; the declaration does not change.
    private static var reported = Set<String>()
    private static let lock = NSLock()

    private static func warnOnce(id: String, handler: String) {
        lock.lock()
        let firstTime = reported.insert("\(id).\(handler)").inserted
        lock.unlock()
        guard firstTime else { return }
        let message = "[SelectBox] \(id): onValueChange '\(handler)' is not called: \(datePickHasNoIndex)"
        if let warningHandler {
            warningHandler(message)
        } else {
            Logger.debug(message)
        }
    }

    /// Convert DynamicComponent to SwiftUI SelectBoxView
    /// Matches selectbox_converter.rb convert method exactly
    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let attrs = component.typedAttributes(SelectBoxAttributes.self)
        // Its handlers' viewId: the id, else the drawn type and the position
        // (LayoutPath.viewId — `selectBox` for every id-less one before).
        let id = LayoutPath.viewId(of: component)

        // --- 1. Build SelectBoxView ---

        // prompt
        let prompt = (component.prompt ?? component.hint ?? component.placeholder)?.dynamicLocalized()

        // `labelAttributes` styles the closed-state label. The nested keys win
        // over the component-level spellings — the cascade rule adjudicated in
        // 49-F #7, and what selectbox_converter.rb:36-45, the rjui converter
        // and the Compose one all implement.
        let labelAttributes = attrs.labelAttributes

        // fontSize
        let fontSize = (labelAttributes?["fontSize"] as? Double).map { CGFloat($0) }
            ?? (labelAttributes?["fontSize"] as? Int).map { CGFloat($0) }
            ?? attrs.fontSize.map { CGFloat($0) }
            ?? 16

        // fontColor
        let fontColor: Color = DynamicHelpers.getColor(
            (labelAttributes?["fontColor"] as? String)
                ?? component.typedAttributes(SelectBoxAttributes.self).fontColor, data: data
        ) ?? .primary

        // hintColor — the placeholder colour, shown while nothing is picked
        // (SelectBoxView applies it at :201/:209 and defaults to .gray). The
        // codegen has passed it since SelectBoxView 10.10.1; this path never
        // named the parameter, so a declared hint colour did nothing here.
        // Through `rawRepresentation` + `getColor(_:data:)` so the bound
        // spelling resolves as well — the route thumbTintColor takes.
        let hintColor: Color? = DynamicHelpers.getColor(
            attrs.hintColor?.rawRepresentation as? String, data: data
        )

        // font — the label family (or "bold"). SelectBoxView hard-wired
        // .font(.system(size:)) inside itself, so a declared font had
        // nowhere to land; the view now takes the name.
        //
        // Same cascade as fontSize / fontColor above.
        let fontName: String? = (labelAttributes?["font"] as? String)
            ?? component.typedAttributes(SelectBoxAttributes.self).font

        // backgroundColor
        let backgroundColor: Color = DynamicHelpers.getColor(component.commonString(\.background), data: data) ?? Color(UIColor.systemGray6)

        // cornerRadius
        let cornerRadius = component.number(CommonAttributes.self, \.cornerRadius, data: data) ?? 8

        // selectItemType
        let selectItemType: SelectBoxView.SelectItemType = {
            if let itemType = component.selectItemType, itemType.lowercased() == "date" {
                return .date
            }
            return .normal
        }()

        // items (for normal type) - with binding support
        let items: [String] = {
            if let staticItems = component.stringList(SelectBoxAttributes.self, \.items), !staticItems.isEmpty {
                return staticItems
            }
            // Binding items
            if let propName = attrs.items?.bindingExpression {
                if let dataItems = data[propName] as? [String] {
                    return dataItems
                }
            }
            return []
        }()

        // datePickerMode
        let datePickerMode: SelectBoxView.DatePickerMode = {
            guard let mode = component.datePickerMode else { return .date }
            switch mode.lowercased() {
            case "time": return .time
            case "datetime", "dateandtime": return .dateTime
            default: return .date
            }
        }()

        // datePickerStyle
        let datePickerStyle: SelectBoxView.DatePickerStyle = {
            guard let style = component.datePickerStyle else { return .wheel }
            switch style.lowercased() {
            case "automatic": return .automatic
            case "compact": return .compact
            case "graphical", "inline": return .graphical
            default: return .wheel
            }
        }()

        // dateStringFormat
        let dateStringFormat = component.dateStringFormat ?? "yyyy-MM-dd"

        // minimumDate / maximumDate / selectedDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        // All three are string|binding: interpolate before parsing, or a
        // bound date reaches DateFormatter as the literal "@{expr}".
        func parseDate(_ attr: AttrValue<String>?) -> Date? {
            guard let raw = attr?.rawRepresentation as? String else { return nil }
            return dateFormatter.date(from: DynamicHelpers.processText(raw, data: data))
        }
        let minimumDate = parseDate(attrs.minimumDate)
        let maximumDate = parseDate(attrs.maximumDate)
        let selectedDate = parseDate(attrs.selectedDate)

        // minuteInterval
        let minuteInterval = component.minuteInterval ?? 1

        // selectedIndex (value for initial, binding for two-way sync)
        // `selectedValue` seeds the initial selection by resolving its index
        // in items (33 cross-effect: ios ignored it while the selectedIndex
        // spelling worked).
        //
        // The bound form used to be excluded outright, but the SSoT declares
        // it `["string","binding"]` and says "binding for two-way" — the web
        // converter and the Compose one both read it. Resolving it here is
        // what the declaration asks for.
        //
        // `selectedItem` is the other spelling of the same seed and wins over
        // `selectedValue` — kjui's SelectBox has taken that precedence since
        // it was written, and the codegen took it after the same bug was
        // found there (selectbox_converter.rb:300-308: reading only
        // `selectedValue` opened the picker with nothing selected). This path
        // still read one spelling.
        let selectedValueIndex: Int? = {
            let declared = attrs.selectedItem?.rawRepresentation as? String
                ?? attrs.selectedValue?.rawRepresentation as? String
            guard let raw = declared else { return nil }
            let resolved = DynamicHelpers.processText(raw, data: data)
            return items.firstIndex(of: resolved)
        }()
        let selectedIndex = component.int(SelectBoxAttributes.self, \.selectedIndex, data: data) ?? selectedValueIndex
        let selectedIndexBinding: SwiftUI.Binding<Int>? = {
            if let si = attrs.selectedIndex?.bindingString {
                let binding = DynamicBindingHelper.int(si, data: data, fallback: selectedIndex ?? 0)
                return binding
            }
            // A bound selectedItem / selectedValue — declared two-way — is the
            // same selection as the item's index: read through `items`, so the
            // box follows the view model, and written back through them when the
            // data holds a two-way Binding<String> (a plain value is only read).
            // It was taken once, as the seed above, and never followed nor
            // written (ticket selectbox-selected-item-binding-is-read-once).
            let itemExpr = attrs.selectedItem?.bindingString ?? attrs.selectedValue?.bindingString
            guard let itemExpr, DynamicEventHelper.extractPropertyName(from: itemExpr) != nil else { return nil }
            let twoWay: SwiftUI.Binding<String>? = DynamicBindingHelper.twoWay(itemExpr, data: data)
            let current = DynamicBindingHelper.string(itemExpr, data: data).wrappedValue
            return SwiftUI.Binding<Int>(
                get: { items.firstIndex(of: twoWay?.wrappedValue ?? current) ?? -1 },
                set: { index in twoWay?.wrappedValue = items.indices.contains(index) ? items[index] : "" }
            )
        }()

        // padding (internal padding for SelectBoxView)
        let padding: EdgeInsets? = {
            let p = DynamicHelpers.getPadding(from: component, data: data)
            if p.top != 0 || p.leading != 0 || p.bottom != 0 || p.trailing != 0 {
                return p
            }
            return nil
        }()

        // caretAttributes — the closed-state caret. Absent: SelectBoxView
        // keeps its fixed chevron, the picture every layout drew before the
        // object was promoted from UIKit-only to every face (jsonui-cli
        // 1.8.101). Present: the view draws the caret from the keys. The
        // codegen (selectbox_converter.rb) emits the same struct.
        let caret = SelectBoxConverter.caret(from: attrs, data: data)

        // onValueChange handler (+ onValueChanged alias)
        let handlerExpr: String? = component.onValueChangeSpelling()
            ?? component.onValueChangedSpelling()

        // onValueChange from the user's pick — after the selection is written
        // (SelectBoxView writes the index binding, and this closure the date,
        // first) and before onClick — with what the handler's parameters ask
        // for (reportPick). Not from the view model's own writes: an
        // `.onChange(of:)` on the bound value reported those too, on the next
        // update and so after the call (4f's ruling: the control's update,
        // then onValueChange, then onClick, all from the user's operation). A
        // box bound to a plain value had neither: nothing was observed, and
        // the pick was not passed on.
        let isDate = selectItemType == .date
        let report: ((String) -> Void)? = {
            guard let handler = handlerExpr, DynamicEventHelper.handlerName(from: handler) != nil else { return nil }
            return { picked in
                reportPick(handler, id: id, picked: picked,
                           index: isDate ? nil : items.firstIndex(of: picked) ?? -1, data: data)
            }
        }()
        // A date bound to a two-way Binding<String> is written back on a pick —
        // it followed the view model but a pick never reached it (ticket
        // selectbox-selected-item-binding-is-read-once).
        let dateBinding: SwiftUI.Binding<String>? = selectItemType == .date
            ? DynamicBindingHelper.twoWay(attrs.selectedDate?.bindingString, data: data) : nil
        // The declared onClick, called from the user's pick — after the
        // selection is written and onValueChange — and from nothing else: no
        // tap around the box, whose own tap opens the picker
        // (DynamicEventHelper.operationClick). SelectBoxView reports a pick
        // through this closure and only a pick.
        let click = DynamicEventHelper.operationClick(component, data: data)
        let onPick: ((String) -> Void)? = dateBinding == nil && report == nil && click == nil ? nil : { newValue in
            dateBinding?.wrappedValue = newValue
            report?(newValue)
            click?()
        }

        var result = AnyView(
            SelectBoxView(
                id: id,
                prompt: prompt,
                fontSize: fontSize,
                fontColor: fontColor,
                fontName: fontName,
                hintColor: hintColor ?? .gray,
                backgroundColor: backgroundColor,
                cornerRadius: cornerRadius,
                caret: caret,
                selectItemType: selectItemType,
                items: items,
                datePickerMode: datePickerMode,
                datePickerStyle: datePickerStyle,
                dateStringFormat: dateStringFormat,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                minuteInterval: minuteInterval,
                selectedIndex: selectedIndex,
                selectedIndexBinding: selectedIndexBinding,
                selectedDate: selectedDate,
                padding: padding,
                onValueChange: onPick
            )
        )

        // --- 3. apply_frame_constraints + apply_frame_size ---
        // SelectBoxView handles padding/background/cornerRadius internally
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component, data: data)
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 4. .overlay (border) ---
        result = DynamicModifierHelper.applyBorder(result, component: component, data: data)

        // --- 5. apply_margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 6. .opacity / .hidden ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)

        // userInteractionEnabled (the standard chain's
        // hitTesting stage, which this hand-built chain did not run)
        result = DynamicModifierHelper.applyHitTesting(result, component: component, data: data)

        // enabled — the standard chain's disabled stages, inside and outside
        // the accessibility element, which this hand-built chain did not run
        // either: `enabled: false` still opened the picker and took a pick
        // (ConformanceHost OnClickProbeUITests, both paths).
        result = DynamicModifierHelper.applyDisabled(result, component: component, data: data)

        // --- 7. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)
        result = DynamicModifierHelper.applyDisabled(result, component: component, data: data)

        return result
    }

    /// `caretAttributes` as the view's struct, or nil when the layout did
    /// not declare the object — the absent/present distinction the SSoT
    /// makes ("absent: native indicator; present: the face draws it").
    ///
    /// Read through the typed struct (`[String: Any]?`, coerced by the
    /// generated table), the route `labelAttributes` takes above. Numbers
    /// arrive as Double or Int depending on how the JSON spelled them, so
    /// both are accepted; colours resolve through `getColor(_:data:)` so
    /// the `@color/…` and bound spellings work here as they do everywhere.
    static func caret(
        from attrs: SelectBoxAttributes,
        data: [String: Any]
    ) -> SelectBoxView.CaretAttributes? {
        guard let raw = attrs.caretAttributes else { return nil }
        func number(_ key: String) -> CGFloat? {
            if let d = raw[key] as? Double { return CGFloat(d) }
            if let i = raw[key] as? Int { return CGFloat(i) }
            return nil
        }
        return SelectBoxView.CaretAttributes(
            src: raw["src"] as? String,
            width: number("width"),
            height: number("height"),
            tintColor: DynamicHelpers.getColor(raw["tintColor"] as? String, data: data),
            background: DynamicHelpers.getColor(raw["background"] as? String, data: data),
            rightMargin: number("rightMargin")
        )
    }
}
#endif // DEBUG
