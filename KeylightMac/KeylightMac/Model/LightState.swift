import SwiftUI

// MARK: - Enumerations

enum LightMode: String, Codable, CaseIterable, Identifiable {
    case white, color
    var id: String { rawValue }
    var title: String { self == .white ? "White" : "Colour" }
}

enum LightLayout: String, Codable, CaseIterable, Identifiable {
    case twoPanel, softbox, ring, topBand, gradient, flat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .twoPanel: return "Two Panel"
        case .softbox:  return "Softbox"
        case .ring:     return "Ring"
        case .topBand:  return "Top Band"
        case .gradient: return "Gradient"
        case .flat:     return "Flat"
        }
    }

    /// Layouts that leave the middle of the screen unlit. These are the ones worth using
    /// when the light sits behind your windows — the lit area stays visible around the
    /// edges instead of being completely covered by whatever you're working in.
    var leavesCentreClear: Bool {
        self == .twoPanel || self == .ring || self == .topBand
    }

    var isShaped: Bool { self != .flat }

    /// Layouts that can run off the edges of the display. Flat and Gradient already fill it.
    var supportsEdgeToEdge: Bool {
        self == .twoPanel || self == .softbox || self == .ring || self == .topBand
    }

    /// What "edge to edge" turns this layout into, for the caption under the toggle.
    var edgeToEdgeDetail: String {
        switch self {
        case .twoPanel: return "Bars run flush to the left and right edges, top to bottom"
        case .softbox:  return "A full-width band, flush to the left and right edges"
        case .ring:     return "The ring becomes a frame around the border of the screen"
        case .topBand:  return "The band runs flush to the top and both sides"
        case .gradient, .flat: return ""
        }
    }
}

/// Where the light window sits in the window stack.
enum Stacking: String, Codable, CaseIterable, Identifiable {
    /// Above the wallpaper and desktop icons, below every app window.
    case behindApps
    /// Above every app window, but click-through so it never intercepts the mouse.
    case inFront

    var id: String { rawValue }

    var title: String { self == .behindApps ? "Behind apps" : "In front" }

    var detail: String {
        switch self {
        case .behindApps: return "Only lights where no window covers it"
        case .inFront:    return "Always lights — clicks pass straight through"
        }
    }
}

// MARK: - State

struct LightState: Codable, Equatable {
    var isOn = true
    var mode: LightMode = .white
    var layout: LightLayout = .twoPanel

    var brightness: Double = 0.85
    var kelvin: Double = 5200
    var tint: Double = 0
    var hue: Double = 0.58
    var saturation: Double = 0.85

    var size: Double = 0.75
    /// Edge softness. 0 is a hard, pixel-sharp edge; 1 is the widest fade.
    var feather: Double = 0.5
    /// Ring stroke as a fraction of its diameter, or of the screen's short side when the
    /// ring is drawn edge to edge as a frame.
    var thickness: Double = 0.2
    /// Run the shape off the display's edges so the light reaches the border at full
    /// strength, with only the inward-facing sides carrying the softness.
    var edgeToEdge = false

    /// Opacity of the fill behind the lit shape. 0 leaves the desktop (or your windows,
    /// in front mode) completely visible; higher values isolate the light.
    var backdrop: Double = 0

    var stacking: Stacking = .behindApps

    /// Screens the light is suppressed on, keyed by display name. Absent = lit.
    var disabledScreens: Set<String> = []

    /// Follow the camera: light up when something starts using it, drop when it stops.
    var followCamera = false

    // MARK: Derived

    var color: Color {
        switch mode {
        case .white: return ColorScience.whiteLight(kelvin: kelvin, tint: tint, brightness: brightness)
        case .color: return ColorScience.colorLight(hue: hue, saturation: saturation, brightness: brightness)
        }
    }

    /// The fill behind the shape, carrying the light's own cast at `backdrop` opacity.
    var backdropColor: Color {
        color.opacity(backdrop)
    }

    func isLit(screenNamed name: String) -> Bool {
        !disabledScreens.contains(name)
    }
}

// MARK: - Decoding

