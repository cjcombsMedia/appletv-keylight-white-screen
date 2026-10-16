import SwiftUI

/// Turns a stream of discrete remote move events into an accelerating step size.
///
/// The Siri Remote repeats a held direction at a fixed rate, which makes crossing an
/// 8000 K range one 25 K press at a time unusable. Consecutive presses in the same
/// direction ramp the multiplier up; changing direction or pausing resets it, so
/// single taps stay precise.
@Observable
final class MoveAccelerator {

    private var lastDirection: MoveCommandDirection?
    private var lastEvent = Date.distantPast
    private var streak = 0

    /// Longest gap between events that still counts as "holding".
    private let holdWindow: TimeInterval = 0.35
    private let maxMultiplier = 10.0
    private let ramp = 0.5

    func multiplier(for direction: MoveCommandDirection, now: Date = Date()) -> Double {
        if direction == lastDirection, now.timeIntervalSince(lastEvent) < holdWindow {
            streak += 1
        } else {
            streak = 0
        }
        lastDirection = direction
        lastEvent = now
        return min(maxMultiplier, 1 + Double(streak) * ramp)
    }

    func reset() {
        lastDirection = nil
        lastEvent = .distantPast
        streak = 0
    }
}
