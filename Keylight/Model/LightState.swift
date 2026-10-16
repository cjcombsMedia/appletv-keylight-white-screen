import SwiftUI

// MARK: - Enumerations

enum LightMode: String, Codable, CaseIterable, Identifiable {
    case white
    case color

    var id: String { rawValue }
    var title: String { self == .white ? "White" : "Colour" }
}

/// How the light is shaped on the panel.
///
/// Shape matters for more than looks: on an OLED the auto-brightness limiter drops
/// peak output as the lit area grows, so a softbox covering 60% of a 55" panel is
/// noticeably *brighter* at the face than a full-field white raster.
enum LightLayout: String, Codable, CaseIterable, Identifiable {
    case flat
    case softbox
    case ring
    case twoPanel
    case topBand
    case gradient

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flat:     return "Flat"
        case .softbox:  return "Softbox"
        case .ring:     return "Ring"
        case .twoPanel: return "Two Panel"
        case .topBand:  return "Top Band"
        case .gradient: return "Gradient"
        }
    }

    var subtitle: String {
        switch self {
        case .flat:     return "Whole panel, maximum spread"
        case .softbox:  return "Feathered rectangle, directional"
        case .ring:     return "Round catchlights in the eyes"
        case .twoPanel: return "Key and fill from both sides"
        case .topBand:  return "Light from above, natural falloff"
        case .gradient: return "Bright top fading to fill"
        }
    }

    /// Layouts whose size / feather controls do something.
    var isShaped: Bool { self != .flat }
}

/// Which parameter the remote's left / right presses drive.
enum Dial: String, Codable, CaseIterable, Identifiable {
    case temperature
    case tint
    case hue
    case saturation
    case size
    case feather
    case ambient

    var id: String { rawValue }

    var title: String {
        switch self {
        case .temperature: return "Temperature"
        case .tint:        return "Tint"
        case .hue:         return "Hue"
        case .saturation:  return "Saturation"
        case .size:        return "Size"
        case .feather:     return "Feather"
        case .ambient:     return "Ambient"
        }
    }
}

// MARK: - State

/// Everything the light is. One `Codable` value so persistence is a single encode.
struct LightState: Codable, Equatable {
    var mode: LightMode = .white
    var layout: LightLayout = .softbox

    var brightness: Double = 0.85      // 0...1
    var kelvin: Double = 5200          // 2000...10000
    var tint: Double = 0               // -1...1, + is green
    var hue: Double = 0.58             // 0...1
    var saturation: Double = 0.85      // 0...1

    var size: Double = 0.78            // 0.25...1, fraction of the panel lit
    var feather: Double = 0.45         // 0...1, edge softness
    var ambient: Double = 0.06         // 0...1, level of the unlit surround

    var dial: Dial = .temperature
    var pixelShift: Bool = true
    var autoOffMinutes: Int = 0        // 0 = never
    var userPresets: [Preset] = []

    // MARK: Derived

    var color: Color {
        switch mode {
        case .white: return ColorScience.whiteLight(kelvin: kelvin, tint: tint, brightness: brightness)
        case .color: return ColorScience.colorLight(hue: hue, saturation: saturation, brightness: brightness)
        }
    }

    /// The surround colour: the same light, heavily attenuated. Keeping it slightly
    /// above black stops a TV's local dimming from pumping as the shape changes.
    var surroundColor: Color {
        switch mode {
        case .white:
            return ColorScience.whiteLight(kelvin: kelvin, tint: tint, brightness: brightness * ambient)
        case .color:
            return ColorScience.colorLight(hue: hue, saturation: saturation, brightness: brightness * ambient)
        }
    }

    /// Dials that make sense for the current mode and layout, in cycle order.
    var availableDials: [Dial] {
        var dials: [Dial] = mode == .white ? [.temperature, .tint] : [.hue, .saturation]
        if layout.isShaped { dials += [.size, .feather] }
        dials.append(.ambient)
        return dials
    }

    // MARK: Range metadata

    func range(for dial: Dial) -> ClosedRange<Double> {
        switch dial {
        case .temperature: return 2000...10000
        case .tint:        return -1...1
        case .hue:         return 0...1
        case .saturation:  return 0...1
        case .size:        return 0.25...1
        case .feather:     return 0...1
        case .ambient:     return 0...1
        }
    }

    /// Amount a single un-accelerated remote press moves a dial.
    func step(for dial: Dial) -> Double {
        switch dial {
        case .temperature: return 25
        case .tint:        return 0.01
        case .hue:         return 0.004
        case .saturation:  return 0.01
        case .size:        return 0.01
        case .feather:     return 0.01
        case .ambient:     return 0.005
        }
    }

    func value(for dial: Dial) -> Double {
        switch dial {
        case .temperature: return kelvin
        case .tint:        return tint
        case .hue:         return hue
        case .saturation:  return saturation
        case .size:        return size
        case .feather:     return feather
        case .ambient:     return ambient
        }
    }

