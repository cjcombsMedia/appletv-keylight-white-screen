import SwiftUI

/// Bottom sheet with every control. It deliberately covers only the lower part of the
/// screen: the top of a 55" panel is what actually lights your face, so you can still
/// judge the light while you dial it in.
struct ControlPanelView: View {
    @Environment(LightStore.self) private var store
    let onShowHelp: () -> Void

    private var state: LightState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            panel
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 18) {
                    presets
                    layouts
                    values
                    remote
                    tools
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 70)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 700)
        .background(
            LinearGradient(colors: [Color.black.opacity(0.86), Color.black.opacity(0.97)],
                           startPoint: .top, endPoint: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 20) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(state.color)
            Text("Keylight")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Text("Menu closes  •  Play/Pause blackout")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 60)
        .padding(.top, 26)
        .padding(.bottom, 18)
    }

    // MARK: Sections

    private var presets: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Presets", detail: "Select to apply")
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(Preset.builtIn) { preset in
                        Chip(title: preset.name, swatch: preset.swatch) {
                            store.apply(preset)
                        }
                    }
                    ForEach(state.userPresets) { preset in
                        Chip(title: preset.name, subtitle: "Saved", swatch: preset.swatch) {
                            store.apply(preset)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .scrollClipDisabled()
        }
    }

    private var layouts: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Shape", detail: "Smaller lit area = higher peak brightness on OLED")
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(LightLayout.allCases) { layout in
                        Chip(title: layout.title,
                             subtitle: layout.subtitle,
                             isSelected: state.layout == layout) {
                            store.setLayout(layout)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .scrollClipDisabled()

            HStack(spacing: 14) {
                ForEach(LightMode.allCases) { mode in
                    Chip(title: mode.title,
                         systemImage: mode == .white ? "sun.max" : "paintpalette",
                         isSelected: state.mode == mode) {
                        store.setMode(mode)
                    }
                }
            }
            .padding(.top, 2)
        }
    }

    private var values: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Light", detail: "Left / right adjusts the focused row")

            ValueRow(title: "Brightness",
                     value: "\(Int((state.brightness * 100).rounded()))%",
                     fraction: state.brightness,
                     accentLeft: "Dim", accentRight: "Full") { m in
                store.adjustBrightness(by: 0.01 * m)
            }

            if state.mode == .white {
                row(.temperature, left: "2000 K warm", right: "10000 K cool")
                row(.tint, left: "Magenta", right: "Green")
            } else {
                row(.hue, left: "0°", right: "360°")
                row(.saturation, left: "White", right: "Saturated")
            }

            if state.layout.isShaped {
                row(.size, left: "Small", right: "Full panel")
                row(.feather, left: "Hard edge", right: "Very soft")
            }

            row(.ambient, left: "Black surround", right: "Bright surround")
        }
    }

    private func row(_ dial: Dial, left: String, right: String) -> some View {
        let range = state.range(for: dial)
        let fraction = (state.value(for: dial) - range.lowerBound) / (range.upperBound - range.lowerBound)
        return ValueRow(title: dial.title,
                        value: state.displayValue(for: dial),
                        fraction: fraction,
                        accentLeft: left,
                        accentRight: right) { m in
            var s = store.state
            s.setValue(s.value(for: dial) + s.step(for: dial) * m, for: dial)
            store.state = s
            store.noteInteraction()
        }
    }

    private var remote: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Remote left / right controls", detail: "Up / down is always brightness")
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(state.availableDials) { dial in
                        Chip(title: dial.title, isSelected: state.dial == dial) {
                            store.state.dial = dial
                            store.noteInteraction()
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .scrollClipDisabled()
        }
    }

    private var tools: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Tools")

            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    // Play/Pause is the fast path, but not every remote has that button —
                    // universal remotes and some Control Center layouts don't.
                    Chip(title: store.isBlackout ? "Restore Light" : "Blackout",
                         systemImage: store.isBlackout ? "sun.max" : "moon.zzz") {
                        store.isBlackout.toggle()
                        store.showPanel = false
                        store.noteInteraction()
                    }
                    Chip(title: "Camera Test Card",
                         systemImage: "square.grid.3x3.square") {
                        store.showCalibration = true
                        store.showPanel = false
                        store.noteInteraction()
                    }
                    Chip(title: "Save Current as Preset",
                         systemImage: "square.and.arrow.down") {
                        store.saveUserPreset()
                    }
                    Chip(title: "Controls",
                         systemImage: "questionmark.circle") {
                        onShowHelp()
                    }
                    Chip(title: "Burn-in Guard",
                         subtitle: state.pixelShift ? "On — image drifts slowly" : "Off",
                         systemImage: state.pixelShift ? "checkmark.circle.fill" : "circle",
                         isSelected: state.pixelShift) {
                        store.state.pixelShift.toggle()
                        store.noteInteraction()
                    }
                    Chip(title: "Reset",
                         systemImage: "arrow.counterclockwise",
                         isDestructive: true) {
                        store.resetToDefaults()
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .scrollClipDisabled()

            SectionHeader(title: "Auto-off", detail: "Counts from your last remote press")
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(autoOffChoices, id: \.self) { minutes in
                        Chip(title: autoOffLabel(minutes),
                             isSelected: state.autoOffMinutes == minutes) {
                            store.state.autoOffMinutes = minutes
                            store.noteInteraction()
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .scrollClipDisabled()

            if !state.userPresets.isEmpty {
                SectionHeader(title: "Delete a saved preset")
                ScrollView(.horizontal) {
                    HStack(spacing: 14) {
                        ForEach(state.userPresets) { preset in
                            Chip(title: preset.name,
                                 systemImage: "trash",
                                 isDestructive: true) {
                                store.deleteUserPreset(preset)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .scrollClipDisabled()
            }
        }
    }

    private var autoOffChoices: [Int] { [0, 30, 60, 120, 240] }

    private func autoOffLabel(_ minutes: Int) -> String {
        switch minutes {
        case 0:   return "Never"
        case 30:  return "30 min"
        case 60:  return "1 hour"
        case 120: return "2 hours"
        default:  return "\(minutes / 60) hours"
        }
    }
}
