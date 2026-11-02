# Standards

Versions and official guidance this project is built against. Recheck any entry older than
90 days, or when a new framework is added.

## Toolchain on this machine

| Item | Version here | Checked | Source |
|---|---|---|---|
| Xcode | **26.6** (17F113) | 2026-11-02 | `xcodebuild -version` |
| tvOS SDK | 26.5 | 2026-11-02 | `xcodebuild -showsdks` |
| macOS (host) | 26.5.2 | 2026-11-02 | `sw_vers` |
| Swift language mode | 5 (`SWIFT_VERSION = 5.0`) | 2026-11-02 | project build settings |

## Current Apple releases

| Item | Current stable | Checked | Source |
|---|---|---|---|
| Xcode | **27.2** | 2026-11-02 | [developer.apple.com/support/xcode](https://developer.apple.com/support/xcode/) |
| Swift compiler (in Xcode 27.2) | 6.4 | 2026-11-02 | same |
| SDKs in Xcode 27.2 | iOS / tvOS / watchOS / visionOS / macOS 27.2 | 2026-11-02 | same |
| Xcode 27.2 host requirement | macOS Tahoe **26.6** or later | 2026-11-02 | same |
| Supported deployment targets | iOS 15–27, macOS 12–27, tvOS 17+ devices | 2026-11-02 | same |

### Finding worth flagging

**This machine is a major version behind.** Xcode here is 26.6; current stable is 27.2.
Upgrading is blocked by the host OS: Xcode 27.2 needs macOS 26.6 or later and this Mac runs
26.5.2, so a macOS update has to come first.

Nothing in the project is broken by this. Both deployment targets remain supported by Xcode 27
(tvOS 17 is still the floor for device support, macOS 14 sits inside the macOS 12–27 range), so
the projects should open and build on 27.2 unchanged. Swift 6.4 would default new projects to
Swift 6 language mode; these targets pin `SWIFT_VERSION = 5.0` with
`SWIFT_STRICT_CONCURRENCY = minimal`, which stays valid — Xcode 27 still lists Swift 5 as a
supported language mode.

## Frameworks and APIs in use

| API | Where | Minimum | Notes |
|---|---|---|---|
| `@Observable` (Observation) | both apps | tvOS 17 / macOS 14 | replaces `ObservableObject` |
| `onMoveCommand` / `onPlayPauseCommand` / `onExitCommand` | tvOS | tvOS 13+ | fires when the focus engine does not consume the input |
| `focusEffectDisabled()` | tvOS | tvOS 17 | does **not** fully suppress a built-in button style's focus treatment — see below |
| `defaultFocus(_:_:)` | tvOS | tvOS 17 | |
| `PBXFileSystemSynchronizedRootGroup` | both projects | Xcode 16+ | folder-synced targets; no per-file entries in the pbxproj |
| `CGWindowLevelForKey` | macOS | — | `.desktopIconWindow + 1` for behind-apps, `.floatingWindow + 1` for in-front |
| `NSPanel` `.nonactivatingPanel` | macOS | — | control box does not steal focus from Teams/Zoom |
| `AVCaptureDevice.isInUseByAnotherApplication` | macOS | — | reports *other* processes; opt-in, polled every 2 s |
| `AVCaptureDevice.DeviceType.external` | macOS | macOS 14 | |
| `NSRunningApplication.activate()` | macOS | macOS 14 | no-argument form; `activateIgnoringOtherApps` deprecated in 14 |
| `SMAppService.mainApp` | macOS | macOS 13 | login item, no helper bundle |
| `ProcessInfo.beginActivity(.idleDisplaySleepDisabled)` | macOS | — | holds the display awake while lit |

### Platform behaviour learned the hard way

**tvOS focus highlight on a transparent button.** The built-in button styles — `.plain`
included — brighten a focused button's label while a finger rests on the Siri Remote
touchpad. A full-screen label at `Color.white.opacity(0.001)` therefore composites to solid
white on real hardware while looking perfect in the Simulator. `focusEffectDisabled()` does not
suppress it. A custom `ButtonStyle` returning only `configuration.label` does.

**`@Environment(\.isFocused)` reports the nearest focusable _ancestor_.** Applying
`.focusable()` to a view and reading `isFocused` inside that same view's body always returns
false. Use `@FocusState` + `.focused($flag)` and pass the value down, or put the focusable on a
genuine ancestor (which is why `Button { } label: { }` works).

**tvOS app icons require the tvOS Simulator runtime**, even for a device-only build.
`actool` fails with *"No available simulator runtimes for platform appletvsimulator"* —
misleading, because the asset catalog is fine. Fix: `xcodebuild -downloadPlatform tvOS`.

**`devicectl device capture screenshot` does not work against tvOS.** Returns
`CoreDeviceError 25004`. Apple TV screenshots have to come off the device by hand.
