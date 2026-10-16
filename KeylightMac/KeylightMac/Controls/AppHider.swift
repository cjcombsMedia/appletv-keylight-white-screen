import AppKit

/// Clears the screen of every other app, which is what actually reveals the light when it's
/// stacked behind your windows.
///
/// Driven per-application rather than through `NSApplication.hideOtherApplications`: Keylight
/// runs as a menu-bar agent and is rarely the active app, and that call is defined in terms of
/// the receiver being frontmost. Walking the running list works regardless of who has focus.
enum AppHider {

    /// Apps that own windows a user would recognise — skips other agents, daemons and
    /// Keylight itself.
    private static var hideableApps: [NSRunningApplication] {
        let me = NSRunningApplication.current
        return NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
                && $0.processIdentifier != me.processIdentifier
        }
    }

    /// True when there is anything left on screen to hide.
    static var hasVisibleApps: Bool {
        hideableApps.contains { !$0.isHidden }
    }

    static var hasHiddenApps: Bool {
        hideableApps.contains { $0.isHidden }
    }

    @discardableResult
    static func hideOthers() -> Int {
        var hidden = 0
        for app in hideableApps where !app.isHidden {
            if app.hide() { hidden += 1 }
        }
        return hidden
    }

    @discardableResult
    static func showAll() -> Int {
        var shown = 0
        for app in hideableApps where app.isHidden {
            if app.unhide() { shown += 1 }
        }
        return shown
    }
}
