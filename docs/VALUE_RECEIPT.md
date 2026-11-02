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
| Tokens (all types) | **102,538,606** (measured) |
| Estimated API-equivalent cost | **~$271** (ESTIMATE) |
| Active build time | **2.60 h** (measured) |
| Manual-equivalent effort | **~50 h** (ESTIMATE) |
| Hours saved | **~47.4 h** (ESTIMATE) |
| Value at $100/hr | **~$4,740** (ESTIMATE) |

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
