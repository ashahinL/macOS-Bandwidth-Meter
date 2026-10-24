# Contributing

Thanks for taking a look.

## Getting set up

```sh
git clone https://github.com/ashahinL/macOS-Bandwidth-Meter.git
cd macOS-Bandwidth-Meter
make          # build the menu bar app and CLI
make test     # run the self-test suite
make dist     # zip the app, the CLI, and a combined archive
make shots    # render the README screenshots into docs/screenshots
```

You need Xcode Command Line Tools (`xcode-select --install`) and macOS 14 or
later. Bandwidth+ is optional for the tests: the live-history check is skipped
when its files are not on the machine.

## Before opening a pull request

- `make test` passes.
- New period, merge, or CSV behaviour comes with a check in
  `Sources/MeterSelfTest/main.swift`. The suite uses synthetic daily records, so
  you can cover weeks and billing cycles without waiting for real traffic.
- Swift style matches what is there. The shared logic lives in `MeterCore`.
  The SwiftUI views and the controller live in `MeterUI`. The app and the CLI
  are thin layers over them.
- A change you can see in the panel, the settings, the menu bar label, or the
  CLI summary comes with fresh screenshots from `make shots`. Look at every PNG
  in `docs/screenshots/` before committing them. The demo data is in
  `Sources/MeterShots/DemoData.swift`; keep the network names made up.
- A change people will notice adds a line under `## [Unreleased]` in
  `CHANGELOG.md`.
- A change to what the app reads, stores, or sends updates
  [PRIVACY.md](PRIVACY.md) in the same pull request.

## The rule that matters

**Do not throw away a more precise reading for a rounded one.** Bandwidth+
exports CSV in decimal megabytes. The live `History` and `Data` files hold byte
counters. A same-day merge must keep the Bandwidth+ live bytes, not `max()` of
the live row and the CSV row, or a later CSV import will replace exact totals
with rounded ones.

When both rows are live Bandwidth+ bytes, keep the larger down and the larger
up. A later smaller copy of that day must not replace a finished one.

The self-test has a check for that — please keep it passing.

## Menu bar extra

macOS dismisses a `MenuBarExtra` window when an `NSMenu`, `Picker`, or sheet
steals key focus. Settings and the network filter have to stay inside the extra
(chips, steppers, a cycle button) rather than opening a system menu. The menu
bar label must be a **single** `Text`; extra views in the label are clipped.

## If the build can't find `SwiftUIMacros`

Some Command Line Tools betas ship a default macOS SDK whose SwiftUI needs a
macro plugin the tools don't include. The build then fails on every `@State`
with "plugin for module 'SwiftUIMacros' not found". Point the build at the
older SDK that came with the same tools:

```sh
ls /Library/Developer/CommandLineTools/SDKs
export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
make test
```

## Reporting a bug

Include your macOS version (`sw_vers`), whether Bandwidth+ is installed, and
the output of:

```sh
bandwidth-meter
bandwidth-meter --help
```

Security or privacy problems go through a private report instead. See
[SECURITY.md](SECURITY.md). [RELEASING.md](RELEASING.md) covers how a version
ships.
