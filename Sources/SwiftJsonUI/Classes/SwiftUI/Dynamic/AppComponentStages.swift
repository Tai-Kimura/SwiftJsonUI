//
//  AppComponentStages.swift
//  SwiftJsonUI
//
//  Whether a component the app registers (CustomComponentRegistry) was drawn
//  with the common stages its node declares. DynamicComponentBuilder does not
//  apply them to an app's component: its adapter does, through
//  DynamicModifierHelper.applyStandardModifiers, as the adapter `sjui g
//  converter` generates does. An adapter that does not call it draws none of
//  them — no tap, no onAppear, no frame, no background — while sjui's codegen
//  applies them to the same component in release. That was silent; a Debug
//  build now names it, once per type.
//

import Foundation
#if DEBUG

enum AppComponentStages {
    /// The node attributes that are common stages applyStandardModifiers
    /// applies: the events, the gates around them, and the common modifiers.
    static let stageKeys = [
        "onClick", "onclick", "onLongPress", "onPan", "onPinch", "onAppear", "onDisappear",
        "userInteractionEnabled", "canTap", "enabled",
        "width", "height", "padding", "paddings", "margins", "background", "cornerRadius",
        "borderWidth", "borderColor", "alpha", "opacity", "hidden", "visibility", "offsetX", "offsetY",
    ]

    /// Hook for tests and apps; defaults to Logger.debug.
    static var warningHandler: ((String) -> Void)?

    private static let marksKey = "SwiftJsonUI.AppComponentStages.marks"
    private static var reported = Set<String>()
    private static let lock = NSLock()

    /// Called by DynamicComponentBuilder before it asks an adapter to build.
    static func begin() {
        var marks = Thread.current.threadDictionary[marksKey] as? [Bool] ?? []
        marks.append(false)
        Thread.current.threadDictionary[marksKey] = marks
    }

    /// Called by applyStandardModifiers: the adapter being asked applied them.
    static func markApplied() {
        guard var marks = Thread.current.threadDictionary[marksKey] as? [Bool], !marks.isEmpty else { return }
        marks[marks.count - 1] = true
        Thread.current.threadDictionary[marksKey] = marks
    }

    /// Called by DynamicComponentBuilder after the adapter built: when the
    /// node declares a common stage and the adapter did not apply the standard
    /// modifiers, says so once per type.
    static func end(for component: DynamicComponent) {
        guard var marks = Thread.current.threadDictionary[marksKey] as? [Bool], let applied = marks.popLast() else { return }
        Thread.current.threadDictionary[marksKey] = marks
        guard !applied, let type = component.type else { return }
        let declared = stageKeys.filter { component.rawAttribute($0) != nil }
        guard !declared.isEmpty else { return }
        lock.lock()
        let firstTime = reported.insert(type).inserted
        lock.unlock()
        guard firstTime else { return }
        let message = "[CustomComponentAdapter] '\(type)' declares \(declared.joined(separator: ", ")), but its adapter did not " +
            "apply the standard modifiers, so Debug draws none of them (sjui's codegen does). Call " +
            "DynamicModifierHelper.applyStandardModifiers on the view buildView returns, as a generated adapter does."
        if let warningHandler {
            warningHandler(message)
        } else {
            Logger.debug(message)
        }
    }

    /// Test hook: forget which types were said.
    static func resetReported() {
        lock.lock()
        reported.removeAll()
        lock.unlock()
    }
}

#endif // DEBUG
