import SwiftUI

/// Transient readout that appears while you're adjusting and fades away, so the panel
/// goes back to being nothing but light.
struct HUDView: View {
    let state: LightState
    let autoOffSeconds: TimeInterval?

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            if let seconds = autoOffSeconds, seconds <= 60 {
                Text("Auto-off in \(Int(seconds))s — press any button to keep the light on")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.75), in: Capsule())
            }

            HStack(spacing: 34) {
                readout(icon: "sun.max.fill",
                        label: "Brightness",
                        value: "\(Int((state.brightness * 100).rounded()))%",
                        fraction: state.brightness,
                        active: true)

                Divider().frame(height: 68).overlay(Color.white.opacity(0.18))

                readout(icon: dialIcon,
                        label: state.dial.title,
                        value: state.displayValue(for: state.dial),
                        fraction: dialFraction,
                        active: true)

                Divider().frame(height: 68).overlay(Color.white.opacity(0.18))

                VStack(alignment: .leading, spacing: 6) {
                    Text(state.layout.title)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(state.mode == .white
                         ? ColorScience.temperatureName(state.kelvin)
                         : "Colour")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 44)
            .padding(.vertical, 26)
            .background(Color.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )

            // Needs its own dark backing: at high brightness this sits on top of a
            // near-white field, where pale text simply disappears.
            Text("↑↓ brightness   ←→ \(state.dial.title.lowercased())   •   Select: controls   •   Play/Pause: blackout")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.62), in: Capsule())
        }
        .padding(.bottom, 60)
        .frame(maxWidth: .infinity)
    }

    private func readout(icon: String, label: String, value: String, fraction: Double, active: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(label)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.55))

            Text(value)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 240, height: 6)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(active ? 0.9 : 0.4))
                        .frame(width: max(6, 240 * fraction), height: 6)
                }
        }
    }

    private var dialIcon: String {
        switch state.dial {
        case .temperature: return "thermometer.medium"
        case .tint:        return "camera.filters"
        case .hue:         return "paintpalette.fill"
        case .saturation:  return "drop.fill"
        case .size:        return "arrow.up.left.and.arrow.down.right"
        case .feather:     return "wind"
        case .ambient:     return "moon.fill"
        }
    }

    private var dialFraction: Double {
        let r = state.range(for: state.dial)
        let v = state.value(for: state.dial)
        return (v - r.lowerBound) / (r.upperBound - r.lowerBound)
    }
}
