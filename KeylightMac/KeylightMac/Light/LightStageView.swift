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

    @ViewBuilder
    private func softbox(_ size: CGSize) -> some View {
        if state.edgeToEdge {
            let h = size.height * (0.35 + 0.65 * state.size)
            bleed(CGRect(x: 0, y: (size.height - h) / 2, width: size.width, height: h),
                  edges: [.leading, .trailing], blur: feather(h), in: size)
        } else {
            boxedSoftbox(size)
        }
    }

    private func boxedSoftbox(_ size: CGSize) -> some View {
        let w = size.width * state.size
        let h = size.height * (0.35 + 0.65 * state.size)
        let blur = feather(min(w, h))
        return RoundedRectangle(cornerRadius: min(w, h) * 0.12, style: .continuous)
            .fill(light)
            .frame(width: max(w - blur, 40), height: max(h - blur, 40))
            .blur(radius: blur)
            .compositingGroup()
    }

    @ViewBuilder
    private func ring(_ size: CGSize) -> some View {
        if state.edgeToEdge { edgeFrame(size) } else { circularRing(size) }
    }

    private func circularRing(_ size: CGSize) -> some View {
        let diameter = min(size.width, size.height) * state.size
        let thickness = diameter * state.thickness
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
    @ViewBuilder
    private func twoPanel(_ size: CGSize) -> some View {
        let panelWidth = size.width * 0.26 * state.size
        let panelHeight = size.height * (0.5 + 0.5 * state.size)
        let blur = feather(panelWidth)
        if state.edgeToEdge {
            ZStack {
                bleed(CGRect(x: 0, y: 0, width: panelWidth, height: size.height),
                      edges: [.leading, .top, .bottom], blur: blur, in: size)
                bleed(CGRect(x: size.width - panelWidth, y: 0, width: panelWidth, height: size.height),
                      edges: [.trailing, .top, .bottom], blur: blur, in: size)
            }
        } else {
            HStack(spacing: 0) {
                bar(panelWidth, panelHeight, blur)
                Spacer(minLength: 0)
                bar(panelWidth, panelHeight, blur)
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private func bar(_ w: CGFloat, _ h: CGFloat, _ blur: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: w * 0.3, style: .continuous)
            .fill(light)
            .frame(width: max(w - blur, 24), height: max(h - blur, 24))
            .blur(radius: blur)
            .compositingGroup()
    }

    @ViewBuilder
    private func topBand(_ size: CGSize) -> some View {
        let h = size.height * (0.18 + 0.5 * state.size)
        let blur = feather(h)
        if state.edgeToEdge {
            bleed(CGRect(x: 0, y: 0, width: size.width, height: h),
                  edges: [.leading, .trailing, .top], blur: blur, in: size)
        } else {
            VStack(spacing: 0) {
                LinearGradient(colors: [light, light, light.opacity(0.4)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: max(h, 40))
                    .blur(radius: blur * 0.6)
                Spacer(minLength: 0)
            }
            .frame(width: size.width, height: size.height)
        }
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

    // MARK: Edge to edge

    /// A square-cornered block of light whose `edges` run off the screen. Pushing those
    /// sides out by twice the blur radius moves their fade off-screen, so the light meets
    /// the border at full strength and only the inward-facing sides carry the softness.
    private func bleed(_ rect: CGRect, edges: Edge.Set, blur: CGFloat, in size: CGSize) -> some View {
        let pad = blur * 2
        var r = rect
        if edges.contains(.leading)  { r.origin.x -= pad; r.size.width += pad }
        if edges.contains(.trailing) { r.size.width += pad }
        if edges.contains(.top)      { r.origin.y -= pad; r.size.height += pad }
        if edges.contains(.bottom)   { r.size.height += pad }
        return Rectangle()
            .fill(light)
            .frame(width: r.width, height: r.height)
            .position(x: r.midX, y: r.midY)
            .frame(width: size.width, height: size.height)
            .blur(radius: blur)
            .compositingGroup()
    }

    /// Ring, edge to edge: a frame around the whole border of the display. The stroke's
    /// rectangle overhangs the screen by the blur padding, so the outer edge is cut off
    /// at full strength and only the inner edge fades.
    private func edgeFrame(_ size: CGSize) -> some View {
        let thickness = min(size.width, size.height) * 0.5 * state.thickness
        let blur = feather(thickness * 2)
        let pad = blur * 2
        return Rectangle()
            .strokeBorder(light, lineWidth: thickness + pad)
            .frame(width: size.width + pad * 2, height: size.height + pad * 2)
            .frame(width: size.width, height: size.height)
            .blur(radius: blur)
            .compositingGroup()
    }

    /// 0 is a genuinely hard edge, with no blur at all.
    private func feather(_ dimension: CGFloat) -> CGFloat {
        dimension * 0.45 * state.feather
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
