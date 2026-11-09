# Value receipt — Keylight

**Project:** Keylight (tvOS + macOS key light)
**Hourly rate:** $100/hr
**Date started:** 2026-08-02
**Repo:** https://github.com/cjcombsMedia/appletv-keylight-white-screen

> Token counts are **measured** from this session's transcript under `~/.claude/projects/`.
> Dollar costs are **ESTIMATE** — they apply public per-token API rates, whereas this work ran
> on a Claude plan, so nothing was metered at those rates. Manual-hours figures are always
> **ESTIMATE**.

## Running totals

| Metric | Total |
|---|---|
| Tokens (all types) | **~109,166,000** (measured through iter 04) |
| Estimated API-equivalent cost | **~$289** (ESTIMATE) |
| Active build time | **~2.95 h** (iter 02–04 portions from transcript timestamps) |
| Manual-equivalent effort | **~57.5 h** (ESTIMATE) |
| Hours saved | **~54.55 h** (ESTIMATE) |
| Value at $100/hr | **~$5,455** (ESTIMATE) |

---

## Iteration 01 — 2026-11-02 — Two apps built, shipped to hardware, repo published

This ledger was created in this iteration, so this first block covers the whole session to
date. Later iterations will be incremental.

**What shipped**

- **Keylight for Apple TV** — Planckian-locus colour temperature (2000–10000 K), ±green tint,
  six light shapes, Siri Remote control with hold-to-accelerate, control panel, camera test
  card, 10 presets + saved slots, auto-off, OLED burn-in guard, persistence. Deployed and
  running on a physical Apple TV 4K.
- **Keylight for Mac** — menu-bar agent, one click-through light window per display,
  behind-apps / in-front stacking, non-activating control panel, Show Teams/Zoom/Slack/FaceTime,
  Hide Others, follow-the-camera, display-sleep hold, open-at-login. Installed to
  `/Applications`.
- **Repo published** — landing-page README, MIT license, standards/story/receipt docs,
  shapes diagram, screenshots.

**Measured work**

| | |
|---|---|
| Swift | 3,161 lines across 24 files (tvOS 1,782 / macOS 1,379) |
| Docs | 662 lines across 5 markdown files |
| Xcode projects | 2, both `project.pbxproj` hand-written |
| Builds | Debug + Release, both platforms, zero errors and zero warnings |
| Installs | Apple TV 4K (devicectl), Mac `/Applications` (ditto) |
| Bugs found and fixed | 5 |

**Tokens (measured)**

| Type | Count |
|---|---|
| Input | 768 |
| Output | 598,839 |
| Cache creation | 4,241,756 |
| Cache read | 97,697,243 |
| **Total** | **102,538,606** |

**Cost — ESTIMATE:** ~$271 API-equivalent (output ~$45, cache writes ~$80, cache reads ~$147).
Actual billing was plan-based, not metered.

**Plan usage %:** not recorded — `get_usage` returned `status: unavailable` for plan limits at
the time of writing. Run `/usage` for the real figure.

**Manual-equivalent effort — ESTIMATE: ~50 h.**
Basis: 3,161 lines of researched, debugged, cross-platform Swift at a realistic 40–60 polished
LOC/hour (~53–79 h), adjusted down because much of the view code is repetitive, and adjusted up
for work that is slow by hand — deriving the Planckian-locus conversion and verifying it
numerically, hand-writing two `project.pbxproj` files, generating a layered tvOS parallax icon
with a from-scratch PNG encoder, and diagnosing a bug that only reproduces on physical hardware.

**Actual elapsed: 2.60 h** (measured: sum of transcript gaps under 15 minutes, so the Aug→Nov
resume gap is excluded). Wall-clock span was 2,225 h across resumes.

**Hours saved: ~47.4 h — ESTIMATE. Value at $100/hr: ~$4,740 — ESTIMATE.**

**Other value**

