import AppKit
import SwiftUI

@main
struct KeylightMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // No window scene: every window here is an NSWindow we place ourselves, and the
        // app runs as a menu-bar agent with no Dock icon.
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private let store = LightStore()
    private var lights: LightWindowManager!
    private var controls: ControlWindowController!
    private var statusItem: NSStatusItem!
    private var cameraMonitor: CameraActivityMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        lights = LightWindowManager(store: store)
        controls = ControlWindowController(store: store)

        cameraMonitor = CameraActivityMonitor { [weak self] inUse in
            self?.store.cameraActivityChanged(inUse: inUse)
        }

        buildStatusItem()
        lights.sync()
        controls.show()
        syncCameraMonitor()
        observeCameraPreference()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controls.saveFrame()
        store.saveNow()
        lights.teardown()
    }

    // MARK: Menu bar

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "lightbulb.fill",
                                           accessibilityDescription: "CJ's Keylight")
        statusItem.button?.toolTip = "CJ's Keylight"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
    }

    /// Rebuilt every time it opens, so the display list matches what's plugged in now.
    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        guard let menu = statusItem.menu else { return }
        menu.removeAllItems()

        let toggle = NSMenuItem(title: store.state.isOn ? "Turn Light Off" : "Turn Light On",
                                action: #selector(toggleLight), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)

        let showControls = NSMenuItem(title: "Show Controls",
                                      action: #selector(showControls), keyEquivalent: "")
        showControls.target = self
        menu.addItem(showControls)

        menu.addItem(.separator())

        let presets = NSMenuItem(title: "Presets", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for preset in Preset.all {
            let item = NSMenuItem(title: preset.name, action: #selector(applyPreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset.id
            submenu.addItem(item)
        }
        presets.submenu = submenu
        menu.addItem(presets)

        let displays = NSMenuItem(title: "Light On", action: nil, keyEquivalent: "")
        let displayMenu = NSMenu()
        for display in store.displays {
            let item = NSMenuItem(title: display.key,
                                  action: #selector(toggleDisplay(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = display.key
            item.state = store.state.isLit(screenNamed: display.key) ? .on : .off
            item.image = NSImage(systemSymbolName: display.symbol, accessibilityDescription: nil)
            displayMenu.addItem(item)
        }
        if store.displays.count > 1 {
            displayMenu.addItem(.separator())
            let all = NSMenuItem(title: "All Displays",
                                 action: #selector(lightAllDisplays), keyEquivalent: "")
            all.target = self
            all.isEnabled = !store.allDisplaysLit
            displayMenu.addItem(all)
        }
        displays.submenu = displayMenu
        menu.addItem(displays)

        for app in CallApp.installed {
            let item = NSMenuItem(title: "Show \(app.name)",
                                  action: #selector(activateApp(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = app.id
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let hide = NSMenuItem(title: "Hide All Other Apps",
                              action: #selector(hideOthers), keyEquivalent: "")
        hide.target = self
        hide.isEnabled = AppHider.hasVisibleApps
        menu.addItem(hide)

        let showAll = NSMenuItem(title: "Show All Apps",
                                 action: #selector(showAllApps), keyEquivalent: "")
        showAll.target = self
        showAll.isEnabled = AppHider.hasHiddenApps
        menu.addItem(showAll)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit CJ's Keylight", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    // MARK: Actions

    @objc private func toggleLight() {
        store.toggleOn()
        rebuildMenu()
    }

    @objc private func showControls() {
        controls.show()
    }

    @objc private func applyPreset(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let preset = Preset.all.first(where: { $0.id == id }) else { return }
        store.apply(preset)
        rebuildMenu()
    }

    @objc private func toggleDisplay(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        store.setScreen(key, lit: !store.state.isLit(screenNamed: key))
    }

    @objc private func lightAllDisplays() {
        store.lightAllDisplays()
    }

    @objc private func activateApp(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let app = CallApp.installed.first(where: { $0.id == id }) else { return }
        app.activate()
    }

    @objc private func hideOthers() {
        AppHider.hideOthers()
        rebuildMenu()
    }

    @objc private func showAllApps() {
        AppHider.showAll()
        rebuildMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: Camera preference

    private func syncCameraMonitor() {
        if store.state.followCamera {
            cameraMonitor.start()
        } else {
            cameraMonitor.stop()
        }
    }

    private func observeCameraPreference() {
        withObservationTracking {
            _ = store.state.followCamera
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.syncCameraMonitor()
                self.observeCameraPreference()
            }
        }
    }
}
