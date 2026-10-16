import SwiftUI

/// Conversions between correlated colour temperature and displayable sRGB.
///
/// The screen is being used as a light source, so the goal is a chromaticity that
/// sits on the Planckian locus (what a real tungsten / LED key light emits) rather
/// than a naive "make it orange" ramp.
enum ColorScience {

    // MARK: Planckian locus

    /// CIE 1931 xy chromaticity for a blackbody radiator, using the Kim et al.
    /// cubic approximation. Valid 1667 K – 25000 K.
    static func planckianXY(kelvin: Double) -> (x: Double, y: Double) {
        let t = min(max(kelvin, 1667), 25000)
        let t2 = t * t
        let t3 = t2 * t

        let x: Double
        if t <= 4000 {
            x = -0.2661239e9 / t3 - 0.2343589e6 / t2 + 0.8776956e3 / t + 0.179910
        } else {
            x = -3.0258469e9 / t3 + 2.1070379e6 / t2 + 0.2226347e3 / t + 0.240390
        }

        let x2 = x * x
        let x3 = x2 * x

        let y: Double
        if t <= 2222 {
            y = -1.1063814 * x3 - 1.34811020 * x2 + 2.18555832 * x - 0.20219683
        } else if t <= 4000 {
            y = -0.9549476 * x3 - 1.37418593 * x2 + 2.09137015 * x - 0.16748867
        } else {
            y = 3.0817580 * x3 - 5.87338670 * x2 + 3.75112997 * x - 0.37001483
        }

        return (x, y)
    }

    // MARK: Linear light

    /// Linear (un-encoded) sRGB primaries for a colour temperature, normalised so the
    /// strongest channel is 1.0. Normalising on the peak channel — rather than on
    /// luminance — is what physical RGBW fixtures do: it always drives the panel as
    /// hard as the chosen colour allows.
    static func linearRGB(kelvin: Double, tint: Double = 0) -> (r: Double, g: Double, b: Double) {
        let (x, y) = planckianXY(kelvin: kelvin)
        guard y > 0 else { return (1, 1, 1) }

        // xyY -> XYZ at Y = 1
        let X = x / y
        let Y = 1.0
        let Z = (1 - x - y) / y

        // XYZ -> linear sRGB (sRGB D65 primaries)
        var r =  3.2404542 * X - 1.5371385 * Y - 0.4985314 * Z
        var g = -0.9692660 * X + 1.8760108 * Y + 0.0415560 * Z
        var b =  0.0556434 * X - 0.2040259 * Y + 1.0572252 * Z

        // Green / magenta trim, the same axis a "±green" knob on a real fixture moves.
        let t = min(max(tint, -1), 1)
        g *= 1 + 0.30 * t
        r *= 1 - 0.15 * t
        b *= 1 - 0.15 * t

        r = max(r, 0); g = max(g, 0); b = max(b, 0)
        let peak = max(r, max(g, b))
        guard peak > 0 else { return (1, 1, 1) }
        return (r / peak, g / peak, b / peak)
    }

    // MARK: Transfer function

    /// Linear light -> sRGB encoded value.
    static func encode(_ linear: Double) -> Double {
        let v = min(max(linear, 0), 1)
        return v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1 / 2.4) - 0.055
    }

    // MARK: Public entry points

    /// The emitted colour for a white-mode light.
    ///
    /// `brightness` scales the *encoded* signal, which makes the dimmer feel evenly
    /// spaced to the eye (luminance follows roughly b^2.2, matching how a hardware
    /// dimmer is calibrated).
    static func whiteLight(kelvin: Double, tint: Double, brightness: Double) -> Color {
        let (r, g, b) = linearRGB(kelvin: kelvin, tint: tint)
        let k = min(max(brightness, 0), 1)
        return Color(.sRGB,
                     red: encode(r) * k,
                     green: encode(g) * k,
                     blue: encode(b) * k,
                     opacity: 1)
    }

    /// The emitted colour for hue-mode (gel / mood lighting).
    static func colorLight(hue: Double, saturation: Double, brightness: Double) -> Color {
        Color(hue: min(max(hue, 0), 1),
              saturation: min(max(saturation, 0), 1),
              brightness: min(max(brightness, 0), 1))
    }

    // MARK: Display helpers

    /// A rough name for a colour temperature, shown in the HUD.
    static func temperatureName(_ kelvin: Double) -> String {
        switch kelvin {
        case ..<2400:  return "Candle"
        case ..<3000:  return "Warm"
        case ..<3600:  return "Tungsten"
        case ..<4300:  return "Soft White"
        case ..<5000:  return "Neutral"
        case ..<5800:  return "Daylight"
        case ..<7000:  return "Cool"
        default:       return "Overcast"
        }
    }
}
