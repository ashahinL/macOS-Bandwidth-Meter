# Contributing

Thanks for taking a look.

## Getting set up

```sh
git clone https://github.com/ashahinL/macOS-Bandwidth-Meter.git
cd macOS-Bandwidth-Meter
make          # build the menu bar app and CLI
make test     # run the self-test suite
make dist     # zip the app, the CLI, and a combined archive
```

You need Xcode Command Line Tools (`xcode-select --install`) and macOS 14 or
later. Bandwidth+ is optional for the tests: the live-history check is skipped
when its files are not on the machine.

## Before opening a pull request

- `make test` passes.
- New period, merge, or CSV behaviour comes with a check in
  `Sources/MeterSelfTest/main.swift`. The suite uses synthetic daily records, so
  you can cover weeks and billing cycles without waiting for real traffic.
- Swift style matches what is there: the shared logic lives in `MeterCore`, the
  GUI and CLI are thin layers over it.

## The rule that matters

**Do not throw away a more precise reading for a rounded one.** Bandwidth+
exports CSV in decimal megabytes; the live `History` / `Data` files hold byte
counters. A same-day merge must keep the Bandwidth+ live bytes, not `max()` of
the two, or a later CSV import will replace exact totals with rounded ones.

The self-test has a check for that — please keep it passing.

## Menu bar extra

macOS dismisses a `MenuBarExtra` window when an `NSMenu`, `Picker`, or sheet
steals key focus. Settings and the network filter have to stay inside the extra
(chips, steppers, a cycle button) rather than opening a system menu. The menu
bar label must be a **single** `Text`; extra views in the label are clipped.

## Reporting a bug

Include your macOS version (`sw_vers`), whether Bandwidth+ is installed, and
the output of:

```sh
bandwidth-meter
bandwidth-meter --help
```
