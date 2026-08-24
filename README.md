# Bandwidth Meter

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Platform: macOS](https://img.shields.io/badge/Platform-macOS%2014%2B-brightgreen.svg)
![Architecture: Apple Silicon](https://img.shields.io/badge/Arch-Apple%20Silicon-orange.svg)
![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-purple.svg)

Weekly and monthly bandwidth totals from [Bandwidth+](https://apps.apple.com/app/bandwidth/id490461369) daily history.

Bandwidth+ is excellent at capturing live speed and each day's usage. It does
not give you this week, last week, this month, or last month. This tool reads
the same daily records Bandwidth+ already keeps and rolls them up.

Keep Bandwidth+ running for capture. Run `bandwidth-meter` every couple of days
when you want the totals — the CLI does not need to stay open. The menu bar
app is there when you want a dashboard.

```
┌──────────────────────────────────────┐
│  METER                    [Wi-Fi] ⚙  │
│  Source: Bandwidth+ live history     │
│ ──────────────────────────────────── │
│  Today   Week   Month   All          │
│                                      │
│           12.32 GB                   │
│        ↓ 11.28 GB  ↑ 1.04 GB         │
│ ──────────────────────────────────── │
│  by network                          │
│  home-5G              10.56 GB       │
│  home                 1.76 GB        │
│ ──────────────────────────────────── │
│  by day                              │
│  2026-08-23           8.68 GB        │
│  2026-08-24           3.64 GB        │
└──────────────────────────────────────┘
```

The menu bar itself shows the compact total for the period you pick in
settings, for example `11.6G`.

This project is not affiliated with Bandwidth+.

## Features

- **This week / last week / this month / last month** — plus today, yesterday,
  last 30 days, this year, and all time
- **CLI** — `bandwidth-meter` prints a summary and exits
- **Menu bar dashboard** — period chips, daily chart, per-network and per-day
  breakdowns
- **Reads Bandwidth+ live** — sandboxed `History` and today's `Data` files, so
  you do not have to export a CSV first
- **CSV import** — merges a Bandwidth+ `History.csv` export when you have one
- **Per-network totals** — filter one Wi-Fi name from the CLI or the dashboard
- **Monday weeks** by default, with an optional billing-cycle start day
- **Decimal SI units** — 1 MB = 1,000,000 bytes, matching Bandwidth+'s CSV
- **Does not replace Bandwidth+** — that app keeps capturing; this one
  aggregates

## How it works

Bandwidth+ writes one row per day per network. This tool reads those rows,
merges them into a local store, and sums the days that fall in the period you
asked for.

```
Bandwidth+  ──►  History + Data (NSKeyedArchiver)
                    │
                    ├── optional History.csv
                    ▼
              MeterCore merge
                    │
                    ▼
     ~/Library/Application Support/BandwidthMeter/usage.json
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
   bandwidth-meter      Bandwidth Meter.app
```

Live Bandwidth+ byte counters outrank a rounded CSV export for the same day and
network, so re-importing the CSV cannot clobber a more precise reading.

Weeks are ISO-style and start on Monday unless you change that. A month is a
calendar month, or a billing cycle if you set the start day to something other
than 1.

## Requirements

- macOS 14 or later
- **Apple Silicon.** Developed on an M-series Mac running macOS 26.
- [Bandwidth+](https://apps.apple.com/app/bandwidth/id490461369) from the Mac
  App Store, left running so each day is recorded

## Install

### Download (recommended)

Grab a zip from [Releases](https://github.com/ashahinL/macOS-Bandwidth-Meter/releases). No Xcode.

| File | What you get |
|---|---|
| `Bandwidth-Meter-*-full-macos-arm64.zip` | **Both** — app, CLI, and `install.sh` |
| `Bandwidth-Meter-*.app.zip` | Menu bar app only |
| `Bandwidth-Meter-*-cli-macos-arm64.zip` | CLI only |

**Both.** Unzip the combined archive and run the installer:

```sh
unzip Bandwidth-Meter-*-full-macos-arm64.zip
cd Bandwidth-Meter-*-full-macos-arm64
./install.sh              # app + CLI
# ./install.sh --app      # menu bar only
# ./install.sh --cli      # CLI only
```

That copies the app to `/Applications` and the CLI to `~/.local/bin`, and
clears the download quarantine so Gatekeeper does not block them.

**App only.** Unzip and drag **Bandwidth Meter.app** to `/Applications`. The
build is not notarized, so the first launch is right-click → Open (or run
`xattr -cr "/Applications/Bandwidth Meter.app"`).

**CLI only.** Unzip and put `bandwidth-meter` on your `PATH`:

```sh
unzip Bandwidth-Meter-*-cli-macos-arm64.zip
mkdir -p ~/.local/bin
cp bandwidth-meter ~/.local/bin/
chmod +x ~/.local/bin/bandwidth-meter
xattr -cr ~/.local/bin/bandwidth-meter
```

Put `~/.local/bin` on your `PATH` if it is not already. Then:

```sh
bandwidth-meter
```

The menu bar app is optional. Open it only when you want the dashboard:

```sh
open "/Applications/Bandwidth Meter.app"
```

### Build from source

```sh
xcode-select --install    # once, if you do not have Command Line Tools

git clone https://github.com/ashahinL/macOS-Bandwidth-Meter.git
cd macOS-Bandwidth-Meter

make                    # build the menu bar app and CLI
make install            # CLI → ~/.local/bin, app → /Applications
```

## Usage

### Command line (the usual way)

```sh
bandwidth-meter                 # full summary
bandwidth-meter today
bandwidth-meter week
bandwidth-meter last-week
bandwidth-meter month
bandwidth-meter last-month
bandwidth-meter 30d
bandwidth-meter year
bandwidth-meter all
```

```
$ bandwidth-meter
Bandwidth Meter
24 Aug 2026
Source: Bandwidth+ live history

Today           3.64 GB   ↓ 3.29 GB   ↑ 348.8 MB
Yesterday       8.68 GB   ↓ 7.99 GB   ↑ 692.7 MB
This week       12.32 GB   ↓ 11.28 GB   ↑ 1.04 GB
Last week       0 B   ↓ 0 B   ↑ 0 B
This month      12.32 GB   ↓ 11.28 GB   ↑ 1.04 GB
…
This month by network
  home-5G                       10.56 GB
  home                          1.76 GB

This month by day
  2026-08-23    8.68 GB
  2026-08-24    3.64 GB
```

| Flag / extra | What it does |
|---|---|
| `--import FILE.csv` | Merge a Bandwidth+ History.csv export |
| `--network NAME` | Limit totals to one Wi-Fi / interface name |
| `--json` or `json` | Machine-readable output |
| `--help` | Usage text |

```sh
bandwidth-meter month --network "Home"
bandwidth-meter --import ~/Desktop/History.csv
bandwidth-meter week --json
```

### Menu bar app

Click the compact total in the menu bar. Pick a period, cycle the network
filter, and open settings from the gear. Settings stay inside the popup —
system menus and pickers would dismiss the extra entirely.

The label can show the period total or live speed (settings → “Show live speed
in menu bar”). Live speed is sampled from 64-bit interface counters; the
weekly and monthly numbers still come from Bandwidth+ history.

## Uninstall

```sh
rm -f ~/.local/bin/bandwidth-meter
rm -rf "/Applications/Bandwidth Meter.app"
```

If you still have the repo checked out, `make uninstall` does the same.

That does not touch Bandwidth+ or the local store. To drop the store as well:

```sh
rm -rf ~/Library/Application\ Support/BandwidthMeter
```

## Testing

```sh
make test
```

The suite is a Swift executable (`MeterSelfTest`) rather than XCTest, so it
runs against Command Line Tools alone. It covers:

- **this week / last week / this month** against known daily rows
- **network filter**
- **billing cycle** starting on a day other than the 1st
- **CSV parse** of a Bandwidth+ export
- **merge ranks** — live Bandwidth+ bytes beat rounded CSV
- **CLI period tokens**
- **live History** — only when Bandwidth+ is installed on the machine

## Troubleshooting

**`bandwidth-meter: no usage yet`.** Bandwidth+ has not written a day yet, or
it is not installed. Leave it running, use the network, then try again. You can
also pass a CSV: `bandwidth-meter --import ~/Desktop/History.csv`.

**Totals look a day short.** Bandwidth+ records whole days. Today is read from
the live `Data` file and will keep growing until midnight.

**This week is only today.** Weeks start on Monday. If today is Monday, last
week is the previous Monday–Sunday.

**CSV and live totals disagree slightly.** The CSV is rounded to 0.1 MB. The
live files keep exact bytes; those win on merge.

**The menu bar shows only a letter, or settings close the popup.** Use a build
from this repo. The label must be a single `Text`, and settings cannot use
`NSMenu` / `Picker` / sheets.

**The menu bar extra is missing.** It is a background agent (`LSUIElement`) with
no Dock icon. Confirm it with `pgrep -fl BandwidthMeter`, then check whether
the menu bar is simply full.

**macOS says the app / CLI cannot be opened because it is from an unidentified
developer.** The GitHub zips are ad-hoc signed, not notarized. Use
`./install.sh` from the combined zip, or right-click the app → Open, or:

```sh
xattr -cr "/Applications/Bandwidth Meter.app"
xattr -cr ~/.local/bin/bandwidth-meter
```

## Layout

```
Sources/MeterCore/              shared aggregation, Bandwidth+ reader, CSV, store
Sources/BandwidthMeter/         SwiftUI menu bar app
Sources/BandwidthMeterCLI/      bandwidth-meter command
Sources/InterfaceCounters/      64-bit interface counters (C)
Sources/MeterSelfTest/          self-test executable
Resources/Info.plist            app bundle metadata
scripts/install-release.sh      copied into the combined zip as install.sh
Makefile                        build, test, dist, install
build.sh                        make test app install, then print a summary
.github/workflows/ci.yml        test, build, and pack zips on macOS
.github/workflows/release.yml   attach zips when a v* tag is pushed
```

The dependency runs one way: GUI and CLI both call `MeterCore`. Anything the
dashboard can show is also available from the terminal.

## License

MIT — see [LICENSE](LICENSE).
