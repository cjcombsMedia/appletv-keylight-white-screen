import SwiftUI

/// The light itself. Static geometry — no animation loop — so the camera sees a
/// genuinely constant field with nothing to beat against.
///
/// Everything outside the lit shape is transparent unless `backdrop` says otherwise,
/// which is what lets the light sit behind your windows (or in front of them, click-through)
/// without blacking out the screen.
struct LightStageView: View {
    let state: LightState

    private var light: Color { state.color }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                state.backdropColor
                shape(in: geo.size)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func shape(in size: CGSize) -> some View {
        switch state.layout {
        case .flat:     flat(size)
        case .softbox:  softbox(size)
        case .ring:     ring(size)
        case .twoPanel: twoPanel(size)
        case .topBand:  topBand(size)
        case .gradient: gradient(size)
        }
    }

    private func flat(_ size: CGSize) -> some View {
        light.frame(width: size.width, height: size.height)
    }

    private func softbox(_ size: CGSize) -> some View {
        let w = size.width * state.size
        let h = size.height * (0.35 + 0.65 * state.size)
        let blur = feather(min(w, h))
        return RoundedRectangle(cornerRadius: min(w, h) * 0.12, style: .continuous)
            .fill(light)
            .frame(width: max(w - blur, 40), height: max(h - blur, 40))
            .blur(radius: blur)
            .compositingGroup()
    }

    private func ring(_ size: CGSize) -> some View {
        let diameter = min(size.width, size.height) * state.size
        let thickness = diameter * 0.20
        let blur = feather(thickness * 2)
        return Circle()
            .strokeBorder(light, lineWidth: thickness)
            .frame(width: diameter, height: diameter)
            .blur(radius: blur)
            .compositingGroup()
    }

    /// The default. On a laptop the two bars land at the far left and right of the
    /// display, which is exactly where a call window usually isn't — so the light keeps
    /// working even when it's stacked behind everything.
    private func twoPanel(_ size: CGSize) -> some View {
        let panelWidth = size.width * 0.26 * state.size
        let panelHeight = size.height * (0.5 + 0.5 * state.size)
        let blur = feather(panelWidth)
        return HStack(spacing: 0) {
            bar(panelWidth, panelHeight, blur)
            Spacer(minLength: 0)
            bar(panelWidth, panelHeight, blur)
        }
        .frame(width: size.width, height: size.height)
    }

    private func bar(_ w: CGFloat, _ h: CGFloat, _ blur: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: w * 0.3, style: .continuous)
            .fill(light)
            .frame(width: max(w - blur, 24), height: max(h - blur, 24))
            .blur(radius: blur)
            .compositingGroup()
    }

    private func topBand(_ size: CGSize) -> some View {
        let h = size.height * (0.18 + 0.5 * state.size)
        let blur = feather(h)
        return VStack(spacing: 0) {
            LinearGradient(colors: [light, light, light.opacity(0.4)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: max(h, 40))
                .blur(radius: blur * 0.6)
            Spacer(minLength: 0)
        }
        .frame(width: size.width, height: size.height)
    }

    private func gradient(_ size: CGSize) -> some View {
        LinearGradient(
            stops: [
                .init(color: light, location: 0),
                .init(color: light, location: 0.20 + 0.25 * state.size),
                .init(color: light.opacity(0), location: 1)
            ],
            startPoint: .top, endPoint: .bottom
        )
        .frame(width: size.width, height: size.height)
    }

    private func feather(_ dimension: CGFloat) -> CGFloat {
        max(2, dimension * 0.30 * state.feather)
    }
}

/// Wrapper hosted in each light window so SwiftUI observes the store directly.
struct LightScreenView: View {
    @Environment(LightStore.self) private var store

    var body: some View {
        LightStageView(state: store.state)
            .opacity(store.state.isOn ? 1 : 0)
            .animation(.easeInOut(duration: 0.35), value: store.state.isOn)
            .animation(.easeOut(duration: 0.18), value: store.state)
    }
}
