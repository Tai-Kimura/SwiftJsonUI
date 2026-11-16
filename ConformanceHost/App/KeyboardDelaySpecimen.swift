//
//  KeyboardDelaySpecimen.swift
//  ConformanceHost
//
//  Test-only: when a field has taken the focus and its keyboard has come up,
//  takes the focus away and gives it back a declared delay later, so the screen
//  is on and the fixture's marker is there while the keyboard is still to come.
//
//  That is the state CI captures landed in on the runner (Xcode 26.3, iOS 26.2):
//  run 41426977222, codegen, TextField/autoFocus__true, the keyboard a few points
//  short of its place, distance 92 / vertical 160. On a fast machine it never
//  happens: 8 local runs on a cold simulator with the host's keyboard wait taken
//  out captured the settled keyboard every time, at load 53 too, so a capture
//  that does not wait passed exactly as one that does. With the delay set it
//  captures the screen with no keyboard, and the host's keyboard wait
//  (ConformanceUITests.waitForKeyboardSettled) is what tells the two apart.
//
//  Both ends of the slide are reachable with it. With the wait out: no keyboard,
//  distance 517 / vertical 647. With a wait of one reading: TextField's keyboard
//  caught a few points short of its place, distance 56 / vertical 68, the shape
//  of the CI capture. With the wait's three readings: distance 0.
//
//  Declared by the run (CONFORMANCE_KEYBOARD_DELAY, seconds, forwarded as a
//  launch environment variable by ConformanceUITests); unset or 0 is the
//  ordinary run. Choose it from the wait's own numbers: above its 0.2 s poll and
//  three readings, inside its 10 s budget — 3.
//

import UIKit

@MainActor
enum KeyboardDelaySpecimen {
    static let seconds: Double =
        Double(ProcessInfo.processInfo.environment["CONFORMANCE_KEYBOARD_DELAY"] ?? "") ?? 0

    private static var observer: NSObjectProtocol?
    /// The fields already delayed, so that giving the focus back does not start it again.
    private static var delayed: [WeakField] = []

    private struct WeakField { weak var view: UIView? }

    /// Starts delaying keyboards when the run declared a delay.
    static func startIfDeclared() {
        guard seconds > 0, observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { delayCurrentField() }
        }
    }

    private static func delayCurrentField() {
        delayed.removeAll { $0.view == nil }
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        guard let field = windows.lazy.compactMap({ firstResponder(in: $0) }).first,
              !delayed.contains(where: { $0.view === field }) else { return }
        delayed.append(WeakField(view: field))
        _ = field.resignFirstResponder()
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak field] in
            _ = field?.becomeFirstResponder()
        }
    }

    private static func firstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder { return view }
        for subview in view.subviews {
            if let found = firstResponder(in: subview) { return found }
        }
        return nil
    }
}
