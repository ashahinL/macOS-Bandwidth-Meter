#!/bin/sh
# Does the work for "Uninstall.app" on the disk image. The app asks first and
# runs the `system` step with administrator rights.
#
#   uninstall.sh status                 list what is installed, one per line:
#                                         system:<path>  needs admin to remove
#                                         user:<path>    an older copy in your home
#                                         data:<path>    saved totals and settings
#   uninstall.sh system                 quit the app, remove the app, the
#                                       command, and the installer receipt
#   uninstall.sh user [--delete-data]   remove ~/.local/bin/bandwidth-meter
#                                       (left by the 1.0 zips), and the saved
#                                       data only with --delete-data
#
# BM_ROOT and BM_HOME point it at a fake / and ~ for tests. With BM_ROOT set
# it does not quit processes or touch pkgutil receipts.

set -u

ROOT="${BM_ROOT:-}"
HOME_DIR="${BM_HOME:-$HOME}"
APP="$ROOT/Applications/Bandwidth Meter.app"
APP_ID="dev.ashahin.BandwidthMeter"
CLI="$ROOT/usr/local/bin/bandwidth-meter"
PKG_ID="dev.ashahin.BandwidthMeter.pkg"
OLD_CLI="$HOME_DIR/.local/bin/bandwidth-meter"
DATA="$HOME_DIR/Library/Application Support/BandwidthMeter"
PREFS="$HOME_DIR/Library/Preferences/$APP_ID.plist"

is_our_app() {
	[ -d "$APP" ] || return 1
	id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist" 2>/dev/null)"
	[ "$id" = "$APP_ID" ]
}

has_file() {
	[ -f "$1" ] || [ -L "$1" ]
}

case "${1:-}" in
	status)
		is_our_app && echo "system:$APP"
		has_file "$CLI" && echo "system:$CLI"
		has_file "$OLD_CLI" && echo "user:$OLD_CLI"
		{ [ -d "$DATA" ] || [ -f "$PREFS" ]; } && echo "data:$DATA"
		exit 0
		;;
	system)
		status=0
		if [ -z "$ROOT" ]; then
			/usr/bin/pkill -x BandwidthMeter 2>/dev/null
			sleep 1
		fi
		if is_our_app; then
			/bin/rm -rf "$APP" && echo "removed $APP" || status=1
		elif [ -d "$APP" ]; then
			echo "left $APP alone: it is not $APP_ID" >&2
		fi
		if has_file "$CLI"; then
			/bin/rm -f "$CLI" && echo "removed $CLI" || status=1
		fi
		if [ -z "$ROOT" ] && /usr/sbin/pkgutil --pkg-info "$PKG_ID" >/dev/null 2>&1; then
			/usr/sbin/pkgutil --forget "$PKG_ID" >/dev/null && echo "forgot receipt $PKG_ID" || status=1
		fi
		exit "$status"
		;;
	user)
		status=0
		if has_file "$OLD_CLI"; then
			/bin/rm -f "$OLD_CLI" && echo "removed $OLD_CLI" || status=1
		fi
		if [ "${2:-}" = "--delete-data" ]; then
			if [ -d "$DATA" ]; then
				/bin/rm -rf "$DATA" && echo "removed $DATA" || status=1
			fi
			if [ -f "$PREFS" ]; then
				if [ -z "${BM_HOME:-}" ]; then
					# Through cfprefsd, so a cached copy doesn't come back.
					/usr/bin/defaults delete "$APP_ID" 2>/dev/null
				fi
				/bin/rm -f "$PREFS" && echo "removed $PREFS" || status=1
			fi
		fi
		exit "$status"
		;;
	*)
		echo "usage: uninstall.sh status | system | user [--delete-data]" >&2
		exit 2
		;;
esac
