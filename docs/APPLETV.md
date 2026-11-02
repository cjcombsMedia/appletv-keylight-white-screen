# Keylight for Apple TV

Deployment, pairing and TV picture settings live in [SETUP.md](../SETUP.md). This page is what
the app actually does.

## Remote controls

| Input | Does |
|---|---|
| **Up / Down** | Brightness. Always, everywhere. |
| **Left / Right** | The assigned dial — Temperature by default. Reassign in the panel. |
| **Click centre** | Open / close the control panel |
| **Play / Pause** | Blackout. Kills the light instantly, press again to restore. |
| **Menu** | Closes whatever's open; from the bare light it leaves the app |

Hold a direction to accelerate — a single tap moves 25 K, holding sweeps the full
2000–10000 K range in a couple of seconds. The readout fades after 2.5 s so the panel goes
back to being nothing but light.

## What it does

**Colour temperature, 2000–10000 K.** Not a naive orange ramp — temperatures are converted
through the Planckian locus (CIE 1931 xy) into linear sRGB and normalised on the peak channel,
so the chromaticity matches what a real fixture at that temperature emits. 6500 K lands on
D65 white; 2700 K matches a tungsten bulb.

**Tint, ±green/magenta.** The same axis a hardware light exposes. Use it to match the room's
existing lighting so your camera's auto white balance stops hunting.

**Brightness, 2–100%,** applied to the encoded signal so the dimmer feels evenly spaced rather
than dropping off a cliff at the bottom.

**Six shapes.** Flat, Softbox (the default), Ring, Two Panel, Top Band, Gradient — plus Size,
Feather and Ambient. A slightly-lifted ambient surround stops the TV's local dimming from
pumping as the shape changes.

**Colour mode.** Full hue and saturation for background and mood lighting.

**Ten presets** — Video Call, Daylight, Warm Room, Evening, Overhead, Ring, Butterfly,
Soft Fill, Blue Hour, Sunset — plus unlimited slots saved from whatever you're looking at.

**Camera test card.** An 18% grey patch, white and black references, an 11-step wedge, and five
skin-tone swatches, all rendered at the light's current colour temperature. Lock your camera's
exposure and white balance against it, then go back to the light.

**Blackout** on Play/Pause, with a 0.3 s fade rather than a jarring cut. Also reachable from
the panel's Tools row, for remotes without a play/pause button.

**Auto-off** — off by default; 30 min to 4 hours, counted from your last remote press, with a
60-second warning so a call doesn't go dark on you.

**Burn-in guard** — the image drifts a few points every 75 seconds. A 55" panel holding a
bright static rectangle for hours is exactly the wear pattern OLEDs dislike.

**Screensaver disabled** while the app is foreground, settings persisted between launches, and
a soft fade-in on launch instead of a blinding flash.

## Design notes

The light is static geometry with no animation loop — a genuinely constant field, no temporal
flicker for the camera to beat against.

Horizontal remote input is deliberately a single assignable dial rather than a mode carousel:
up/down is brightness forever, left/right is the one thing you're currently tuning, and
everything else lives one click away in the panel. The panel is a bottom sheet, not a
full-screen takeover, because the top of the panel is what actually lights your face — you can
watch the light change while you adjust it.

### The invisible-button trap

The full-screen focus catcher that turns remote input into light changes started life as a
`Button` with a `Color.white.opacity(0.001)` label. That is invisible in a simulator and solid
white on real hardware: tvOS brightens a focused button's label while a finger rests on the
Siri Remote touchpad, so the near-zero white composited to full white across the entire screen.

The fix is in `ContentView.swift` — a custom `BareButtonStyle` that renders only the label
(the built-in `.plain` style still applies the platform's focus treatment, and
`.focusEffectDisabled()` does not fully suppress it), a `Color.clear` label, and a 60 pt frame
in the corner instead of full-screen so no focus decoration can reach the light.

Worth remembering generally: **touchpad-contact behaviour cannot be reproduced in the
Simulator.** It needs the real remote.
