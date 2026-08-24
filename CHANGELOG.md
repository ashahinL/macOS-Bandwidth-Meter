# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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

[1.0.0]: https://github.com/ashahinL/macOS-Bandwidth-Meter/releases/tag/v1.0.0
