import SwiftUI

/// The light itself. Everything here is static geometry — no animation loops — so the
/// panel shows a genuinely constant field with no temporal flicker for the camera.
struct LightStageView: View {
    let state: LightState
    /// Slow sub-pixel wander that keeps a static bright image from ageing OLED pixels.
    var pixelShift: CGSize = .zero

    private var light: Color { state.color }
    private var surround: Color { state.surroundColor }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                surround
                shape(in: geo.size)
                    .offset(x: pixelShift.width, y: pixelShift.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    // MARK: Shapes

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

    /// Oversized so the pixel-shift offset never exposes an edge.
    private func flat(_ size: CGSize) -> some View {
        light
            .frame(width: size.width + bleed * 2, height: size.height + bleed * 2)
    }

    private func softbox(_ size: CGSize) -> some View {
        let w = size.width * state.size
        let h = size.height * (0.35 + 0.65 * state.size)
        let blur = featherRadius(for: min(w, h))
        return RoundedRectangle(cornerRadius: min(w, h) * 0.12, style: .continuous)
            .fill(light)
            .frame(width: max(w - blur, 40), height: max(h - blur, 40))
            .blur(radius: blur)
            .compositingGroup()
    }

    private func ring(_ size: CGSize) -> some View {
        let diameter = min(size.width, size.height) * state.size
        let thickness = diameter * 0.22
        let blur = featherRadius(for: thickness * 2)
        return Circle()
            .strokeBorder(light, lineWidth: thickness)
            .frame(width: diameter, height: diameter)
            .blur(radius: blur)
            .compositingGroup()
    }

    private func twoPanel(_ size: CGSize) -> some View {
        let panelWidth = size.width * 0.30 * state.size
        let panelHeight = size.height * (0.45 + 0.55 * state.size)
        let blur = featherRadius(for: panelWidth)
        let inset = size.width * 0.04

        return HStack(spacing: 0) {
            panel(panelWidth, panelHeight, blur)
            Spacer(minLength: 0)
            panel(panelWidth, panelHeight, blur)
        }
        .padding(.horizontal, inset)
        .frame(width: size.width, height: size.height)
    }

    private func panel(_ w: CGFloat, _ h: CGFloat, _ blur: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: w * 0.3, style: .continuous)
            .fill(light)
            .frame(width: max(w - blur, 30), height: max(h - blur, 30))
            .blur(radius: blur)
            .compositingGroup()
    }

    private func topBand(_ size: CGSize) -> some View {
        let h = size.height * (0.20 + 0.55 * state.size)
        let blur = featherRadius(for: h)
        return VStack(spacing: 0) {
            LinearGradient(
                colors: [light, light, light.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: max(h, 60))
            .blur(radius: blur * 0.6)
            Spacer(minLength: 0)
        }
        .frame(width: size.width + bleed * 2, height: size.height)
    }

    private func gradient(_ size: CGSize) -> some View {
        LinearGradient(
            stops: [
                .init(color: light, location: 0),
                .init(color: light, location: 0.22 + 0.25 * state.size),
                .init(color: light.opacity(0.30 - 0.20 * state.feather), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: size.width + bleed * 2, height: size.height + bleed * 2)
    }

    // MARK: Helpers

    private var bleed: CGFloat { 40 }

    /// Feather expressed as a blur radius relative to the shape, so the softness looks
    /// the same whether the box covers a third of the panel or all of it.
    private func featherRadius(for dimension: CGFloat) -> CGFloat {
        max(2, dimension * 0.28 * state.feather)
    }
}
