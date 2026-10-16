import AppKit

/// Brings a video-call app to the front. The light window is click-through and the control
/// panel is non-activating, so nothing here has to fight Keylight for focus.
struct CallApp: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    /// Tried in order — Teams ships under two different identifiers depending on version.
    let bundleIDs: [String]

    static let candidates: [CallApp] = [
        CallApp(id: "teams", name: "Teams", symbol: "person.2.fill",
                bundleIDs: ["com.microsoft.teams2", "com.microsoft.teams"]),
        CallApp(id: "zoom", name: "Zoom", symbol: "video.fill",
                bundleIDs: ["us.zoom.xos"]),
        CallApp(id: "meet", name: "Webex", symbol: "video.circle.fill",
                bundleIDs: ["Cisco-Systems.Spark"]),
        CallApp(id: "slack", name: "Slack", symbol: "number.square.fill",
                bundleIDs: ["com.tinyspeck.slackmacgap"]),
        CallApp(id: "facetime", name: "FaceTime", symbol: "video.bubble.left.fill",
                bundleIDs: ["com.apple.FaceTime"]),
    ]

    /// The first identifier that resolves to something actually installed.
    var installedBundleID: String? {
        bundleIDs.first { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) != nil }
    }

    var isInstalled: Bool { installedBundleID != nil }

    var isRunning: Bool {
        guard let id = installedBundleID else { return false }
        return !NSRunningApplication.runningApplications(withBundleIdentifier: id).isEmpty
    }

    /// Only the apps present on this Mac, so the panel never offers a dead button.
    static var installed: [CallApp] { candidates.filter(\.isInstalled) }

    /// Focus the app, launching it only if it isn't already running.
    func activate() {
        guard let id = installedBundleID else { return }

        if let running = NSRunningApplication.runningApplications(withBundleIdentifier: id).first {
            running.activate()
            return
        }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