    mutating func setValue(_ newValue: Double, for dial: Dial) {
        let r = range(for: dial)
        let v = min(max(newValue, r.lowerBound), r.upperBound)
        switch dial {
        case .temperature: kelvin = v
        case .tint:        tint = v
        case .hue:         hue = v
        case .saturation:  saturation = v
        case .size:        size = v
        case .feather:     feather = v
        case .ambient:     ambient = v
        }
    }

    /// Human-readable value for the HUD and panel.
    func displayValue(for dial: Dial) -> String {
        switch dial {
        case .temperature: return "\(Int((kelvin / 50).rounded()) * 50) K"
        case .tint:        return tintLabel
        case .hue:         return "\(Int((hue * 360).rounded()))°"
        case .saturation:  return percent(saturation)
        case .size:        return percent(size)
        case .feather:     return percent(feather)
        case .ambient:     return percent(ambient)
        }
    }

    private var tintLabel: String {
        let v = (tint * 100).rounded()
        if abs(v) < 1 { return "Neutral" }
        return v > 0 ? "+\(Int(v)) green" : "\(Int(-v)) magenta"
    }

    private func percent(_ v: Double) -> String { "\(Int((v * 100).rounded()))%" }
}

// MARK: - Presets

struct Preset: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var mode: LightMode
    var layout: LightLayout
    var brightness: Double
    var kelvin: Double
    var tint: Double
    var hue: Double
    var saturation: Double
    var size: Double
    var feather: Double
    var ambient: Double

    /// Capture the light-defining parts of a state (not the timers or preset list).
    init(name: String, from state: LightState) {
        self.name = name
        self.mode = state.mode
        self.layout = state.layout
        self.brightness = state.brightness
        self.kelvin = state.kelvin
        self.tint = state.tint
        self.hue = state.hue
        self.saturation = state.saturation
        self.size = state.size
        self.feather = state.feather
        self.ambient = state.ambient
    }

    init(name: String,
         mode: LightMode = .white,
         layout: LightLayout = .softbox,
         brightness: Double = 0.85,
         kelvin: Double = 5200,
         tint: Double = 0,
         hue: Double = 0.58,
         saturation: Double = 0.85,
         size: Double = 0.78,
         feather: Double = 0.45,
         ambient: Double = 0.06) {
        self.name = name
        self.mode = mode
        self.layout = layout
        self.brightness = brightness
        self.kelvin = kelvin
        self.tint = tint
        self.hue = hue
        self.saturation = saturation
        self.size = size
        self.feather = feather
        self.ambient = ambient
    }

    /// Swatch shown on the preset button.
    var swatch: Color {
        mode == .white
            ? ColorScience.whiteLight(kelvin: kelvin, tint: tint, brightness: 1)
            : ColorScience.colorLight(hue: hue, saturation: saturation, brightness: 1)
    }

    func apply(to state: inout LightState) {
        state.mode = mode
        state.layout = layout
        state.brightness = brightness
        state.kelvin = kelvin
        state.tint = tint
        state.hue = hue
        state.saturation = saturation
        state.size = size
        state.feather = feather
        state.ambient = ambient
        if !state.availableDials.contains(state.dial) {
            state.dial = state.availableDials.first ?? .temperature
        }
    }
}

extension Preset {
    /// Starting points chosen for a 55" panel roughly 1–1.5 m from the subject.
    static let builtIn: [Preset] = [
        Preset(name: "Video Call",
               layout: .softbox, brightness: 0.88, kelvin: 5200,
               size: 0.80, feather: 0.45, ambient: 0.06),
        Preset(name: "Daylight",
               layout: .softbox, brightness: 1.0, kelvin: 5600,
               size: 0.85, feather: 0.40, ambient: 0.05),
        Preset(name: "Warm Room",
               layout: .softbox, brightness: 0.75, kelvin: 3200,
               size: 0.78, feather: 0.55, ambient: 0.08),
        Preset(name: "Evening",
               layout: .gradient, brightness: 0.55, kelvin: 2700,
               size: 0.9, feather: 0.6, ambient: 0.12),
        Preset(name: "Overhead",
               layout: .topBand, brightness: 0.95, kelvin: 5000,
               size: 0.55, feather: 0.7, ambient: 0.05),
        Preset(name: "Ring",
               layout: .ring, brightness: 1.0, kelvin: 5400,
               size: 0.85, feather: 0.35, ambient: 0.04),
        Preset(name: "Butterfly",
               layout: .twoPanel, brightness: 0.9, kelvin: 5200,
               size: 0.7, feather: 0.5, ambient: 0.05),
        Preset(name: "Soft Fill",
               layout: .flat, brightness: 0.35, kelvin: 4500,
               ambient: 0.0),
        Preset(name: "Blue Hour",
               mode: .color, layout: .gradient, brightness: 0.6,
               hue: 0.60, saturation: 0.75, size: 0.9, feather: 0.6, ambient: 0.1),
        Preset(name: "Sunset",
               mode: .color, layout: .softbox, brightness: 0.7,
               hue: 0.05, saturation: 0.7, size: 0.8, feather: 0.6, ambient: 0.1),
    ]
}
