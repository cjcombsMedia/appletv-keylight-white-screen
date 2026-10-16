import SwiftUI

/// A reference chart to point your webcam at while you lock exposure and white
/// balance. The card is rendered at the light's current colour temperature, so once
/// the camera reads the 18% patch as neutral grey the rest of the frame — your face —
/// is balanced for the same light.
struct CalibrationView: View {
    let state: LightState

    /// 18% reflectance is ~0.466 in sRGB code value, the classic exposure reference.
    private let midGrey = 0.466

    var body: some View {
        ZStack {
            tinted(0.10).ignoresSafeArea()

            VStack(spacing: 34) {
                Text("Camera Test Card")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 26) {
                    patch(midGrey, label: "18% grey", detail: "Set exposure here")
                    patch(1.0, label: "White", detail: "Clipping check")
                    patch(0.0, label: "Black", detail: "Shadow check")
                }

                VStack(spacing: 10) {
                    Text("Step wedge")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                    HStack(spacing: 4) {
                        ForEach(0..<11, id: \.self) { i in
                            Rectangle()
                                .fill(tinted(Double(i) / 10.0))
                                .frame(width: 92, height: 74)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                VStack(spacing: 10) {
                    Text("Skin tone references")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                    HStack(spacing: 14) {
                        ForEach(skinTones.indices, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(skinTones[index])
                                .frame(width: 130, height: 74)
                        }
                    }
                }

                Text("\(Int((state.kelvin / 50).rounded()) * 50) K  •  \(Int((state.brightness * 100).rounded()))% brightness  •  \(state.layout.title)")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                Text("Menu or Select returns to the light")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(50)
        }
    }

    private func patch(_ level: Double, label: String, detail: String) -> some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tinted(level))
                .frame(width: 320, height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
            Text(label)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            Text(detail)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    /// Grey levels carry the light's own colour cast so the reference matches the key.
    private func tinted(_ level: Double) -> Color {
        guard state.mode == .white else {
            return Color(hue: state.hue, saturation: state.saturation * 0.15, brightness: level)
        }
        let (r, g, b) = ColorScience.linearRGB(kelvin: state.kelvin, tint: state.tint)
        return Color(.sRGB,
                     red: ColorScience.encode(r) * level,
                     green: ColorScience.encode(g) * level,
                     blue: ColorScience.encode(b) * level,
                     opacity: 1)
    }

    private var skinTones: [Color] {
        [
            Color(.sRGB, red: 0.94, green: 0.80, blue: 0.71, opacity: 1),
            Color(.sRGB, red: 0.83, green: 0.65, blue: 0.53, opacity: 1),
            Color(.sRGB, red: 0.66, green: 0.47, blue: 0.36, opacity: 1),
            Color(.sRGB, red: 0.45, green: 0.31, blue: 0.24, opacity: 1),
            Color(.sRGB, red: 0.28, green: 0.19, blue: 0.15, opacity: 1),
        ]
    }
}