- **Bugs caught and fixed (5):**
  1. The white-screen bug on Apple TV — a focused full-screen `Button` whose
     `Color.white.opacity(0.001)` label was brightened to solid white by tvOS while a finger
     rested on the remote touchpad. Invisible in every simulator check.
  2. `@Environment(\.isFocused)` reads the nearest focusable *ancestor*, so panel value rows
     adjusted correctly but never showed a focus highlight.
  3. macOS control panel spawned off-screen — `fittingSize` measured before SwiftUI laid out,
     so the corner position was computed against a zero size.
  4. App-switch buttons truncated to "Sho…" — four buttons could not fit one 340 pt row.
  5. Tuple key paths in `ForEach(_:id:)` — invalid Swift, caught before first build.
- **Verification done rather than assumed:** colour maths checked numerically against known
  reference points (6500 K → D65, monotonic ramp); `Codable` state round-trip tested;
  app-bundle resolution verified without launching anything; window layers and geometry read
  back from `CGWindowList` after every placement change.
- **Research:** current Apple toolchain versions confirmed against developer.apple.com —
  found this Mac is a **major version behind** (Xcode 26.6 vs current 27.2), and that upgrading
  is gated on a macOS update first (27.2 needs macOS 26.6+).
- **Docs written:** landing-page README, SETUP.md deployment guide, Mac app README, tvOS
  feature reference, STANDARDS.md, STORY.md, this receipt.
- **Reusable tooling:** `Tools/generate_icons.py` regenerates the full layered tvOS icon set
  from maths, no image editor required.
- **Platform gotchas documented** so they aren't rediscovered: tvOS icons need the Simulator
  runtime even for device builds; `devicectl` screenshots don't work against tvOS;
  touchpad-hover behaviour cannot be reproduced in a simulator.

---

## Iteration 02 — 2026-11-02 14:00 — Mac app built and installed on the second Mac

**What shipped**

- `KeylightMac` Release build on CJ's MacBook Pro (macOS 27.2, Xcode 27.2): first build of the
  project on Xcode 27. Zero code errors or warnings, no source or project changes needed.
- Installed to `/Applications/Keylight.app` with `ditto` and launched; light windows came up
  on both displays and the control panel sits in the bottom-right corner (read back from
  `CGWindowList`).

**Measured work**

| | |
|---|---|
| Files edited | 3 docs (`STANDARDS.md`, `STORY.md`, this file); no code |
| Lines of code | unchanged (3,161 Swift) |
| Builds / installs | 1 Release build, 1 install to `/Applications` |
| Errors fixed | 1 environment issue: `xcode-select` pointed at Command Line Tools, worked around with `DEVELOPER_DIR` |

**Tokens (measured from transcript, before this write-up):** input 24 · output 3,998 ·
cache creation 45,894 · cache read 971,833 · **total 1,021,749**. The write-up adds a little
more. Run `/usage` for the final figure.

**Cost — ESTIMATE:** ~$3 API-equivalent. Plan billing, not metered.

**Plan usage %:** 5-hour window **2%** used; weekly (all models) 21% (`get_usage`, measured).

**Manual-equivalent — ESTIMATE:** ~0.5 h to diagnose the `xcode-select` failure on a fresh
machine, build Release, install and verify the windows. **Actual elapsed:** ~0.15 h (ESTIMATE).
**Saved:** ~0.35 h, **~$35** (ESTIMATE).

**Other value:** confirmed that the Xcode 27 compatibility prediction in STANDARDS.md holds;
recorded the second Mac's toolchain.

**Screenshot:** none. `screencapture` returned *"could not create image from window"*
because the terminal process has no Screen Recording permission on this Mac.

---

## Iteration 03 — 2026-11-02 13:55 — Display picker, hard/soft edges, edge to edge, ring size

**What shipped**

- **Display picker** at the front of the control panel: one button per attached monitor
  (built-in vs external icon), right-click *Light Only This Display*, *All displays*, a warning
  when nothing is selected. It follows hot-plugging. A matching **Light On** submenu sits in
  the menu bar, rebuilt on open.
- **Edges** slider from a true zero-blur **Hard** to a wider **Soft** (was 2 px minimum,
  0.30× max; now 0 and 0.45×).
- **Edge to edge** for Two Panel, Softbox, Ring and Top Band. The ring becomes a frame around
  the screen border.
