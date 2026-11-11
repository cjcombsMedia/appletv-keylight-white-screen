import AppKit
import SwiftUI

/// The little control box. A non-activating utility panel, so clicking a slider never pulls
/// focus away from Teams or Zoom mid-call.
@MainActor
final class ControlWindowController: NSObject, NSWindowDelegate {

    private let panel: NSPanel
    private let frameKey = "mac.control.frame"
    /// Once the panel has been dragged we stop re-homing it to the corner.
    private var userPositioned = false
    private var movingProgrammatically = false

    init(store: LightStore) {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 400),
            styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false)

        panel.title = "CJ's Keylight"
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

        let host = NSHostingView(rootView: ControlPanelView().environment(store))
        host.sizingOptions = [.preferredContentSize]
        panel.contentView = host

        super.init()

        // Force a layout pass first: `fittingSize` is zero until SwiftUI has measured, and
        // positioning against a zero size puts the panel off the corner of the screen.
        host.layoutSubtreeIfNeeded()
        let measured = host.fittingSize
        panel.setContentSize(NSSize(width: max(measured.width, 340),
                                    height: max(measured.height, 260)))

        panel.delegate = self
        restoreOrPlaceBottomRight()
    }

    // MARK: NSWindowDelegate

    /// The panel changes height when "More" is expanded. Re-home or re-clamp so it can never
    /// grow off the bottom of the screen.
    func windowDidResize(_ notification: Notification) {
        if userPositioned { clampIntoScreen() } else { placeBottomRight() }
    }

    func windowDidMove(_ notification: Notification) {
        guard !movingProgrammatically else { return }
        userPositioned = true
        saveFrame()
    }

    // MARK: Placement

    /// Bottom-right of the main display, clear of the Dock, unless the user has dragged it
    /// somewhere they prefer.
    private func restoreOrPlaceBottomRight() {
        if let saved = UserDefaults.standard.string(forKey: frameKey), !saved.isEmpty {
            let rect = NSRectFromString(saved)
            // Only honour a saved spot that still lands on a display that's attached now —
            // otherwise unplugging a monitor would strand the panel somewhere invisible.
            if rect.width > 100, isOnAnAttachedScreen(rect) {
                movingProgrammatically = true
                panel.setFrameOrigin(rect.origin)
                movingProgrammatically = false
                userPositioned = true
                clampIntoScreen()
                return
            }
        }
        placeBottomRight()
    }

    func placeBottomRight() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let margin: CGFloat = 24
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(x: visible.maxX - size.width - margin,
                             y: visible.minY + margin)
        movingProgrammatically = true
        panel.setFrameOrigin(origin)
        movingProgrammatically = false
    }

    /// Keep the whole panel inside a display, whatever just resized or moved it.
    private func clampIntoScreen() {
        let frame = panel.frame
        let screen = NSScreen.screens.first { $0.visibleFrame.intersects(frame) }
            ?? NSScreen.main ?? NSScreen.screens.first
        guard let visible = screen?.visibleFrame else { return }

        // Keep a little breathing room rather than sitting flush against the screen edge,
        // but never let the margin push the panel off a display it barely fits on.
        let m: CGFloat = 12
        let minX = visible.minX + m, maxX = visible.maxX - frame.width - m
        let minY = visible.minY + m, maxY = visible.maxY - frame.height - m

        var origin = frame.origin
        origin.x = maxX >= minX ? min(max(origin.x, minX), maxX) : visible.minX
        origin.y = maxY >= minY ? min(max(origin.y, minY), maxY) : visible.minY
        guard origin != frame.origin else { return }

        movingProgrammatically = true
        panel.setFrameOrigin(origin)
        movingProgrammatically = false
    }

    private func isOnAnAttachedScreen(_ frame: NSRect) -> Bool {
        NSScreen.screens.contains { $0.visibleFrame.intersects(frame) }
    }

    func saveFrame() {
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: frameKey)
    }

    // MARK: Visibility

    var isVisible: Bool { panel.isVisible }

    func show() {
        // orderFrontRegardless keeps the panel from activating the app just to appear.
        panel.orderFrontRegardless()
    }

    func hide() {
        saveFrame()
        panel.orderOut(nil)
    }

    func toggle() {
        isVisible ? hide() : show()
    }
}
