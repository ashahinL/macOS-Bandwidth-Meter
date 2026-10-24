# Fix the five number bugs

Status: in progress. Tasks 1 to 4 are done.

The menu bar app and the CLI already share MeterCore. These tasks fix wrong totals and quiet failures. Each task is one commit. `make test` is the check.

## Tasks

1. Done. Live self-test. Drop the home-network names and the 23 Aug 2026 total. When Bandwidth+ files are on the machine, decoding them must succeed, and every row must have a `yyyy-MM-dd` date, a network name, and a non-zero total. Skip the check when the files are absent.
2. Done. Merge. Two Bandwidth+ rows for the same day and network keep the larger down and the larger up. A CSV row still loses to a live row, even when the CSV number is higher.
3. Done. Default summary. `bandwidth-meter --network NAME` with no period filters every line. The summary names the network.
4. Done. Bad input. `--import` of a CSV that does not parse prints the parse error and does not say "no usage yet". A `usage.json` that does not decode is copied to `usage.json.bak` (or a timestamped bak if that file exists). The original is not overwritten unless that copy succeeds. The error is printed. The menu bar shows it.
5. Bandwidth+ read failure. If `History` or `Data` exists but does not decode, the status says so and the last saved rows stay on screen. Missing files are not an error. A decoded archive still loads.

## Out of scope

Sampler spikes, quota in the menu bar, polling, notarization, and version display.