extension LightState {
    /// Every field falls back to its default, so a state saved by an older build — one
    /// without `edgeToEdge` or `thickness`, say — still loads instead of resetting
    /// everything the user had set.
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isOn            = try c.decodeIfPresent(Bool.self, forKey: .isOn) ?? isOn
        mode            = try c.decodeIfPresent(LightMode.self, forKey: .mode) ?? mode
        layout          = try c.decodeIfPresent(LightLayout.self, forKey: .layout) ?? layout
        brightness      = try c.decodeIfPresent(Double.self, forKey: .brightness) ?? brightness
        kelvin          = try c.decodeIfPresent(Double.self, forKey: .kelvin) ?? kelvin
        tint            = try c.decodeIfPresent(Double.self, forKey: .tint) ?? tint
        hue             = try c.decodeIfPresent(Double.self, forKey: .hue) ?? hue
        saturation      = try c.decodeIfPresent(Double.self, forKey: .saturation) ?? saturation
        size            = try c.decodeIfPresent(Double.self, forKey: .size) ?? size
        feather         = try c.decodeIfPresent(Double.self, forKey: .feather) ?? feather
        thickness       = try c.decodeIfPresent(Double.self, forKey: .thickness) ?? thickness
        edgeToEdge      = try c.decodeIfPresent(Bool.self, forKey: .edgeToEdge) ?? edgeToEdge
        backdrop        = try c.decodeIfPresent(Double.self, forKey: .backdrop) ?? backdrop
        stacking        = try c.decodeIfPresent(Stacking.self, forKey: .stacking) ?? stacking
        disabledScreens = try c.decodeIfPresent(Set<String>.self, forKey: .disabledScreens) ?? disabledScreens
        followCamera    = try c.decodeIfPresent(Bool.self, forKey: .followCamera) ?? followCamera
    }
}

// MARK: - Displays

/// One attached screen, as the controls list it.
struct DisplayInfo: Identifiable, Equatable {
    /// What `LightState.disabledScreens` remembers it by.
    let key: String
    let isBuiltIn: Bool
    /// The display with the menu bar.
    let isPrimary: Bool

    var id: String { key }
    var symbol: String { isBuiltIn ? "laptopcomputer" : "display" }
}

// MARK: - Presets

struct Preset: Identifiable, Equatable {
    let id: String
    let name: String
    let layout: LightLayout
    let brightness: Double
    let kelvin: Double
    let size: Double
    let feather: Double
    let backdrop: Double

    func apply(to state: inout LightState) {
        state.mode = .white
        state.layout = layout
        state.brightness = brightness
        state.kelvin = kelvin
        state.size = size
        state.feather = feather
        state.backdrop = backdrop
    }

    /// Tuned for a face roughly an arm's length from a laptop or desk display, which is
    /// far closer than the TV build assumes — so these run dimmer and softer.
    static let all: [Preset] = [
        Preset(id: "call",    name: "Video Call", layout: .twoPanel, brightness: 0.80,
               kelvin: 5200, size: 0.75, feather: 0.50, backdrop: 0),
        Preset(id: "bright",  name: "Bright Room", layout: .twoPanel, brightness: 1.0,
               kelvin: 5600, size: 0.85, feather: 0.40, backdrop: 0),
        Preset(id: "dim",     name: "Dim Room", layout: .twoPanel, brightness: 0.55,
               kelvin: 4300, size: 0.70, feather: 0.60, backdrop: 0),
        Preset(id: "warm",    name: "Evening", layout: .twoPanel, brightness: 0.50,
               kelvin: 3000, size: 0.70, feather: 0.60, backdrop: 0),
        Preset(id: "overhead", name: "Overhead", layout: .topBand, brightness: 0.90,
               kelvin: 5000, size: 0.45, feather: 0.70, backdrop: 0),
        Preset(id: "ring",    name: "Ring", layout: .ring, brightness: 0.95,
               kelvin: 5400, size: 0.80, feather: 0.35, backdrop: 0),
        Preset(id: "fill",    name: "Soft Fill", layout: .softbox, brightness: 0.45,
               kelvin: 4800, size: 0.90, feather: 0.70, backdrop: 0),
        Preset(id: "flood",   name: "Full Flood", layout: .flat, brightness: 0.85,
               kelvin: 5200, size: 1.0, feather: 0, backdrop: 1),
    ]
}
