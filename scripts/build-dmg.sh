#!/bin/bash
# Build dist/Bandwidth-Meter-<version>.dmg from the app `make app` built.
#
# The disk image holds:
#   Install.pkg     app to /Applications, CLI to /usr/local/bin
#   Uninstall.app   asks, then removes both (and, if you say so, the saved
#                   data in ~/Library)
#   .background/    the window artwork (hidden)
#
# Unsigned by default. Set these to sign and notarize (see RELEASING.md):
#   DEVELOPER_ID_APP        "Developer ID Application: Name (TEAMID)", signs the
#                           app, the CLI, the uninstaller, and the disk image
#   DEVELOPER_ID_INSTALLER  "Developer ID Installer: Name (TEAMID)", signs the pkg
#   NOTARY_PROFILE          a `xcrun notarytool store-credentials` profile name;
#                           submits the disk image and staples the ticket
#
# Other knobs:
#   DMG_LAYOUT=plain        skip dmgbuild and the window layout (hdiutil only)
#   DMGBUILD=/path/dmgbuild use this dmgbuild instead of the pinned venv copy
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Bandwidth Meter"
APP_ID="dev.ashahin.BandwidthMeter"
PKG_ID="dev.ashahin.BandwidthMeter.pkg"
DIST_DIR="${DIST_DIR:-dist}"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
WORK="${WORK_DIR:-.build/package}"
DMGBUILD_VERSION="1.6.7"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
DMG="$DIST_DIR/Bandwidth-Meter-$VERSION.dmg"
# Short names so the Finder labels fit on one line, even with "Show all
# filename extensions" on. The window title and artwork name the app.
PKG_NAME="Install.pkg"
UNINSTALLER_NAME="Uninstall.app"

: "${DEVELOPER_ID_APP:=}"
: "${DEVELOPER_ID_INSTALLER:=}"
: "${NOTARY_PROFILE:=}"
: "${DMG_LAYOUT:=}"

step() { printf '==> %s\n' "$*"; }

if [[ ! -x "$APP_BUNDLE/Contents/MacOS/BandwidthMeter" || ! -x "$APP_BUNDLE/Contents/Helpers/bandwidth-meter" ]]; then
	echo "$APP_BUNDLE is missing or has no Helpers/bandwidth-meter. Run make app first." >&2
	exit 1
fi
if [[ -n "$NOTARY_PROFILE" && ( -z "$DEVELOPER_ID_APP" || -z "$DEVELOPER_ID_INSTALLER" ) ]]; then
	echo "NOTARY_PROFILE needs DEVELOPER_ID_APP and DEVELOPER_ID_INSTALLER too." >&2
	exit 1
fi

