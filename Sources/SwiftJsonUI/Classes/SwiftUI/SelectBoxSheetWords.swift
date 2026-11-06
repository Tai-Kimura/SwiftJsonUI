//
//  SelectBoxSheetWords.swift
//  SwiftJsonUI
//
//  The word on the button that closes SelectBoxView's sheet. It was a fixed
//  Button("Done"), which looks the key up in the app's Localizable.strings and
//  otherwise shows English on every screen (jsonui-cli ticket
//  kjui-selectbox-hardcoded-japanese-strings). The order keeps that lookup:
//  the layout's doneButtonText, the app's own Done, this table, English.
//
//  The table is what UIKit says for "Done" (UIKitCore's Localizable.strings on
//  iOS 26.2), in the languages the library's sheets have on Android too.
//

import Foundation

enum SelectBoxSheetWords {

    static let done: [String: String] = [
        "en": "Done", "ja": "完了", "de": "Fertig", "fr": "OK", "nl": "Gereed", "da": "OK", "pl": "OK",
        "cs": "Hotovo", "es-419": "Listo", "es": "OK", "pt": "OK", "pt-PT": "OK",
        "zh-Hant": "完成", "zh-Hans": "完成", "ko": "완료",
    ]

    /// The word for the sheet of this app, in the language `String.localized` resolves to.
    static func done(given: String?) -> String {
        done(given: given, appWord: "Done".localized(), language: AppLanguageDateFormat.locale().identifier)
    }

    /// The decision alone, for the tests. `appWord` is the lookup's answer: the key itself when the app has none.
    static func done(given: String?, appWord: String, language: String) -> String {
        if let given, !given.isEmpty { return given }
        if appWord != "Done" { return appWord }
        return done[tableKey(language)] ?? "Done"
    }

    /// The table's spelling of a language: an .lproj's name, or a locale's identifier.
    /// A plain zh is Simplified and every Traditional region is Traditional, as iOS treats them.
    static func tableKey(_ language: String) -> String {
        let parts = language.replacingOccurrences(of: "_", with: "-").split(separator: "-").map(String.init)
        guard let primary = parts.first else { return "en" }
        let rest = Set(parts.dropFirst())
        switch primary {
        case "zh":
            return rest.contains("Hant") || !rest.isDisjoint(with: ["TW", "HK", "MO"]) ? "zh-Hant" : "zh-Hans"
        case "es":
            return rest.isEmpty || rest.contains("ES") ? "es" : "es-419"
        case "pt":
            return rest.contains("PT") ? "pt-PT" : "pt"
        default:
            return primary
        }
    }
}
