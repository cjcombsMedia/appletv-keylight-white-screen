import ServiceManagement

/// Launch-at-login, via the modern `SMAppService` registration (no helper bundle needed).
///
/// Registration records whatever copy of the app is running, so a build launched straight
/// out of DerivedData would register that path. Move Keylight to /Applications before
/// switching this on.
enum LoginItem {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Returns whether the change took. macOS can refuse if the user has the item disabled
    /// in System Settings, in which case we surface that rather than silently lying.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}
