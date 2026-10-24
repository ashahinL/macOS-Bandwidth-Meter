# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- Releases ship one disk image, `Bandwidth-Meter-<version>.dmg`, instead of three zips. Double-click **Install** in it to put the app in `/Applications` and the `bandwidth-meter` command in `/usr/local/bin`. No Terminal needed.
- The installer quits a running copy first, keeps your history and settings when it updates, and opens the app when it finishes.
- The disk image also has **Uninstall**. It removes the app, the command, and the installer receipt, and deletes your saved totals only if you say so.
- The README explains how to open the installer on macOS 15 and later, where right-click › Open no longer gets past Gatekeeper.
- `make dmg` (and `make dist`) builds the disk image. `scripts/build-dmg.sh` can sign and notarize it when Developer ID settings are given.

### Removed
- The app, CLI, and combined zips, and the `install.sh` that came with the combined zip.

## [1.0.1] - 2026-10-24

### Added
- README screenshots drawn from the app's own views with demo data. `make shots` renders them again.
- `PRIVACY.md` lists every file the app reads and writes. `SECURITY.md` explains how to report a problem privately, and `RELEASING.md` how a version ships.
- Release notes live in `docs/release-notes/`. The release workflow uses them for the GitHub release.

### Fixed
- A later Bandwidth+ read keeps the larger down and up totals for that day and network. A smaller today file no longer replaces a finished history day.
- `bandwidth-meter --network NAME` filters the default summary, not only a single period.
- A CSV import that cannot be parsed prints the parse error.
- A usage file that cannot be read is copied to `usage.json.bak`. It is not overwritten when that copy fails. The menu bar and the CLI show the error.
- When a Bandwidth+ history file cannot be read, the menu bar says so and keeps the last saved totals.

### Changed
- The panel drops the "METER" label and the box around the total. Import, Export, and Quit stay at the bottom. A failed import or export shows its error there.
- The monthly quota bar uses the download color, and turns red after 90 percent.
- Settings labels are sentence case, and Done is a button.

## [1.0.0] - 2026-08-24

### Added
- **Weekly and monthly totals** rolled up from Bandwidth+ daily history:
  today, yesterday, this week, last week, this month, last month, last 30 days,
  this year, and all time.
- **Menu bar dashboard** (SwiftUI `MenuBarExtra`, `LSUIElement`) showing the
  selected period, download/upload split, a daily chart, per-network breakdown,
  and per-day rows. The menu bar label is a single compact total (for example
  `11.6G`) so macOS does not clip it.
- **`bandwidth-meter` CLI** for on-demand checks. Bandwidth+ stays running to
  capture each day; the CLI does not need to stay open.
- **Live Bandwidth+ reader** for the sandboxed `History` and `Data`
  NSKeyedArchiver files, including today's still-open counters.
- **CSV import** of a Bandwidth+ `History.csv` export (decimal MB, 1 MB =
  1,000,000 bytes), with a Desktop `History.csv` fallback when live history is
  missing.
- **Merge policy** that prefers Bandwidth+ live bytes over rounded CSV figures
  for the same day and network.
- **Network filter** so totals can be limited to one Wi-Fi / interface name.
- **ISO weeks** that start on Monday by default, and **billing months** that
  can start on a day other than the 1st.
- **Local store** at `~/Library/Application Support/BandwidthMeter/usage.json`.
- **JSON output** (`bandwidth-meter json` or `--json`) for scripts.
- **Self-test executable** covering period math, CSV parsing, merge ranks, and
  CLI tokens. A live Bandwidth+ check runs only when that app's history is
  present.
- **Prebuilt GitHub Release zips** for Apple Silicon: menu bar app, CLI, or
  both (with `install.sh`), so you do not have to build from source.

[1.0.1]: https://github.com/ashahinL/macOS-Bandwidth-Meter/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/ashahinL/macOS-Bandwidth-Meter/releases/tag/v1.0.0
