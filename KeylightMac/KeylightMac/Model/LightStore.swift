import AppKit
import Observation
import SwiftUI

@Observable
final class LightStore {

    var state: LightState {
        didSet {
            if state != oldValue { scheduleSave() }
            if state.isOn != oldValue.isOn { updateSleepAssertion() }
        }
    }

    /// True while some other process holds the camera. Only meaningful when
    /// `state.followCamera` is on, which is what starts the monitor.
    var cameraInUse = false

    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var sleepActivity: NSObjectProtocol?
    @ObservationIgnored private let key = "mac.light.state.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(LightState.self, from: data) {
            state = decoded
        } else {
            state = LightState()
        }
        updateSleepAssertion()
    }

    // MARK: Persistence

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = state
        saveTask = Task { [key] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            if let data = try? JSONEncoder().encode(snapshot) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }

    func saveNow() {
        saveTask?.cancel()
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: Display sleep

    /// A key light that lets the display sleep mid-call is useless, so hold an activity
    /// assertion for exactly as long as the light is on.
    private func updateSleepAssertion() {
        if state.isOn, sleepActivity == nil {
            sleepActivity = ProcessInfo.processInfo.beginActivity(
                options: [.idleDisplaySleepDisabled, .userInitiated],
                reason: "Keylight is lighting the screen")
        } else if !state.isOn, let activity = sleepActivity {
            ProcessInfo.processInfo.endActivity(activity)
            sleepActivity = nil
        }
    }

    // MARK: Actions

    func toggleOn() { state.isOn.toggle() }

    func adjustBrightness(by delta: Double) {
        state.brightness = min(max(state.brightness + delta, 0.02), 1)
        if !state.isOn { state.isOn = true }
    }

    func apply(_ preset: Preset) {
        var next = state
        preset.apply(to: &next)
        next.isOn = true
        state = next
    }

    func setScreen(_ name: String, lit: Bool) {
        if lit { state.disabledScreens.remove(name) } else { state.disabledScreens.insert(name) }
    }

    /// Called by the camera monitor. Only drives the light while the option is enabled.
    func cameraActivityChanged(inUse: Bool) {
        cameraInUse = inUse
        guard state.followCamera else { return }
        if state.isOn != inUse { state.isOn = inUse }
    }
}
