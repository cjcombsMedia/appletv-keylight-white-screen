import AppKit
import SwiftUI
import Observation

/// Owns one borderless, click-through window per display and keeps that set in sync with
/// the screens actually attached.
@MainActor
final class LightWindowManager {

    private let store: LightStore
    private var windows: [CGDirectDisplayID: NSWindow] = [:]

    init(store: LightStore) {
        self.store = store
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.sync() }
            }
        observeStore()
    }

    // MARK: Window levels

    /// Above the wallpaper and the desktop icons, below every ordinary app window.
    private static let behindAppsLevel =
        NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)

    /// Above ordinary windows. Safe only because the window ignores mouse events.
    private static let inFrontLevel =
        NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)

    private var currentLevel: NSWindow.Level {
        store.state.stacking == .behindApps ? Self.behindAppsLevel : Self.inFrontLevel
    }

    // MARK: Sync

    func sync() {
        var seen = Set<CGDirectDisplayID>()

        for screen in NSScreen.screens {
            guard let id = screen.displayID else { continue }
            seen.insert(id)

            let shouldLight = store.state.isLit(screenNamed: screen.keylightName)
            if shouldLight {
                let window = windows[id] ?? makeWindow(for: screen)
                windows[id] = window
                configure(window, for: screen)
            } else if let window = windows.removeValue(forKey: id) {
                window.orderOut(nil)
            }
        }

        // Displays that went away.
        for (id, window) in windows where !seen.contains(id) {
            window.orderOut(nil)
            windows.removeValue(forKey: id)
        }
    }

    private func makeWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(contentRect: screen.frame,
                              styleMask: [.borderless],
                              backing: .buffered,
                              defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
        window.displaysWhenScreenProfileChanges = true
        // Present on every Space, and invisible to Mission Control and ⌘-tab.
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        window.contentView = NSHostingView(
            rootView: LightScreenView().environment(store))
        return window
    }

    private func configure(_ window: NSWindow, for screen: NSScreen) {
        window.level = currentLevel
        // screen.frame, not visibleFrame: the light should reach under the menu bar and Dock.
        if window.frame != screen.frame {
            window.setFrame(screen.frame, display: true)
        }
        if !window.isVisible {
            window.orderFront(nil)
        }
        // Keep it pinned at its level even as other windows come and go.
        if store.state.stacking == .behindApps {
            window.order(.below, relativeTo: 0)
            window.level = currentLevel
        }
    }

    func teardown() {
        windows.values.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }

    // MARK: Observation

    /// AppKit windows can't observe `@Observable` the way a SwiftUI view does, so re-arm a
    /// tracking closure for the properties that change window structure. Colour and
    /// brightness are handled inside the hosted SwiftUI view and don't need to come through
    /// here.
    private func observeStore() {
        withObservationTracking {
            _ = store.state.stacking
            _ = store.state.disabledScreens
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.sync()
                self.observeStore()
            }
        }
    }
}

// MARK: - Screen helpers

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }

    /// Stable-enough identity for remembering which displays the user switched off.
    var keylightName: String {
        localizedName
    }
}
