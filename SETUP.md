# Keylight — setup and deployment to your Apple TV

Verified on this Mac: **Xcode 26.6**, tvOS 26.5 SDK. The project builds clean (zero errors,
zero warnings) for `appletvos` in both Debug and Release.

---

## Step 0 — install tvOS platform support (required once)

Your Mac has the tvOS **device SDK** but not the tvOS **Simulator runtime**. Xcode's asset
compiler (`actool`) refuses to build a tvOS app icon without it, so the first build will fail
with this exact message:

```
Assets.xcassets: error: No available simulator runtimes for platform appletvsimulator.
```

Fix it once:

```bash
xcodebuild -downloadPlatform tvOS
```

That's a multi-gigabyte download and takes a while. You can also do it from
Xcode → Settings → Components. Nothing else in the project depends on it.

**If you'd rather skip the download:** open the project, select the **Keylight** target →
Build Settings → search `ASSETCATALOG_COMPILER_APPICON_NAME`, and clear the value. The app
builds and runs identically, it just gets a blank tile on the Apple TV home screen.

---

## Step 1 — open the project

```bash
open "Keylight.xcodeproj"
```

## Step 2 — set your signing team

1. Select the **Keylight** project in the navigator → **Keylight** target → **Signing & Capabilities**.
2. Tick **Automatically manage signing**.
3. Pick your **Team**. A free Apple ID works — add it under Xcode → Settings → Accounts.
4. If the bundle ID `com.cjcombs.Keylight` is taken, change it to anything unique
   (e.g. `com.yourname.keylight`).

> Free Apple ID: the app expires after **7 days** and you re-run from Xcode to renew it.
> Paid Developer Program ($99/yr): **1 year**, and you can install it wirelessly without
> re-plugging anything.

## Step 3 — pair your Apple TV with Xcode

Apple TV 4K has no USB port, so pairing is over the network.

1. Put the Mac and the Apple TV **on the same Wi-Fi network / subnet**.
2. On the Apple TV: **Settings → Remotes and Devices → Remote App and Devices**. Leave that
   screen open — it puts the device into pairing mode.
3. In Xcode: **Window → Devices and Simulators** (⇧⌘2), **Devices** tab.
4. Your Apple TV appears in the left column. Select it and click **Pair**.
5. A six-digit code shows on the TV. Type it into Xcode.
6. Wait for "Preparing debugger support" / symbol copying to finish — the first time can take
   several minutes. The device is ready when the amber dot next to it turns green.

*Apple TV HD (the 2015 model) does have a USB-C port and can pair over a cable instead.*

## Step 4 — build and run

1. In the Xcode toolbar scheme selector, choose **Keylight** → **your Apple TV**.
2. Press **⌘R**.
3. First run only: the Apple TV shows "Untrusted Developer". On the Apple TV go to
   **Settings → General → VPN & Device Management → your Apple ID → Trust**. Then ⌘R again.

The app launches straight into the light.

## Step 5 — run it without the Mac

Once installed it lives on the Apple TV home screen and launches on its own — Xcode is only
needed to install and to re-sign when the 7-day free-provisioning window lapses.

---

## Getting the most light out of the panel

The app can only drive pixel values; the TV decides how many nits that becomes. Worth doing
once on the TV itself:

- **Picture mode → Vivid / Dynamic / Standard.** Filmmaker, Cinema and Calibrated modes
  deliberately cap brightness and warm the white point, which fights everything this app does.
- **Backlight / OLED Light → maximum.**
- **Turn off the ambient light sensor** (often "Eco", "Auto Brightness", "Energy Saving",
  "Intelligent Picture"). Otherwise the TV dims itself and your exposure drifts mid-call.
- **Turn off any auto-dimming / logo-detection / static-image protection** if you can find it.
  Some sets dim a static bright image after a couple of minutes; that shows up as the call
  slowly getting darker.
- On the Apple TV: **Settings → Video and Audio → Match Content → Match Dynamic Range: Off.**
  Keeps the TV from flipping into an HDR mode with a different tone curve.

**OLED owners:** peak brightness on an OLED is limited by total lit area (the auto brightness
limiter). A **Softbox** covering ~60–70% of the panel measures brighter at your face than a
full-field white raster, and it puts less total charge through the panel. Use Softbox or Ring
rather than Flat. Leave **Burn-in Guard** on (it's on by default).

---

## Regenerating the app icon

The icon and top-shelf art are generated, not hand-drawn. To change the look, edit the colour
maths in `Tools/generate_icons.py` and re-run:

```bash
python3 Tools/generate_icons.py Keylight
```

It rewrites `Keylight/Assets.xcassets` in place — layered parallax icon (400×240 and
1280×768), plus both top-shelf sizes.

---

## Project layout

```
Keylight.xcodeproj
Keylight/
  KeylightApp.swift            app entry point
  Model/
    ColorScience.swift         Kelvin -> CIE xy -> sRGB, tint, transfer function
    LightState.swift           the light as one Codable value + presets
    LightStore.swift           observable owner, debounced persistence, auto-off
  Input/
    MoveAccelerator.swift      hold-to-accelerate for remote presses
  Views/
    ContentView.swift          root, remote handling, timers, overlay coordination
    LightStageView.swift       the six light shapes
    HUDView.swift              transient readout
    ControlPanelView.swift     bottom sheet with every control
    PanelComponents.swift      Chip, ValueRow, SectionHeader
    CalibrationView.swift      camera test card
    HelpOverlay.swift          controls cheat sheet
  Assets.xcassets/             generated icon + top shelf
Tools/generate_icons.py
```

The target uses an Xcode 16+ **file-system synchronized group**, so any `.swift` file you drop
into `Keylight/` is compiled automatically — no need to add it to the target by hand.

---

## Troubleshooting

**"No available simulator runtimes for platform appletvsimulator"** — Step 0 above.

**Apple TV never appears in Devices and Simulators** — it's almost always the network. Both
devices must be on the same subnet; guest networks, client isolation, and split 2.4/5 GHz SSIDs
all break discovery. Turning the Apple TV's screen to *Remote App and Devices* and leaving it
there while you look in Xcode is what actually advertises it.

**"Untrusted Developer" on launch** — Step 4, item 3.

**App quits back to the home screen after a while** — that's the screensaver taking over. The
app disables the idle timer on launch, so this only happens if it lost foreground. Relaunch it.

**Light looks green or magenta on camera** — that's your camera's white balance, not the light.
Open the panel → Tools → **Camera Test Card**, lock your camera's white balance on the 18% grey
patch, then go back to the light. If it still skews, trim **Tint** (the panel's ±green axis).
