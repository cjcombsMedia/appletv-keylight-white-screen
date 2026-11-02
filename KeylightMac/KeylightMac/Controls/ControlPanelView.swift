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
            Divider()
            displayPicker
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

            shapeControls
        }
    }

    // MARK: Shape

    /// Size, ring width, edge hardness and edge to edge. Up front rather than under More,
    /// because these are what make a shape fit the face and the screen it's on.
    @ViewBuilder
    private var shapeControls: some View {
        @Bindable var store = store
        let layout = store.state.layout
        let edge = store.state.edgeToEdge && layout.supportsEdgeToEdge

        if layout.isShaped {
            // Edge to edge, the ring is a border frame and its only dimension is its width.
            if !(layout == .ring && edge) {
                slider(sizeTitle(layout, edge: edge), value: $store.state.size, range: 0.1...1,
                       readout: percent(store.state.size))
            }
            if layout == .ring {
                slider(edge ? "Frame width" : "Ring width", value: $store.state.thickness,
                       range: 0.04...0.5, readout: percent(store.state.thickness))
            }
            slider("Edges", value: $store.state.feather, range: 0...1,
                   readout: edgeLabel, ends: ("Hard", "Soft"))
        }

        if layout.supportsEdgeToEdge {
            Toggle(isOn: $store.state.edgeToEdge) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Edge to edge").font(.system(size: 11, weight: .medium))
                    Text(edge ? layout.edgeToEdgeDetail : "Run the light right to the screen's edges")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .controlSize(.small)
        }
    }

    private func sizeTitle(_ layout: LightLayout, edge: Bool) -> String {
        switch layout {
        case .twoPanel where edge: return "Bar width"
        case .softbox where edge, .topBand: return "Band height"
        case .ring: return "Ring size"
        default: return "Size"
        }
    }

    private var edgeLabel: String {
        let v = store.state.feather
        if v < 0.01 { return "Hard" }
        return "Soft \(percent(v))"
    }

    // MARK: Displays

    /// One button per attached monitor. Click to switch that display on or off; right-click
    /// for "Light only this one". The list follows monitors being plugged and unplugged.
    private var displayPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("LIGHT ON")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(.tertiary)
                Spacer()
                if store.displays.count > 1 {
                    Button("All displays") { store.lightAllDisplays() }
                        .buttonStyle(.link)
                        .font(.system(size: 10, weight: .medium))
                        .disabled(store.allDisplaysLit)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)],
                      spacing: 6) {
                ForEach(store.displays) { display in
                    Toggle(isOn: Binding(
                        get: { store.state.isLit(screenNamed: display.key) },
                        set: { store.setScreen(display.key, lit: $0) }
                    )) {
                        Label(display.key, systemImage: display.symbol)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .toggleStyle(.button)
                    .controlSize(.small)
                    .help(display.isPrimary ? "\(display.key) — has the menu bar" : display.key)
                    .contextMenu {
                        Button("Light Only This Display") { store.lightOnly(display.key) }
                        Button("Light All Displays") { store.lightAllDisplays() }
                    }
                }
            }
            if store.displays.allSatisfy({ !store.state.isLit(screenNamed: $0.key) }) {
                Text("No display is selected, so nothing is lit.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
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

    // MARK: Bits

    private func slider(_ title: String, value: Binding<Double>,
                        range: ClosedRange<Double>, readout: String,
                        ends: (String, String)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).font(.system(size: 11, weight: .medium))
                Spacer()
                Text(readout)
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            if let ends {
                Slider(value: value, in: range) {
                    EmptyView()
                } minimumValueLabel: {
                    Text(ends.0).font(.system(size: 9)).foregroundStyle(.tertiary)
                } maximumValueLabel: {
                    Text(ends.1).font(.system(size: 9)).foregroundStyle(.tertiary)
                }
                .controlSize(.small)
            } else {
                Slider(value: value, in: range).controlSize(.small)
            }
        }
    }

    private var tintLabel: String {
        let v = (store.state.tint * 100).rounded()
        if abs(v) < 1 { return "Neutral" }
        return v > 0 ? "+\(Int(v)) green" : "\(Int(-v)) magenta"
    }

    private func percent(_ v: Double) -> String { "\(Int((v * 100).rounded()))%" }
}