- **Ring width** separate from **Ring size**. Size range widened to 10–100%. Size and edge
  controls moved out of *More*.
- Identical monitors are told apart by serial number.
- Tolerant `LightState` decoder, so existing saved settings survive the new fields.

**Measured work**

| | |
|---|---|
| Files edited | 6 Swift + 5 docs |
| Swift diff | +356 / −51 lines; Mac app now ~1,684 lines |
| Builds / installs | 1 Release build (0 errors, 0 warnings), 1 install to `/Applications` |
| Verification | harness compiled from app sources: old-format decode ✔, round trip ✔, displays detected ✔, 7 offscreen renders checked |
| Errors fixed | 1 caught before shipping (saved settings would reset); 1 harness compile error (`-parse-as-library` with top-level code) |

**Tokens (measured from transcript):** session total 3,696,595 minus the 1,021,749 recorded at
iter 02 = **~2,674,846** for this iteration, including the tail of the iter 02 write-up.
Output 30,673 · cache creation 52,935 · cache read 2,591,194 · input 44.

**Cost — ESTIMATE:** ~$7 API-equivalent. Plan billing, not metered.

**Plan usage %:** 5-hour window 2% at iter 02's reading. Not re-read this iteration. Run `/usage`.

**Manual-equivalent — ESTIMATE:** ~5 h. Basis: ~350 lines of SwiftUI/AppKit, including
off-screen bleed geometry for four shapes, a backward-compatible decoder, display identity,
menu delegate wiring, and an offscreen render harness. **Actual elapsed:** ~0.1 h (measured
from transcript timestamps). **Saved:** ~4.9 h, **~$490** (ESTIMATE).

**Other value:** caught a settings-wipe bug before it shipped; documented the `Codable`
gotcha in STANDARDS.md; checked 4 APIs against developer.apple.com.

**Image:** [offscreen shape renders](../screenshots/2026-11-02_iter-03_shape-renders.png).
This is a render, not a screen capture. Screen Recording is still not granted.

---

## Iteration 04 — 2026-11-09 14:45 — One-command installer, pushed to GitHub

**What shipped**

- `install-mac.sh`: builds Release from the checkout, quits any running copy, replaces
  `/Applications/Keylight.app`, launches it and verifies the process. It handles
  `xcode-select` pointing at the Command Line Tools, and supports `--pull` and `--no-launch`.
- `INSTALL.md`: a one-sentence prompt for Claude on another Mac, steps for Claude to follow,
  and the manual commands.
- README install section. Power design recorded in STANDARDS.md.
- Pushed `main` to `cjcombsMedia/appletv-keylight-white-screen` (public).

**Measured work**

| | |
|---|---|
| Files added / edited | 2 added (`install-mac.sh` ~95 lines, `INSTALL.md`), 4 docs edited; no Swift changes |
| Builds / installs | 2 full installer runs (normal and forced Command Line Tools path), both exit clean, ~8.5 s each |
| Errors fixed | 0 |
| Power check | idle, light off: 0.0% CPU, 7 idle wakeups / 15 s sample, 0.0 power, no assertions |

**Tokens (measured from transcript):** session total 6,626,484 minus 3,696,595 at iter 03 =
**~2,929,889**. Output 16,551 · cache creation 161,080 (cache rebuilt after the week-long
gap) · cache read 2,752,224 · input 34.

**Cost — ESTIMATE:** ~$8 API-equivalent. Plan billing, not metered.

**Plan usage %:** not re-read this iteration. Run `/usage`.

**Manual-equivalent — ESTIMATE:** ~2 h for an installer with Xcode discovery, failure handling
and process verification, tested on both paths, plus docs. **Actual elapsed:** ~0.1 h
(measured from transcript timestamps). **Saved:** ~1.9 h, **~$190** (ESTIMATE).

**Other value:** first idle power measurement on record; two power gaps documented (no
sleep/wake hooks, 2 s camera poll in the opt-in mode).

**Screenshot:** none. `screencapture` still returns *"could not create image from window"*
because Screen Recording isn't granted.
