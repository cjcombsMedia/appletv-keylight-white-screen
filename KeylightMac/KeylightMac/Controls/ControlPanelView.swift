import AppKit
import SwiftUI

struct ControlPanelView: View {
    @Environment(LightStore.self) private var store

    @State private var showMore = false
    @State private var launchAtLogin = LoginItem.isEnabled
    private let callApps = CallApp.installed

    var body: some View {
        @Bindable var store = store

        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            essentials
            if !callApps.isEmpty {
                Divider()
                appButtons
            }
            Divider()
            DisclosureGroup("More", isExpanded: $showMore) {
                moreControls.padding(.top, 10)
            }
            .font(.system(size: 12, weight: .semibold))
        }
        .padding(16)
        .frame(width: 340)
        .background(.regularMaterial)
    }

    // MARK: Header

    private var header: some View {
        @Bindable var store = store
        return HStack(spacing: 10) {
            Image(systemName: store.state.isOn ? "lightbulb.fill" : "lightbulb")
                .foregroundStyle(store.state.isOn ? swatch : .secondary)
                .font(.system(size: 15, weight: .semibold))
            Text("Keylight")
                .font(.system(size: 14, weight: .bold))
            Spacer()
            Toggle("", isOn: $store.state.isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
                .help("Turn the light on or off")
        }
    }

    private var swatch: Color {
        ColorScience.whiteLight(kelvin: store.state.kelvin, tint: store.state.tint, brightness: 1)
    }

    // MARK: Essentials

    private var essentials: some View {
        @Bindable var store = store
        return VStack(alignment: .leading, spacing: 12) {
            slider("Brightness",
                   value: $store.state.brightness,
                   range: 0.02...1,
                   readout: "\(Int((store.state.brightness * 100).rounded()))%")

            slider("Warmth",
                   value: $store.state.kelvin,
                   range: 2000...10000,
                   readout: "\(Int((store.state.kelvin / 50).rounded()) * 50) K")

            HStack(spacing: 10) {
                Picker("", selection: $store.state.layout) {
                    ForEach(LightLayout.allCases) { layout in
                        Text(layout.title).tag(layout)
                    }
                }
                .labelsHidden()
                .controlSize(.small)

                Menu("Presets") {
                    ForEach(Preset.all) { preset in
                        Button(preset.name) { store.apply(preset) }
                    }
                }
                .menuStyle(.borderlessButton)
                .controlSize(.small)
                .fixedSize()
            }

            if store.state.stacking == .behindApps && !store.state.layout.leavesCentreClear {
                Label("This shape lights the middle of the screen, where your windows sit. Two Panel, Ring or Top Band stay visible behind apps.",
                      systemImage: "info.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: App switching

    private var appButtons: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BRING TO FRONT")
                .font(.system(size: 9, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
            // Two columns: four apps in a single row truncates every label to "Sho…".
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)],
                      spacing: 6) {
                ForEach(callApps) { app in
                    Button {
                        app.activate()
                    } label: {
                        Label("Show \(app.name)", systemImage: app.symbol)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .controlSize(.small)
                    .help(app.isRunning ? "Bring \(app.name) to the front"
                                        : "Launch \(app.name)")
                }
            }

            HStack(spacing: 8) {
                Button {
                    AppHider.hideOthers()
                } label: {
                    Label("Hide Others", systemImage: "eye.slash")
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .controlSize(.small)
                .help("Hide every other app so the light isn't covered")

                Button {
                    AppHider.showAll()
                } label: {
                    Label("Show All", systemImage: "eye")
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .controlSize(.small)
                .help("Bring back everything you hid")
            }
            .padding(.top, 2)
        }
    }

    // MARK: More

    private var moreControls: some View {
        @Bindable var store = store
        return VStack(alignment: .leading, spacing: 12) {
            slider("Tint", value: $store.state.tint, range: -1...1, readout: tintLabel)

            if store.state.layout.isShaped {
                slider("Size", value: $store.state.size, range: 0.25...1,
                       readout: percent(store.state.size))
                slider("Softness", value: $store.state.feather, range: 0...1,
                       readout: percent(store.state.feather))
            }

            slider("Backdrop", value: $store.state.backdrop, range: 0...1,
                   readout: store.state.backdrop < 0.01 ? "Off" : percent(store.state.backdrop))

            VStack(alignment: .leading, spacing: 4) {
                Text("STACKING")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(.tertiary)
                Picker("", selection: $store.state.stacking) {
                    ForEach(Stacking.allCases) { Text($0.title).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .controlSize(.small)
                Text(store.state.stacking.detail)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            screenToggles

            Toggle(isOn: $store.state.followCamera) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Follow the camera").font(.system(size: 11, weight: .medium))
                    Text(store.state.followCamera
                         ? (store.cameraInUse ? "Camera in use — light on" : "Waiting for a call")
                         : "Light up automatically when a call starts")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .controlSize(.small)

            Toggle(isOn: Binding(
                get: { launchAtLogin },
                set: { launchAtLogin = LoginItem.setEnabled($0) ? $0 : launchAtLogin }
            )) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Open at login").font(.system(size: 11, weight: .medium))
                    Text("Keep Keylight in the menu bar, ready before a call")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .controlSize(.small)
        }
    }

    private var screenToggles: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DISPLAYS")
                .font(.system(size: 9, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
            ForEach(NSScreen.screens, id: \.keylightName) { screen in
                Toggle(isOn: Binding(
                    get: { store.state.isLit(screenNamed: screen.keylightName) },
                    set: { store.setScreen(screen.keylightName, lit: $0) }
                )) {
                    Text(screen.keylightName)
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
                .controlSize(.small)
            }
        }
    }

    // MARK: Bits

    private func slider(_ title: String, value: Binding<Double>,
                        range: ClosedRange<Double>, readout: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).font(.system(size: 11, weight: .medium))
                Spacer()
                Text(readout)
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range).controlSize(.small)
        }
    }

    private var tintLabel: String {
        let v = (store.state.tint * 100).rounded()
        if abs(v) < 1 { return "Neutral" }
        return v > 0 ? "+\(Int(v)) green" : "\(Int(-v)) magenta"
    }

    private func percent(_ v: Double) -> String { "\(Int((v * 100).rounded()))%" }
}
