import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(LightStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("hasSeenControls") private var hasSeenControls = false

    @State private var accelerator = MoveAccelerator()
    @State private var hudVisible = false
    @State private var hudTask: Task<Void, Never>?
    @State private var pixelShift: CGSize = .zero
    @State private var showHelp = false
    @State private var didFadeIn = false
    @State private var autoOffRemaining: TimeInterval?

    @FocusState private var focus: FocusTarget?

    private enum FocusTarget: Hashable { case stage }

    private var overlayIsOpen: Bool {
        showHelp || store.showPanel || store.showCalibration
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LightStageView(state: store.state,
                           pixelShift: store.state.pixelShift ? pixelShift : .zero)
                .opacity(store.isBlackout ? 0 : (didFadeIn ? 1 : 0))
                .animation(.easeInOut(duration: 0.3), value: store.isBlackout)
                .animation(.easeOut(duration: 0.2), value: store.state)
                .animation(.easeIn(duration: 0.8), value: didFadeIn)

            if store.showCalibration {
                CalibrationView(state: store.state)
                    .transition(.opacity)
            }

            // Focus target that turns remote input into light changes.
            //
            // Deliberately tiny and fully clear. tvOS brightens a focused button's label
            // while a finger rests on the Siri Remote touchpad, so a full-screen label
            // — even at 0.001 opacity — gets composited to solid white over the light.
            // Keeping it 60pt in a corner means no focus decoration can reach the stage.
            if !store.showPanel {
                Button(action: handleSelect) {
                    Color.clear.frame(width: 60, height: 60)
                }
                .buttonStyle(BareButtonStyle())
                .focusEffectDisabled()
                .focused($focus, equals: .stage)
                .onMoveCommand(perform: handleMove)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            if !store.showPanel && !store.showCalibration && !showHelp && shouldShowHUD {
                HUDView(state: store.state, autoOffSeconds: autoOffRemaining)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if store.showPanel {
                ControlPanelView(onShowHelp: {
                    store.showPanel = false
                    showHelp = true
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showHelp {
                HelpOverlay(dialName: store.state.dial.title)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeOut(duration: 0.25), value: store.showPanel)
        .animation(.easeOut(duration: 0.2), value: showHelp)
        .animation(.easeOut(duration: 0.2), value: store.showCalibration)
        .animation(.easeInOut(duration: 0.25), value: shouldShowHUD)
        .onPlayPauseCommand(perform: handlePlayPause)
        .modifier(ExitCommand(isActive: overlayIsOpen, action: handleExit))
        .defaultFocus($focus, .stage)
        .onAppear(perform: start)
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onChange(of: store.showPanel) { _, isOpen in
            if !isOpen { focus = .stage }
        }
        .onChange(of: scenePhase) { _, phase in
            UIApplication.shared.isIdleTimerDisabled = (phase == .active)
            if phase != .active { store.saveNow() }
        }
        .task(id: store.state.pixelShift) { await runPixelShift() }
        .task(id: store.state.autoOffMinutes) { await runAutoOff() }
    }

    private var shouldShowHUD: Bool {
        hudVisible || autoOffRemaining != nil
    }

    // MARK: Lifecycle

    private func start() {
        UIApplication.shared.isIdleTimerDisabled = true
        focus = .stage
        didFadeIn = true
        if !hasSeenControls {
            showHelp = true
            hasSeenControls = true
        } else {
            flashHUD()
        }
    }

    // MARK: Remote handling

    private func handleMove(_ direction: MoveCommandDirection) {
        if showHelp {
            showHelp = false
            return
        }

        let step = accelerator.multiplier(for: direction)

        if store.isBlackout {
            store.isBlackout = false
            store.noteInteraction()
            flashHUD()
            return
        }

        switch direction {
        case .up:    store.adjustBrightness(by: 0.01 * step)
        case .down:  store.adjustBrightness(by: -0.01 * step)
        case .left:  store.adjustDial(by: -step)
        case .right: store.adjustDial(by: step)
        @unknown default: break
        }

        autoOffRemaining = nil
        flashHUD()
    }

    private func handleSelect() {
        if showHelp {
            showHelp = false
            return
        }
        if store.showCalibration {
            store.showCalibration = false
            store.noteInteraction()
            return
        }
        if store.isBlackout {
            store.isBlackout = false
            store.noteInteraction()
            autoOffRemaining = nil
            flashHUD()
            return
        }
        store.showPanel = true
        store.noteInteraction()
        hudVisible = false
        hudTask?.cancel()
    }

    private func handlePlayPause() {
        if showHelp {
            showHelp = false
            return
        }
        store.isBlackout.toggle()
        store.noteInteraction()
        autoOffRemaining = nil
        if !store.isBlackout { flashHUD() }
    }

    private func handleExit() {
        if showHelp {
            showHelp = false
        } else if store.showPanel {
            store.showPanel = false
        } else if store.showCalibration {
            store.showCalibration = false
        }
        store.noteInteraction()
    }

    // MARK: HUD

    private func flashHUD() {
        hudVisible = true
        hudTask?.cancel()
        hudTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            hudVisible = false
        }
    }

    // MARK: Background work

    /// Nudges the whole image a few points every so often. A 55" panel holding a bright
    /// static rectangle for hours is exactly the wear pattern OLEDs dislike.
    private func runPixelShift() async {
        guard store.state.pixelShift else {
            withAnimation(.easeInOut(duration: 2)) { pixelShift = .zero }
            return
        }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(75))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 4)) {
                pixelShift = CGSize(width: .random(in: -14...14),
                                    height: .random(in: -14...14))
            }
        }
    }

    private func runAutoOff() async {
        guard store.state.autoOffMinutes > 0 else {
            autoOffRemaining = nil
            return
        }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            guard let remaining = store.secondsUntilAutoOff() else {
                autoOffRemaining = nil
                continue
            }
            if remaining <= 0 {
                store.isBlackout = true
                autoOffRemaining = nil
            } else if remaining <= 60 {
                autoOffRemaining = remaining
            } else if autoOffRemaining != nil {
                autoOffRemaining = nil
            }
        }
    }
}

/// Renders the label and nothing else. The built-in tvOS button styles — including
/// `.plain` — still apply the platform's focused/hovered treatment, which `.focusEffectDisabled()`
/// does not fully suppress. A custom style replaces that treatment outright.
private struct BareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

/// `onExitCommand` swallows the Menu button, which would trap the user in the app.
/// Attaching it only while something is dismissible keeps the system behaviour intact.
private struct ExitCommand: ViewModifier {
    let isActive: Bool
    let action: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if isActive {
            content.onExitCommand(perform: action)
        } else {
            content
        }
    }
}
