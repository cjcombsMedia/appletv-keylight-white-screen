// App icon generator. Writes the Icon Composer document for Keylight for Mac:
//   swift Tools/make-icon.swift KeylightMac/KeylightMac/AppIcon.icon
//
// macOS 26+ draws classic PNG icon sets (AppIcon.appiconset) shrunk onto a grey system tile.
// Only an Icon Composer `.icon` document fills the Dock tile, so the icon is an `.icon` with:
//   - CJ's standard black tile: display-p3 grey 0.17 → 0.02 (light), 0.14 → 0.01 (dark), top to bottom;
//   - one glass group with two SVG layers drawn as line art (stroke 34 on the 1024 canvas):
//       white:  the display outline and stand;
//       yellow: two light bars down the sides of the screen (#F7CA53), the one accent. That is the
//               Two Panel layout, the app's default: the screen itself is the light.
//   The mark spans about 62% of the tile, centred. No shadows or glows of our own; the system adds them.
// Preview the system rendering with:
//   "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool" \
//     KeylightMac/KeylightMac/AppIcon.icon --export-image --output-file out.png --platform macOS \
//     --rendition Default --width 1024 --height 1024 --scale 1
import Foundation

let args = CommandLine.arguments.dropFirst()
let dir = URL(fileURLWithPath: args.first ?? "KeylightMac/KeylightMac/AppIcon.icon")
let assets = dir.appendingPathComponent("Assets")
try? FileManager.default.removeItem(at: assets)
try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)

let stroke = 34.0
func f(_ v: Double) -> String { String(format: "%.1f", v) }

func svg(_ colour: String, join: String, _ body: String) -> String {
    """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
    <g fill="none" stroke="\(colour)" stroke-width="\(Int(stroke))" stroke-linecap="round" stroke-linejoin="\(join)">
    \(body)
    </g>
    </svg>

    """
}

// The display: 640 × 400 with a short neck and a base, spanning y 262…762 so it sits centred.
let sx0 = 192.0, sx1 = 832.0, sy0 = 262.0, sy1 = 662.0, sr = 46.0
let display = """
<rect x="\(f(sx0))" y="\(f(sy0))" width="\(f(sx1 - sx0))" height="\(f(sy1 - sy0))" rx="\(f(sr))"/>
<path d="M 512 \(f(sy1)) L 512 742 M 412 762 L 612 762"/>
"""

// Two Panel, the app's default: a light bar down each side of the screen.
let barW = 74.0, barH = 250.0, inset = 64.0, cy = (sy0 + sy1) / 2
let bars = [sx0 + inset, sx1 - inset - barW].map { x in
    "<rect x=\"\(f(x))\" y=\"\(f(cy - barH / 2))\" width=\"\(f(barW))\" height=\"\(f(barH))\" rx=\"\(f(barW / 2))\"/>"
}
let white = display
let yellow = bars.joined(separator: "\n")

try svg("#FFFFFF", join: "round", white).write(to: assets.appendingPathComponent("mark-white.svg"),
                                              atomically: true, encoding: .utf8)
try svg("#F7CA53", join: "round", yellow).write(to: assets.appendingPathComponent("mark-yellow.svg"),
                                               atomically: true, encoding: .utf8)

func fill(_ top: Double, _ bottom: Double) -> String {
    """
    {
            "linear-gradient": [
              "display-p3:\(String(format: "%.5f,%.5f,%.5f", top, top, top)),1.00000",
              "display-p3:\(String(format: "%.5f,%.5f,%.5f", bottom, bottom, bottom)),1.00000"
            ],
            "orientation": { "start": { "x": 0.5, "y": 0 }, "stop": { "x": 0.5, "y": 1 } }
          }
    """
}
let json = """
{
  "color-space-for-untagged-svg-colors": "display-p3",
  "fill-specializations": [
    { "value": \(fill(0.17, 0.02)) },
    { "appearance": "dark", "value": \(fill(0.14, 0.01)) }
  ],
  "groups": [
    {
      "layers": [
        { "glass": true, "image-name": "mark-white.svg", "name": "White" },
        { "glass": true, "image-name": "mark-yellow.svg", "name": "Yellow" }
      ],
      "lighting": "combined",
      "name": "Mark",
      "shadow": { "kind": "neutral", "opacity": 0.5 },
      "translucency": { "enabled": false, "value": 0 }
    }
  ],
  "supported-platforms": { "squares": [ "macOS" ] }
}

"""
try json.write(to: dir.appendingPathComponent("icon.json"), atomically: true, encoding: .utf8)
print("wrote", dir.path)
