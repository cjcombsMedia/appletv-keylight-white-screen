# Install CJ's Keylight for Mac

One script builds the Mac app from source and installs it to `/Applications`. Building from
source needs **Xcode** (the full app, not just the Command Line Tools) and **macOS 14 or
later**. There's no prebuilt download to trust, no Gatekeeper prompt and no signing setup.

## Ask Claude to do it

On the other Mac, open Claude Code and say:

> Pull github.com/cjcombsMedia/appletv-keylight-white-screen and follow INSTALL.md to install
> CJ's Keylight for Mac.

## Instructions for Claude

1. **Get the code.**
   - If the repo is already on this Mac (check `~/PROJECTS/appletv-keylight-white-screen`),
     `cd` into it and run `git status`. If there are local changes, stop and ask before pulling.
     Otherwise pull, using `ghx pull personal` if `ghx` is installed, or `git pull --ff-only`
     if it isn't.
   - If it isn't there, clone it with `ghx clone personal cjcombsMedia/appletv-keylight-white-screen ~/PROJECTS/appletv-keylight-white-screen`
     if `ghx` is installed. If not, use plain `git clone https://github.com/cjcombsMedia/appletv-keylight-white-screen.git ~/PROJECTS/appletv-keylight-white-screen`.
     The repo is public, so no sign-in is needed.
2. **Run the installer** from the repo root: `./install-mac.sh`
   It finds Xcode even when `xcode-select` points at the Command Line Tools, builds Release,
   quits any running copy, installs `/Applications/CJ's Keylight.app` (removing an old
   `/Applications/Keylight.app` from before the rename), and launches it.
3. **Check it worked.** The script ends with `Done: CJ's Keylight (commit …) is in /Applications.`
   and `pgrep -x Keylight` returns a process ID. The process keeps the short name on purpose. If the build fails, the script prints the
   compiler errors. Report them, and don't change signing settings to get past them.
4. **Tell CJ** to look for the lightbulb in the menu bar. The control box opens in the
   bottom-right of the main display.

## Doing it by hand

```bash
git clone https://github.com/cjcombsMedia/appletv-keylight-white-screen.git
```

```bash
cd appletv-keylight-white-screen && ./install-mac.sh
```

To update later, use `./install-mac.sh --pull`. It refuses to run over uncommitted changes,
pulls `main` (through `ghx pull personal` when `ghx` is installed, otherwise
`git pull --ff-only`), then rebuilds and reinstalls. Your settings live in the app's preferences, not in the app bundle,
so they survive reinstalls.

## Notes

- **Renamed from Keylight:** if *Open at login* was on before the rename, switch it off and on
  again once so macOS registers the new `CJ's Keylight.app`.
- **Open at login:** turn it on *after* installing, from the control box under **More**. That
  way macOS registers the copy in `/Applications`.
- **No Xcode?** Install it from the App Store, open it once to finish setup, then re-run the
  script.
- The Apple TV app is a separate install. See [SETUP.md](SETUP.md).
