#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
make test app install
echo
"$HOME/.local/bin/bandwidth-meter"
