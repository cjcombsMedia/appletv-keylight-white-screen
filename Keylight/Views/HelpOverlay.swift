import SwiftUI

/// Shown once on first launch, and any time you pick "Controls" from the panel.
struct HelpOverlay: View {
    let dialName: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 26) {
                Text("Remote controls")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 18) {
                    row("chevron.up.chevron.down", "Up / Down", "Brightness")
                    row("chevron.left.slash.chevron.right", "Left / Right", dialName + " — change what this does in the panel")
                    row("circle.circle", "Click centre", "Open and close the control panel")
                    row("playpause", "Play / Pause", "Blackout — instantly kills the light, press again to restore")
                    row("chevron.left", "Menu", "Closes the panel, or leaves the app")
                }

                Text("Hold a direction to speed up. The readout fades after a couple of seconds so the panel is nothing but light.")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: 900, alignment: .leading)

                Text("Press any button to dismiss")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, 6)
            }
            .padding(60)
        }
    }

    private func row(_ icon: String, _ control: String, _ meaning: String) -> some View {
        HStack(alignment: .top, spacing: 22) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 56, alignment: .center)
            Text(control)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 260, alignment: .leading)
            Text(meaning)
                .font(.system(size: 26, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .frame(maxWidth: 900, alignment: .leading)
        }
    }
}
