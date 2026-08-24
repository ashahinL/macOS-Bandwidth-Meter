#!/bin/bash
# Install from a GitHub Release zip. Lives next to Bandwidth Meter.app
# and/or bandwidth-meter.
#
#   ./install.sh           app + CLI (whichever is in this folder)
#   ./install.sh --app     menu bar app only
#   ./install.sh --cli     CLI only
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
APP_SRC="$DIR/Bandwidth Meter.app"
CLI_SRC="$DIR/bandwidth-meter"
APP_DEST="/Applications/Bandwidth Meter.app"
CLI_DEST="${HOME}/.local/bin/bandwidth-meter"

want_app=0
want_cli=0

usage() {
	cat <<'EOF'
Install Bandwidth Meter from this folder.

  ./install.sh           app + CLI (whichever files are present)
  ./install.sh --app     menu bar app → /Applications
  ./install.sh --cli     CLI → ~/.local/bin
  ./install.sh --all     both
EOF
}

if [[ $# -eq 0 ]]; then
	want_app=1
	want_cli=1
else
	for arg in "$@"; do
		case "$arg" in
			--app) want_app=1 ;;
			--cli) want_cli=1 ;;
			--all)
				want_app=1
				want_cli=1
				;;
			-h|--help)
				usage
				exit 0
				;;
			*)
				echo "unknown option: $arg" >&2
				usage >&2
				exit 2
				;;
		esac
	done
fi

installed=0

if [[ "$want_app" -eq 1 ]]; then
	if [[ ! -d "$APP_SRC" ]]; then
		if [[ $# -gt 0 ]]; then
			echo "Bandwidth Meter.app not found in $DIR" >&2
			exit 1
		fi
	else
		pkill -x BandwidthMeter 2>/dev/null || true
		rm -rf "$APP_DEST"
		cp -R "$APP_SRC" "$APP_DEST"
		xattr -cr "$APP_DEST" 2>/dev/null || true
		echo "installed $APP_DEST"
		installed=1
	fi
fi

if [[ "$want_cli" -eq 1 ]]; then
	if [[ ! -f "$CLI_SRC" ]]; then
		if [[ $# -gt 0 ]]; then
			echo "bandwidth-meter not found in $DIR" >&2
			exit 1
		fi
	else
		mkdir -p "$(dirname "$CLI_DEST")"
		cp "$CLI_SRC" "$CLI_DEST"
		chmod +x "$CLI_DEST"
		xattr -cr "$CLI_DEST" 2>/dev/null || true
		echo "installed $CLI_DEST"
		installed=1
	fi
fi

if [[ "$installed" -eq 0 ]]; then
	echo "nothing to install in $DIR" >&2
	exit 1
fi

case ":$PATH:" in
	*":$HOME/.local/bin:"*) ;;
	*)
		echo
		echo "Put ~/.local/bin on your PATH if you want to run bandwidth-meter from any directory."
		;;
esac
