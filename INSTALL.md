# Install CJ's Keylight for Mac

One script builds the Mac app from source and installs it to `/Applications`. Building from
source needs **Xcode** (the full app, not just the Command Line Tools) and **macOS 14 or
later**. There's no prebuilt download to trust, no Gatekeeper prompt and no signing setup.

Repos: `cj/appletv-keylight-white-screen` on TANSTAFL (`tanstafl.devservers1313.space`, private,
the source) and `github.com/cjcombsMedia/appletv-keylight-white-screen` (public, the second copy).

## The easy way

CJ's MacTools → App Updater → CJ's Keylight → **Install** (or **Update**). It clones from
TANSTAFL and runs the same script as below.

## Ask Claude to do it

On the other Mac, open Claude Code and say:

> Pull github.com/cjcombsMedia/appletv-keylight-white-screen and follow INSTALL.md to install
> CJ's Keylight for Mac.

## Instructions for Claude

1. **Get the code.**
   - If the repo is already on this Mac (check `~/PROJECTS/appletv-keylight-white-screen`),
     `cd` into it and run `git status`. If there are local changes, stop and ask before pulling.
     Otherwise skip to step 2 and run `./install-mac.sh --pull`, which pulls `main` from
     TANSTAFL (then GitHub) before it builds.
   - If it isn't there and `ghx` is installed, clone it from TANSTAFL and link the GitHub copy:
     `ghx clone tanstafl cj/appletv-keylight-white-screen ~/PROJECTS/appletv-keylight-white-screen`,
     then in that folder `ghx link personal cjcombsMedia/appletv-keylight-white-screen`.
     With `ghx` but no TANSTAFL account, use `ghx clone personal cjcombsMedia/appletv-keylight-white-screen ~/PROJECTS/appletv-keylight-white-screen`.
     Without `ghx`, use plain `git clone https://github.com/cjcombsMedia/appletv-keylight-white-screen.git ~/PROJECTS/appletv-keylight-white-screen`.
     The GitHub copy is public, so no sign-in is needed.
2. **Run the installer** from the repo root: `./install-mac.sh` (or `./install-mac.sh --pull`
   to update an existing clone)
   It finds Xcode even when `xcode-select` points at the Command Line Tools, builds Release,
   quits any running copy, installs `/Applications/CJ's Keylight.app` (removing an old
   `/Applications/Keylight.app` from before the rename), and launches it.
3. **Check it worked.** The script ends with `Done: CJ's Keylight (commit …) is in /Applications.`
   and `pgrep -x Keylight` returns a process ID. The process keeps the short name on purpose. If the build fails, the script prints the
   compiler errors. Report them, and don't change signing settings to get past them.
4. **Tell CJ** to look for the lightbulb in the menu bar. The control box opens in the
   bottom-right of the main display.

## Doing it by hand

With `ghx`:

```bash
ghx clone tanstafl cj/appletv-keylight-white-screen
```

```bash
cd appletv-keylight-white-screen && ghx link personal cjcombsMedia/appletv-keylight-white-screen && ./install-mac.sh
```

Without `ghx` (the GitHub copy is public):

```bash
git clone https://github.com/cjcombsMedia/appletv-keylight-white-screen.git
```

```bash
cd appletv-keylight-white-screen && ./install-mac.sh
```

To update later, use `./install-mac.sh --pull`. It refuses to run over uncommitted changes,
switches to `main` and pulls it through `ghx` from the highest-priority account the clone has a
remote for (TANSTAFL first, then GitHub personal; plain git from `origin` without `ghx`), then
rebuilds and reinstalls. Your settings live in the app's preferences, not in the app bundle,
so they survive reinstalls.

## Notes

- **Renamed from Keylight:** if *Open at login* was on before the rename, switch it off and on
  again once so macOS registers the new `CJ's Keylight.app`.
- **Open at login:** turn it on *after* installing, from the control box under **More**. That
  way macOS registers the copy in `/Applications`.
- **No Xcode?** Install it from the App Store, open it once to finish setup, then re-run the
  script.
- The Apple TV app is a separate install. See [SETUP.md](SETUP.md).
