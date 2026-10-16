import AVFoundation
import Foundation

/// Watches whether any other process has the camera open, so the light can follow your
/// calls automatically.
///
/// Deliberately opt-in and lazily started: enumerating devices is harmless, but there is no
/// reason to touch the camera subsystem at all for someone who doesn't want this.
@MainActor
final class CameraActivityMonitor {

    private var task: Task<Void, Never>?
    private let onChange: (Bool) -> Void
    private var lastValue = false

    init(onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
    }

    var isRunning: Bool { task != nil }

    func start() {
        guard task == nil else { return }
        task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let inUse = Self.anyCameraInUse()
                if inUse != self.lastValue {
                    self.lastValue = inUse
                    self.onChange(inUse)
                }
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        if lastValue {
            lastValue = false
            onChange(false)
        }
    }

    /// `isInUseByAnotherApplication` reports processes other than this one, which is exactly
    /// the question — Keylight never opens the camera itself.
    private static func anyCameraInUse() -> Bool {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
            mediaType: .video,
            position: .unspecified)
        return session.devices.contains { $0.isInUseByAnotherApplication }
    }
}
