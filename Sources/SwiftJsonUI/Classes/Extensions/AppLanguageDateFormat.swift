//
//  AppLanguageDateFormat.swift
//  SwiftJsonUI
//
//  The locale a date string is drawn and read in: the app's language, on the
//  Gregorian calendar.
//
//  Until 10.29.5 the SelectBox formatted its date text with a bare
//  DateFormatter — Locale.current, the DEVICE locale — while the rest of the
//  screen was in the app's language (String.currentLanguage, the in-app
//  switch `.localized()` reads). A device in ja-JP with the app in en drew a
//  Japanese month name, and a device set to the Japanese calendar
//  (ja_JP@calendar=japanese) drew and stored the imperial year even for
//  yyyy/MM/dd (ticket selectbox-date-text-formatted-in-the-device-locale).
//

import Foundation

public enum AppLanguageDateFormat {

    /// The app's language as a Locale, resolved the way `String.localized`
    /// resolves text: `String.currentLanguage` when its .lproj exists, else the
    /// main bundle's localization, else `fallback` (the device locale).
    public static func locale(fallback: Locale = .current) -> Locale {
        resolve(
            currentLanguage: String.currentLanguage,
            hasLproj: { Bundle.main.path(forResource: $0, ofType: "lproj") != nil },
            preferred: Bundle.main.preferredLocalizations.first,
            fallback: fallback
        )
    }

    /// The decision alone, for the tests.
    static func resolve(
        currentLanguage: String?,
        hasLproj: (String) -> Bool,
        preferred: String?,
        fallback: Locale
    ) -> Locale {
        if let language = currentLanguage, hasLproj(language) {
            return Locale(identifier: language)
        }
        if let language = preferred {
            return Locale(identifier: language)
        }
        return fallback
    }

    /// A formatter for a declared date pattern, in `locale` (the app's
    /// language by default) on the Gregorian calendar — the calendar is pinned
    /// because the string is also the value the ViewModel stores and reads
    /// back.
    public static func formatter(_ pattern: String, locale: Locale = AppLanguageDateFormat.locale()) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = pattern
        return formatter
    }

    /// A formatter for a fixed internal shape (yyyy-MM-dd, HH:mm): en_US_POSIX
    /// on the Gregorian calendar, so parsing never depends on any locale.
    public static func posixFormatter(_ pattern: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = pattern
        return formatter
    }
}