rm -rf "$WORK"
mkdir -p "$WORK/root" "$WORK/resources" "$WORK/packages"
rm -f "$DIST_DIR"/*.zip "$DIST_DIR"/*.dmg

# --- App payload ------------------------------------------------------------
step "staging $APP_NAME.app $VERSION"
ditto --norsrc --noextattr --noacl "$APP_BUNDLE" "$WORK/root/$APP_NAME.app"
find "$WORK/root" -name .DS_Store -delete

if [[ -n "$DEVELOPER_ID_APP" ]]; then
	step "signing with $DEVELOPER_ID_APP"
	codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APP" \
		"$WORK/root/$APP_NAME.app/Contents/Helpers/bandwidth-meter"
	codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APP" \
		"$WORK/root/$APP_NAME.app"
fi
codesign --verify --strict --deep "$WORK/root/$APP_NAME.app"

# --- Component package ------------------------------------------------------
step "building the component package"
pkgbuild --analyze --root "$WORK/root" "$WORK/component.plist" >/dev/null
# Install to /Applications even if another copy of the app lives elsewhere,
# and replace an older version in place.
plutil -replace 0.BundleIsRelocatable -bool NO "$WORK/component.plist"
plutil -replace 0.BundleIsVersionChecked -bool NO "$WORK/component.plist"
plutil -replace 0.BundleOverwriteAction -string upgrade "$WORK/component.plist"
plutil -replace 0.BundleHasStrictIdentifier -bool YES "$WORK/component.plist"

pkgbuild \
	--root "$WORK/root" \
	--component-plist "$WORK/component.plist" \
	--identifier "$PKG_ID" \
	--version "$VERSION" \
	--install-location /Applications \
	--scripts packaging/pkg-scripts \
	--ownership recommended \
	"$WORK/packages/BandwidthMeter-component.pkg" >/dev/null

# pkgbuild turns every extended attribute into an AppleDouble "._" entry in
# the payload. Recent macOS tags each new file with com.apple.provenance, which
# can't be cleared, so a local build would ship a ._ twin for every file and
# list them in the receipt. Rebuild the payload, Bom, and scripts without them.
strip_appledouble() {
	local pkg="$1" x="$WORK/component-expanded" files
	if ! pkgutil --payload-files "$pkg" | grep -q '/\._'; then
		return
	fi
	rm -rf "$x"
	pkgutil --expand "$pkg" "$x"
	(cd "$WORK/root" && find . | COPYFILE_DISABLE=1 cpio -o --quiet --format odc -R 0:0) |
		gzip -9 > "$x/Payload"
	lsbom "$x/Bom" | grep -v '/\._' > "$WORK/bom.txt"
	rm -f "$x/Bom"
	mkbom -i "$WORK/bom.txt" "$x/Bom"
	find "$x/Scripts" -name '._*' -delete
	files="$(wc -l < "$WORK/bom.txt" | tr -d ' ')"
	sed -i '' -E "s/numberOfFiles=\"[0-9]+\"/numberOfFiles=\"$files\"/" "$x/PackageInfo"
	rm -f "$pkg"
	COPYFILE_DISABLE=1 pkgutil --flatten "$x" "$pkg"
	rm -rf "$x"
	if pkgutil --payload-files "$pkg" | grep -q '/\._'; then
		echo "AppleDouble files are still in the payload of $pkg" >&2
		exit 1
	fi
}
strip_appledouble "$WORK/packages/BandwidthMeter-component.pkg"

# --- Product archive (the pkg people double-click) -------------------------
step "building $PKG_NAME"
sed "s/@VERSION@/$VERSION/g" packaging/installer/welcome.html > "$WORK/resources/welcome.html"
sed "s/@VERSION@/$VERSION/g" packaging/installer/conclusion.html > "$WORK/resources/conclusion.html"
cp LICENSE "$WORK/resources/License.txt"
sed -e "s/@VERSION@/$VERSION/g" -e "s/@COMPONENT@/BandwidthMeter-component.pkg/g" \
	packaging/installer/distribution.xml > "$WORK/distribution.xml"

productbuild_sign=()
if [[ -n "$DEVELOPER_ID_INSTALLER" ]]; then
	productbuild_sign=(--sign "$DEVELOPER_ID_INSTALLER" --timestamp)
fi
productbuild \
	--distribution "$WORK/distribution.xml" \
	--resources "$WORK/resources" \
	--package-path "$WORK/packages" \
	${productbuild_sign[@]+"${productbuild_sign[@]}"} \
	"$WORK/$PKG_NAME" >/dev/null

# --- Uninstaller ------------------------------------------------------------
step "building $UNINSTALLER_NAME"
UNINSTALLER="$WORK/$UNINSTALLER_NAME"
osacompile -o "$UNINSTALLER" packaging/uninstaller/Uninstall.applescript 2>/dev/null
cp packaging/uninstaller/uninstall.sh "$UNINSTALLER/Contents/Resources/uninstall.sh"
chmod 755 "$UNINSTALLER/Contents/Resources/uninstall.sh"
plist="$UNINSTALLER/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "$APP_ID.uninstaller" "$plist"
plutil -replace CFBundleName -string "Uninstall $APP_NAME" "$plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$plist"
plutil -replace LSMinimumSystemVersion -string "14.0" "$plist"
if [[ -n "$DEVELOPER_ID_APP" ]]; then
	codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APP" "$UNINSTALLER"
else
	codesign --force --sign - "$UNINSTALLER" 2>/dev/null
fi
codesign --verify --strict --deep "$UNINSTALLER"

# --- Disk image -------------------------------------------------------------
tiffutil -cathidpicheck packaging/dmg/background.png packaging/dmg/background@2x.png \
	-out "$WORK/background.tiff" 2>/dev/null

if [[ "$DMG_LAYOUT" != "plain" && -z "${DMGBUILD:-}" ]]; then
	venv=".build/tools/dmgbuild-$DMGBUILD_VERSION"
	if [[ ! -x "$venv/bin/dmgbuild" ]]; then
		step "installing dmgbuild $DMGBUILD_VERSION into $venv"
		if ! { python3 -m venv "$venv" && "$venv/bin/pip" install --quiet --disable-pip-version-check "dmgbuild==$DMGBUILD_VERSION"; }; then
			rm -rf "$venv"
		fi
	fi
	if [[ -x "$venv/bin/dmgbuild" ]]; then
		DMGBUILD="$venv/bin/dmgbuild"
	fi
fi

mkdir -p "$DIST_DIR"
if [[ "$DMG_LAYOUT" != "plain" && -n "${DMGBUILD:-}" ]]; then
	step "building $DMG with dmgbuild"
	rw="$WORK/layout-rw.dmg"
	"$DMGBUILD" -s packaging/dmg/settings.py \
		-D pkg="$WORK/$PKG_NAME" \
		-D uninstaller="$UNINSTALLER" \
		-D background="$WORK/background.tiff" \
		-D format=UDRW \
		"$APP_NAME" "$rw" >/dev/null
	# Move the background into .background/ and hide the dot files, then
	# compress. dmgbuild shrinks the image to the minimum, so give it room.
	hdiutil resize -quiet -size 16m "$rw"
	rwmnt="$(mktemp -d "${TMPDIR:-/tmp}/bandwidth-meter-rw.XXXXXX")"
	hdiutil attach -quiet -nobrowse -owners off -noautoopen -mountpoint "$rwmnt" "$rw"
	finish_status=0
	"$(dirname "$DMGBUILD")/python" packaging/dmg/finish-layout.py "$rwmnt" >/dev/null || finish_status=1
	rm -rf "$rwmnt/.fseventsd" "$rwmnt/.Trashes"
	sync
	hdiutil detach -quiet "$rwmnt" || hdiutil detach -quiet -force "$rwmnt"
	rmdir "$rwmnt" 2>/dev/null || true
	[[ $finish_status -eq 0 ]] || { echo "finish-layout.py failed" >&2; exit 1; }
	hdiutil resize -quiet -sectors min "$rw"
	hdiutil convert -quiet "$rw" -format ULFO -ov -o "$DMG"
	rm -f "$rw"
else
	if [[ "$DMG_LAYOUT" != "plain" ]]; then
		echo "warning: dmgbuild is not available, so the disk image has no window layout" >&2
	fi
	step "building $DMG with hdiutil"
	mkdir -p "$WORK/dmg"
	ditto "$WORK/$PKG_NAME" "$WORK/dmg/$PKG_NAME"
	ditto "$UNINSTALLER" "$WORK/dmg/$UNINSTALLER_NAME"
	hdiutil create -quiet -ov -volname "$APP_NAME" -srcfolder "$WORK/dmg" \
		-fs HFS+ -format ULFO "$DMG"
fi

if [[ -n "$DEVELOPER_ID_APP" ]]; then
	codesign --force --timestamp --sign "$DEVELOPER_ID_APP" "$DMG"
fi
if [[ -n "$NOTARY_PROFILE" ]]; then
	step "notarizing $DMG"
	xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
	xcrun stapler staple "$DMG"
fi

hdiutil verify -quiet "$DMG"

# Check what people will actually get: both items, a valid uninstaller
# signature, and a pkg that installs the app to /Applications.
step "checking $DMG"
fail() { echo "$DMG: $*" >&2; return 1; }
check_mounted() {
	local mnt="$1" payload
	[[ -f "$mnt/$PKG_NAME" ]] || fail "missing $PKG_NAME" || return 1
	[[ -d "$mnt/$UNINSTALLER_NAME" ]] || fail "missing $UNINSTALLER_NAME" || return 1
	codesign --verify --strict --deep "$mnt/$UNINSTALLER_NAME" ||
		fail "the uninstaller's signature doesn't verify" || return 1
	installer -pkginfo -pkg "$mnt/$PKG_NAME" >/dev/null ||
		fail "installer can't read the pkg" || return 1
	payload="$(pkgutil --payload-files "$mnt/$PKG_NAME")" ||
		fail "pkgutil can't read the pkg payload" || return 1
	grep -qx "./$APP_NAME.app/Contents/Helpers/bandwidth-meter" <<<"$payload" ||
		fail "the pkg payload has no Helpers/bandwidth-meter" || return 1
	if grep -q '/\._' <<<"$payload"; then
		fail "the pkg payload has AppleDouble files"
		return 1
	fi
	if [[ "$DMG_LAYOUT" != "plain" && -n "${DMGBUILD:-}" ]]; then
		[[ -f "$mnt/.background/background.tiff" && ! -e "$mnt/.background.tiff" ]] ||
			fail "the background isn't in .background/" || return 1
	fi
}
mnt="$(mktemp -d "${TMPDIR:-/tmp}/bandwidth-meter-dmg.XXXXXX")"
hdiutil attach -quiet -nobrowse -readonly -noautoopen -mountpoint "$mnt" "$DMG"
check_status=0
check_mounted "$mnt" || check_status=1
hdiutil detach -quiet "$mnt" || hdiutil detach -quiet -force "$mnt"
rmdir "$mnt" 2>/dev/null || true
[[ $check_status -eq 0 ]] || exit 1
size="$(du -h "$DMG" | cut -f1 | tr -d ' ')"
echo "packed $DMG ($size)"
