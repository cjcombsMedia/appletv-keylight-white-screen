# Keylight for Mac

A menu-bar key light for the Mac. Lights your face from the screen you're already looking at,
with a small control box in the corner and one-click focus back to Teams or Zoom.

Separate Xcode project from the tvOS app — open `KeylightMac.xcodeproj`.

```bash
open KeylightMac.xcodeproj
```

Then ⌘R. It's an agent app: no Dock icon, a lightbulb in the menu bar, and the control box in
the bottom-right of your main display.

To keep it around, copy the built `Keylight.app` to `/Applications` and launch it from there —
**do that before switching on "Open at login"**, or macOS registers the copy sitting in
DerivedData.

---

## How it stacks

This is the setting that decides whether the thing is useful, so it's worth understanding.

**Behind apps** (default) — the light window sits above the wallpaper and desktop icons but
below every app window. Nothing ever covers your work. The catch: wherever a window sits, the
light is hidden behind it.

**In front** — the light floats above every window, but `ignoresMouseEvents` is set, so clicks,
scrolls and drags pass straight through to whatever is underneath. You can't tell it's there
except for the light.

In-front mode only works because the shaped layouts leave the middle of the screen empty. Two
Panel — the default — puts a soft bar down the far left and far right, which on a laptop is
exactly where your call window isn't. The centre is fully transparent, not black.

That's also why the panel warns you if you pick Flat or Softbox while in behind-apps mode:
those light the middle of the screen, which is the part your windows cover.

## Controls

The box has the things you actually change mid-call up top: **Brightness**, **Warmth**, the
shape picker and presets, and the shape's own controls:

- **Size** (*Bar width*, *Band height* or *Ring size*, depending on the shape): 10–100%
- **Ring width**: how thick the ring's stroke is, separate from how big the ring is
- **Edges**: from **Hard** (no blur at all, a pixel-sharp edge) to **Soft**
- **Edge to edge**: runs the shape right off the screen's border, so the light meets the edge
  of the display at full strength and only the inward-facing side is softened. Two Panel
  becomes two full-height bars flush to the sides, Softbox a full-width band, Top Band a strip
  flush to the top and both sides, and Ring a **frame around the whole screen border** (its
  width set by *Frame width*). Flat and Gradient already fill the screen, so the toggle is
  hidden for them.

Below that, **Light on** has one button per attached monitor. Click to switch a display on or
off, right-click for *Light Only This Display*, and use **All displays** to bring them all back.
The list follows monitors being plugged and unplugged, and the same choice is in the menu bar
under **Light On**. Two identical monitors share a name, so they're told apart by serial
number.

Everything else lives under **More**:

- **Tint** — the ±green/magenta axis, to match the room so your camera's auto white balance
  stops hunting
- **Backdrop** — opacity of the fill behind the lit shape. 0 (default) leaves everything
  visible; raise it to isolate the light
- **Stacking** — behind apps or in front
- **Follow the camera** — off by default. When on, the light comes up the moment another app
  opens the camera and drops when it lets go. Keylight never opens the camera itself, it only
  asks whether someone else has it
- **Open at login**

## Bring to front

Buttons for the call apps actually installed on this Mac — Teams, Zoom, Webex, Slack, FaceTime.
Anything not installed is hidden rather than shown as a dead button. An app that's already
running gets activated; one that isn't gets launched. Teams is checked under both
`com.microsoft.teams2` and `com.microsoft.teams`, since the identifier changed with new Teams.

The same list is in the menu bar menu, along with presets and an on/off toggle.

## Details worth knowing

- The control box is a **non-activating panel**, so clicking a slider doesn't pull focus out of
  Teams mid-call. It floats above other windows so it stays reachable, and remembers where you
  drag it. Move it and it stays put; leave it alone and it re-homes to the bottom-right corner.
- **Display sleep is blocked** while the light is on, and released the moment you turn it off.
- The light window joins **all Spaces** and is invisible to Mission Control and ⌘-tab.
- Settings persist, debounced so dragging a slider doesn't hammer `UserDefaults`.
- No pixel-shift / burn-in guard here, unlike the tvOS build — Mac panels aren't left showing a
  static bright field for hours the way a TV is, and a drifting light would be distracting at
  desk distance.

## Getting good light out of it

The screen is a dim light source compared to a real fixture, so the wins are in placement:

- **Turn your display brightness up.** The app sets pixel values; the panel decides the nits.
- **Sit closer to the screen than you think.** Illuminance falls off with the square of
  distance — halving your distance quadruples the light on your face.
- **Two Panel or Ring**, not Flat. Two Panel gives some modelling instead of a flat wash, and
  Ring puts round catchlights in your eyes.
- **Match the room.** Set Warmth near your room's own lighting (~2700–3000 K for warm bulbs,
  ~5000–5600 K for daylight) so your camera isn't trying to balance two different whites.
- If you're on an **external display and a laptop screen**, light the one your camera is on and
  switch the other off under Displays — otherwise the second screen just adds a colour cast
  from the side.

## Shared code

`Model/ColorScience.swift` is a copy of the tvOS app's, unchanged: Kelvin → Planckian locus
(CIE 1931 xy) → linear sRGB, normalised on the peak channel, plus the ±green trim and the sRGB
transfer function. The two apps are deliberately separate projects, so a fix to the colour maths
needs applying in both places.
