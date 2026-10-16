import SwiftUI
import Observation

/// Owns the light state and persists it. Writes are coalesced so that holding a
/// direction on the remote doesn't hammer `UserDefaults` sixty times a second.
@Observable
final class LightStore {

    var state: LightState {
        didSet { if state != oldValue { scheduleSave() } }
    }

    /// Transient UI state that shouldn't be persisted.
    var isBlackout = false
    var showPanel = false
    var showCalibration = false
    var lastInteraction = Date()

    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private let defaultsKey = "light.state.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(LightState.self, from: data) {
            state = decoded
        } else {
            state = LightState()
        }
    }

    // MARK: Persistence

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = state
        saveTask = Task { [defaultsKey] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            if let data = try? JSONEncoder().encode(snapshot) {
                UserDefaults.standard.set(data, forKey: defaultsKey)
            }
        }
    }

    func saveNow() {
        saveTask?.cancel()
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    // MARK: Adjustments

    func noteInteraction() {
        lastInteraction = Date()
    }

    func adjustBrightness(by delta: Double) {
        state.brightness = min(max(state.brightness + delta, 0.02), 1)
        noteInteraction()
    }

    func adjustDial(by multiplier: Double) {
        let dial = state.dial
        let next = state.value(for: dial) + state.step(for: dial) * multiplier
        state.setValue(next, for: dial)
        noteInteraction()
    }

    func cycleDial(forward: Bool = true) {
        let dials = state.availableDials
        guard let index = dials.firstIndex(of: state.dial) else {
            state.dial = dials.first ?? .temperature
            return
        }
        let next = forward
            ? (index + 1) % dials.count
            : (index - 1 + dials.count) % dials.count
        state.dial = dials[next]
        noteInteraction()
    }

    func setMode(_ mode: LightMode) {
        state.mode = mode
        if !state.availableDials.contains(state.dial) {
            state.dial = state.availableDials.first ?? .temperature
        }
        noteInteraction()
    }

    func setLayout(_ layout: LightLayout) {
        state.layout = layout
        if !state.availableDials.contains(state.dial) {
            state.dial = state.availableDials.first ?? .temperature
        }
        noteInteraction()
    }

    func apply(_ preset: Preset) {
        preset.apply(to: &state)
        isBlackout = false
        noteInteraction()
    }

    func saveUserPreset() {
        let name = "Custom \(state.userPresets.count + 1)"
        state.userPresets.append(Preset(name: name, from: state))
        saveNow()
        noteInteraction()
    }

    func deleteUserPreset(_ preset: Preset) {
        state.userPresets.removeAll { $0.id == preset.id }
        saveNow()
        noteInteraction()
    }

    func resetToDefaults() {
        var fresh = LightState()
        fresh.userPresets = state.userPresets
        state = fresh
        isBlackout = false
        noteInteraction()
    }

    // MARK: Auto-off

    /// Seconds until the light shuts itself off, or nil if the timer is disabled.
    func secondsUntilAutoOff(now: Date = Date()) -> TimeInterval? {
        guard state.autoOffMinutes > 0, !isBlackout else { return nil }
        let deadline = lastInteraction.addingTimeInterval(Double(state.autoOffMinutes) * 60)
        return max(0, deadline.timeIntervalSince(now))
    }
}
