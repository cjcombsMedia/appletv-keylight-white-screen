#!/bin/bash
# Build CJ's Keylight for Mac from this checkout and install it to /Applications.
#
#   ./install-mac.sh            build, install, launch
#   ./install-mac.sh --pull     switch to main and pull it first (TANSTAFL, then GitHub, through
#                               ghx when installed), then the above; refuses uncommitted changes
#   ./install-mac.sh --no-launch
#
# Needs Xcode (not just the Command Line Tools). Works whichever developer directory
# xcode-select points at: if it's the Command Line Tools, Xcode is used for this run only
# via DEVELOPER_DIR, and the system setting is left alone.

set -euo pipefail

# PRODUCT_NAME, and so the executable and the process name, stays "Keylight"; only the
# installed bundle and what people see carry the "CJ's" name.
APP_NAME="Keylight"
DISPLAY_NAME="CJ's Keylight"
BUNDLE_ID="com.cjcombs.KeylightMac"
PROJECT="KeylightMac/KeylightMac.xcodeproj"
SCHEME="KeylightMac"
DEST="/Applications/${DISPLAY_NAME}.app"
OLD_DEST="/Applications/${APP_NAME}.app"

pull=false
launch=true
for arg in "$@"; do
    case "$arg" in
        --pull)      pull=true ;;
        --no-launch) launch=false ;;
        -h|--help)   sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)           echo "Unknown option: $arg (try --help)" >&2; exit 2 ;;
    esac
done

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[31mFAILED:\033[0m %s\n' "$*" >&2; exit 1; }

# The highest-priority ghx account (the order `ghx accounts` lists: TANSTAFL, then GitHub
# personal, then work) that has a remote in the clone at $1. Prints nothing if none does.
# Same function as CJ's MacTools' install-mac.sh.
pull_account() {  # $1 = clone folder
  local mapped a
  mapped=$(cd "$1" && ghx status 2>/dev/null | awk '/^REMOTE +ACCOUNT/ {t=1; next} t && NF >= 3 {print $2}')
  for a in $(ghx accounts 2>/dev/null | awk 'NR > 1 && NF >= 3 && $1 !~ /^•/ {print $1}'); do
    if printf '%s\n' "$mapped" | grep -qx "$a"; then echo "$a"; return 0; fi
  done
}

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
    step "Pulling the latest main"
    [[ -z "$(git status --porcelain)" ]] || fail "Uncommitted changes here — commit or stash them, then re-run with --pull."
    [[ "$(git rev-parse --abbrev-ref HEAD)" == main ]] || { echo "Switching to main"; git switch --quiet main; }
    if command -v ghx >/dev/null 2>&1; then
        account=$(pull_account .)
        [[ -n "$account" ]] || fail "This clone has no remote for any ghx account (ghx status shows them). Add one: ghx link tanstafl cj/appletv-keylight-white-screen"
        echo "Pulling main from $account"
        ghx pull "$account" main --ff-only
    else
        # Plain git: origin when there is one (git clone names it that), else the first remote.
        remote=origin
        git remote | grep -qx origin || remote=$(git remote | head -1)
        git pull --ff-only "$remote" main
    fi
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
    osascript -e "quit app id \"$BUNDLE_ID\"" >/dev/null 2>&1 || true
    for _ in {1..20}; do pgrep -xq "$APP_NAME" || break; sleep 0.25; done
fi
rm -rf "$DEST"
ditto "$built" "$DEST"
# Builds before the rename installed as Keylight.app; don't leave two copies.
[[ -d "$OLD_DEST" ]] && rm -rf "$OLD_DEST" && echo "Removed the old $OLD_DEST"
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
    pgrep -xq "$APP_NAME" || fail "Installed, but $DISPLAY_NAME didn't start. Try: open \"$DEST\""
    echo "Running — look for the lightbulb in the menu bar."
fi

printf '\n\033[32mDone:\033[0m %s (commit %s) is in /Applications.\n' "$DISPLAY_NAME" "$commit"
