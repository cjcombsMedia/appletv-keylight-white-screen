#!/bin/bash
# Build Keylight for Mac from this checkout and install it to /Applications.
#
#   ./install-mac.sh            build, install, launch
#   ./install-mac.sh --pull     git pull --ff-only first, then the above
#   ./install-mac.sh --no-launch
#
# Needs Xcode (not just the Command Line Tools). Works whichever developer directory
# xcode-select points at: if it's the Command Line Tools, Xcode is used for this run only
# via DEVELOPER_DIR, and the system setting is left alone.

set -euo pipefail

APP_NAME="Keylight"
PROJECT="KeylightMac/KeylightMac.xcodeproj"
SCHEME="KeylightMac"
DEST="/Applications/${APP_NAME}.app"

pull=false
launch=true
for arg in "$@"; do
    case "$arg" in
        --pull)      pull=true ;;
        --no-launch) launch=false ;;
        -h|--help)   sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)           echo "Unknown option: $arg (try --help)" >&2; exit 2 ;;
    esac
done

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[31mFAILED:\033[0m %s\n' "$*" >&2; exit 1; }

cd "$(dirname "$0")"
[[ "$(uname)" == "Darwin" ]] || fail "Keylight for Mac only builds on macOS."
[[ -d "$PROJECT" ]] || fail "Can't find $PROJECT — run this from the repo root."

# --- Xcode ---------------------------------------------------------------------------
if ! xcodebuild -version >/dev/null 2>&1; then
    xcode=""
    for candidate in /Applications/Xcode.app /Applications/Xcode-beta.app; do
        [[ -d "$candidate" ]] && { xcode="$candidate"; break; }
    done
    if [[ -z "$xcode" ]]; then
        xcode="$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null | head -1)"
    fi
    [[ -n "$xcode" ]] || fail "Xcode isn't installed. Install it from the App Store, open it once, then re-run."
    export DEVELOPER_DIR="$xcode/Contents/Developer"
    echo "xcode-select points at the Command Line Tools; using $xcode for this build."
fi
xcodebuild -version | head -1

# --- Source --------------------------------------------------------------------------
if $pull; then
    step "Pulling latest"
    git pull --ff-only
fi
commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "Building commit $commit"

# --- Build ---------------------------------------------------------------------------
step "Building $APP_NAME (Release)"
derived="$(mktemp -d "${TMPDIR:-/tmp}/keylight-build.XXXXXX")"
trap 'rm -rf "$derived"' EXIT
log="$derived/build.log"
if ! xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
        -derivedDataPath "$derived" build >"$log" 2>&1; then
    grep -E "error:" "$log" | sort -u | head -20 >&2 || true
    fail "Build failed. Full log was at $log (deleted on exit; re-run with the build command above to keep it)."
fi
built="$derived/Build/Products/Release/${APP_NAME}.app"
[[ -d "$built" ]] || fail "Build reported success but $built is missing."
echo "Build succeeded."

# --- Install -------------------------------------------------------------------------
step "Installing to $DEST"
if pgrep -xq "$APP_NAME"; then
    osascript -e "quit app \"$APP_NAME\"" >/dev/null 2>&1 || true
    for _ in {1..20}; do pgrep -xq "$APP_NAME" || break; sleep 0.25; done
fi
rm -rf "$DEST"
ditto "$built" "$DEST"
# Receipt for CJ's MacTools > App Updater: which commit this Mac now runs.
( set +e
  dir="$HOME/Library/Application Support/CJ Apps/receipts"; mkdir -p "$dir"
  top=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
  dirty=false; [ -n "$(git -C "$top" status --porcelain)" ] && dirty=true
  printf '{"bundleId":"%s","commit":"%s","branch":"%s","dirty":%s,"source":"%s","installedAt":"%s","mac":"%s"}\n' \
    "com.cjcombs.KeylightMac" "$(git -C "$top" rev-parse HEAD)" "$(git -C "$top" rev-parse --abbrev-ref HEAD)" "$dirty" \
    "$top" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(scutil --get ComputerName)" > "$dir/com.cjcombs.KeylightMac.json"
) || true
echo "Installed."

if $launch; then
    step "Launching"
    open "$DEST"
    for _ in {1..20}; do pgrep -xq "$APP_NAME" && break; sleep 0.25; done
    pgrep -xq "$APP_NAME" || fail "Installed, but $APP_NAME didn't start. Try: open \"$DEST\""
    echo "Running — look for the lightbulb in the menu bar."
fi

printf '\n\033[32mDone:\033[0m %s (commit %s) is in /Applications.\n' "$APP_NAME" "$commit"
